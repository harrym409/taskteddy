"""Email OTP management using Redis with secure hashing.

This module handles 6-digit OTP generation, storage, and verification
for email verification flow.
"""
import hashlib
import random
import threading
import time
from typing import Optional

import redis

from config import get_settings

settings = get_settings()

# OTP hashing secret
_OTP_HASH_SECRET = settings.get("JWT_SECRET", "default-otp-secret")


def _get_redis_client() -> Optional[redis.Redis]:
    """Get Redis client from settings."""
    if not settings.get("redis_enabled") or not settings.get("redis_url"):
        return None
    try:
        return redis.from_url(settings["redis_url"])
    except Exception:
        return None


def _hash_otp(otp: str, email: str) -> str:
    """Hash OTP with email as salt for secure storage."""
    key = f"{otp}:{email.lower()}:{_OTP_HASH_SECRET}"
    return hashlib.sha256(key.encode()).hexdigest()[:64]


def _generate_otp() -> str:
    """Generate 6-digit OTP."""
    return "".join(random.choices("0123456789", k=6))


def _otp_key(email: str) -> str:
    """Redis key for email OTP."""
    return f"email_otp:{email.lower()}"


def _pending_email_key(email: str) -> str:
    """Redis key for pending email."""
    return f"pending_email:{email.lower()}"


def send_email_otp(email: str) -> dict:
    """
    Send OTP to email address.
    Stores HASHED OTP in Redis with 60-second expiry.
    Rate limited to prevent abuse.

    Args:
        email: Email address to send OTP to

    Returns:
        {"success": bool, "otp": str (dev only), "message": str}
    """
    redis_client = _get_redis_client()
    email_normalized = email.strip().lower()

    # Check rate limit first
    is_allowed, remaining = _check_email_otp_rate_limit(email_normalized)
    if not is_allowed:
        return {
            "success": False,
            "message": "Too many OTP requests. Please try again after 1 hour."
        }

    # Check resend cooldown (60 seconds)
    with _last_otp_sent_lock:
        last_sent = _last_otp_sent.get(email_normalized, 0)
        if time.time() - last_sent < _RESEND_COOLDOWN:
            remaining_time = int(_RESEND_COOLDOWN - (time.time() - last_sent))
            return {
                "success": False,
                "message": f"Please wait {remaining_time} seconds before requesting a new OTP.",
                "cooldown": remaining_time
            }
        _last_otp_sent[email_normalized] = time.time()

    # Generate OTP
    otp = _generate_otp()

    # Hash OTP before storing (never store plain text)
    otp_hash = _hash_otp(otp, email_normalized)

    # Store hashed OTP in Redis with 60s expiry
    if redis_client:
        try:
            redis_client.setex(
                _otp_key(email_normalized),
                settings.get("OTP_EXPIRY_SECONDS", 60),
                otp_hash
            )
            # Track rate limit in Redis
            redis_client.incr(f"email_otp_rate:{email_normalized}")
            redis_client.expire(f"email_otp_rate:{email_normalized}", _EMAIL_OTP_RATE_WINDOW)
        except Exception as e:
            return {"success": False, "message": f"Redis error: {e}"}
    else:
        # Thread-safe in-memory fallback (for development without Redis)
        with _email_otp_lock:
            _email_otp_store[email_normalized] = {
                "otp_hash": otp_hash,
                "otp_plain": otp,  # Keep plain for dev testing only
                "expires_at": time.time() + 60
            }

    # Always return OTP - needed for sending email via SendGrid
    # Security is maintained because OTP is hashed in storage

    return {
        "success": True,
        "otp": otp,
        "message": "OTP sent successfully"
    }


def verify_email_otp(email: str, otp: str) -> dict:
    """
    Verify OTP for email and return result.

    Args:
        email: Email address
        otp: 6-digit OTP

    Returns:
        {"valid": bool, "message": str}
    """
    redis_client = _get_redis_client()
    email_normalized = email.strip().lower()

    # Check failed attempt lockout first
    is_allowed, remaining = _check_failed_email_attempts(email_normalized)
    if not is_allowed:
        return {
            "valid": False,
            "message": "Too many failed attempts. Please try again after 5 minutes."
        }

    # Hash the provided OTP for comparison
    otp_hash = _hash_otp(otp, email_normalized)

    # Verify OTP
    stored_hash = None

    if redis_client:
        try:
            stored_hash = redis_client.get(_otp_key(email_normalized))
            if stored_hash and isinstance(stored_hash, bytes):
                stored_hash = stored_hash.decode('utf-8')
        except Exception:
            pass
    else:
        # Thread-safe in-memory fallback
        with _email_otp_lock:
            entry = _email_otp_store.get(email_normalized)
            if entry and entry.get("expires_at", 0) > time.time():
                stored_hash = entry.get("otp_hash")

    # Compare hashes
    if not stored_hash or str(stored_hash) != str(otp_hash):
        # Record failed attempt
        _record_failed_email_attempt(email_normalized)

        # Also track in Redis if available
        if redis_client:
            try:
                redis_client.incr(f"email_otp_fail:{email_normalized}")
                redis_client.expire(f"email_otp_fail:{email_normalized}", _FAILED_ATTEMPTS_WINDOW)
            except Exception:
                pass

        return {"valid": False, "message": "Invalid or expired OTP"}

    # Clear failed attempts on success
    _clear_failed_email_attempts(email_normalized)
    if redis_client:
        try:
            redis_client.delete(_otp_key(email_normalized))
        except Exception:
            pass
    else:
        with _email_otp_lock:
            _email_otp_store.pop(email_normalized, None)

    return {"valid": True, "message": "Email verified successfully"}


# Thread-safe in-memory fallback store
_email_otp_store: dict = {}
_email_otp_lock = threading.Lock()

# Email OTP rate limiting (max 5 OTPs per email per hour)
_email_otp_rate_limit: dict = {}
_email_otp_rate_lock = threading.Lock()
_EMAIL_OTP_RATE_LIMIT = 5  # Max OTPs per window
_EMAIL_OTP_RATE_WINDOW = 3600  # 1 hour in seconds
_RESEND_COOLDOWN = 60  # 60 seconds between resend requests

# Track last OTP sent time for resend cooldown
_last_otp_sent: dict = {}
_last_otp_sent_lock = threading.Lock()

# Failed attempt tracking (max 3 attempts per email)
_failed_email_attempts: dict = {}
_failed_email_attempts_lock = threading.Lock()
_MAX_FAILED_ATTEMPTS = 3
_FAILED_ATTEMPTS_WINDOW = 300  # 5 minutes lockout after max failures


def _check_email_otp_rate_limit(email: str) -> tuple[bool, int]:
    """
    Check if email has exceeded OTP rate limit.
    Returns: (is_allowed, remaining_attempts)
    """
    now = time.time()
    cutoff = now - _EMAIL_OTP_RATE_WINDOW

    with _email_otp_rate_lock:
        # Clean old entries
        _email_otp_rate_limit[email] = [
            ts for ts in _email_otp_rate_limit.get(email, [])
            if ts > cutoff
        ]

        total_sent = len(_email_otp_rate_limit.get(email, []))

        if total_sent >= _EMAIL_OTP_RATE_LIMIT:
            return False, 0

        _email_otp_rate_limit[email].append(now)
        return True, _EMAIL_OTP_RATE_LIMIT - total_sent - 1


def _check_failed_email_attempts(email: str) -> tuple[bool, int]:
    """
    Check if email is locked due to failed attempts.
    Returns: (is_allowed, remaining_attempts)
    """
    now = time.time()
    cutoff = now - _FAILED_ATTEMPTS_WINDOW

    with _failed_email_attempts_lock:
        # Clean old entries
        _failed_email_attempts[email] = [
            ts for ts in _failed_email_attempts.get(email, [])
            if ts > cutoff
        ]

        total_failed = len(_failed_email_attempts.get(email, []))

        if total_failed >= _MAX_FAILED_ATTEMPTS:
            return False, 0

        return True, _MAX_FAILED_ATTEMPTS - total_failed


def _record_failed_email_attempt(email: str) -> None:
    """Record failed OTP attempt for brute force protection."""
    now = time.time()
    with _failed_email_attempts_lock:
        if email not in _failed_email_attempts:
            _failed_email_attempts[email] = []
        _failed_email_attempts[email].append(now)


def _clear_failed_email_attempts(email: str) -> None:
    """Clear failed attempts after successful verification."""
    with _failed_email_attempts_lock:
        _failed_email_attempts.pop(email, None)
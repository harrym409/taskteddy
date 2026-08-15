"""OTP management using Redis with multi-tenant support."""
import hashlib
import random
import threading
import time
import redis
from typing import Literal, Optional

from config import get_settings
from utils.sms import provider_configured, send_sms

settings = get_settings()

# OTP hashing secret (should be in env in production)
_OTP_HASH_SECRET = settings.get("JWT_SECRET", "default-otp-secret")


def _get_redis_client() -> Optional[redis.Redis]:
    """Get Redis client from settings."""
    if not settings.get("redis_enabled") or not settings.get("redis_url"):
        return None
    try:
        return redis.from_url(settings["redis_url"])
    except Exception:
        return None


def _hash_otp(otp: str, phone: str) -> str:
    """Hash OTP with phone number as salt for secure storage."""
    key = f"{otp}:{phone}:{_OTP_HASH_SECRET}"
    return hashlib.sha256(key.encode()).hexdigest()[:64]


def _generate_otp() -> str:
    """Generate 6-digit OTP."""
    return "".join(random.choices("0123456789", k=6))


def _otp_key(phone: str) -> str:
    """Redis key for OTP."""
    return f"otp:{phone}"


def _user_type_key(phone: str) -> str:
    """Redis key for user type."""
    return f"user_type:{phone}"


def send_otp(phone: str, user_type: Literal["customer", "tasker"] = "customer") -> dict:
    """
    Send OTP to phone number.
    Stores HASHED OTP in Redis with 60-second expiry.
    Rate limited to prevent abuse.
    
    Args:
        phone: Phone number
        user_type: "customer" or "tasker" (determines ID prefix)
    
    Returns: {"success": bool, "otp": str (only in dev), "message": str}
    """
    redis_client = _get_redis_client()
    phone_normalized = _normalize_phone(phone)
    
    # Check rate limit first
    is_allowed, remaining = _check_otp_rate_limit(phone_normalized)
    if not is_allowed:
        return {
            "success": False,
            "message": "Too many OTP requests. Please try again after 1 hour."
        }

    # Generate OTP
    otp = _generate_otp()
    
    # Hash OTP before storing (never store plain text)
    otp_hash = _hash_otp(otp, phone_normalized)

    # Store hashed OTP in Redis with 60s expiry
    if redis_client:
        try:
            redis_client.setex(
                _otp_key(phone_normalized),
                settings.get("OTP_EXPIRY_SECONDS", 60),
                otp_hash
            )
            # Also store user_type for verification
            redis_client.setex(
                _user_type_key(phone_normalized),
                settings.get("OTP_EXPIRY_SECONDS", 60),
                user_type
            )
            # Track rate limit in Redis too
            redis_client.incr(f"otp_rate:{phone_normalized}")
            redis_client.expire(f"otp_rate:{phone_normalized}", _OTP_RATE_WINDOW)
        except Exception as e:
            return {"success": False, "message": f"Redis error: {e}"}
    else:
        # Thread-safe in-memory fallback (for development without Redis)
        with _otp_lock:
            _otp_store[phone_normalized] = {
                "otp_hash": otp_hash,
                "otp_plain": otp,  # Keep plain for dev testing only
                "user_type": user_type,
                "expires_at": time.time() + 60
            }

    # Deliver the OTP over SMS.
    delivered = send_sms(
        phone_normalized,
        f"Your TaskTeddy verification code is {otp}. It expires in 1 minute.",
    )
    if not delivered:
        return {"success": False, "message": "Failed to send OTP. Please try again."}

    # Only expose the OTP in the response for local dev WITHOUT a real SMS
    # provider (so the apps can autofill). Once a provider is configured — and
    # always in production — the OTP is never returned to the client.
    expose_otp = not settings["IS_PRODUCTION"] and not provider_configured()

    return {
        "success": True,
        "otp": otp if expose_otp else None,
        "message": f"OTP sent to {phone_normalized}" if expose_otp else "OTP sent successfully",
    }


def verify_otp(phone: str, otp: str) -> dict:
    """
    Verify OTP and return user data.
    Compares hashed OTP for security.
    
    Returns: {"valid": bool, "is_new_user": bool, "user_id": str, "user_type": str, "message": str}
    """
    from database import User, SessionLocal, generate_user_id
    
    redis_client = _get_redis_client()
    phone_normalized = _normalize_phone(phone)

    # Check failed attempt lockout first
    is_allowed, remaining = _check_failed_attempts(phone_normalized)
    if not is_allowed:
        return {
            "valid": False,
            "is_new_user": False,
            "user_id": None,
            "user_type": None,
            "message": "Too many failed attempts. Please try again after 5 minutes."
        }

    # Hash the provided OTP for comparison
    otp_hash = _hash_otp(otp, phone_normalized)
    
    # Verify OTP
    stored_hash = None
    stored_user_type = "customer"  # Default
    
    if redis_client:
        try:
            stored_hash = redis_client.get(_otp_key(phone_normalized))
            if stored_hash and isinstance(stored_hash, bytes):
                stored_hash = stored_hash.decode('utf-8')
            
            # Get stored user_type
            user_type_data = redis_client.get(_user_type_key(phone_normalized))
            if user_type_data:
                stored_user_type = user_type_data.decode('utf-8') if isinstance(user_type_data, bytes) else user_type_data
        except Exception:
            pass
    else:
        # Thread-safe in-memory fallback
        with _otp_lock:
            entry = _otp_store.get(phone_normalized)
            if entry and entry.get("expires_at", 0) > time.time():
                stored_hash = entry.get("otp_hash")
                stored_user_type = entry.get("user_type", "customer")
    
    # Compare hashes
    if not stored_hash or str(stored_hash) != str(otp_hash):
        # Record failed attempt
        _record_failed_attempt(phone_normalized)
        
        # Also track in Redis if available
        if redis_client:
            try:
                redis_client.incr(f"otp_fail:{phone_normalized}")
                redis_client.expire(f"otp_fail:{phone_normalized}", _FAILED_ATTEMPTS_WINDOW)
            except Exception:
                pass
        
        return {"valid": False, "is_new_user": False, "user_id": None, "user_type": None, "message": "Invalid or expired OTP"}

    # Clear failed attempts on success
    _clear_failed_attempts(phone_normalized)
    if redis_client:
        try:
            redis_client.delete(f"otp_fail:{phone_normalized}")
        except Exception:
            pass

    # Delete OTP after successful verification
    if redis_client:
        try:
            redis_client.delete(_otp_key(phone_normalized))
            redis_client.delete(_user_type_key(phone_normalized))
        except Exception:
            pass
    else:
        with _otp_lock:
            _otp_store.pop(phone_normalized, None)
    
    # Check if user exists in database
    with SessionLocal() as session:
        from sqlalchemy import select
        user = session.execute(
            select(User).where(User.phone == phone_normalized)
        ).scalar_one_or_none()
        
        if user:
            if user.is_suspended:
                return {
                    "valid": False,
                    "is_new_user": False,
                    "user_id": None,
                    "user_type": None,
                    "message": "This account has been suspended. Please contact support.",
                }
            # Prevent role switching - if phone exists, must match stored user_type
            if user.user_type != stored_user_type:
                return {
                    "valid": False,
                    "is_new_user": False,
                    "user_id": None,
                    "user_type": None,
                    "message": f"Phone already registered as {user.user_type}. Cannot change role."
                }
            return {
                "valid": True,
                "is_new_user": False,
                "user_id": user.id,
                "user_type": user.user_type,
                "message": "Login successful"
            }
        else:
            # New user - create in database with role prefix
            from datetime import datetime
            now = datetime.utcnow()
            
            # Use stored user_type (from send-otp)
            final_user_type = stored_user_type or "customer"
            
            # Generate ID with role prefix
            new_user_id = generate_user_id(final_user_type)
            
            new_user = User(
                id=new_user_id,
                user_type=final_user_type,
                name="TaskTeddy User",
                email=None,
                password=None,
                phone=phone_normalized,
                avatar_url=None,
                location=None,
                bio=None,
                rating=0.0,
                total_reviews=0,
                coins=0,
                wallet_balance=0.0,
                is_online=False,
                email_verified_at=None,
                phone_verified_at=now,
                last_login_at=now,
                created_at=now,
                updated_at=now,
            )
            session.add(new_user)
            session.commit()
            session.refresh(new_user)
            
            return {
                "valid": True,
                "is_new_user": True,
                "user_id": new_user.id,
                "user_type": new_user.user_type,
                "message": "New user created"
            }


def _normalize_phone(phone: str) -> str:
    """Normalize phone to +91 format."""
    digits = "".join(ch for ch in phone if ch.isdigit())
    if len(digits) >= 10:
        return f"+91{digits[-10:]}"
    return f"+91{digits}"


# Thread-safe in-memory fallback store
_otp_store: dict = {}
_otp_lock = threading.Lock()

# OTP rate limiting (max 5 OTPs per phone per hour)
_otp_rate_limit: dict = {}
_otp_rate_lock = threading.Lock()
_OTP_RATE_LIMIT = 5  # Max OTPs per window
_OTP_RATE_WINDOW = 3600  # 1 hour in seconds

# Failed attempt tracking (max 3 attempts per phone)
_failed_attempts: dict = {}
_failed_attempts_lock = threading.Lock()
_MAX_FAILED_ATTEMPTS = 3
_FAILED_ATTEMPTS_WINDOW = 300  # 5 minutes lockout after max failures


def _check_otp_rate_limit(phone: str) -> tuple[bool, int]:
    """
    Check if phone has exceeded OTP rate limit.
    Returns: (is_allowed, remaining_attempts)
    """
    now = time.time()
    cutoff = now - _OTP_RATE_WINDOW
    
    with _otp_rate_lock:
        # Clean old entries
        _otp_rate_limit[phone] = [
            (ts, count) for ts, count in _otp_rate_limit.get(phone, [])
            if ts > cutoff
        ]
        
        total_sent = sum(count for ts, count in _otp_rate_limit.get(phone, []))
        
        if total_sent >= _OTP_RATE_LIMIT:
            return False, 0
        
        _otp_rate_limit[phone].append((now, 1))
        return True, _OTP_RATE_LIMIT - total_sent - 1


def _check_failed_attempts(phone: str) -> tuple[bool, int]:
    """
    Check if phone is locked due to failed attempts.
    Returns: (is_allowed, remaining_attempts)
    """
    now = time.time()
    cutoff = now - _FAILED_ATTEMPTS_WINDOW
    
    with _failed_attempts_lock:
        # Clean old entries
        _failed_attempts[phone] = [
            (ts, count) for ts, count in _failed_attempts.get(phone, [])
            if ts > cutoff
        ]
        
        total_failed = sum(count for ts, count in _failed_attempts.get(phone, []))
        
        if total_failed >= _MAX_FAILED_ATTEMPTS:
            return False, 0
        
        return True, _MAX_FAILED_ATTEMPTS - total_failed


def _record_failed_attempt(phone: str) -> None:
    """Record failed OTP attempt for brute force protection."""
    now = time.time()
    with _failed_attempts_lock:
        if phone not in _failed_attempts:
            _failed_attempts[phone] = []
        _failed_attempts[phone].append((now, 1))


def _clear_failed_attempts(phone: str) -> None:
    """Clear failed attempts after successful verification."""
    with _failed_attempts_lock:
        _failed_attempts.pop(phone, None)
import secrets
import threading
import time
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from pydantic import BaseModel
from sqlalchemy import and_, func, select
from sqlalchemy.orm import Session

from database import PortfolioItem, Review, TaskerAvailability, User, get_db_session
from models.schemas import EmailVerifyRequest, UserUpdate
from routes._helpers import clean_phone, user_to_public
from utils.auth import get_current_user
from utils.uploads import save_upload_file
from utils.email import send_email_otp
from utils.email_otp import send_email_otp as generate_email_otp, verify_email_otp

_EMAIL_VERIFY_EXPIRY = 600  # 10 minutes

# Rate limiting for email verification requests
_email_rate_limit: dict = {}
_email_rate_lock = threading.Lock()
_EMAIL_RATE_LIMIT = 5  # Max requests per window
_EMAIL_RATE_WINDOW = 3600  # 1 hour


def _generate_email_token() -> str:
    """Generate secure verification token."""
    return secrets.token_urlsafe(32)


def _check_email_rate_limit(user_id: str) -> tuple[bool, int]:
    """Check if user has exceeded email verification rate limit."""
    now = time.time()
    cutoff = now - _EMAIL_RATE_WINDOW

    with _email_rate_lock:
        # Clean old entries
        _email_rate_limit[user_id] = [
            ts for ts in _email_rate_limit.get(user_id, [])
            if ts > cutoff
        ]

        total_requests = len(_email_rate_limit.get(user_id, []))

        if total_requests >= _EMAIL_RATE_LIMIT:
            return False, 0

        _email_rate_limit[user_id].append(now)
        return True, _EMAIL_RATE_LIMIT - total_requests - 1


router = APIRouter()


def _find_user_or_404(session: Session, user_id: str) -> User:
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.get("/me")
def get_me(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    user = _find_user_or_404(session, current_user["sub"])
    return user_to_public(user)


@router.patch("/me")
def update_me(
    data: UserUpdate,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    user = _find_user_or_404(session, current_user["sub"])
    payload = data.model_dump(exclude_unset=True)
    if not payload:
        raise HTTPException(status_code=400, detail="No data to update")

    if "phone" in payload:
        payload["phone"] = clean_phone(payload["phone"])
        existing = session.execute(
            select(User).where(and_(User.phone == payload["phone"], User.id != user.id))
        ).scalar_one_or_none()
        if existing:
            raise HTTPException(status_code=409, detail="Phone number already exists")

    if "email" in payload and payload["email"] is not None:
        new_email = payload["email"].strip().lower()
        
        # Check if email already exists
        existing = session.execute(
            select(User).where(and_(func.lower(User.email) == new_email, User.id != user.id))
        ).scalar_one_or_none()
        if existing:
            raise HTTPException(status_code=409, detail="Email already exists")
        
        # Don't update email directly - store as pending until verified
        # Only allow if user has no current email OR is changing to new email
        if new_email != (user.email or "").strip().lower():
            # Check if there's already a pending verification for this email
            if user.pending_email and user.pending_email.lower() == new_email:
                raise HTTPException(status_code=400, detail="Verification already pending for this email")
            
            # Store as pending_email (don't update email field yet)
            payload.pop("email", None)  # Remove email from payload
            user.pending_email = new_email
            user.pending_email_token = _generate_email_token()
            user.pending_email_expires_at = datetime.utcnow() + timedelta(hours=24)
            # Don't set email_verified_at to None yet - keep old verified email until new is verified

    if "title" in payload and payload["title"] is not None:
        if payload["title"] not in {"Mr", "Ms"}:
            raise HTTPException(status_code=400, detail="Title must be Mr or Ms")

    if "gender" in payload and payload["gender"] is not None:
        gender = payload["gender"].strip().lower()
        if gender not in {"male", "female", "other"}:
            raise HTTPException(status_code=400, detail="Gender must be male, female or other")
        payload["gender"] = gender

    for field, value in payload.items():
        setattr(user, field, value)
    user.updated_at = datetime.utcnow()

    session.commit()
    session.refresh(user)
    return user_to_public(user)


@router.post("/me/avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    user = _find_user_or_404(session, current_user["sub"])
    avatar_url = await save_upload_file(file, "avatars")
    user.avatar_url = avatar_url
    user.updated_at = datetime.utcnow()
    session.commit()
    return {"avatar_url": avatar_url}


@router.post("/me/verify-email")
def verify_email(
    data: EmailVerifyRequest,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Verify email with OTP."""
    user = _find_user_or_404(session, current_user["sub"])

    # Check pending_email exists
    if not user.pending_email:
        raise HTTPException(status_code=400, detail="No pending email to verify")

    # Check if pending email has expired
    if user.pending_email_expires_at and user.pending_email_expires_at < datetime.utcnow():
        # Clear expired pending email
        user.pending_email = None
        user.pending_email_token = None
        user.pending_email_expires_at = None
        session.commit()
        raise HTTPException(status_code=400, detail="Verification link expired. Please request a new one.")

    # Verify OTP
    result = verify_email_otp(user.pending_email, data.code.strip())
    if not result.get("valid"):
        raise HTTPException(status_code=400, detail=result.get("message", "Invalid or expired OTP"))

    # Store verified email
    verified_email = user.pending_email
    now = datetime.utcnow()

    # Move pending_email to email and mark as verified
    user.email = verified_email
    user.email_verified_at = now
    user.pending_email = None
    user.pending_email_token = None
    user.pending_email_expires_at = None
    user.updated_at = now
    session.commit()
    session.refresh(user)

    return user_to_public(user)


@router.post("/me/request-email-verification")
def request_email_verification(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Request a new email verification OTP."""
    user = _find_user_or_404(session, current_user["sub"])

    # Check rate limit
    is_allowed, remaining = _check_email_rate_limit(user.id)
    if not is_allowed:
        raise HTTPException(
            status_code=429,
            detail="Too many verification requests. Please try again after 1 hour."
        )

    # Check pending_email first
    if not user.pending_email:
        raise HTTPException(
            status_code=400,
            detail="No pending email to verify. Update your email first."
        )

    # Check if already verified
    if user.email and user.email_verified_at:
        raise HTTPException(
            status_code=400,
            detail="Email already verified. Contact support to change."
        )

    # Generate OTP
    result = generate_email_otp(user.pending_email)
    if not result.get("success"):
        raise HTTPException(
            status_code=500,
            detail="Failed to generate OTP. Please try again."
        )

    otp = result.get("otp", "------")

    # Send email with OTP via SendGrid
    sent = send_email_otp(
        to_email=user.pending_email,
        name=user.name or "User",
        otp=otp,
    )

    if not sent:
        raise HTTPException(
            status_code=500,
            detail="Failed to send verification email. Please try again."
        )

    return {
        "success": True,
        "message": f"OTP sent to {user.pending_email}",
        "pending_email": user.pending_email,
    }


# ============================================================================
# Email OTP Verification Endpoints (NEW)
# ============================================================================

class EmailOtpRequest(BaseModel):
    email: str


class EmailOtpVerify(BaseModel):
    email: str
    otp: str


@router.post("/me/send-email-otp")
def send_email_otp_endpoint(
    data: EmailOtpRequest,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Send OTP to email for verification."""
    user = _find_user_or_404(session, current_user["sub"])
    email = data.email.strip().lower()

    # Validate email format
    if "@" not in email or "." not in email:
        raise HTTPException(status_code=400, detail="Invalid email format")

    # Check if email is already verified
    if user.email and user.email_verified_at:
        raise HTTPException(
            status_code=400,
            detail="Email already verified. Contact support to change."
        )

    # Check if email already exists
    existing = session.execute(
        select(User).where(
            and_(
                func.lower(User.email) == email,
                User.id != user.id
            )
        )
    ).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=409, detail="Email already exists")

    # Check rate limit
    is_allowed, remaining = _check_email_rate_limit(user.id)
    if not is_allowed:
        raise HTTPException(
            status_code=429,
            detail="Too many verification requests. Please try again after 1 hour."
        )

    # Generate OTP
    result = generate_email_otp(email)
    if not result.get("success"):
        raise HTTPException(
            status_code=500,
            detail="Failed to generate OTP. Please try again."
        )

    otp = result.get("otp", "------")

    # Send email with OTP
    sent = send_email_otp(
        to_email=email,
        name=user.name or "User",
        otp=otp,
    )

    if not sent:
        raise HTTPException(
            status_code=500,
            detail="Failed to send verification email. Please try again."
        )

    return {
        "success": True,
        "message": f"OTP sent to {email}",
    }


@router.post("/me/verify-email-otp")
def verify_email_otp_endpoint(
    data: EmailOtpVerify,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Verify OTP and save email to user profile."""
    user = _find_user_or_404(session, current_user["sub"])
    email = data.email.strip().lower()
    otp = data.otp.strip()

    # Validate OTP format
    if not otp or len(otp) != 6 or not otp.isdigit():
        raise HTTPException(status_code=400, detail="Invalid OTP format")

    # Verify OTP
    result = verify_email_otp(email, otp)
    if not result.get("valid"):
        raise HTTPException(status_code=400, detail=result.get("message", "Invalid or expired OTP"))

    # Check if email already exists (double check)
    existing = session.execute(
        select(User).where(
            and_(
                func.lower(User.email) == email,
                User.id != user.id
            )
        )
    ).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=409, detail="Email already exists")

    # Save verified email to user
    now = datetime.utcnow()
    user.email = email
    user.email_verified_at = now
    user.updated_at = now
    session.commit()
    session.refresh(user)

    return {
        "success": True,
        "message": "Email verified successfully",
        "user": user_to_public(user),
    }


@router.get("/{user_id}")
def get_user(user_id: str, session: Session = Depends(get_db_session)):
    user = _find_user_or_404(session, user_id)
    payload = user_to_public(user, include_wallet=False)
    payload.pop("wallet_balance", None)
    return payload


@router.get("/{user_id}/portfolio")
def get_user_portfolio(user_id: str, session: Session = Depends(get_db_session)):
    """Public gallery of a tasker's past work."""
    rows = (
        session.execute(
            select(PortfolioItem)
            .where(PortfolioItem.tasker_id == user_id)
            .order_by(PortfolioItem.created_at.desc())
        )
        .scalars()
        .all()
    )
    return [
        {
            "id": p.id,
            "image_url": p.image_url,
            "caption": p.caption,
            "created_at": p.created_at,
        }
        for p in rows
    ]


@router.get("/{user_id}/availability")
def get_user_availability(user_id: str, session: Session = Depends(get_db_session)):
    """Public weekly availability of a tasker."""
    rows = (
        session.execute(
            select(TaskerAvailability)
            .where(TaskerAvailability.tasker_id == user_id)
            .order_by(TaskerAvailability.day_of_week.asc())
        )
        .scalars()
        .all()
    )
    by_day = {
        int(r.day_of_week): {
            "day_of_week": int(r.day_of_week),
            "start_minute": int(r.start_minute),
            "end_minute": int(r.end_minute),
            "is_available": bool(r.is_available),
        }
        for r in rows
    }
    days = [
        by_day.get(d, {
            "day_of_week": d, "start_minute": 540, "end_minute": 1080,
            "is_available": False,
        })
        for d in range(7)
    ]
    return {"days": days}


@router.get("/{user_id}/reviews")
def get_user_reviews(user_id: str, session: Session = Depends(get_db_session)):
    """Public reviews received by a user (most recent first)."""
    rows = (
        session.execute(
            select(Review)
            .where(Review.reviewed_user_id == user_id)
            .order_by(Review.created_at.desc())
            .limit(50)
        )
        .scalars()
        .all()
    )
    out = []
    for r in rows:
        reviewer = session.get(User, r.reviewer_id)
        out.append({
            "id": r.id,
            "rating": float(r.rating),
            "comment": r.comment,
            "created_at": r.created_at,
            "reviewer_name": (reviewer.name if reviewer else None) or "TaskTeddy user",
            "reviewer_avatar": reviewer.avatar_url if reviewer else None,
        })
    return out


@router.patch("/me/online")
def toggle_online(
    is_online: bool,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    user = _find_user_or_404(session, current_user["sub"])
    user.is_online = bool(is_online)
    user.updated_at = datetime.utcnow()
    session.commit()
    return {"is_online": user.is_online}


# ============================================================================
# Email OTP Verification Endpoints
# ============================================================================

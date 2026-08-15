from __future__ import annotations

import html
import re
from datetime import datetime
from typing import Any

from sqlalchemy.orm import Session

from constants import (
    DEFAULT_PAGE_SIZE,
    MAX_CONVERSATION_PREVIEW,
    VALID_GENDERS,
    VALID_TITLES,
)
from database import Task, User


def escape_html(text: str) -> str:
    """Escape HTML entities to prevent XSS attacks."""
    if not text:
        return ""
    # Escape HTML characters
    escaped = html.escape(text)
    # Remove potential script tags (case insensitive)
    cleaned = re.sub(r'<script[^>]*>.*?</script>', '', escaped, flags=re.IGNORECASE | re.DOTALL)
    cleaned = re.sub(r'javascript:', '', cleaned, flags=re.IGNORECASE)
    return cleaned.strip()


def sanitize_text(text: str | None, max_length: int = 0) -> str:
    """Sanitize text input - escape HTML and optionally truncate."""
    if not text:
        return ""
    cleaned = escape_html(text)
    if max_length > 0 and len(cleaned) > max_length:
        cleaned = cleaned[:max_length]
    return cleaned


def clean_phone(phone: str | None) -> str | None:
    """Normalize phone to +91 format."""
    if not phone:
        return None
    digits = "".join(ch for ch in phone if ch.isdigit())
    if not digits:
        return None
    if len(digits) >= 12 and digits.startswith("91"):
        return f"+91{digits[-10:]}"
    if len(digits) >= 10:
        return f"+91{digits[-10:]}"
    return f"+91{digits}"


def normalize_phone_for_match(phone: str | None) -> str:
    """Normalize phone for database matching."""
    digits = "".join(ch for ch in (phone or "") if ch.isdigit())
    return digits[-10:] if len(digits) >= 10 else digits


def phone_lookup_values(phone: str | None) -> list[str]:
    """Get all possible phone lookup values for matching."""
    digits = "".join(ch for ch in (phone or "") if ch.isdigit())
    values: list[str] = []
    clean = clean_phone(phone)
    if clean:
        values.append(clean)
    if digits:
        values.append(digits)
    if len(digits) >= 10:
        values.append(digits[-10:])
        values.append(f"91{digits[-10:]}")
    return list(dict.fromkeys(values))


_LEVELS = [
    # (key, label, min_completed, min_rating)
    ("pro", "Pro", 200, 4.7),
    ("gold", "Gold", 75, 4.5),
    ("silver", "Silver", 25, 4.0),
    ("bronze", "Bronze", 5, 0.0),
    ("new", "New", 0, 0.0),
]


def tasker_reputation(user: User) -> dict[str, Any]:
    """Compute a tasker's level + reliability from stored stats.

    Level ladder: New -> Bronze(5) -> Silver(25) -> Gold(75) -> Pro(200),
    each also gated on a minimum rating. Reliability (0-100) blends the star
    rating with how often they finish vs cancel committed jobs.
    """
    completed = int(getattr(user, "completed_tasks", 0) or 0)
    cancels = int(getattr(user, "cancel_count", 0) or 0)
    rating = float(getattr(user, "rating", 0.0) or 0.0)

    level_key, level_label = "new", "New"
    for key, label, min_c, min_r in _LEVELS:
        if completed >= min_c and rating >= min_r:
            level_key, level_label = key, label
            break

    # Next threshold for a progress bar (None when already at the top).
    ladder = [5, 25, 75, 200]
    next_at = next((t for t in ladder if completed < t), None)

    finish_ratio = completed / (completed + cancels) if (completed + cancels) > 0 else 1.0
    reliability = round((rating / 5.0) * 60 + finish_ratio * 40)

    return {
        "level": level_key,
        "level_label": level_label,
        "reliability": max(0, min(100, reliability)),
        "completed_tasks": completed,
        "cancel_count": cancels,
        "next_level_at": next_at,
    }


def mask_id_number(value: str | None) -> str | None:
    """Mask an identity number, revealing only the last 4 characters.
    e.g. '123412341234' -> 'XXXX XXXX 1234'."""
    if not value:
        return None
    digits = value.strip().replace(" ", "")
    if len(digits) <= 4:
        return digits
    masked = "X" * (len(digits) - 4) + digits[-4:]
    # Group in 4s for readability.
    return " ".join(masked[i:i + 4] for i in range(0, len(masked), 4))


def user_to_public(user: User, include_wallet: bool = True) -> dict[str, Any]:
    """Convert User model to public response dict."""
    payload = {
        "id": user.id,
        "name": user.name or "TaskTeddy User",
        "email": user.email,
        "pending_email": user.pending_email,  # Show pending email if any
        "role": user.user_type,  # Use user_type from database
        "phone": user.phone,
        "title": user.title,
        "gender": user.gender,
        "avatar_url": user.avatar_url,
        "location": user.location,
        "bio": user.bio,
        "rating": float(user.rating or 0.0),
        "total_reviews": int(user.total_reviews or 0),
        "coins": int(user.coins or 0),
        "wallet_balance": float(user.wallet_balance or 0.0) if include_wallet else 0.0,
        "is_online": bool(user.is_online),
        "is_verified": bool(user.is_verified),
        "cancel_count": int(getattr(user, "cancel_count", 0) or 0),
        "completed_tasks": int(getattr(user, "completed_tasks", 0) or 0),
        "reputation": tasker_reputation(user),
        "email_verified": bool(user.email_verified_at),
        "phone_verified": bool(user.phone_verified_at),
        "created_at": user.created_at,
        "updated_at": user.updated_at,
    }
    # KYC id numbers, masked, only on the user's OWN profile view (include_wallet
    # is True for self; public/other views never see them, even masked).
    if include_wallet:
        payload["aadhaar_masked"] = mask_id_number(getattr(user, "aadhaar_number", None))
        payload["pan_masked"] = mask_id_number(getattr(user, "pan_number", None))
    return payload


def safe_user(session: Session, user_id: str | None) -> dict[str, Any] | None:
    """Get safe user dict without sensitive data."""
    if not user_id:
        return None
    user = session.get(User, user_id)
    if not user:
        return None
    payload = user_to_public(user, include_wallet=False)
    payload.pop("wallet_balance", None)
    return payload


def task_to_response(
    session: Session,
    task: Task,
    distance_km: float | None = None,
) -> dict[str, Any]:
    """Convert Task model to response dict.
    
    Args:
        session: Database session
        task: Task model instance
        distance_km: Optional distance from tasker to task location
    """
    posted_by = safe_user(session, task.posted_by)
    assigned_to = safe_user(session, task.assigned_to)
    
    response = {
        "id": task.id,
        "title": task.title,
        "description": task.description,
        "category": task.category,
        "budget": float(task.budget),
        "location": task.location,
        "latitude": task.latitude,
        "longitude": task.longitude,
        "deadline": task.deadline,
        "images": task.images or [],
        "status": task.status,
        "posted_by": posted_by,
        "assigned_to": assigned_to,
        "applicants_count": int(task.applicants_count or 0),
        "completion_otp": task.completion_otp,
        "on_the_way_at": getattr(task, "on_the_way_at", None),
        "cancel_reason": getattr(task, "cancel_reason", None),
        "cancelled_by": getattr(task, "cancelled_by", None),
        "review_reason": getattr(task, "review_reason", None),
        "created_at": task.created_at,
        "updated_at": task.updated_at,
    }
    
    # Include distance if provided
    if distance_km is not None:
        response["distance_km"] = round(distance_km, 1)
    
    return response


def new_booking_ref() -> str:
    """Generate new booking reference number."""
    return f"TT-{str(int(datetime.utcnow().timestamp() * 1000000))[-6:]}"


# ============================================================================
# JSON Query Helpers (for PostgreSQL JSON columns)
# ============================================================================

def json_array_contains(column, value: str):
    """Create a PostgreSQL JSON array containment query.
    
    This handles both JSON and JSONB columns safely.
    For JSON columns, uses explicit casting for compatibility.
    """
    from sqlalchemy import cast, String
    # Cast to text for JSON array comparison (works with both JSON and JSONB)
    return cast(column, String).contains(f'"{value}"')


def credit_earning(session, tasker_id: str, gross: float, description: str,
                   task_id: str | None = None) -> dict:
    """Credit a tasker's wallet for completed work, minus platform commission.

    Commission comes from the admin-editable `platform_commission_percent`
    setting (default 10). Writes an `earning` Transaction (the type used by the
    wallet /earnings endpoint and the admin revenue stats) and returns
    {gross, commission, net}.
    """
    import uuid as _uuid
    from datetime import datetime as _dt

    from database import Setting, Transaction, User

    commission_pct = 10.0
    row = session.get(Setting, "platform_commission_percent")
    if row and row.value:
        try:
            commission_pct = max(0.0, min(50.0, float(row.value)))
        except ValueError:
            pass

    gross = round(float(gross), 2)
    commission = round(gross * commission_pct / 100.0, 2)
    net = round(gross - commission, 2)

    tasker = session.get(User, tasker_id)
    if tasker:
        tasker.wallet_balance = round(float(tasker.wallet_balance or 0.0) + net, 2)
        tasker.updated_at = _dt.utcnow()

    session.add(Transaction(
        id=str(_uuid.uuid4()),
        user_id=tasker_id,
        type="earning",
        amount=net,
        description=f"{description} (₹{gross:.0f} − {commission_pct:.0f}% fee)",
        task_id=task_id,
        created_at=_dt.utcnow(),
    ))
    return {"gross": gross, "commission": commission, "net": net}


_DEFAULT_BANNED = "escort,nude,sex,drugs,weapon,gun,scam,fraud,xxx,porn"


def scan_banned_keywords(session, *texts: str) -> str | None:
    """Return the first banned keyword found in the given texts, else None.
    The list is the admin-editable `banned_keywords` setting (comma-separated)."""
    from database import Setting
    row = session.get(Setting, "banned_keywords")
    raw = row.value if (row and row.value) else _DEFAULT_BANNED
    words = [w.strip().lower() for w in raw.split(",") if w.strip()]
    blob = " ".join(t for t in texts if t).lower()
    for w in words:
        if w and w in blob:
            return w
    return None


def task_review_enabled(session) -> bool:
    """Whether new tasks must pass admin moderation before going live.
    Setting `task_review_enabled`, default True."""
    from database import Setting
    row = session.get(Setting, "task_review_enabled")
    if row is None or row.value is None:
        return True
    return str(row.value).strip().lower() in ("1", "true", "yes", "on")


def task_review_hold_minutes(session) -> int:
    """How long a task waits in review before auto-releasing to `open`.
    Setting `task_review_hold_minutes`, default 5. 0 disables auto-release
    (tasks then stay pending until an admin approves)."""
    from database import Setting
    row = session.get(Setting, "task_review_hold_minutes")
    try:
        return max(0, int(row.value)) if row and row.value is not None else 5
    except (TypeError, ValueError):
        return 5


def release_pending_tasks(session) -> int:
    """Auto-approve tasks that have sat in `pending_review` past the hold window.
    Called lazily on feed/list reads so tasks never get stuck if no admin is
    online. Returns the number released. A hold of 0 means manual-only."""
    from datetime import datetime as _dt, timedelta as _td

    from database import Task

    minutes = task_review_hold_minutes(session)
    if minutes <= 0:
        return 0
    cutoff = _dt.utcnow() - _td(minutes=minutes)
    stale = session.query(Task).filter(
        Task.status == "pending_review",
        Task.created_at <= cutoff,
        # Auto-flagged tasks (they carry a review note) must be reviewed by a
        # human — never auto-release those.
        Task.review_reason.is_(None),
    ).all()
    if not stale:
        return 0
    for t in stale:
        t.status = "open"
        t.updated_at = _dt.utcnow()
        notify_user(session, t.posted_by, "Task approved",
                    f"'{t.title}' passed review and is now live for taskers.",
                    emoji="✅")
    session.commit()
    return len(stale)


def _commission_pct(session) -> float:
    from database import Setting
    row = session.get(Setting, "platform_commission_percent")
    if row and row.value:
        try:
            return max(0.0, min(50.0, float(row.value)))
        except ValueError:
            pass
    return 10.0


def charge_commission(session, tasker_id: str, gross: float, description: str,
                      task_id: str | None = None) -> dict:
    """Cash-paid job: the customer handed the tasker cash directly, so instead
    of crediting the tasker we record the platform commission the tasker now
    owes. Debits their wallet by the commission (a running balance they keep
    topped up) and writes a `commission` Transaction for admin revenue stats.
    Returns {gross, commission, net, method}.
    """
    import uuid as _uuid
    from datetime import datetime as _dt

    from database import Transaction, User

    pct = _commission_pct(session)
    gross = round(float(gross), 2)
    commission = round(gross * pct / 100.0, 2)
    net = round(gross - commission, 2)

    tasker = session.get(User, tasker_id)
    if tasker:
        tasker.wallet_balance = round(float(tasker.wallet_balance or 0.0) - commission, 2)
        tasker.updated_at = _dt.utcnow()

    session.add(Transaction(
        id=str(_uuid.uuid4()),
        user_id=tasker_id,
        type="commission",
        amount=-commission,
        description=f"{description} — platform fee {pct:.0f}% on ₹{gross:.0f} (cash job)",
        task_id=task_id,
        created_at=_dt.utcnow(),
    ))
    return {"gross": gross, "commission": commission, "net": net, "method": "cash"}


def notify_user(session, user_id: str, title: str, body: str, emoji: str = "💰") -> None:
    """Insert an in-app notification (committed with the caller's commit)."""
    import uuid as _uuid
    from datetime import datetime as _dt

    from database import Notification

    session.add(Notification(
        id=str(_uuid.uuid4()),
        user_id=user_id,
        title=title,
        body=body,
        emoji=emoji,
        type="payment",
        is_read=False,
        created_at=_dt.utcnow(),
    ))

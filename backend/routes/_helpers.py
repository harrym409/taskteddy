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
        "promo_discount": float(getattr(task, "promo_discount", 0.0) or 0.0),
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
                    emoji="✅", notif_type="task", related_id=t.id)
    session.commit()
    # Newly-live tasks: notify taskers in each region + refresh browse feeds.
    try:
        from realtime import notify_new_task
        for t in stale:
            notify_taskers_of_new_task(session, t)
        notify_new_task()
    except Exception:
        pass
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


# ── Promo / signup-bonus tunables ────────────────────────────────────────────
# Early-marketing signup bonus credited to a new customer's promo_balance.
SIGNUP_BONUS = 500.0
# Max share of a task's value that the promo bonus may discount. Kept at (or
# below) the commission percent so the discount always comes out of the
# platform's own margin — never a loss, and the tasker is paid in full.
PROMO_MAX_PCT = 10.0


def grant_signup_bonus_if_eligible(session, user) -> float:
    """Credit the one-time ₹500 welcome bonus to a customer's promo wallet, but
    only once they have completed their profile and VERIFIED their email.

    Idempotent: guarded by ``signup_bonus_granted`` so it can be called from
    every email-verification path without ever double-crediting. Returns the
    amount granted (0.0 if not eligible or already granted). Does not commit —
    the caller's transaction does.
    """
    import uuid as _uuid
    from datetime import datetime as _dt

    from database import Transaction

    if user is None or SIGNUP_BONUS <= 0:
        return 0.0
    if getattr(user, "user_type", None) != "customer":
        return 0.0
    if getattr(user, "signup_bonus_granted", False):
        return 0.0
    if not (getattr(user, "email", None) and getattr(user, "email_verified_at", None)):
        return 0.0

    user.promo_balance = round(float(user.promo_balance or 0.0) + float(SIGNUP_BONUS), 2)
    user.signup_bonus_granted = True
    user.updated_at = _dt.utcnow()
    session.add(Transaction(
        id=str(_uuid.uuid4()),
        user_id=user.id,
        type="bonus",
        amount=float(SIGNUP_BONUS),
        description="Welcome bonus unlocked — email verified",
        task_id=None,
        created_at=_dt.utcnow(),
    ))
    try:
        notify_user(session, user.id, "🎁 ₹500 bonus unlocked!",
                    f"Your TaskTeddy welcome bonus of ₹{SIGNUP_BONUS:.0f} is ready — "
                    "save up to 10% on every task.", emoji="🎁", notif_type="bonus")
    except Exception:
        pass
    return float(SIGNUP_BONUS)


def promo_cap_for(session, gross: float) -> float:
    """The most promo/bonus (₹) that may be applied to a task of this value.

    This is min(commission on the task, PROMO_MAX_PCT of the task) so it can
    never exceed the platform's profit on the job — guaranteeing no loss.
    """
    gross = max(0.0, round(float(gross), 2))
    commission = gross * _commission_pct(session) / 100.0
    cap_pct = gross * PROMO_MAX_PCT / 100.0
    return round(min(commission, cap_pct), 2)


def charge_commission(session, tasker_id: str, gross: float, description: str,
                      task_id: str | None = None, discount: float = 0.0) -> dict:
    """Cash-paid job: the customer handed the tasker cash directly, so instead
    of crediting the tasker we record the platform commission the tasker now
    owes. Debits their wallet by the commission (a running balance they keep
    topped up) and writes a `commission` Transaction for admin revenue stats.

    ``discount`` is any promo/bonus the customer applied to this task. It is
    clamped to at most the full commission (so profit never goes negative) and
    reduces the commission the tasker owes by the same amount — because the
    customer already paid the tasker that much less in cash, the tasker's net
    take-home is unchanged. Returns
    {gross, commission, commission_full, discount, collected, net, method}.
    """
    import uuid as _uuid
    from datetime import datetime as _dt

    from database import Transaction, User

    pct = _commission_pct(session)
    gross = round(float(gross), 2)
    commission_full = round(gross * pct / 100.0, 2)
    discount = round(max(0.0, min(float(discount or 0.0), commission_full)), 2)
    commission = round(commission_full - discount, 2)  # what the tasker owes
    collected = round(gross - discount, 2)  # cash the customer actually handed over
    net = round(gross - commission_full, 2)  # tasker take-home (unchanged by promo)

    tasker = session.get(User, tasker_id)
    if tasker:
        tasker.wallet_balance = round(float(tasker.wallet_balance or 0.0) - commission, 2)
        # Count this as an unsettled cash job — the browse gate pauses the tasker
        # once too many pile up, until they settle their wallet.
        tasker.pending_cash_jobs = int(tasker.pending_cash_jobs or 0) + 1
        tasker.updated_at = _dt.utcnow()

    desc = f"{description} — platform fee {pct:.0f}% on ₹{gross:.0f} (cash job)"
    if discount > 0:
        desc += f"; ₹{discount:.0f} covered by customer's TaskTeddy bonus"
    session.add(Transaction(
        id=str(_uuid.uuid4()),
        user_id=tasker_id,
        type="commission",
        amount=-commission,
        description=desc,
        task_id=task_id,
        created_at=_dt.utcnow(),
    ))
    return {
        "gross": gross,
        "commission": commission,
        "commission_full": commission_full,
        "discount": discount,
        "collected": collected,
        "net": net,
        "method": "cash",
    }


def notify_taskers_of_new_task(session, task, radius_km: float = 40.0) -> None:
    """Notify taskers in the task's region that a new task went live.

    Geotagged tasks notify taskers within ``radius_km`` (plus taskers whose
    location is unknown — they see every task anyway). Un-geotagged tasks notify
    all active taskers. Best-effort: never let a notification failure break the
    request that triggered it."""
    try:
        from sqlalchemy import select as _select
        from database import User as _User
        from utils.geolocation import haversine_distance

        taskers = (
            session.execute(
                _select(_User)
                .where(_User.user_type == "tasker", _User.is_suspended.is_(False))
                .limit(2000)
            )
            .scalars()
            .all()
        )
        has_coords = task.latitude is not None and task.longitude is not None
        budget = float(task.budget or 0)
        notified = 0
        for t in taskers:
            if t.id == task.posted_by:
                continue
            if has_coords and t.latitude is not None and t.longitude is not None:
                d = haversine_distance(
                    task.latitude, task.longitude, t.latitude, t.longitude
                )
                if d > radius_km:
                    continue
                body = f"'{task.title}' posted ~{d:.0f} km away · ₹{budget:.0f}."
            else:
                body = f"'{task.title}' is now available · ₹{budget:.0f}."
            notify_user(session, t.id, "New task nearby", body, emoji="🆕",
                        notif_type="task_available", related_id=task.id)
            notified += 1
        if notified:
            session.commit()
    except Exception:
        pass


def notify_user(session, user_id: str, title: str, body: str, emoji: str = "💰",
                notif_type: str = "general", related_id: str | None = None) -> None:
    """Insert an in-app notification (committed with the caller's commit).

    ``notif_type`` + ``related_id`` let the apps deep-link when the alert is
    tapped, e.g. type="bid"/"task" with the task id, "chat" with a conversation
    id, "verify_email"/"bonus" for account prompts.
    """
    import uuid as _uuid
    from datetime import datetime as _dt

    from database import Notification

    session.add(Notification(
        id=str(_uuid.uuid4()),
        user_id=user_id,
        title=title,
        body=body,
        emoji=emoji,
        type=notif_type,
        related_id=related_id,
        is_read=False,
        created_at=_dt.utcnow(),
    ))

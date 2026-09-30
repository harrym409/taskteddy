"""Additional admin endpoints: dashboard time-series, user 360° overview,
and service create/delete. Mounted under /api/admin alongside main.py."""
import uuid
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from database import (
    Booking,
    Review,
    Service,
    Task,
    Transaction,
    User,
    UserReport,
    Withdrawal,
    get_db_session,
)
from routes.admin.main import get_current_admin, get_current_manager

router = APIRouter()


def _report_user_brief(session: Session, user_id: str) -> dict | None:
    u = session.get(User, user_id)
    if u is None:
        return None
    return {
        "id": u.id,
        "name": u.name or "TaskTeddy User",
        "user_type": u.user_type,
        "phone": u.phone,
        "is_suspended": bool(u.is_suspended),
    }


@router.get("/reports")
def list_reports(
    status_filter: str | None = None,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    """Safety reports filed by users, newest first (default: open only)."""
    stmt = select(UserReport).order_by(UserReport.created_at.desc())
    status_filter = status_filter or "open"
    if status_filter != "all":
        stmt = stmt.where(UserReport.status == status_filter)
    rows = session.execute(stmt.limit(200)).scalars().all()
    return [
        {
            "id": r.id,
            "reason": r.reason,
            "detail": r.detail,
            "status": r.status,
            "task_id": r.task_id,
            "created_at": r.created_at,
            "reporter": _report_user_brief(session, r.reporter_id),
            "reported": _report_user_brief(session, r.reported_id),
        }
        for r in rows
    ]


class ReportStatusUpdate(BaseModel):
    status: str = Field(..., pattern="^(open|reviewed|actioned|dismissed)$")


class KycNumbers(BaseModel):
    aadhaar_number: str | None = None
    pan_number: str | None = None


@router.patch("/users/{user_id}/kyc-numbers")
def set_kyc_numbers(
    user_id: str,
    body: KycNumbers,
    admin: dict = Depends(get_current_manager),
    session: Session = Depends(get_db_session),
):
    """Admin enters the tasker's Aadhaar / PAN number during verification.
    Stored server-side; the tasker only ever sees the last 4 digits."""
    user = session.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    if body.aadhaar_number is not None:
        aadhaar = body.aadhaar_number.strip().replace(" ", "")
        user.aadhaar_number = aadhaar or None
    if body.pan_number is not None:
        pan = body.pan_number.strip().upper()
        user.pan_number = pan or None
    user.updated_at = datetime.utcnow()
    audit(session, admin, "user.kyc_numbers", "user", user.id, "set aadhaar/pan")
    session.commit()
    from routes._helpers import mask_id_number
    return {
        "message": "Saved",
        "aadhaar_masked": mask_id_number(user.aadhaar_number),
        "pan_masked": mask_id_number(user.pan_number),
    }


@router.get("/queue-counts")
def queue_counts(
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    """Live counts of things awaiting admin action — for sidebar/dashboard badges."""
    from database import SupportTicket, Task, UserReport, Withdrawal

    review_queue = session.query(Task).filter(Task.status == "pending_review").count()
    flagged = session.query(Task).filter(
        Task.status == "pending_review", Task.review_reason.isnot(None)
    ).count()
    safety_reports = session.query(UserReport).filter(UserReport.status == "open").count()
    pending_withdrawals = session.query(Withdrawal).filter(
        Withdrawal.status == "pending"
    ).count()
    open_tickets = session.query(SupportTicket).filter(
        SupportTicket.status == "open"
    ).count()

    return {
        "review_queue": review_queue,
        "flagged_tasks": flagged,
        "safety_reports": safety_reports,
        "pending_withdrawals": pending_withdrawals,
        "open_tickets": open_tickets,
        "total": review_queue + safety_reports + pending_withdrawals + open_tickets,
    }


@router.get("/review-queue")
def task_review_queue(
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    """Tasks awaiting moderation, oldest first (so the longest-waiting shows up)."""
    from routes._helpers import task_to_response
    rows = (
        session.execute(
            select(Task)
            .where(Task.status == "pending_review")
            .order_by(Task.created_at.asc())
        )
        .scalars()
        .all()
    )
    return [task_to_response(session, t) for t in rows]


@router.patch("/tasks/{task_id}/approve")
def approve_task(
    task_id: str,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    from routes._helpers import notify_user
    task = session.get(Task, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.status not in ("pending_review", "rejected"):
        raise HTTPException(status_code=400, detail="Task is not awaiting review")
    task.status = "open"
    task.review_reason = None
    task.updated_at = datetime.utcnow()
    notify_user(session, task.posted_by, "Task approved",
                f"'{task.title}' passed review and is now live for taskers.",
                emoji="✅")
    session.commit()
    # Live push + region notifications: the task just went live.
    try:
        from realtime import notify_new_task
        from routes._helpers import notify_taskers_of_new_task
        notify_new_task()
        notify_taskers_of_new_task(session, task)
    except Exception:
        pass
    return {"message": "Task approved", "status": task.status}


class RejectTask(BaseModel):
    reason: str = Field(..., min_length=1, max_length=500)


@router.patch("/tasks/{task_id}/reject")
def reject_task(
    task_id: str,
    body: RejectTask,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    from routes._helpers import notify_user
    task = session.get(Task, task_id)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.status not in ("pending_review", "open"):
        raise HTTPException(status_code=400, detail="Task cannot be rejected")
    task.status = "rejected"
    task.review_reason = body.reason.strip()
    task.updated_at = datetime.utcnow()
    notify_user(session, task.posted_by, "Task not approved",
                f"'{task.title}' was not approved: {task.review_reason}",
                emoji="⚠️")
    session.commit()
    return {"message": "Task rejected", "status": task.status}


@router.patch("/reports/{report_id}")
def update_report(
    report_id: str,
    body: ReportStatusUpdate,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    report = session.get(UserReport, report_id)
    if report is None:
        raise HTTPException(status_code=404, detail="Report not found")
    report.status = body.status
    session.commit()
    return {"message": "Report updated", "status": report.status}


# ============================================================================
# Dashboard time-series (last 14 days)
# ============================================================================
@router.get("/stats/timeseries")
def get_stats_timeseries(
    days: int = 14,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    """Per-day counts for the dashboard charts: bookings, booking value, new users."""
    days = max(1, min(days, 90))
    start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(
        days=days - 1
    )

    booking_day = func.date_trunc("day", Booking.created_at).label("day")
    booking_rows = session.execute(
        select(
            booking_day,
            func.count(Booking.id),
            func.coalesce(func.sum(Booking.total_amount), 0),
        )
        .where(Booking.created_at >= start)
        .group_by(booking_day)
    ).all()

    user_day = func.date_trunc("day", User.created_at).label("day")
    user_rows = session.execute(
        select(user_day, func.count(User.id))
        .where(User.created_at >= start)
        .group_by(user_day)
    ).all()

    bookings_by_day = {
        d.strftime("%Y-%m-%d"): (int(c), float(v or 0)) for d, c, v in booking_rows
    }
    users_by_day = {d.strftime("%Y-%m-%d"): (int(c), 0.0) for d, c in user_rows}

    series = []
    for i in range(days):
        day = start + timedelta(days=i)
        key = day.strftime("%Y-%m-%d")
        b_count, b_value = bookings_by_day.get(key, (0, 0.0))
        u_count, _ = users_by_day.get(key, (0, 0.0))
        series.append(
            {
                "date": key,
                "bookings": b_count,
                "booking_value": b_value,
                "new_users": u_count,
            }
        )
    return {"days": days, "series": series}


# ============================================================================
# User 360° overview
# ============================================================================
@router.get("/users/{user_id}/overview")
def get_user_overview(
    user_id: str,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    bookings = session.execute(
        select(Booking)
        .where(Booking.customer_id == user_id)
        .order_by(Booking.created_at.desc())
        .limit(10)
    ).scalars().all()

    tasks = session.execute(
        select(Task)
        .where((Task.posted_by == user_id) | (Task.assigned_to == user_id))
        .order_by(Task.created_at.desc())
        .limit(10)
    ).scalars().all()

    transactions = session.execute(
        select(Transaction)
        .where(Transaction.user_id == user_id)
        .order_by(Transaction.created_at.desc())
        .limit(10)
    ).scalars().all()

    review_stats = session.execute(
        select(func.count(Review.id), func.coalesce(func.avg(Review.rating), 0)).where(
            Review.reviewed_user_id == user_id
        )
    ).one()

    withdrawals_pending = session.execute(
        select(func.count(Withdrawal.id)).where(
            Withdrawal.user_id == user_id, Withdrawal.status == "pending"
        )
    ).scalar() or 0

    return {
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "phone": user.phone,
            "user_type": user.user_type,
            "avatar_url": user.avatar_url,
            "location": user.location,
            "bio": user.bio,
            "rating": float(user.rating or 0),
            "total_reviews": int(user.total_reviews or 0),
            "coins": int(user.coins or 0),
            "wallet_balance": float(user.wallet_balance or 0),
            "is_online": bool(user.is_online),
            "is_suspended": bool(user.is_suspended),
            "is_verified": bool(user.is_verified),
            "email_verified": bool(user.email_verified_at),
            "phone_verified": bool(user.phone_verified_at),
            "created_at": user.created_at.isoformat(),
            "last_login_at": user.last_login_at.isoformat() if user.last_login_at else None,
        },
        "bookings": [
            {
                "id": b.id,
                "booking_id": b.booking_id,
                "service_name": (b.service or {}).get("name", ""),
                "scheduled_at": b.scheduled_at.isoformat(),
                "status": b.status,
                "total_amount": float(b.total_amount),
                "paid_with_wallet": bool(b.paid_with_wallet),
            }
            for b in bookings
        ],
        "tasks": [
            {
                "id": t.id,
                "title": t.title,
                "status": t.status,
                "budget": float(t.budget),
                "role": "poster" if t.posted_by == user_id else "tasker",
                "created_at": t.created_at.isoformat(),
            }
            for t in tasks
        ],
        "transactions": [
            {
                "id": txn.id,
                "type": txn.type,
                "amount": float(txn.amount),
                "description": txn.description,
                "created_at": txn.created_at.isoformat(),
            }
            for txn in transactions
        ],
        "stats": {
            "reviews_received": int(review_stats[0] or 0),
            "avg_rating_received": round(float(review_stats[1] or 0), 1),
            "pending_withdrawals": int(withdrawals_pending),
        },
    }


# ============================================================================
# Booking operations: assign tasker / mark completed
# ============================================================================
class BookingAssign(BaseModel):
    tasker_id: str


def _booking_notify(session: Session, user_id: str, title: str, body: str) -> None:
    from database import Notification

    session.add(
        Notification(
            id=str(uuid.uuid4()),
            user_id=user_id,
            title=title,
            body=body,
            emoji="🗓️",
            type="booking",
            is_read=False,
            created_at=datetime.utcnow(),
        )
    )


@router.post("/bookings/{booking_id}/assign")
def assign_booking_tasker(
    booking_id: str,
    data: BookingAssign,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    """Assign a tasker to fulfil a booking."""
    booking = session.get(Booking, booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.status not in ("pending", "confirmed"):
        raise HTTPException(
            status_code=400,
            detail=f"A {booking.status} booking cannot be assigned",
        )

    tasker = session.get(User, data.tasker_id)
    if not tasker or tasker.user_type != "tasker":
        raise HTTPException(status_code=404, detail="Tasker not found")
    if tasker.is_suspended:
        raise HTTPException(status_code=400, detail="Tasker is suspended")

    booking.tasker_id = tasker.id
    booking.status = "confirmed"
    booking.updated_at = datetime.utcnow()

    service_name = (booking.service or {}).get("name", "your booking")
    when = booking.scheduled_at.strftime("%d %b, %I:%M %p")
    _booking_notify(
        session,
        booking.customer_id,
        "Tasker Assigned",
        f"{tasker.name} will handle {service_name} on {when}.",
    )
    _booking_notify(
        session,
        tasker.id,
        "New Booking Assigned",
        f"You have been assigned {service_name} ({booking.booking_id}) on {when}.",
    )

    audit(session, admin, "booking.assign", "booking", booking.booking_id,
          f"Assigned {tasker.name}")
    session.commit()
    return {
        "message": "Tasker assigned",
        "booking_id": booking.booking_id,
        "tasker": {"id": tasker.id, "name": tasker.name},
    }


@router.post("/bookings/{booking_id}/complete")
def complete_booking(
    booking_id: str,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    """Mark a booking as completed."""
    booking = session.get(Booking, booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.status not in ("pending", "confirmed"):
        raise HTTPException(
            status_code=400,
            detail=f"A {booking.status} booking cannot be completed",
        )

    booking.status = "completed"
    booking.updated_at = datetime.utcnow()

    service_name = (booking.service or {}).get("name", "Your booking")
    _booking_notify(
        session,
        booking.customer_id,
        "Booking Completed",
        f"{service_name} ({booking.booking_id}) is complete. We hope you loved it!",
    )

    # Release wallet-paid funds to the assigned tasker (minus commission).
    if booking.paid_with_wallet and booking.tasker_id:
        from routes._helpers import credit_earning, notify_user
        earning = credit_earning(
            session, booking.tasker_id, float(booking.total_amount),
            f"Earning for {service_name} ({booking.booking_id})",
        )
        notify_user(session, booking.tasker_id, "Payment Received",
                    f"₹{earning['net']:.0f} credited to your wallet for {service_name}.")

    audit(session, admin, "booking.complete", "booking", booking.booking_id)
    session.commit()
    return {"message": "Booking completed", "booking_id": booking.booking_id}


# ============================================================================
# User moderation: suspend / unsuspend
# ============================================================================
@router.post("/users/{user_id}/suspend")
def suspend_user(
    user_id: str,
    admin: dict = Depends(get_current_manager),
    session: Session = Depends(get_db_session),
):
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_suspended = True
    user.updated_at = datetime.utcnow()
    audit(session, admin, "user.suspend", "user", user.id, user.name)
    session.commit()
    return {"message": "User suspended", "id": user.id}


@router.post("/users/{user_id}/unsuspend")
def unsuspend_user(
    user_id: str,
    admin: dict = Depends(get_current_manager),
    session: Session = Depends(get_db_session),
):
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_suspended = False
    user.updated_at = datetime.utcnow()
    audit(session, admin, "user.unsuspend", "user", user.id, user.name)
    session.commit()
    return {"message": "User reactivated", "id": user.id}


# ============================================================================
# Tasker verification (KYC approval)
# ============================================================================
@router.post("/users/{user_id}/verify")
def verify_user(
    user_id: str,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_verified = True
    user.updated_at = datetime.utcnow()
    _booking_notify(
        session,
        user.id,
        "You're Verified",
        "Your TaskTeddy profile has been verified. Customers can now see your verified badge.",
    )
    audit(session, admin, "user.verify", "user", user.id, user.name)
    session.commit()
    return {"message": "User verified", "id": user.id}


@router.post("/users/{user_id}/unverify")
def unverify_user(
    user_id: str,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_verified = False
    user.updated_at = datetime.utcnow()
    audit(session, admin, "user.unverify", "user", user.id, user.name)
    session.commit()
    return {"message": "Verification revoked", "id": user.id}


# ============================================================================
# Broadcast announcements
# ============================================================================
class AnnouncementCreate(BaseModel):
    title: str = Field(..., min_length=2, max_length=120)
    body: str = Field(..., min_length=2, max_length=1000)
    audience: str = Field(default="all", pattern="^(all|customers|taskers)$")


@router.post("/announcements", status_code=201)
def send_announcement(
    data: AnnouncementCreate,
    admin: dict = Depends(get_current_manager),
    session: Session = Depends(get_db_session),
):
    """Broadcast an in-app notification (and push, if FCM is configured) to
    all users, customers only, or taskers only."""
    from database import DeviceToken, Notification
    from utils.push import send_push_detailed

    query = select(User).where(User.is_suspended.is_(False))
    if data.audience == "customers":
        query = query.where(User.user_type == "customer")
    elif data.audience == "taskers":
        query = query.where(User.user_type == "tasker")

    users = session.execute(query).scalars().all()
    now = datetime.utcnow()
    for u in users:
        session.add(
            Notification(
                id=str(uuid.uuid4()),
                user_id=u.id,
                title=data.title.strip(),
                body=data.body.strip(),
                emoji="📢",
                type="announcement",
                is_read=False,
                created_at=now,
            )
        )
    audit(session, admin, "announcement.send", "announcement", None,
          f"{data.audience}: {data.title.strip()[:60]}")
    session.commit()

    # Best-effort push to registered devices of the audience.
    pushed = 0
    try:
        user_ids = [u.id for u in users]
        if user_ids:
            tokens = session.execute(
                select(DeviceToken.token).where(DeviceToken.user_id.in_(user_ids))
            ).scalars().all()
            if tokens:
                pushed, _ = send_push_detailed(
                    list(tokens), data.title.strip(), data.body.strip()
                )
    except Exception:
        pass

    return {
        "message": "Announcement sent",
        "recipients": len(users),
        "pushed": pushed,
        "audience": data.audience,
    }


class AdminNotifyCreate(BaseModel):
    title: str
    body: str
    # Deep-link type the app routes on when the alert is tapped:
    # verify_email | bonus | task | chat | announcement | general
    type: str = "announcement"
    related_id: str | None = None
    emoji: str | None = None
    user_id: str | None = None            # target one user…
    audience: str = "all"                 # …or an audience: all|customers|taskers


_NOTIFY_EMOJI = {
    "verify_email": "✉️",
    "bonus": "🎁",
    "task": "📋",
    "chat": "💬",
    "announcement": "📢",
}


@router.post("/notify", status_code=201)
def admin_notify(
    data: AdminNotifyCreate,
    admin: dict = Depends(get_current_manager),
    session: Session = Depends(get_db_session),
):
    """Send a typed in-app notification to one user or an audience. The ``type``
    (and ``related_id``) let the app deep-link when the alert is tapped — e.g.
    type="verify_email" opens the email-verification flow."""
    from routes._helpers import notify_user

    emoji = data.emoji or _NOTIFY_EMOJI.get(data.type, "🔔")

    if data.user_id:
        target = session.get(User, data.user_id)
        if not target:
            raise HTTPException(status_code=404, detail="User not found")
        users = [target]
    else:
        query = select(User).where(User.is_suspended.is_(False))
        if data.audience == "customers":
            query = query.where(User.user_type == "customer")
        elif data.audience == "taskers":
            query = query.where(User.user_type == "tasker")
        users = session.execute(query).scalars().all()

    for u in users:
        notify_user(session, u.id, data.title.strip(), data.body.strip(),
                    emoji=emoji, notif_type=data.type,
                    related_id=data.related_id)
    audit(session, admin, "notify.send", "notification", data.user_id,
          f"{data.type}: {data.title.strip()[:60]}")
    session.commit()
    return {"message": "Notification sent", "recipients": len(users),
            "type": data.type}


# ============================================================================
# Service create / delete
# ============================================================================
class ServiceCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=120)
    emoji: str = Field(default="🧰", max_length=8)
    category: str = Field(..., min_length=2, max_length=60)
    description: str = Field(default="", max_length=2000)
    price: float = Field(..., gt=0)
    original_price: float | None = Field(default=None, gt=0)
    includes: list[str] = Field(default_factory=list)
    is_hot: bool = False
    is_new: bool = True


@router.post("/services", status_code=201)
def create_service(
    data: ServiceCreate,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    now = datetime.utcnow()
    service = Service(
        id=f"SERV_{uuid.uuid4().hex[:16]}",
        name=data.name.strip(),
        emoji=data.emoji,
        category=data.category.strip().lower(),
        description=data.description.strip(),
        price=float(data.price),
        original_price=float(data.original_price or data.price),
        rating=0.0,
        review_count=0,
        is_hot=data.is_hot,
        is_new=data.is_new,
        includes=data.includes,
        is_active=True,
        created_at=now,
    )
    session.add(service)
    audit(session, admin, "service.create", "service", service.id, service.name)
    session.commit()
    session.refresh(service)
    return {"id": service.id, "message": "Service created"}


@router.delete("/services/{service_id}")
def delete_service(
    service_id: str,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    service = session.get(Service, service_id)
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    # Soft-delete: bookings keep their service snapshots, so deactivate instead
    # of destroying rows that may be referenced.
    service.is_active = False
    audit(session, admin, "service.deactivate", "service", service.id, service.name)
    session.commit()
    return {"message": "Service deactivated"}


# ============================================================================
# Audit log
# ============================================================================
def audit(session: Session, admin: dict, action: str, target_type: str | None = None,
          target_id: str | None = None, detail: str | None = None) -> None:
    from database import AuditLog

    session.add(AuditLog(
        id=str(uuid.uuid4()),
        admin_email=str(admin.get("email", "admin")),
        action=action,
        target_type=target_type,
        target_id=target_id,
        detail=detail,
        created_at=datetime.utcnow(),
    ))


@router.get("/audit-logs")
def get_audit_logs(
    limit: int = 100,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    from database import AuditLog

    rows = session.execute(
        select(AuditLog).order_by(AuditLog.created_at.desc()).limit(min(limit, 500))
    ).scalars().all()
    return [
        {
            "id": r.id,
            "admin_email": r.admin_email,
            "action": r.action,
            "target_type": r.target_type,
            "target_id": r.target_id,
            "detail": r.detail,
            "created_at": r.created_at.isoformat(),
        }
        for r in rows
    ]


# ============================================================================
# Task applications (bids) viewer
# ============================================================================
@router.get("/tasks/{task_id}/applications")
def get_task_applications(
    task_id: str,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    from database import Application

    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    apps = session.execute(
        select(Application).where(Application.task_id == task_id)
        .order_by(Application.created_at.desc())
    ).scalars().all()

    result = []
    for a in apps:
        u = session.get(User, a.applicant_id)
        result.append({
            "id": a.id,
            "applicant": {
                "id": a.applicant_id,
                "name": u.name if u else a.applicant_id,
                "rating": float(u.rating or 0) if u else 0,
                "is_verified": bool(u.is_verified) if u else False,
            },
            "bid_amount": float(a.bid_amount),
            "cover_letter": a.cover_letter,
            "status": a.status,
            "created_at": a.created_at.isoformat(),
        })
    return result


# ============================================================================
# Review moderation
# ============================================================================
@router.delete("/reviews/{review_id}")
def delete_review(
    review_id: str,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    review = session.get(Review, review_id)
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")

    reviewed_id = review.reviewed_user_id
    session.delete(review)
    session.flush()

    # Recompute the reviewed user's aggregate rating.
    stats = session.execute(
        select(func.count(Review.id), func.coalesce(func.avg(Review.rating), 0))
        .where(Review.reviewed_user_id == reviewed_id)
    ).one()
    target = session.get(User, reviewed_id)
    if target:
        target.total_reviews = int(stats[0] or 0)
        target.rating = round(float(stats[1] or 0), 1)
        target.updated_at = datetime.utcnow()

    audit(session, admin, "review.delete", "review", review_id,
          f"Removed review of {reviewed_id}")
    session.commit()
    return {"message": "Review deleted", "id": review_id}


# ============================================================================
# Analytics insights
# ============================================================================
@router.get("/stats/insights")
def get_insights(
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    # Top services by booking volume (service snapshot name).
    svc_name = Booking.service["name"].as_string().label("name")
    top_services = session.execute(
        select(svc_name, func.count(Booking.id), func.coalesce(func.sum(Booking.total_amount), 0))
        .where(Booking.status != "cancelled")
        .group_by(svc_name)
        .order_by(func.count(Booking.id).desc())
        .limit(5)
    ).all()

    # Category split of non-cancelled bookings.
    cat = Booking.service["category"].as_string().label("category")
    categories = session.execute(
        select(cat, func.count(Booking.id))
        .where(Booking.status != "cancelled")
        .group_by(cat)
        .order_by(func.count(Booking.id).desc())
        .limit(8)
    ).all()

    # Top taskers by completed bookings, then rating.
    top_taskers = session.execute(
        select(User, func.count(Booking.id).label("done"))
        .join(Booking, Booking.tasker_id == User.id)
        .where(Booking.status == "completed")
        .group_by(User.id)
        .order_by(func.count(Booking.id).desc(), User.rating.desc())
        .limit(5)
    ).all()

    return {
        "top_services": [
            {"name": n or "Unknown", "bookings": int(c), "value": float(v or 0)}
            for n, c, v in top_services
        ],
        "categories": [
            {"category": (c or "other"), "bookings": int(n)} for c, n in categories
        ],
        "top_taskers": [
            {
                "id": u.id,
                "name": u.name,
                "rating": float(u.rating or 0),
                "is_verified": bool(u.is_verified),
                "completed_bookings": int(done),
            }
            for u, done in top_taskers
        ],
    }


# ============================================================================
# System health
# ============================================================================
@router.get("/system")
def get_system_health(
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    import redis as _redis

    from config import get_settings as _gs

    settings = _gs()

    db_ok = True
    try:
        session.execute(select(func.count(User.id))).scalar()
    except Exception:
        db_ok = False

    redis_ok = False
    if settings.get("redis_enabled"):
        try:
            _redis.from_url(settings["redis_url"]).ping()
            redis_ok = True
        except Exception:
            redis_ok = False

    from database import AuditLog, Notification

    return {
        "environment": settings["ENVIRONMENT"],
        "database": "connected" if db_ok else "error",
        "redis": "connected" if redis_ok else ("disabled" if not settings.get("redis_enabled") else "error"),
        "counts": {
            "users": session.execute(select(func.count(User.id))).scalar() or 0,
            "services": session.execute(select(func.count(Service.id))).scalar() or 0,
            "bookings": session.execute(select(func.count(Booking.id))).scalar() or 0,
            "tasks": session.execute(select(func.count(Task.id))).scalar() or 0,
            "notifications": session.execute(select(func.count(Notification.id))).scalar() or 0,
            "audit_logs": session.execute(select(func.count(AuditLog.id))).scalar() or 0,
        },
        "checked_at": datetime.utcnow().isoformat(),
    }


# ============================================================================
# KYC review (admin)
# ============================================================================
class KycReject(BaseModel):
    reason: str = Field(..., min_length=3, max_length=500)


@router.get("/kyc")
def list_kyc_submissions(
    status_filter: str | None = None,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    """KYC documents grouped by tasker, newest submissions first."""
    from database import KycDocument

    q = select(KycDocument).order_by(KycDocument.updated_at.desc())
    if status_filter:
        q = q.where(KycDocument.status == status_filter)
    docs = session.execute(q).scalars().all()

    by_user: dict = {}
    for d in docs:
        entry = by_user.setdefault(d.user_id, {"documents": []})
        entry["documents"].append({
            "id": d.id,
            "doc_type": d.doc_type,
            "file_url": d.file_url,
            "status": d.status,
            "reason": d.reason,
            "updated_at": d.updated_at.isoformat(),
        })

    result = []
    for uid, entry in by_user.items():
        u = session.get(User, uid)
        result.append({
            "user": {
                "id": uid,
                "name": u.name if u else uid,
                "user_type": u.user_type if u else "tasker",
                "is_verified": bool(u.is_verified) if u else False,
                "phone": u.phone if u else None,
            },
            "documents": entry["documents"],
        })
    return result


@router.post("/kyc/{doc_id}/approve")
def approve_kyc_document(
    doc_id: str,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    from database import KycDocument

    doc = session.get(KycDocument, doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    doc.status = "approved"
    doc.reason = None
    doc.updated_at = datetime.utcnow()
    _booking_notify(session, doc.user_id, "Document Approved",
                    f"Your {doc.doc_type} document has been approved.")
    audit(session, admin, "kyc.approve", "kyc_document", doc.id, doc.doc_type)

    # Auto-grant the verified badge once every required document is approved.
    REQUIRED_DOCS = {"aadhaar", "pan", "address", "selfie"}
    approved_types = set(
        session.execute(
            select(KycDocument.doc_type).where(
                KycDocument.user_id == doc.user_id,
                KycDocument.status == "approved",
            )
        ).scalars().all()
    ) | {doc.doc_type}
    auto_verified = False
    if REQUIRED_DOCS.issubset(approved_types):
        user = session.get(User, doc.user_id)
        if user and not user.is_verified:
            user.is_verified = True
            user.updated_at = datetime.utcnow()
            auto_verified = True
            _booking_notify(
                session, user.id, "You're Verified",
                "All your documents are approved — your profile now shows the verified badge.",
            )
            audit(session, admin, "user.verify", "user", user.id,
                  "auto: all KYC documents approved")

    session.commit()
    return {
        "message": "Document approved"
        + (" — all documents approved, tasker is now verified" if auto_verified else ""),
        "id": doc.id,
        "auto_verified": auto_verified,
    }


@router.post("/kyc/{doc_id}/reject")
def reject_kyc_document(
    doc_id: str,
    data: KycReject,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    from database import KycDocument

    doc = session.get(KycDocument, doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    doc.status = "rejected"
    doc.reason = data.reason.strip()
    doc.updated_at = datetime.utcnow()
    _booking_notify(session, doc.user_id, "Document Rejected",
                    f"Your {doc.doc_type} document was rejected: {doc.reason}. Please re-upload.")
    audit(session, admin, "kyc.reject", "kyc_document", doc.id,
          f"{doc.doc_type}: {doc.reason}")

    # A verified profile must not rest on a rejected document.
    user = session.get(User, doc.user_id)
    if user and user.is_verified:
        user.is_verified = False
        user.updated_at = datetime.utcnow()
        audit(session, admin, "user.unverify", "user", user.id,
              f"auto: {doc.doc_type} document rejected")

    session.commit()
    return {"message": "Document rejected", "id": doc.id}


# ============================================================================
# Support inbox (admin)
# ============================================================================
class TicketReply(BaseModel):
    reply: str = Field(..., min_length=2, max_length=4000)
    resolve: bool = True


@router.get("/support")
def list_tickets(
    status_filter: str | None = None,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    from database import SupportTicket

    q = select(SupportTicket).order_by(SupportTicket.created_at.desc())
    if status_filter:
        q = q.where(SupportTicket.status == status_filter)
    tickets = session.execute(q).scalars().all()

    result = []
    for t in tickets:
        u = session.get(User, t.user_id)
        result.append({
            "id": t.id,
            "user": {
                "id": t.user_id,
                "name": u.name if u else t.user_id,
                "user_type": u.user_type if u else None,
                "phone": u.phone if u else None,
            },
            "subject": t.subject,
            "message": t.message,
            "status": t.status,
            "reply": t.reply,
            "created_at": t.created_at.isoformat(),
            "updated_at": t.updated_at.isoformat(),
        })
    return result


@router.post("/support/{ticket_id}/reply")
def reply_ticket(
    ticket_id: str,
    data: TicketReply,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    from database import SupportTicket

    ticket = session.get(SupportTicket, ticket_id)
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    ticket.reply = data.reply.strip()
    if data.resolve:
        ticket.status = "resolved"
    ticket.updated_at = datetime.utcnow()

    _booking_notify(
        session,
        ticket.user_id,
        "Support Reply",
        f"Re: {ticket.subject} — {ticket.reply[:150]}",
    )
    audit(session, admin, "support.reply", "ticket", ticket.id, ticket.subject[:60])
    session.commit()
    return {"message": "Reply sent", "id": ticket.id, "status": ticket.status}

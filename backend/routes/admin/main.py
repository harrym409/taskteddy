"""Admin API routes for TaskTeddy admin panel."""
import os
import secrets as _secrets
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from config import get_settings
from database import (
    Application,
    Booking,
    Review,
    Service,
    Setting,
    Task,
    Transaction,
    User,
    Withdrawal,
    get_db_session,
)

router = APIRouter()
security = HTTPBearer()

# Get settings
settings = get_settings()


# ============================================================================
# Admin Configuration (from environment)
# ============================================================================
_INSECURE_DEFAULT_PASSWORDS = {"admin123", "change-me-in-dev", "password", ""}


def verify_admin_credentials(email: str, password: str) -> bool:
    """Verify admin login credentials against environment config.

    Prefers a bcrypt hash in ADMIN_PASSWORD_HASH; falls back to a plaintext
    ADMIN_PASSWORD for local dev. In production, refuses to authenticate unless
    a proper credential is configured (no default password is ever accepted).
    """
    from utils.auth import verify_password

    configured_email = os.getenv("ADMIN_EMAIL", "admin@taskteddy.com")
    password_hash = os.getenv("ADMIN_PASSWORD_HASH", "")
    plaintext = os.getenv("ADMIN_PASSWORD", "")

    if settings["IS_PRODUCTION"]:
        if not password_hash and (not plaintext or plaintext in _INSECURE_DEFAULT_PASSWORDS):
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Admin login is not configured. Set ADMIN_PASSWORD_HASH.",
            )

    email_ok = _secrets.compare_digest(email or "", configured_email)

    if password_hash:
        password_ok = verify_password(password or "", password_hash)
    else:
        # Dev-only plaintext path, still constant-time.
        password_ok = _secrets.compare_digest(password or "", plaintext)

    return email_ok and password_ok


# ============================================================================
# Admin Authentication Dependency
# ============================================================================
# Portal roles, highest privilege first.
ADMIN_ROLES = ("superadmin", "admin", "support")


async def get_current_admin(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> dict:
    """Verify a portal (admin/superadmin/support) JWT and return its claims.

    The returned dict carries ``role`` ∈ {superadmin, admin, support} and
    ``admin_id`` so downstream handlers can enforce per-role permissions.
    """
    from jose import JWTError, jwt

    token = credentials.credentials
    try:
        payload = jwt.decode(
            token,
            settings["JWT_SECRET"],
            algorithms=[settings["JWT_ALGORITHM"]]
        )
        role = payload.get("role")
        if role not in ADMIN_ROLES:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Admin access required"
            )
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )


def require_admin_roles(*allowed: str):
    """Dependency factory that restricts an endpoint to the given portal roles."""
    async def _checker(admin: dict = Depends(get_current_admin)) -> dict:
        if admin.get("role") not in allowed:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to perform this action.",
            )
        return admin
    return _checker


async def get_current_super_admin(admin: dict = Depends(get_current_admin)) -> dict:
    """Only a super admin (team management, etc.)."""
    if admin.get("role") != "superadmin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Super admin access required.",
        )
    return admin


async def get_current_manager(admin: dict = Depends(get_current_admin)) -> dict:
    """Super admin or admin — for financial/destructive actions (not support)."""
    if admin.get("role") not in ("superadmin", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This action requires admin privileges.",
        )
    return admin


# ============================================================================
# Auth Schemas
# ============================================================================
class LoginRequest(BaseModel):
    email: str
    password: str


class LoginResponse(BaseModel):
    access_token: str
    admin: dict


# ============================================================================
# Auth Endpoints (No auth required)
# ============================================================================
@router.post("/login", response_model=LoginResponse)
def admin_login(data: LoginRequest, session: Session = Depends(get_db_session)):
    """Portal login. Checks the team table first (admin/support accounts a super
    admin created), then falls back to the env-configured bootstrap super admin."""
    from utils.auth import create_access_token, verify_password
    from database import AdminUser

    email = (data.email or "").strip().lower()

    # 1) A real team account (admin or support, or a promoted super admin).
    member = session.execute(
        select(AdminUser).where(func.lower(AdminUser.email) == email)
    ).scalar_one_or_none()
    if member is not None:
        if not member.is_active:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                                detail="This account has been deactivated.")
        if not verify_password(data.password or "", member.password_hash):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                                detail="Invalid credentials")
        token = create_access_token({
            "sub": member.id, "admin_id": member.id,
            "email": member.email, "role": member.role,
        })
        return {
            "access_token": token,
            "admin": {"id": member.id, "email": member.email,
                      "name": member.name or "Admin", "role": member.role},
        }

    # 2) Bootstrap super admin from environment (the very first login).
    if verify_admin_credentials(data.email, data.password):
        token = create_access_token({
            "sub": "superadmin", "admin_id": "superadmin",
            "email": data.email, "role": "superadmin",
        })
        return {
            "access_token": token,
            "admin": {"id": "superadmin", "email": data.email,
                      "name": "Super Admin", "role": "superadmin"},
        }

    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Invalid credentials")


# ============================================================================
# Team management (super admin only) — create/list/manage admin & support logins
# ============================================================================
class TeamMemberCreate(BaseModel):
    email: str
    name: str
    password: str
    role: str  # "admin" | "support"


class TeamMemberUpdate(BaseModel):
    name: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None


class PasswordReset(BaseModel):
    password: str


def _admin_to_dict(m) -> dict:
    return {
        "id": m.id,
        "email": m.email,
        "name": m.name,
        "role": m.role,
        "is_active": bool(m.is_active),
        "created_at": m.created_at,
    }


@router.get("/team")
def list_team(
    admin: dict = Depends(get_current_super_admin),
    session: Session = Depends(get_db_session),
):
    from database import AdminUser
    rows = session.execute(
        select(AdminUser).order_by(AdminUser.created_at.desc())
    ).scalars().all()
    return [_admin_to_dict(m) for m in rows]


@router.post("/team", status_code=201)
def create_team_member(
    data: TeamMemberCreate,
    admin: dict = Depends(get_current_super_admin),
    session: Session = Depends(get_db_session),
):
    import uuid as _uuid
    from utils.auth import hash_password
    from database import AdminUser

    if data.role not in ("admin", "support"):
        raise HTTPException(status_code=400,
                            detail="Role must be 'admin' or 'support'.")
    email = (data.email or "").strip().lower()
    if not email or "@" not in email:
        raise HTTPException(status_code=400, detail="A valid email is required.")
    if len(data.password or "") < 6:
        raise HTTPException(status_code=400,
                            detail="Password must be at least 6 characters.")
    exists = session.execute(
        select(AdminUser).where(func.lower(AdminUser.email) == email)
    ).scalar_one_or_none()
    if exists is not None:
        raise HTTPException(status_code=400,
                            detail="An account with this email already exists.")

    member = AdminUser(
        id=str(_uuid.uuid4()),
        email=email,
        name=(data.name or "").strip(),
        password_hash=hash_password(data.password),
        role=data.role,
        is_active=True,
        created_by=admin.get("admin_id"),
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    session.add(member)
    session.commit()
    session.refresh(member)
    return _admin_to_dict(member)


@router.patch("/team/{member_id}")
def update_team_member(
    member_id: str,
    data: TeamMemberUpdate,
    admin: dict = Depends(get_current_super_admin),
    session: Session = Depends(get_db_session),
):
    from database import AdminUser
    member = session.get(AdminUser, member_id)
    if not member:
        raise HTTPException(status_code=404, detail="Member not found.")
    if data.role is not None:
        if data.role not in ("admin", "support"):
            raise HTTPException(status_code=400,
                                detail="Role must be 'admin' or 'support'.")
        member.role = data.role
    if data.name is not None:
        member.name = data.name.strip()
    if data.is_active is not None:
        member.is_active = data.is_active
    member.updated_at = datetime.utcnow()
    session.commit()
    session.refresh(member)
    return _admin_to_dict(member)


@router.post("/team/{member_id}/reset-password")
def reset_team_password(
    member_id: str,
    data: PasswordReset,
    admin: dict = Depends(get_current_super_admin),
    session: Session = Depends(get_db_session),
):
    from utils.auth import hash_password
    from database import AdminUser
    member = session.get(AdminUser, member_id)
    if not member:
        raise HTTPException(status_code=404, detail="Member not found.")
    if len(data.password or "") < 6:
        raise HTTPException(status_code=400,
                            detail="Password must be at least 6 characters.")
    member.password_hash = hash_password(data.password)
    member.updated_at = datetime.utcnow()
    session.commit()
    return {"message": "Password updated."}


@router.delete("/team/{member_id}")
def delete_team_member(
    member_id: str,
    admin: dict = Depends(get_current_super_admin),
    session: Session = Depends(get_db_session),
):
    from database import AdminUser
    member = session.get(AdminUser, member_id)
    if not member:
        raise HTTPException(status_code=404, detail="Member not found.")
    session.delete(member)
    session.commit()
    return {"message": "Member removed."}


@router.get("/me")
def admin_me(admin: dict = Depends(get_current_admin)):
    """The current portal user's identity + role (drives UI permissions)."""
    return {
        "id": admin.get("admin_id") or admin.get("sub"),
        "email": admin.get("email"),
        "role": admin.get("role"),
    }


# ============================================================================
# Dashboard Stats
# ============================================================================
@router.get("/stats")
def get_stats(
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session)
):
    """Get dashboard statistics."""
    # Count customers
    total_customers = session.execute(
        select(func.count(User.id)).where(User.user_type == "customer")
    ).scalar() or 0

    # Count taskers
    total_taskers = session.execute(
        select(func.count(User.id)).where(User.user_type == "tasker")
    ).scalar() or 0

    # Count tasks
    total_tasks = session.execute(select(func.count(Task.id))).scalar() or 0

    # Count bookings
    total_bookings = session.execute(select(func.count(Booking.id))).scalar() or 0

    # Total revenue (sum of all transaction amounts)
    total_revenue = session.execute(
        select(func.coalesce(func.sum(Transaction.amount), 0)
    ).where(Transaction.type == "earning")
    ).scalar() or 0

    # Pending withdrawals
    pending_withdrawals = session.execute(
        select(func.count(Withdrawal.id)).where(Withdrawal.status == "pending")
    ).scalar() or 0

    return {
        "total_customers": total_customers,
        "total_taskers": total_taskers,
        "total_tasks": total_tasks,
        "total_bookings": total_bookings,
        "total_revenue": float(total_revenue),
        "pending_withdrawals": pending_withdrawals,
    }


# ============================================================================
# Users Endpoints
# ============================================================================
@router.get("/users")
def get_users(
    type: Optional[str] = Query(None, description="Filter by user type"),
    search: Optional[str] = Query(None, description="Search query"),
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    """Get all users with optional filters."""
    query = select(User)

    if type:
        query = query.where(User.user_type == type)

    if search:
        search_pattern = f"%{search}%"
        query = query.where(
            (User.name.ilike(search_pattern)) |
            (User.email.ilike(search_pattern)) |
            (User.phone.ilike(search_pattern))
        )

    query = query.order_by(User.created_at.desc())
    users = session.execute(query).scalars().all()

    return [
        {
            "id": u.id,
            "name": u.name,
            "email": u.email,
            "phone": u.phone,
            "user_type": u.user_type,
            "title": u.title,
            "gender": u.gender,
            "avatar_url": u.avatar_url,
            "location": u.location,
            "bio": u.bio,
            "rating": float(u.rating or 0),
            "total_reviews": u.total_reviews or 0,
            "coins": u.coins or 0,
            "wallet_balance": float(u.wallet_balance or 0),
            "is_online": u.is_online,
            "is_suspended": bool(u.is_suspended),
            "is_verified": bool(u.is_verified),
            "email_verified": bool(u.email_verified_at),
            "phone_verified": bool(u.phone_verified_at),
            "created_at": u.created_at.isoformat(),
            "updated_at": u.updated_at.isoformat(),
        }
        for u in users
    ]


@router.get("/users/{user_id}")
def get_user(
    user_id: str,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session)
):
    """Get user by ID."""
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "phone": user.phone,
        "user_type": user.user_type,
        "title": user.title,
        "gender": user.gender,
        "avatar_url": user.avatar_url,
        "location": user.location,
        "bio": user.bio,
        "rating": float(user.rating or 0),
        "total_reviews": user.total_reviews or 0,
        "coins": user.coins or 0,
        "wallet_balance": float(user.wallet_balance or 0),
        "is_online": user.is_online,
        "is_suspended": bool(user.is_suspended),
        "is_verified": bool(user.is_verified),
        "email_verified": bool(user.email_verified_at),
        "phone_verified": bool(user.phone_verified_at),
        "created_at": user.created_at.isoformat(),
        "updated_at": user.updated_at.isoformat(),
    }


@router.patch("/users/{user_id}")
def update_user(
    user_id: str,
    data: dict,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session)
):
    """Update user."""
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    for key, value in data.items():
        if hasattr(user, key):
            setattr(user, key, value)

    user.updated_at = datetime.utcnow()
    session.commit()
    session.refresh(user)

    return {"message": "User updated"}


@router.delete("/users/{user_id}")
def delete_user(
    user_id: str,
    admin: dict = Depends(get_current_manager),
    session: Session = Depends(get_db_session)
):
    """Delete user."""
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    from routes.admin.extra import audit as _audit
    _audit(session, admin, "user.delete", "user", user_id, user.name)
    session.delete(user)
    session.commit()

    return {"message": "User deleted"}


# ============================================================================
# Tasks Endpoints
# ============================================================================
@router.get("/tasks")
def get_tasks(
    status: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    """Get all tasks."""
    query = select(Task)

    if status:
        query = query.where(Task.status == status)

    if search:
        search_pattern = f"%{search.strip()}%"
        # Search the task reference id, title, category and location so admins
        # can look a task up by its TASK_000123 number or any keyword.
        query = query.where(
            Task.id.ilike(search_pattern)
            | Task.title.ilike(search_pattern)
            | Task.category.ilike(search_pattern)
            | Task.location.ilike(search_pattern)
        )

    query = query.order_by(Task.created_at.desc())
    tasks = session.execute(query).scalars().all()

    result = []
    for t in tasks:
        posted_by = session.get(User, t.posted_by) if t.posted_by else None
        assigned_to = session.get(User, t.assigned_to) if t.assigned_to else None

        result.append({
            "id": t.id,
            "title": t.title,
            "description": t.description,
            "category": t.category,
            "budget": float(t.budget),
            "location": t.location,
            "deadline": t.deadline.isoformat(),
            "images": t.images or [],
            "status": t.status,
            "posted_by": {
                "id": posted_by.id,
                "name": posted_by.name,
                "avatar_url": posted_by.avatar_url,
            } if posted_by else None,
            "assigned_to": {
                "id": assigned_to.id,
                "name": assigned_to.name,
                "avatar_url": assigned_to.avatar_url,
            } if assigned_to else None,
            "applicants_count": t.applicants_count or 0,
            "completion_otp": t.completion_otp,
            "review_reason": getattr(t, "review_reason", None),
            "cancel_reason": getattr(t, "cancel_reason", None),
            "created_at": t.created_at.isoformat(),
            "updated_at": t.updated_at.isoformat(),
        })

    return result


@router.get("/tasks/{task_id}")
def get_task(
    task_id: str,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session)
):
    """Get task by ID."""
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    posted_by = session.get(User, task.posted_by) if task.posted_by else None
    assigned_to = session.get(User, task.assigned_to) if task.assigned_to else None

    return {
        "id": task.id,
        "title": task.title,
        "description": task.description,
        "category": task.category,
        "budget": float(task.budget),
        "location": task.location,
        "deadline": task.deadline.isoformat(),
        "images": task.images or [],
        "status": task.status,
        "posted_by": {
            "id": posted_by.id,
            "name": posted_by.name,
            "avatar_url": posted_by.avatar_url,
        } if posted_by else None,
        "assigned_to": {
            "id": assigned_to.id,
            "name": assigned_to.name,
            "avatar_url": assigned_to.avatar_url,
        } if assigned_to else None,
        "applicants_count": task.applicants_count or 0,
        "completion_otp": task.completion_otp,
        "created_at": task.created_at.isoformat(),
        "updated_at": task.updated_at.isoformat(),
    }


@router.post("/tasks/{task_id}/assign")
def assign_task(
    task_id: str,
    data: dict,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session)
):
    """Assign task to a tasker."""
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    tasker_id = data.get("tasker_id")
    if not tasker_id:
        raise HTTPException(status_code=400, detail="tasker_id required")

    tasker = session.get(User, tasker_id)
    if not tasker or tasker.user_type != "tasker":
        raise HTTPException(status_code=404, detail="Tasker not found")

    task.assigned_to = tasker_id
    task.status = "assigned"
    task.updated_at = datetime.utcnow()
    session.commit()

    return {"message": "Task assigned"}


@router.patch("/tasks/{task_id}")
def update_task(
    task_id: str,
    data: dict,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session)
):
    """Update task."""
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    for key, value in data.items():
        if hasattr(task, key):
            setattr(task, key, value)

    task.updated_at = datetime.utcnow()
    session.commit()

    return {"message": "Task updated"}


# ============================================================================
# Services Endpoints
# ============================================================================
@router.get("/services")
def get_services(
    category: Optional[str] = Query(None),
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    """Get all services."""
    query = select(Service)

    if category:
        query = query.where(Service.category == category)

    services = session.execute(query).scalars().all()

    return [
        {
            "id": s.id,
            "name": s.name,
            "emoji": s.emoji,
            "icon_asset": s.icon_asset,
            "category": s.category,
            "description": s.description,
            "price": float(s.price),
            "original_price": float(s.original_price),
            "rating": float(s.rating or 0),
            "review_count": s.review_count or 0,
            "is_hot": s.is_hot,
            "is_new": s.is_new,
            "includes": s.includes or [],
            "tasker_id": s.tasker_id,
            "is_active": s.is_active,
            "created_at": s.created_at.isoformat(),
        }
        for s in services
    ]


@router.patch("/services/{service_id}")
def update_service(
    service_id: str,
    data: dict,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session)
):
    """Update service."""
    service = session.get(Service, service_id)
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")

    for key, value in data.items():
        if hasattr(service, key):
            setattr(service, key, value)

    session.commit()
    session.refresh(service)

    return {"message": "Service updated"}


# ============================================================================
# Bookings Endpoints
# ============================================================================
@router.get("/bookings")
def get_bookings(
    status: Optional[str] = Query(None),
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    """Get all bookings."""
    query = select(Booking)

    if status:
        query = query.where(Booking.status == status)

    query = query.order_by(Booking.created_at.desc())
    bookings = session.execute(query).scalars().all()

    def _name_of(uid):
        if not uid:
            return None
        u = session.get(User, uid)
        return {"id": uid, "name": u.name if u else uid}

    return [
        {
            "id": b.id,
            "booking_id": b.booking_id,
            "customer_id": b.customer_id,
            "customer": _name_of(b.customer_id),
            "tasker": _name_of(b.tasker_id),
            "tasker_id": b.tasker_id,
            "service_id": b.service_id,
            "service": b.service,
            "scheduled_at": b.scheduled_at.isoformat(),
            "address": b.address,
            "notes": b.notes,
            "status": b.status,
            "total_amount": float(b.total_amount),
            "paid_with_wallet": bool(b.paid_with_wallet),
            "created_at": b.created_at.isoformat(),
            "updated_at": b.updated_at.isoformat(),
        }
        for b in bookings
    ]


@router.post("/bookings/{booking_id}/cancel")
def cancel_booking(
    booking_id: str,
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session)
):
    """Cancel booking (admin). Wallet-paid bookings are refunded in full."""
    import uuid as _uuid

    from database import Notification

    booking = session.get(Booking, booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.status == "cancelled":
        raise HTTPException(status_code=400, detail="Booking is already cancelled")

    refunded = 0.0
    if booking.paid_with_wallet and booking.status != "completed":
        customer = session.get(User, booking.customer_id)
        if customer:
            refunded = float(booking.total_amount)
            customer.wallet_balance = round(
                float(customer.wallet_balance or 0.0) + refunded, 2
            )
            customer.updated_at = datetime.utcnow()
            session.add(
                Transaction(
                    id=str(_uuid.uuid4()),
                    user_id=booking.customer_id,
                    type="refund",
                    amount=refunded,
                    description=f"Refund for cancelled {booking.booking_id} (by support)",
                    created_at=datetime.utcnow(),
                )
            )

    booking.status = "cancelled"
    booking.updated_at = datetime.utcnow()

    service_name = (booking.service or {}).get("name", "Your booking")
    session.add(
        Notification(
            id=str(_uuid.uuid4()),
            user_id=booking.customer_id,
            title="Booking Cancelled",
            body=f"{service_name} ({booking.booking_id}) was cancelled by support."
            + (f" ₹{refunded:.0f} refunded to your wallet." if refunded else ""),
            emoji="❌",
            type="booking",
            is_read=False,
            created_at=datetime.utcnow(),
        )
    )
    from routes.admin.extra import audit as _audit
    _audit(session, admin, "booking.cancel", "booking", booking.booking_id,
           f"refunded ₹{refunded:.0f}" if refunded else None)
    session.commit()

    return {
        "message": "Booking cancelled"
        + (f", ₹{refunded:.0f} refunded to wallet" if refunded else ""),
        "refunded": refunded,
    }


# ============================================================================
# Transactions Endpoints
# ============================================================================
@router.get("/transactions")
def get_transactions(
    limit: int = Query(50, le=100),
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    """Get all transactions."""
    query = select(Transaction).order_by(Transaction.created_at.desc()).limit(limit)
    transactions = session.execute(query).scalars().all()

    _names: dict = {}

    def _uname(uid):
        if uid not in _names:
            u = session.get(User, uid)
            _names[uid] = u.name if u else uid
        return _names[uid]

    return [
        {
            "id": t.id,
            "user_id": t.user_id,
            "user_name": _uname(t.user_id),
            "type": t.type,
            "amount": float(t.amount),
            "description": t.description,
            "task_id": t.task_id,
            "related_user_id": t.related_user_id,
            "created_at": t.created_at.isoformat(),
        }
        for t in transactions
    ]


# ============================================================================
# Withdrawals Endpoints
# ============================================================================
@router.get("/withdrawals")
def get_withdrawals(
    status: Optional[str] = Query(None),
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session),
):
    """Get all withdrawals."""
    query = select(Withdrawal)

    if status:
        query = query.where(Withdrawal.status == status)

    query = query.order_by(Withdrawal.created_at.desc())
    withdrawals = session.execute(query).scalars().all()

    _wnames: dict = {}

    def _wname(uid):
        if uid not in _wnames:
            u = session.get(User, uid)
            _wnames[uid] = u.name if u else uid
        return _wnames[uid]

    return [
        {
            "id": w.id,
            "user_id": w.user_id,
            "user_name": _wname(w.user_id),
            "amount": float(w.amount),
            "method": w.method,
            "details": w.details,
            "status": w.status,
            "created_at": w.created_at.isoformat(),
        }
        for w in withdrawals
    ]


@router.post("/withdrawals/{withdrawal_id}/approve")
def approve_withdrawal(
    withdrawal_id: str,
    admin: dict = Depends(get_current_manager),
    session: Session = Depends(get_db_session)
):
    """Approve withdrawal."""
    withdrawal = session.get(Withdrawal, withdrawal_id)
    if not withdrawal:
        raise HTTPException(status_code=404, detail="Withdrawal not found")

    if withdrawal.status != "pending":
        raise HTTPException(
            status_code=400,
            detail=f"Withdrawal is already {withdrawal.status}",
        )
    withdrawal.status = "approved"
    from routes._helpers import notify_user
    from routes.admin.extra import audit as _audit
    notify_user(session, withdrawal.user_id, "Withdrawal Approved",
                f"Your withdrawal of ₹{float(withdrawal.amount):.0f} has been approved and is being processed.")
    _audit(session, admin, "withdrawal.approve", "withdrawal", withdrawal.id,
           f"₹{float(withdrawal.amount):.0f}")
    session.commit()

    return {"message": "Withdrawal approved"}


@router.post("/withdrawals/{withdrawal_id}/reject")
def reject_withdrawal(
    withdrawal_id: str,
    admin: dict = Depends(get_current_manager),
    session: Session = Depends(get_db_session)
):
    """Reject withdrawal."""
    withdrawal = session.get(Withdrawal, withdrawal_id)
    if not withdrawal:
        raise HTTPException(status_code=404, detail="Withdrawal not found")

    if withdrawal.status != "pending":
        raise HTTPException(
            status_code=400,
            detail=f"Withdrawal is already {withdrawal.status}",
        )
    withdrawal.status = "rejected"
    # The amount was deducted at request time — return it to the wallet.
    import uuid as _uuid
    user = session.get(User, withdrawal.user_id)
    amount = float(withdrawal.amount)
    if user:
        user.wallet_balance = round(float(user.wallet_balance or 0.0) + amount, 2)
        user.updated_at = datetime.utcnow()
    session.add(Transaction(
        id=str(_uuid.uuid4()),
        user_id=withdrawal.user_id,
        type="refund",
        amount=amount,
        description=f"Withdrawal rejected — ₹{amount:.0f} returned to wallet",
        created_at=datetime.utcnow(),
    ))
    from routes._helpers import notify_user
    from routes.admin.extra import audit as _audit
    notify_user(session, withdrawal.user_id, "Withdrawal Rejected",
                f"Your withdrawal of ₹{amount:.0f} was rejected. The amount has been returned to your wallet.")
    _audit(session, admin, "withdrawal.reject", "withdrawal", withdrawal.id,
           f"₹{amount:.0f} refunded")
    session.commit()

    return {"message": "Withdrawal rejected"}


# ============================================================================
# Reviews Endpoints
# ============================================================================
@router.get("/reviews")
def get_reviews(
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session)
):
    """Get all reviews."""
    query = select(Review).order_by(Review.created_at.desc())
    reviews = session.execute(query).scalars().all()

    _rnames: dict = {}

    def _rname(uid):
        if uid not in _rnames:
            u = session.get(User, uid)
            _rnames[uid] = u.name if u else uid
        return _rnames[uid]

    return [
        {
            "id": r.id,
            "task_id": r.task_id,
            "reviewer_id": r.reviewer_id,
            "reviewer_name": _rname(r.reviewer_id),
            "reviewed_user_id": r.reviewed_user_id,
            "reviewed_user_name": _rname(r.reviewed_user_id),
            "rating": float(r.rating),
            "comment": r.comment,
            "created_at": r.created_at.isoformat(),
        }
        for r in reviews
    ]


# ============================================================================
# Settings Endpoints
# ============================================================================
# Default platform settings surfaced to the admin panel. These are returned
# when a key has not yet been persisted to the database.
_DEFAULT_SETTINGS = {
    "platform_name": "TaskTeddy",
    "support_email": "support@taskteddy.com",
    "platform_commission_percent": "10",
}


@router.get("/settings")
def get_admin_settings(
    admin: dict = Depends(get_current_admin),
    session: Session = Depends(get_db_session)
):
    """Get all platform settings as a key/value dict."""
    rows = session.execute(select(Setting)).scalars().all()
    result = dict(_DEFAULT_SETTINGS)
    for row in rows:
        result[row.key] = row.value
    return result


@router.put("/settings")
def update_admin_settings(
    data: dict,
    admin: dict = Depends(get_current_manager),
    session: Session = Depends(get_db_session)
):
    """Upsert one or more platform settings."""
    for key, value in data.items():
        if not isinstance(key, str):
            continue
        setting = session.get(Setting, key)
        str_value = "" if value is None else str(value)
        if setting:
            setting.value = str_value
            setting.updated_at = datetime.utcnow()
        else:
            session.add(Setting(key=key, value=str_value))

    session.commit()

    rows = session.execute(select(Setting)).scalars().all()
    result = dict(_DEFAULT_SETTINGS)
    for row in rows:
        result[row.key] = row.value
    return result
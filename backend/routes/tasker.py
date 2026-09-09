"""Tasker-specific endpoints: Services, Applications, and Tasker-only operations."""
import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from pydantic import BaseModel, Field
from sqlalchemy import and_, func, select
from sqlalchemy.orm import Session, joinedload

from database import (
    Application,
    Booking,
    PortfolioItem,
    Service,
    Setting,
    Task,
    TaskerAvailability,
    User,
    generate_application_id,
    generate_service_id,
    get_db_session,
    is_tasker,
)
from models.schemas import TaskCategory, LocationUpdate
from routes._helpers import task_to_response, user_to_public
from utils.auth import get_current_user
from utils.uploads import save_upload_file
from utils.geolocation import DEFAULT_RADIUS_KM, MAX_RADIUS_KM, haversine_distance

router = APIRouter(tags=["tasker"])

# How many unsettled cash jobs a tasker may carry before browsing is paused.
CASH_DUES_LIMIT = 2


def _require_tasker(user_id: str) -> None:
    """Ensure user is a tasker"""
    if not is_tasker(user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This endpoint is for taskers only"
        )


def _get_tasker_session(session: Session, tasker_id: str) -> User:
    """Get tasker user or raise 404"""
    user = session.get(User, tasker_id)
    if not user or not is_tasker(user.id):
        raise HTTPException(status_code=404, detail="Tasker not found")
    return user


def _verification_required(session: Session) -> bool:
    """Whether taskers must be KYC-verified before applying. Defaults to True;
    admins can relax it (e.g. during testing) via the settings table."""
    row = session.get(Setting, "require_tasker_verification")
    if row is None or row.value is None:
        return True
    return str(row.value).strip().lower() in ("1", "true", "yes", "on")


# ============================================================================
# Schemas
# ============================================================================

class TaskerServiceCreate(BaseModel):
    name: str = Field(..., min_length=3, max_length=200)
    emoji: str | None = None
    category: str
    description: str = Field(..., min_length=10)
    price: float = Field(..., gt=0)
    original_price: float = Field(..., gt=0)
    includes: list[str] = []
    is_hot: bool = False
    is_new: bool = False


class TaskerServiceUpdate(BaseModel):
    name: str | None = None
    emoji: str | None = None
    description: str | None = None
    price: float | None = None
    original_price: float | None = None
    includes: list[str] | None = None
    is_hot: bool | None = None
    is_active: bool | None = None


class TaskerApplicationCreate(BaseModel):
    task_id: str
    bid_amount: float = Field(..., gt=0)
    cover_letter: str = Field(..., min_length=20)


# ============================================================================
# Service Endpoints
# ============================================================================

@router.post("/services", status_code=status.HTTP_201_CREATED)
def create_service(
    service_data: TaskerServiceCreate,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Tasker creates a new service offering"""
    _require_tasker(current_user["sub"])
    
    tasker = _get_tasker_session(session, current_user["sub"])
    
    new_service = Service(
        id=generate_service_id(tasker.id),
        name=service_data.name.strip(),
        emoji=service_data.emoji,
        category=service_data.category,
        description=service_data.description.strip(),
        price=float(service_data.price),
        original_price=float(service_data.original_price),
        includes=list(service_data.includes or []),
        is_hot=service_data.is_hot,
        is_new=service_data.is_new,
        tasker_id=tasker.id,
        is_active=True,
        created_at=datetime.utcnow(),
    )
    
    session.add(new_service)
    session.commit()
    session.refresh(new_service)
    
    return {
        "message": "Service created successfully",
        "service": {
            "id": new_service.id,
            "name": new_service.name,
            "emoji": new_service.emoji,
            "category": new_service.category,
            "description": new_service.description,
            "price": new_service.price,
            "original_price": new_service.original_price,
            "includes": new_service.includes,
            "is_hot": new_service.is_hot,
            "is_new": new_service.is_new,
            "is_active": new_service.is_active,
            "rating": new_service.rating,
            "review_count": new_service.review_count,
            "created_at": new_service.created_at,
        },
    }


@router.get("/services")
def get_my_services(
    active_only: bool = Query(default=True),
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Get all services offered by this tasker"""
    _require_tasker(current_user["sub"])
    
    query = select(Service).where(Service.tasker_id == current_user["sub"])
    
    if active_only:
        query = query.where(Service.is_active == True)
    
    services = session.execute(
        query.order_by(Service.created_at.desc())
    ).scalars().all()
    
    return [
        {
            "id": s.id,
            "name": s.name,
            "emoji": s.emoji,
            "category": s.category,
            "description": s.description,
            "price": s.price,
            "original_price": s.original_price,
            "includes": s.includes,
            "is_hot": s.is_hot,
            "is_new": s.is_new,
            "is_active": s.is_active,
            "rating": s.rating,
            "review_count": s.review_count,
            "created_at": s.created_at,
        }
        for s in services
    ]


@router.get("/services/{service_id}")
def get_service(
    service_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Get a specific service (must be owned by this tasker)"""
    _require_tasker(current_user["sub"])
    
    service = session.get(Service, service_id)
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    
    if service.tasker_id != current_user["sub"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only view your own services"
        )
    
    return {
        "id": service.id,
        "name": service.name,
        "emoji": service.emoji,
        "category": service.category,
        "description": service.description,
        "price": service.price,
        "original_price": service.original_price,
        "includes": service.includes,
        "is_hot": service.is_hot,
        "is_new": service.is_new,
        "is_active": service.is_active,
        "rating": service.rating,
        "review_count": service.review_count,
        "created_at": service.created_at,
    }


@router.patch("/services/{service_id}")
def update_service(
    service_id: str,
    service_data: TaskerServiceUpdate,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Update a service (only by the tasker who created it)"""
    _require_tasker(current_user["sub"])
    
    service = session.get(Service, service_id)
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    
    if service.tasker_id != current_user["sub"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only update your own services"
        )
    
    payload = service_data.model_dump(exclude_unset=True)
    for field, value in payload.items():
        setattr(service, field, value)
    
    session.commit()
    session.refresh(service)
    
    return {
        "message": "Service updated successfully",
        "service": {
            "id": service.id,
            "name": service.name,
            "price": service.price,
            "is_active": service.is_active,
        },
    }


@router.delete("/services/{service_id}")
def delete_service(
    service_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Delete a service (soft delete - just mark inactive)"""
    _require_tasker(current_user["sub"])
    
    service = session.get(Service, service_id)
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    
    if service.tasker_id != current_user["sub"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only delete your own services"
        )
    
    service.is_active = False
    session.commit()
    
    return {"message": "Service deleted successfully"}


# ============================================================================
# Location (for Taskers to update their current location)
# ============================================================================

@router.post("/location")
def update_location(
    location_data: LocationUpdate,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Update tasker's current location for task matching.
    
    Taskers must update their location to see nearby tasks.
    Tasks are filtered to show only those within 20km radius.
    """
    _require_tasker(current_user["sub"])
    
    tasker = _get_tasker_session(session, current_user["sub"])
    tasker.latitude = location_data.latitude
    tasker.longitude = location_data.longitude
    tasker.last_location_at = datetime.utcnow()
    session.commit()
    
    return {
        "message": "Location updated successfully",
        "latitude": tasker.latitude,
        "longitude": tasker.longitude,
        "search_radius_km": DEFAULT_RADIUS_KM,
    }


@router.get("/location")
def get_location(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Get tasker's current location."""
    _require_tasker(current_user["sub"])
    
    tasker = _get_tasker_session(session, current_user["sub"])
    
    return {
        "latitude": tasker.latitude,
        "longitude": tasker.longitude,
        "last_location_at": tasker.last_location_at,
        "search_radius_km": DEFAULT_RADIUS_KM,
    }


# ============================================================================
# Browse Tasks (for Taskers to find work)
# ============================================================================

@router.get("/dues-status")
def dues_status(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Whether the tasker is paused from browsing over unsettled cash dues."""
    _require_tasker(current_user["sub"])
    tasker = session.get(User, current_user["sub"])
    pending = int(tasker.pending_cash_jobs or 0) if tasker else 0
    balance = float(tasker.wallet_balance or 0.0) if tasker else 0.0
    dues = round(-balance, 2) if balance < 0 else 0.0
    return {
        "blocked": pending >= CASH_DUES_LIMIT,
        "pending_cash_jobs": pending,
        "limit": CASH_DUES_LIMIT,
        "dues": dues,
    }


@router.post("/settle-dues")
def settle_dues(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Settle the platform commission the tasker collected in cash. Clears the
    negative balance and resets the unsettled-cash counter, unpausing browsing.
    (No payment gateway at this stage — settlement is recorded directly.)"""
    import uuid as _uuid
    from database import Transaction
    _require_tasker(current_user["sub"])
    tasker = session.get(User, current_user["sub"])
    if tasker is None:
        raise HTTPException(status_code=404, detail="Tasker not found")

    balance = float(tasker.wallet_balance or 0.0)
    dues = round(-balance, 2) if balance < 0 else 0.0
    if dues > 0:
        session.add(Transaction(
            id=str(_uuid.uuid4()),
            user_id=tasker.id,
            type="settlement",
            amount=dues,
            description=f"Settled platform dues (₹{dues:.0f})",
            created_at=datetime.utcnow(),
        ))
        tasker.wallet_balance = 0.0
    tasker.pending_cash_jobs = 0
    tasker.updated_at = datetime.utcnow()
    session.commit()
    return {"message": "Dues settled", "settled": dues, "balance": float(tasker.wallet_balance)}


@router.get("/tasks")
def browse_tasks(
    category: str | None = None,
    status_filter: str = Query(default="open", alias="status"),
    min_budget: float | None = Query(default=None, alias="min_budget"),
    max_budget: float | None = Query(default=None, alias="max_budget"),
    location: str | None = None,
    latitude: float | None = Query(default=None, alias="latitude"),
    longitude: float | None = Query(default=None, alias="longitude"),
    radius_km: float = Query(default=DEFAULT_RADIUS_KM, le=MAX_RADIUS_KM),
    limit: int = Query(default=20, le=100),
    offset: int = Query(default=0),
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Browse available tasks that taskers can apply to.

    If latitude/longitude are provided, tasks are sorted nearest-first and
    geotagged tasks beyond ``radius_km`` (default 40km, max 50km) are dropped.
    Tasks WITHOUT coordinates are always kept — at launch many posted tasks are
    not geotagged, and hiding them would leave taskers with an empty feed.
    """
    _require_tasker(current_user["sub"])

    # Cash-dues gate: a tasker who has piled up unsettled cash jobs is paused
    # from browsing until they settle their wallet.
    _tasker = session.get(User, current_user["sub"])
    if _tasker and int(_tasker.pending_cash_jobs or 0) >= CASH_DUES_LIMIT:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Settle your platform dues to continue browsing tasks.",
        )

    # Remember the tasker's region so new-task notifications can target them.
    if (
        _tasker is not None
        and latitude is not None
        and longitude is not None
        and (_tasker.latitude != latitude or _tasker.longitude != longitude)
    ):
        _tasker.latitude = latitude
        _tasker.longitude = longitude
        _tasker.last_location_at = datetime.utcnow()
        session.commit()

    # Release any tasks that have cleared the review-hold window before listing.
    from routes._helpers import release_pending_tasks
    release_pending_tasks(session)

    query = select(Task).where(Task.status == status_filter)
    
    if category:
        query = query.where(Task.category == category)
    
    if min_budget is not None:
        query = query.where(Task.budget >= min_budget)
    
    if max_budget is not None:
        query = query.where(Task.budget <= max_budget)
    
    if location:
        query = query.where(func.lower(Task.location).contains(location.lower()))
    
    # Exclude tasks already assigned to this tasker
    query = query.where(
        (Task.assigned_to == None) | (Task.assigned_to == current_user["sub"])
    )

    # Hide tasks posted by anyone this tasker has blocked (or who blocked them).
    from routes.safety import blocked_user_ids
    blocked = blocked_user_ids(session, current_user["sub"])
    if blocked:
        query = query.where(Task.posted_by.not_in(blocked))

    tasks = session.execute(
        query.order_by(Task.created_at.desc())
        .offset(offset)
        .limit(limit * 2)  # Fetch extra to account for distance filtering
    ).scalars().all()
    
    # Rank/filter by distance when the tasker shares their location.
    if latitude is not None and longitude is not None:
        with_distance = []  # (distance_km, task) for geotagged tasks within radius
        without_coords = []  # tasks we can't place — kept so the feed isn't empty
        for task in tasks:
            if task.latitude is not None and task.longitude is not None:
                distance = haversine_distance(
                    latitude, longitude, task.latitude, task.longitude
                )
                if distance <= radius_km:
                    with_distance.append((distance, task))
            else:
                without_coords.append(task)

        # Nearest geotagged tasks first, then the un-geotagged ones.
        with_distance.sort(key=lambda pair: pair[0])
        ordered = [(d, t) for d, t in with_distance] + [(None, t) for t in without_coords]
        ordered = ordered[:limit]
        return [
            task_to_response(session, task, distance_km=distance)
            for distance, task in ordered
        ]

    # No tasker location: return most-recent tasks as before.
    tasks = tasks[:limit]
    return [task_to_response(session, task) for task in tasks]


# ============================================================================
# Application Endpoints
# ============================================================================

@router.post("/applications", status_code=status.HTTP_201_CREATED)
def create_application(
    app_data: TaskerApplicationCreate,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Tasker applies to a task"""
    _require_tasker(current_user["sub"])

    tasker = _get_tasker_session(session, current_user["sub"])

    # Safety gate: only KYC-verified taskers may apply (they show up at a
    # customer's home). Admin-toggleable via the `require_tasker_verification`
    # setting; defaults to enforced.
    if _verification_required(session) and not tasker.is_verified:
        raise HTTPException(
            status_code=403,
            detail="Please complete verification before applying to tasks.",
        )

    # Verify task exists and is open
    task = session.get(Task, app_data.task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task.status != "open":
        raise HTTPException(
            status_code=400,
            detail="Task is no longer accepting applications"
        )
    
    # Check if already applied
    existing = session.execute(
        select(Application).where(
            and_(
                Application.task_id == app_data.task_id,
                Application.applicant_id == tasker.id,
            )
        )
    ).scalar_one_or_none()
    
    if existing:
        if existing.status == "withdrawn":
            existing.status = "pending"
            existing.bid_amount = float(app_data.bid_amount)
            existing.cover_letter = app_data.cover_letter.strip()
            existing.updated_at = datetime.utcnow()
            
            task.applicants_count = (task.applicants_count or 0) + 1
            
            session.commit()
            session.refresh(existing)
            
            return {
                "message": "Application resubmitted successfully",
                "application": {
                    "id": existing.id,
                    "task_id": existing.task_id,
                    "bid_amount": existing.bid_amount,
                    "status": existing.status
                }
            }
        else:
            raise HTTPException(
                status_code=400,
                detail="You have already applied to this task"
            )
    
    new_application = Application(
        id=generate_application_id(tasker.id, task.id),
        task_id=task.id,
        applicant_id=tasker.id,
        bid_amount=float(app_data.bid_amount),
        cover_letter=app_data.cover_letter.strip(),
        status="pending",
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    
    # Increment applicant's count
    task.applicants_count = (task.applicants_count or 0) + 1
    
    session.add(new_application)
    session.commit()
    session.refresh(new_application)
    
    return {
        "message": "Application submitted successfully",
        "application": {
            "id": new_application.id,
            "task_id": new_application.task_id,
            "bid_amount": new_application.bid_amount,
            "cover_letter": new_application.cover_letter,
            "status": new_application.status,
            "created_at": new_application.created_at,
        },
    }


@router.get("/applications")
def get_my_applications(
    status_filter: str | None = Query(default=None, alias="status"),
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Get all applications by this tasker"""
    _require_tasker(current_user["sub"])
    
    # Use joinedload to avoid N+1 queries on task
    query = (
        select(Application)
        .options(joinedload(Application.task))
        .where(Application.applicant_id == current_user["sub"])
    )
    
    if status_filter:
        query = query.where(Application.status == status_filter)
    
    applications = session.execute(
        query.order_by(Application.created_at.desc())
    ).unique().scalars().all()
    
    return [
        {
            "id": app.id,
            "task": task_to_response(session, app.task) if app.task else None,
            "bid_amount": app.bid_amount,
            "cover_letter": app.cover_letter,
            "status": app.status,
            "created_at": app.created_at,
        }
        for app in applications
    ]


@router.get("/applications/{application_id}")
def get_application(
    application_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Get a specific application"""
    _require_tasker(current_user["sub"])
    
    application = session.get(Application, application_id)
    if not application or application.applicant_id != current_user["sub"]:
        raise HTTPException(status_code=404, detail="Application not found")
    
    task = session.get(Task, application.task_id)
    
    return {
        "id": application.id,
        "task": task_to_response(session, task) if task else None,
        "bid_amount": application.bid_amount,
        "cover_letter": application.cover_letter,
        "status": application.status,
        "created_at": application.created_at,
    }


@router.delete("/applications/{application_id}")
def withdraw_application(
    application_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Withdraw an application"""
    _require_tasker(current_user["sub"])
    
    application = session.get(Application, application_id)
    if not application or application.applicant_id != current_user["sub"]:
        raise HTTPException(status_code=404, detail="Application not found")
    
    if application.status != "pending":
        raise HTTPException(
            status_code=400,
            detail="Can only withdraw pending applications"
        )
    
    application.status = "withdrawn"
    application.updated_at = datetime.utcnow()
    
    # Decrement applicant's count
    task = session.get(Task, application.task_id)
    if task and (task.applicants_count or 0) > 0:
        task.applicants_count -= 1
        
    session.commit()
    
    return {"message": "Application withdrawn successfully"}


# ============================================================================
# Bookings (for Taskers to see their bookings)
# ============================================================================

@router.get("/bookings")
def get_my_bookings(
    status_filter: str | None = Query(default=None, alias="status"),
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Get all bookings for this tasker"""
    _require_tasker(current_user["sub"])
    
    query = select(Booking).where(Booking.tasker_id == current_user["sub"])
    
    if status_filter:
        query = query.where(Booking.status == status_filter)
    
    bookings = session.execute(
        query.order_by(Booking.scheduled_at.asc())
    ).scalars().all()
    
    result = []
    for b in bookings:
        customer = session.get(User, b.customer_id)
        result.append({
            "id": b.id,
            "booking_id": b.booking_id,
            "service": b.service,
            "customer": user_to_public(customer, include_wallet=False) if customer else None,
            "scheduled_at": b.scheduled_at,
            "address": b.address,
            "status": b.status,
            "total_amount": b.total_amount,
            "created_at": b.created_at,
        })
    
    return result


@router.patch("/bookings/{booking_id}/complete")
def complete_booking(
    booking_id: str,
    completion_otp: str = Query(..., min_length=4),
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Mark booking as completed (requires OTP from customer)"""
    _require_tasker(current_user["sub"])
    
    booking = session.get(Booking, booking_id)
    if not booking or booking.tasker_id != current_user["sub"]:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    if booking.status != "confirmed":
        raise HTTPException(
            status_code=400,
            detail="Booking is not in confirmed status"
        )
    
    # Verify OTP
    task = session.get(Task, booking.service_id)
    if task and task.completion_otp != completion_otp:
        raise HTTPException(
            status_code=400,
            detail="Invalid completion OTP"
        )
    
    booking.status = "completed"
    booking.updated_at = datetime.utcnow()

    # Wallet-paid bookings: release the (already collected) amount to the
    # tasker, minus platform commission. Pay-after-service bookings settle in
    # cash, so no wallet movement.
    if booking.paid_with_wallet:
        from routes._helpers import credit_earning, notify_user
        service_name = (booking.service or {}).get("name", "booking")
        earning = credit_earning(
            session, current_user["sub"], float(booking.total_amount),
            f"Earning for {service_name} ({booking.booking_id})",
        )
        notify_user(session, current_user["sub"], "Payment Received",
                    f"₹{earning['net']:.0f} credited to your wallet for {service_name}.")
    session.commit()
    
    return {"message": "Booking completed successfully"}


@router.patch("/tasks/{task_id}/complete")
def complete_task(
    task_id: str,
    completion_otp: str = Query(..., min_length=4),
    payment_method: str = Query("cash", pattern="^(cash|wallet)$"),
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Mark task as completed (requires OTP from customer).

    ``payment_method`` reflects how the customer paid: ``cash`` (default for the
    post-task model — customer pays the tasker directly, so the tasker owes the
    platform its commission) or ``wallet`` (funds held by TaskTeddy, released to
    the tasker minus commission)."""
    _require_tasker(current_user["sub"])
    
    task = session.get(Task, task_id)
    if not task or task.assigned_to != current_user["sub"]:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task.status != "assigned":
        raise HTTPException(
            status_code=400,
            detail="Task is not in assigned status"
        )
    
    # Verify OTP
    if task.completion_otp != completion_otp:
        raise HTTPException(
            status_code=400,
            detail="Invalid completion OTP"
        )
    
    task.status = "completed"
    task.updated_at = datetime.utcnow()

    # Bump the tasker's lifetime completed count (drives reputation level).
    _tasker_user = session.get(User, current_user["sub"])
    if _tasker_user is not None:
        _tasker_user.completed_tasks = int(_tasker_user.completed_tasks or 0) + 1

    # Settle the job. Accepted bid amount (fallback: task budget) is the gross.
    from routes._helpers import charge_commission, credit_earning, notify_user
    accepted = session.execute(
        select(Application).where(
            and_(
                Application.task_id == task.id,
                Application.applicant_id == current_user["sub"],
                Application.status == "accepted",
            )
        )
    ).scalar_one_or_none()
    gross = float(accepted.bid_amount) if accepted else float(task.budget or 0)

    promo = float(task.promo_discount or 0.0)
    if payment_method == "wallet":
        # Funds held by the platform: release net to the tasker's wallet. Any
        # customer bonus was already deducted at apply time and simply reduces
        # the platform's kept commission — the tasker's net is unchanged.
        earning = credit_earning(
            session, current_user["sub"], gross,
            f"Earning for '{task.title}'", task_id=task.id,
        )
        notify_user(session, current_user["sub"], "Payment Received",
                    f"₹{earning['net']:.0f} credited to your wallet for '{task.title}'.")
    else:
        # Cash job: tasker collected cash; record the commission they owe. A
        # customer bonus reduces both the cash they collect and the fee they owe
        # by the same amount, so their take-home is unchanged.
        earning = charge_commission(
            session, current_user["sub"], gross,
            f"'{task.title}'", task_id=task.id, discount=promo,
        )
        collected = earning.get("collected", earning["gross"])
        notify_user(session, current_user["sub"], "Job Completed",
                    f"You collected ₹{collected:.0f} in cash. "
                    f"Platform fee ₹{earning['commission']:.0f} was deducted from your wallet.")

    if promo > 0:
        notify_user(session, task.posted_by, "Bonus Applied",
                    f"Your ₹{promo:.0f} TaskTeddy bonus saved you money on '{task.title}'. "
                    f"Thanks for using TaskTeddy!", emoji="🎁")

    notify_user(session, task.posted_by, "Task Completed",
                f"'{task.title}' has been completed. Don't forget to leave a review!",
                emoji="✅")
    session.commit()

    return {"message": "Task completed successfully", "earning": earning}


@router.patch("/tasks/{task_id}/on-the-way")
def mark_on_the_way(
    task_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Assigned tasker signals they are heading to the job — powers the
    customer's live "on the way" / tracking UI."""
    _require_tasker(current_user["sub"])
    task = session.get(Task, task_id)
    if not task or task.assigned_to != current_user["sub"]:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.status != "assigned":
        raise HTTPException(status_code=400, detail="Task is not in assigned status")

    task.on_the_way_at = datetime.utcnow()
    task.updated_at = datetime.utcnow()
    from routes._helpers import notify_user
    notify_user(session, task.posted_by, "Tasker on the way",
                f"Your tasker is heading to '{task.title}'.", emoji="🚗")
    session.commit()
    return {"message": "Marked on the way", "on_the_way_at": task.on_the_way_at}


class TaskerCancel(BaseModel):
    reason: str | None = None


@router.patch("/tasks/{task_id}/cancel")
def tasker_cancel_task(
    task_id: str,
    body: TaskerCancel,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Assigned tasker backs out of a committed job. The task is reopened for
    other taskers, and the back-out counts against the tasker's reliability."""
    _require_tasker(current_user["sub"])
    task = session.get(Task, task_id)
    if not task or task.assigned_to != current_user["sub"]:
        raise HTTPException(status_code=404, detail="Task not found")
    if task.status not in ("assigned",):
        raise HTTPException(status_code=400, detail="Only an assigned job can be cancelled")

    from routes._helpers import notify_user

    former_customer = task.posted_by
    now = datetime.utcnow()

    # Drop this tasker's accepted application.
    accepted = session.execute(
        select(Application).where(
            and_(Application.task_id == task.id,
                 Application.applicant_id == current_user["sub"],
                 Application.status == "accepted")
        )
    ).scalar_one_or_none()
    if accepted:
        accepted.status = "withdrawn"
        accepted.updated_at = now

    # Restore the OTHER offers that were auto-rejected when this tasker was
    # accepted, so the customer can immediately pick someone else instead of
    # starting from zero.
    others = session.execute(
        select(Application).where(
            and_(Application.task_id == task.id,
                 Application.applicant_id != current_user["sub"],
                 Application.status == "rejected")
        )
    ).scalars().all()
    for o in others:
        o.status = "pending"
        o.updated_at = now
        notify_user(session, o.applicant_id, "Job available again",
                    f"'{task.title}' is open again — your offer is back in the running.",
                    emoji="🔄")

    # Reopen the task, unassigned, with the restored offers as its live count.
    task.status = "open"
    task.assigned_to = None
    task.on_the_way_at = None
    task.cancel_reason = (body.reason or "").strip() or "Tasker backed out"
    task.cancelled_by = current_user["sub"]
    task.applicants_count = len(others)
    task.updated_at = now

    # Refund any bonus the customer had locked onto this task — the tasker/bid it
    # was tied to is gone, so the customer can re-apply it after choosing again.
    refund = round(float(task.promo_discount or 0.0), 2)
    if refund > 0:
        import uuid as _uuid
        from database import Transaction
        _cust = session.get(User, former_customer)
        if _cust:
            _cust.promo_balance = round(float(_cust.promo_balance or 0.0) + refund, 2)
        task.promo_discount = 0.0
        session.add(Transaction(
            id=str(_uuid.uuid4()),
            user_id=former_customer,
            type="promo",
            amount=refund,
            description=f"TaskTeddy bonus refunded — tasker left '{task.title}'",
            task_id=task.id,
            created_at=now,
        ))

    tasker = session.get(User, current_user["sub"])
    if tasker:
        tasker.cancel_count = int(tasker.cancel_count or 0) + 1

    # Tell the customer, with a CTA that matches whether offers are waiting.
    if others:
        notify_user(
            session, former_customer, "Tasker cancelled",
            f"Your tasker backed out of '{task.title}'. "
            f"{len(others)} other offer(s) are ready — choose another tasker.",
            emoji="⚠️")
    else:
        notify_user(
            session, former_customer, "Tasker cancelled",
            f"Your tasker backed out of '{task.title}'. It's open again for new offers.",
            emoji="⚠️")

    session.commit()
    return {
        "message": "You have withdrawn from this job",
        "task_id": task.id,
        "offers_restored": len(others),
    }


# ============================================================================
# Profile Endpoints
# ============================================================================

@router.get("/profile")
def get_profile(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Get tasker profile"""
    _require_tasker(current_user["sub"])
    tasker = _get_tasker_session(session, current_user["sub"])
    return user_to_public(tasker)


@router.post("/profile/avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Upload tasker avatar"""
    _require_tasker(current_user["sub"])
    
    tasker = _get_tasker_session(session, current_user["sub"])
    avatar_url = await save_upload_file(file, "avatars")
    tasker.avatar_url = avatar_url
    tasker.updated_at = datetime.utcnow()
    session.commit()

    return {"avatar_url": avatar_url}


# ============================================================================
# Availability (weekly working hours)
# ============================================================================

def _availability_row_to_dict(row: TaskerAvailability) -> dict:
    return {
        "day_of_week": int(row.day_of_week),
        "start_minute": int(row.start_minute),
        "end_minute": int(row.end_minute),
        "is_available": bool(row.is_available),
    }


def _default_week() -> list[dict]:
    # Mon–Sat 9:00–18:00 available, Sunday off — a sensible starting schedule.
    return [
        {
            "day_of_week": d,
            "start_minute": 540,
            "end_minute": 1080,
            "is_available": d != 6,
        }
        for d in range(7)
    ]


class AvailabilityDay(BaseModel):
    day_of_week: int = Field(..., ge=0, le=6)
    start_minute: int = Field(540, ge=0, le=1440)
    end_minute: int = Field(1080, ge=0, le=1440)
    is_available: bool = True


class AvailabilityUpdate(BaseModel):
    days: list[AvailabilityDay]


@router.get("/availability")
def get_availability(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    _require_tasker(current_user["sub"])
    rows = (
        session.execute(
            select(TaskerAvailability)
            .where(TaskerAvailability.tasker_id == current_user["sub"])
            .order_by(TaskerAvailability.day_of_week.asc())
        )
        .scalars()
        .all()
    )
    if not rows:
        return {"days": _default_week()}
    by_day = {int(r.day_of_week): _availability_row_to_dict(r) for r in rows}
    # Always return a full 7-day week so the client can render every row.
    days = [by_day.get(d, {
        "day_of_week": d, "start_minute": 540, "end_minute": 1080,
        "is_available": False,
    }) for d in range(7)]
    return {"days": days}


@router.put("/availability")
def set_availability(
    body: AvailabilityUpdate,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    _require_tasker(current_user["sub"])
    tasker_id = current_user["sub"]
    existing = {
        int(r.day_of_week): r
        for r in session.execute(
            select(TaskerAvailability).where(
                TaskerAvailability.tasker_id == tasker_id
            )
        ).scalars().all()
    }
    for day in body.days:
        end = max(day.end_minute, day.start_minute)
        row = existing.get(day.day_of_week)
        if row is None:
            session.add(TaskerAvailability(
                id=f"AVL_{uuid.uuid4().hex[:20]}",
                tasker_id=tasker_id,
                day_of_week=day.day_of_week,
                start_minute=day.start_minute,
                end_minute=end,
                is_available=day.is_available,
                updated_at=datetime.utcnow(),
            ))
        else:
            row.start_minute = day.start_minute
            row.end_minute = end
            row.is_available = day.is_available
            row.updated_at = datetime.utcnow()
    session.commit()
    return get_availability(current_user, session)


# ============================================================================
# Portfolio (photos of past work)
# ============================================================================

def _portfolio_to_dict(item: PortfolioItem) -> dict:
    return {
        "id": item.id,
        "image_url": item.image_url,
        "caption": item.caption,
        "created_at": item.created_at,
    }


@router.get("/portfolio")
def get_my_portfolio(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    _require_tasker(current_user["sub"])
    rows = (
        session.execute(
            select(PortfolioItem)
            .where(PortfolioItem.tasker_id == current_user["sub"])
            .order_by(PortfolioItem.created_at.desc())
        )
        .scalars()
        .all()
    )
    return [_portfolio_to_dict(p) for p in rows]


@router.post("/portfolio", status_code=status.HTTP_201_CREATED)
async def add_portfolio_item(
    file: UploadFile = File(...),
    caption: str | None = Query(None, max_length=300),
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    _require_tasker(current_user["sub"])
    # Cap portfolio size to keep profiles tidy and storage bounded.
    count = (
        session.query(PortfolioItem)
        .filter(PortfolioItem.tasker_id == current_user["sub"])
        .count()
    )
    if count >= 12:
        raise HTTPException(status_code=400, detail="Portfolio limit reached (12 photos)")

    image_url = await save_upload_file(file, "portfolio")
    item = PortfolioItem(
        id=f"PORT_{uuid.uuid4().hex[:20]}",
        tasker_id=current_user["sub"],
        image_url=image_url,
        caption=(caption.strip() if caption else None),
        created_at=datetime.utcnow(),
    )
    session.add(item)
    session.commit()
    session.refresh(item)
    return _portfolio_to_dict(item)


@router.delete("/portfolio/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_portfolio_item(
    item_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    _require_tasker(current_user["sub"])
    item = session.get(PortfolioItem, item_id)
    if item is not None and item.tasker_id == current_user["sub"]:
        session.delete(item)
        session.commit()
    return None
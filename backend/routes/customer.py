"""Customer-specific endpoints: Tasks, Bookings, and Customer-only operations."""
from datetime import datetime
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import and_, select
from sqlalchemy.orm import Session, joinedload

from database import (
    Booking,
    Task,
    User,
    generate_booking_id,
    generate_task_id,
    get_db_session,
    is_customer,
)
from models.schemas import TaskCategory, TaskStatus
from routes._helpers import task_to_response, user_to_public
from utils.auth import get_current_user

router = APIRouter(tags=["customer"])


def _require_customer(user_id: str) -> None:
    """Ensure user is a customer"""
    if not is_customer(user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This endpoint is for customers only"
        )


def _get_customer_session(session: Session, customer_id: str) -> User:
    """Get customer user or raise 404"""
    user = session.get(User, customer_id)
    if not user or not is_customer(user.id):
        raise HTTPException(status_code=404, detail="Customer not found")
    return user


# ============================================================================
# Schemas
# ============================================================================

class CustomerTaskCreate(BaseModel):
    title: str = Field(..., min_length=5, max_length=200)
    description: str = Field(..., min_length=10)
    category: TaskCategory
    budget: float = Field(..., gt=0)
    location: str
    deadline: datetime
    images: list[str] = []


class CustomerTaskUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    budget: float | None = None
    location: str | None = None
    deadline: datetime | None = None
    status: TaskStatus | None = None


class CustomerBookingCreate(BaseModel):
    service_id: str
    tasker_id: str
    scheduled_at: datetime
    address: str
    notes: str | None = None


# ============================================================================
# Task Endpoints
# ============================================================================

@router.post("/tasks", status_code=status.HTTP_201_CREATED)
def create_task(
    task_data: CustomerTaskCreate,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Customer posts a new task"""
    _require_customer(current_user["sub"])
    
    customer = _get_customer_session(session, current_user["sub"])
    
    new_task = Task(
        id=generate_task_id(session),
        title=task_data.title.strip(),
        description=task_data.description.strip(),
        category=task_data.category.value,
        budget=float(task_data.budget),
        location=task_data.location.strip(),
        deadline=task_data.deadline,
        images=list(task_data.images or []),
        status="open",
        posted_by=customer.id,
        assigned_to=None,
        applicants_count=0,
        completion_otp=None,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    
    session.add(new_task)
    session.commit()
    session.refresh(new_task)
    
    return {
        "message": "Task posted successfully",
        "task": task_to_response(session, new_task),
    }


@router.get("/tasks")
def get_my_tasks(
    status_filter: str | None = Query(default=None, alias="status"),
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Get all tasks posted by this customer"""
    _require_customer(current_user["sub"])
    
    query = select(Task).where(Task.posted_by == current_user["sub"])
    
    if status_filter:
        query = query.where(Task.status == status_filter)
    
    tasks = session.execute(
        query.order_by(Task.created_at.desc())
    ).scalars().all()
    
    return [task_to_response(session, task) for task in tasks]


@router.get("/tasks/{task_id}")
def get_task(
    task_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Get a specific task (must be posted by this customer)"""
    _require_customer(current_user["sub"])
    
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task.posted_by != current_user["sub"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only view your own tasks"
        )
    
    return task_to_response(session, task)


@router.patch("/tasks/{task_id}")
def update_task(
    task_id: str,
    task_data: CustomerTaskUpdate,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Update a task (only by the customer who posted it)"""
    _require_customer(current_user["sub"])
    
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task.posted_by != current_user["sub"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only update your own tasks"
        )
    
    if task.status not in ("open", "cancelled"):
        raise HTTPException(
            status_code=400,
            detail="Cannot update task that is already assigned or completed"
        )
    
    payload = task_data.model_dump(exclude_unset=True)
    for field, value in payload.items():
        setattr(task, field, value)
    task.updated_at = datetime.utcnow()
    
    session.commit()
    session.refresh(task)
    
    return {
        "message": "Task updated successfully",
        "task": task_to_response(session, task),
    }


@router.delete("/tasks/{task_id}")
def cancel_task(
    task_id: str,
    reason: str | None = Query(default=None),
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Cancel a task (only by the customer who posted it)"""
    _require_customer(current_user["sub"])
    
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task.posted_by != current_user["sub"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only cancel your own tasks"
        )

    if task.status not in ("open", "assigned"):
        raise HTTPException(
            status_code=400,
            detail="This task can no longer be cancelled"
        )

    was_assigned = task.status == "assigned"
    assigned_tasker = task.assigned_to
    task.status = "cancelled"
    task.cancel_reason = (reason or "").strip() or "Cancelled by customer"
    task.cancelled_by = current_user["sub"]
    task.on_the_way_at = None
    task.updated_at = datetime.utcnow()

    # Cancelling an already-committed (assigned) job is a reliability hit and
    # the assigned tasker should be told.
    if was_assigned and assigned_tasker:
        from database import User as _User
        from routes._helpers import notify_user
        customer = session.get(_User, current_user["sub"])
        if customer:
            customer.cancel_count = int(customer.cancel_count or 0) + 1
        notify_user(session, assigned_tasker, "Job cancelled",
                    f"The customer cancelled '{task.title}'.", emoji="⚠️")

    session.commit()
    return {"message": "Task cancelled successfully"}


# ============================================================================
# Booking Endpoints
# ============================================================================

@router.post("/bookings", status_code=status.HTTP_201_CREATED)
def create_booking(
    booking_data: CustomerBookingCreate,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Customer books a service from a tasker"""
    _require_customer(current_user["sub"])
    
    customer = _get_customer_session(session, current_user["sub"])
    
    # Verify tasker exists and is actually a tasker
    tasker = session.get(User, booking_data.tasker_id)
    if not tasker or not is_tasker(tasker.id):
        raise HTTPException(status_code=404, detail="Tasker not found")
    
    # Get service details
    from database import Service
    service = session.get(Service, booking_data.service_id)
    if not service or service.tasker_id != booking_data.tasker_id:
        raise HTTPException(status_code=404, detail="Service not found")
    
    if not service.is_active:
        raise HTTPException(status_code=400, detail="Service is not available")
    
    new_booking = Booking(
        id=generate_booking_id(session),
        booking_id=generate_booking_id(session),
        customer_id=customer.id,
        tasker_id=tasker.id,
        service_id=service.id,
        service={
            "name": service.name,
            "emoji": service.emoji,
            "price": service.price,
        },
        scheduled_at=booking_data.scheduled_at,
        address=booking_data.address,
        notes=booking_data.notes,
        status="confirmed",
        total_amount=service.price,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    
    session.add(new_booking)
    session.commit()
    session.refresh(new_booking)
    
    return {
        "message": "Booking created successfully",
        "booking": {
            "id": new_booking.id,
            "booking_id": new_booking.booking_id,
            "service": new_booking.service,
            "tasker": user_to_public(tasker, include_wallet=False),
            "scheduled_at": new_booking.scheduled_at,
            "address": new_booking.address,
            "status": new_booking.status,
            "total_amount": new_booking.total_amount,
            "created_at": new_booking.created_at,
        },
    }


@router.get("/bookings")
def get_my_bookings(
    status_filter: str | None = Query(default=None, alias="status"),
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Get all bookings made by this customer"""
    _require_customer(current_user["sub"])
    
    # Use joinedload to avoid N+1 queries on tasker
    query = (
        select(Booking)
        .options(joinedload(Booking.tasker))
        .where(Booking.customer_id == current_user["sub"])
    )
    
    if status_filter:
        query = query.where(Booking.status == status_filter)
    
    bookings = session.execute(
        query.order_by(Booking.created_at.desc())
    ).unique().scalars().all()
    
    result = []
    for b in bookings:
        result.append({
            "id": b.id,
            "booking_id": b.booking_id,
            "service": b.service,
            "tasker": user_to_public(b.tasker, include_wallet=False) if b.tasker else None,
            "scheduled_at": b.scheduled_at,
            "address": b.address,
            "status": b.status,
            "total_amount": b.total_amount,
            "created_at": b.created_at,
        })
    
    return result


@router.get("/bookings/{booking_id}")
def get_booking(
    booking_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Get a specific booking"""
    _require_customer(current_user["sub"])
    
    booking = session.get(Booking, booking_id)
    if not booking or booking.customer_id != current_user["sub"]:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    tasker = session.get(User, booking.tasker_id)
    
    return {
        "id": booking.id,
        "booking_id": booking.booking_id,
        "service": booking.service,
        "tasker": user_to_public(tasker, include_wallet=False) if tasker else None,
        "scheduled_at": booking.scheduled_at,
        "address": booking.address,
        "notes": booking.notes,
        "status": booking.status,
        "total_amount": booking.total_amount,
        "created_at": booking.created_at,
    }


@router.patch("/bookings/{booking_id}/cancel")
def cancel_booking(
    booking_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Cancel a booking (only by the customer who made it)"""
    _require_customer(current_user["sub"])
    
    booking = session.get(Booking, booking_id)
    if not booking or booking.customer_id != current_user["sub"]:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    if booking.status != "confirmed":
        raise HTTPException(
            status_code=400,
            detail="Can only cancel confirmed bookings"
        )
    
    booking.status = "cancelled"
    booking.updated_at = datetime.utcnow()
    session.commit()
    
    return {"message": "Booking cancelled successfully"}


# ============================================================================
# Profile Endpoints
# ============================================================================

@router.get("/profile")
def get_profile(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Get customer profile"""
    _require_customer(current_user["sub"])
    customer = _get_customer_session(session, current_user["sub"])
    return user_to_public(customer)


# Helper to check if tasker (needed for booking validation)
def is_tasker(user_id: str) -> bool:
    """Check if user ID belongs to tasker"""
    return user_id.startswith("TSKR_")
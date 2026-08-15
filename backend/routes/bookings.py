from datetime import datetime
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import Session

from database import Booking, Notification, Service, Transaction, User, get_db_session
from routes._helpers import new_booking_ref, safe_user
from utils.auth import get_current_user

router = APIRouter()


class BookingCreate(BaseModel):
    service_id: str
    scheduled_at: datetime
    address: str
    notes: str | None = None
    # When true the total is debited from the customer's wallet at booking
    # time (and refunded automatically on cancellation).
    pay_with_wallet: bool = False


class BookingReschedule(BaseModel):
    scheduled_at: datetime


def _service_snapshot(service: Service, service_id: str) -> dict:
    if service is None:
        return {
            "id": service_id,
            "name": f"Service #{service_id}",
            "emoji": "🧰",
            "category": "service",
            "description": "Booked service",
            "price": 499,
            "original_price": 499,
            "rating": 0,
            "review_count": 0,
            "includes": [],
        }

    return {
        "id": service.id,
        "name": service.name,
        "emoji": service.emoji,
        "icon_asset": service.icon_asset,
        "category": service.category,
        "description": service.description,
        "price": float(service.price),
        "original_price": float(service.original_price),
        "rating": float(service.rating or 0),
        "review_count": int(service.review_count or 0),
        "is_hot": bool(service.is_hot),
        "is_new": bool(service.is_new),
        "includes": service.includes or [],
    }


def _booking_to_dict(record: Booking, customer: dict | None = None) -> dict:
    return {
        "id": record.id,
        "booking_id": record.booking_id,
        "customer_id": record.customer_id,
        "service_id": record.service_id,
        "service": record.service,
        "scheduled_at": record.scheduled_at,
        "address": record.address,
        "notes": record.notes,
        "status": record.status,
        "total_amount": float(record.total_amount),
        "paid_with_wallet": bool(record.paid_with_wallet),
        "created_at": record.created_at,
        "updated_at": record.updated_at,
        "customer": customer,
    }


def _notify(
    session: Session,
    user_id: str,
    title: str,
    body: str,
    emoji: str,
    related_id: str | None = None,
) -> None:
    """Insert an in-app notification row (committed with the caller's commit)."""
    session.add(
        Notification(
            id=str(uuid.uuid4()),
            user_id=user_id,
            title=title,
            body=body,
            emoji=emoji,
            type="booking",
            related_id=related_id,
            is_read=False,
            created_at=datetime.utcnow(),
        )
    )


@router.post("/", status_code=status.HTTP_201_CREATED)
def create_booking(
    booking: BookingCreate,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    if not booking.address.strip():
        raise HTTPException(status_code=400, detail="Address is required")

    service = session.get(Service, str(booking.service_id))
    snapshot = _service_snapshot(service, booking.service_id)
    total = float(snapshot.get("price", 499))

    paid_with_wallet = False
    if booking.pay_with_wallet:
        user = session.get(User, current_user["sub"])
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        balance = float(user.wallet_balance or 0.0)
        if balance < total:
            raise HTTPException(
                status_code=400,
                detail=f"Insufficient wallet balance (₹{balance:.0f} available, ₹{total:.0f} needed)",
            )
        user.wallet_balance = round(balance - total, 2)
        user.updated_at = datetime.utcnow()
        paid_with_wallet = True

    now = datetime.utcnow()
    record = Booking(
        id=str(uuid.uuid4()),
        booking_id=new_booking_ref(),
        customer_id=current_user["sub"],
        service_id=str(booking.service_id),
        service=snapshot,
        scheduled_at=booking.scheduled_at,
        address=booking.address.strip(),
        notes=(booking.notes or "").strip(),
        status="confirmed",
        total_amount=total,
        paid_with_wallet=paid_with_wallet,
        created_at=now,
        updated_at=now,
    )
    session.add(record)

    if paid_with_wallet:
        session.add(
            Transaction(
                id=str(uuid.uuid4()),
                user_id=current_user["sub"],
                type="booking_payment",
                amount=-total,
                description=f"Paid for {snapshot['name']} ({record.booking_id})",
                created_at=now,
            )
        )

    when = booking.scheduled_at.strftime("%d %b, %I:%M %p")
    _notify(
        session,
        current_user["sub"],
        "Booking Confirmed",
        f"{snapshot['name']} is booked for {when}."
        + (f" ₹{total:.0f} paid from wallet." if paid_with_wallet else ""),
        "🎉",
        related_id=record.id,
    )

    session.commit()
    session.refresh(record)

    return _booking_to_dict(record, safe_user(session, current_user["sub"]))


@router.post("/{booking_id}/cancel")
def cancel_booking(
    booking_id: str,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Customer cancels their own booking (only while pending/confirmed).

    Wallet-paid bookings are refunded in full to the wallet.
    """
    record = session.get(Booking, booking_id)
    if not record or record.customer_id != current_user["sub"]:
        raise HTTPException(status_code=404, detail="Booking not found")

    if record.status not in ("pending", "confirmed"):
        raise HTTPException(
            status_code=400,
            detail=f"A {record.status} booking cannot be cancelled",
        )

    refunded = 0.0
    if record.paid_with_wallet:
        user = session.get(User, current_user["sub"])
        if user:
            refunded = float(record.total_amount)
            user.wallet_balance = round(
                float(user.wallet_balance or 0.0) + refunded, 2
            )
            user.updated_at = datetime.utcnow()
            session.add(
                Transaction(
                    id=str(uuid.uuid4()),
                    user_id=current_user["sub"],
                    type="refund",
                    amount=refunded,
                    description=f"Refund for cancelled {record.booking_id}",
                    created_at=datetime.utcnow(),
                )
            )

    record.status = "cancelled"
    record.updated_at = datetime.utcnow()

    service_name = (record.service or {}).get("name", "Your booking")
    _notify(
        session,
        current_user["sub"],
        "Booking Cancelled",
        f"{service_name} ({record.booking_id}) was cancelled."
        + (f" ₹{refunded:.0f} refunded to your wallet." if refunded else ""),
        "❌",
        related_id=record.id,
    )

    session.commit()
    session.refresh(record)

    return {
        "id": record.id,
        "booking_id": record.booking_id,
        "status": record.status,
        "refunded": refunded,
        "message": "Booking cancelled"
        + (f", ₹{refunded:.0f} refunded to wallet" if refunded else ""),
    }


@router.patch("/{booking_id}/reschedule")
def reschedule_booking(
    booking_id: str,
    data: BookingReschedule,
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    """Customer moves an upcoming booking to a new date/time."""
    record = session.get(Booking, booking_id)
    if not record or record.customer_id != current_user["sub"]:
        raise HTTPException(status_code=404, detail="Booking not found")

    if record.status not in ("pending", "confirmed"):
        raise HTTPException(
            status_code=400,
            detail=f"A {record.status} booking cannot be rescheduled",
        )

    if data.scheduled_at <= datetime.utcnow():
        raise HTTPException(
            status_code=400, detail="New time must be in the future"
        )

    record.scheduled_at = data.scheduled_at
    record.updated_at = datetime.utcnow()

    service_name = (record.service or {}).get("name", "Your booking")
    when = data.scheduled_at.strftime("%d %b, %I:%M %p")
    _notify(
        session,
        current_user["sub"],
        "Booking Rescheduled",
        f"{service_name} ({record.booking_id}) moved to {when}.",
        "🗓️",
        related_id=record.id,
    )

    session.commit()
    session.refresh(record)

    return _booking_to_dict(record, safe_user(session, current_user["sub"]))


@router.get("/")
def get_bookings(
    current_user: dict = Depends(get_current_user),
    session: Session = Depends(get_db_session),
):
    items = session.execute(
        select(Booking)
        .where(Booking.customer_id == current_user["sub"])
        .order_by(Booking.created_at.desc())
    ).scalars().all()

    customer = safe_user(session, current_user["sub"])
    return [_booking_to_dict(item, customer) for item in items]

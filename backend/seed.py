#!/usr/bin/env python3
"""Seed relational PostgreSQL tables with demo TaskTeddy data.

Aligned with current database.py schema:
- User: id (CUST_/TSKR_ prefix), user_type field
- Service: tasker_id required
- Booking: customer_id + tasker_id
- Conversation: participants as JSON dict
- Message: sender_type required
"""

from __future__ import annotations

from datetime import datetime, timedelta

from data.service_catalog import DEFAULT_SERVICES
from database import (
    Application,
    Booking,
    Conversation,
    Message,
    Notification,
    Review,
    Service,
    SessionLocal,
    Task,
    Transaction,
    User,
    Withdrawal,
    generate_service_id,
    generate_task_id,
    generate_user_id,
    init_db,
)
from routes._helpers import new_booking_ref


def _upsert_by_id(session, model, payload: dict):
    """Insert or update a record by ID."""
    existing = session.get(model, payload["id"])
    if existing:
        for key, value in payload.items():
            setattr(existing, key, value)
    else:
        session.add(model(**payload))


def seed_users(session) -> dict[str, User]:
    """Seed demo users with proper ID prefixes."""
    now = datetime.utcnow()

    # Use proper ID generation functions
    harry_id = generate_user_id("customer")
    rajesh_id = generate_user_id("tasker")
    priya_id = generate_user_id("tasker")

    fixtures = [
        {
            "id": harry_id,
            "user_type": "customer",
            "name": "Harry Malhotra",
            "email": "harry@example.com",
            "password": None,  # OTP-based auth, no password
            "phone": "+919876543210",
            "title": "Mr",
            "gender": "male",
            "location": "Ludhiana, Punjab",
            "bio": "Frequent TaskTeddy user",
            "rating": 4.8,
            "total_reviews": 12,
            "coins": 150,
            "wallet_balance": 500.0,
            "is_online": False,
            "email_verified_at": now,
            "phone_verified_at": now,
            "last_login_at": now,
            "created_at": now,
            "updated_at": now,
        },
        {
            "id": rajesh_id,
            "user_type": "tasker",
            "name": "Rajesh Kumar",
            "email": "rajesh@example.com",
            "password": None,
            "phone": "+919812345678",
            "title": "Mr",
            "gender": "male",
            "location": "Ludhiana, Punjab",
            "bio": "Professional cleaner and handyman with 5+ years experience",
            "rating": 4.9,
            "total_reviews": 87,
            "coins": 340,
            "wallet_balance": 12840.0,
            "is_online": True,
            "email_verified_at": now,
            "phone_verified_at": now,
            "last_login_at": now,
            "created_at": now,
            "updated_at": now,
        },
        {
            "id": priya_id,
            "user_type": "tasker",
            "name": "Priya Sharma",
            "email": "priya@example.com",
            "password": None,
            "phone": "+919801234567",
            "title": "Ms",
            "gender": "female",
            "location": "Ludhiana, Punjab",
            "bio": "Home cook and tutor",
            "rating": 4.7,
            "total_reviews": 45,
            "coins": 210,
            "wallet_balance": 6500.0,
            "is_online": True,
            "email_verified_at": now,
            "phone_verified_at": now,
            "last_login_at": now,
            "created_at": now,
            "updated_at": now,
        },
    ]

    users_by_email: dict[str, User] = {}

    for fixture in fixtures:
        # Check by phone (more reliable for OTP users)
        existing = session.query(User).filter(User.phone == fixture["phone"]).one_or_none()
        if existing:
            users_by_email[fixture["email"]] = existing
            continue
        user = User(**fixture)
        session.add(user)
        users_by_email[fixture["email"]] = user

    session.commit()

    # Reload to get proper objects
    for email in ["harry@example.com", "rajesh@example.com", "priya@example.com"]:
        users_by_email[email] = session.query(User).filter(User.email == email).one()

    return users_by_email


def seed_services(session, tasker_id: str):
    """Seed default services linked to a tasker."""
    now = datetime.utcnow()

    for service in DEFAULT_SERVICES:
        service_id = generate_service_id(tasker_id)
        existing = session.query(Service).filter(Service.id == service_id).first()

        # Check if service with same name exists
        if not existing:
            existing = session.query(Service).filter(Service.name == service["name"]).first()

        payload = {
            "id": service_id if not existing else existing.id,
            "name": service["name"],
            "emoji": service.get("emoji"),
            "icon_asset": service.get("icon_asset"),
            "category": service["category"],
            "description": service["description"],
            "price": float(service["price"]),
            "original_price": float(service["original_price"]),
            "rating": float(service.get("rating", 5.0)),
            "review_count": int(service.get("review_count", 0)),
            "is_hot": bool(service.get("is_hot", False)),
            "is_new": bool(service.get("is_new", False)),
            "includes": list(service.get("includes", [])),
            "tasker_id": tasker_id,
            "is_active": True,
            "created_at": now,
        }

        if existing:
            for key, value in payload.items():
                setattr(existing, key, value)
        else:
            session.add(Service(**payload))

    session.commit()


def seed_tasks_and_related(session, users: dict[str, User]):
    """Seed tasks, applications, bookings, conversations, messages, etc."""
    now = datetime.utcnow()

    harry = users["harry@example.com"]
    rajesh = users["rajesh@example.com"]
    priya = users["priya@example.com"]

    # Generate proper IDs
    task1_id = generate_task_id(session, customer_id=harry.id)
    task2_id = generate_task_id(session, customer_id=harry.id)

    # Task 1 - Open
    task1 = {
        "id": task1_id,
        "title": "Deep clean my 2BHK before guests arrive",
        "description": "Need full home cleaning for living room, kitchen and 2 bathrooms.",
        "category": "cleaning",
        "budget": 1800.0,
        "location": "Model Town, Ludhiana",
        "deadline": now + timedelta(days=2),
        "images": [],
        "status": "open",
        "posted_by": harry.id,
        "assigned_to": None,
        "applicants_count": 1,
        "completion_otp": None,
        "created_at": now - timedelta(days=2),
        "updated_at": now - timedelta(days=1),
    }

    # Task 2 - Assigned to Priya
    task2 = {
        "id": task2_id,
        "title": "Weekly tiffin meal prep support",
        "description": "Need a cook for chopping and basic meal prep.",
        "category": "cooking",
        "budget": 2500.0,
        "location": "Sarabha Nagar, Ludhiana",
        "deadline": now + timedelta(days=3),
        "images": [],
        "status": "assigned",
        "posted_by": harry.id,
        "assigned_to": priya.id,
        "applicants_count": 1,
        "completion_otp": "4519",
        "created_at": now - timedelta(days=4),
        "updated_at": now - timedelta(days=1),
    }

    _upsert_by_id(session, Task, task1)
    _upsert_by_id(session, Task, task2)
    session.commit()

    # Application from Rajesh to Task 1
    app = {
        "id": f"app-{rajesh.id[:6]}-{task1_id[:6]}-001",
        "task_id": task1_id,
        "applicant_id": rajesh.id,
        "bid_amount": 1700.0,
        "cover_letter": "I can do this task tomorrow morning with supplies.",
        "status": "pending",
        "created_at": now - timedelta(days=1),
        "updated_at": now - timedelta(days=1),
    }
    _upsert_by_id(session, Application, app)

    # Get a service for booking
    bathroom_service = session.query(Service).filter(Service.name == "Bathroom Cleaning").first()
    if bathroom_service:
        booking = {
            "id": f"book-{harry.id[:8]}-001",
            "booking_id": new_booking_ref(),
            "customer_id": harry.id,
            "tasker_id": bathroom_service.tasker_id,
            "service_id": bathroom_service.id,
            "service": {
                "id": bathroom_service.id,
                "name": bathroom_service.name,
                "price": bathroom_service.price,
                "category": bathroom_service.category,
                "emoji": bathroom_service.emoji,
            },
            "scheduled_at": now + timedelta(days=1),
            "address": "Model Town, Ludhiana",
            "notes": "Call before arrival",
            "status": "confirmed",
            "total_amount": bathroom_service.price,
            "created_at": now,
            "updated_at": now,
        }
        _upsert_by_id(session, Booking, booking)

    # Conversation between Harry and Rajesh about Task 1
    conv = {
        "id": f"conv-{harry.id[:6]}-{rajesh.id[:6]}-001",
        "participants": {"customer_id": harry.id, "tasker_id": rajesh.id},
        "task_id": task1_id,
        "last_message": "Sure, I can come by 10am.",
        "last_message_at": now - timedelta(hours=2),
        "created_at": now - timedelta(days=1),
    }
    _upsert_by_id(session, Conversation, conv)

    # Message from Rajesh
    msg1 = {
        "id": f"msg-{rajesh.id[:6]}-001",
        "conversation_id": conv["id"],
        "sender_id": rajesh.id,
        "sender_type": "tasker",
        "text": "Sure, I can come by 10am.",
        "image_url": None,
        "is_read": False,
        "created_at": now - timedelta(hours=2),
    }
    _upsert_by_id(session, Message, msg1)

    # Notification for Harry
    notif = {
        "id": f"notif-{harry.id[:6]}-001",
        "user_id": harry.id,
        "sender_type": "tasker",
        "title": "New application",
        "body": "Rajesh applied to your task.",
        "emoji": "📩",
        "type": "application",
        "related_id": task1_id,
        "is_read": False,
        "created_at": now - timedelta(hours=1),
    }
    _upsert_by_id(session, Notification, notif)

    # Review from Harry for Priya
    review = {
        "id": f"review-{harry.id[:6]}-{priya.id[:6]}-001",
        "task_id": task2_id,
        "reviewer_id": harry.id,
        "reviewed_user_id": priya.id,
        "rating": 4.8,
        "comment": "Great tutoring support. Very patient and clear explanations.",
        "created_at": now - timedelta(hours=4),
    }
    _upsert_by_id(session, Review, review)

    # Transaction for Rajesh
    txn = {
        "id": f"txn-{rajesh.id[:6]}-001",
        "user_id": rajesh.id,
        "type": "earning",
        "amount": 1200.0,
        "description": "Task payout",
        "task_id": task1_id,
        "related_user_id": harry.id,
        "created_at": now - timedelta(hours=3),
    }
    _upsert_by_id(session, Transaction, txn)

    # Withdrawal request from Rajesh
    wd = {
        "id": f"wd-{rajesh.id[:6]}-001",
        "user_id": rajesh.id,
        "amount": 500.0,
        "method": "upi",
        "details": {"upi_id": "rajesh@upi"},
        "status": "pending",
        "created_at": now - timedelta(hours=2),
    }
    _upsert_by_id(session, Withdrawal, wd)

    session.commit()


def main():
    """Main seeding function."""
    print("Initializing database and seeding...")

    # Create tables
    init_db()

    with SessionLocal() as session:
        # Seed users first
        users = seed_users(session)

        # Get tasker ID for services
        rajesh = users["rajesh@example.com"]

        # Seed services linked to tasker
        seed_services(session, rajesh.id)

        # Seed tasks and related data
        seed_tasks_and_related(session, users)

    print("Done. Demo data seeded successfully.")
    print("\n📱 Login with phone + OTP:")
    print("- Customer: +919876543210")
    print("- Tasker 1: +919812345678")
    print("- Tasker 2: +919801234567")
    print("\n🔑 OTP (dev mode): Check server logs or use 123456 for testing")


if __name__ == "__main__":
    main()
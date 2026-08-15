"""Relational PostgreSQL layer using SQLAlchemy.

This replaces document-style route access with explicit relational models.
Supports multi-tenant architecture: Customers (CUST_) and Taskers (TSKR_).
"""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Literal

from sqlalchemy import (
    JSON,
    Boolean,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    create_engine,
    text,
)
from sqlalchemy.orm import Session, declarative_base, relationship, sessionmaker

from config import get_settings

settings = get_settings()


# ============================================================================
# ID Generation Helpers - Best Practices
# - Users: UUID (distributed, no DB dependency)
# - Tasks: Sequential via DB (human-readable, business value)
# - Bookings: Sequential via DB (order numbers)
# - Services: UUID (unique, no business meaning)
# ============================================================================


def _get_next_sequence(session, sequence_name: str) -> int:
    """Get next value from database sequence."""
    from sqlalchemy import text
    
    # Validate sequence name to prevent SQL injection
    allowed_sequences = {
        "tt_tasks_id_seq": "tt_tasks",
        "tt_bookings_booking_id_seq": "tt_bookings",
    }
    if sequence_name not in allowed_sequences:
        raise ValueError(f"Invalid sequence name: {sequence_name}")
    
    try:
        # Use parameterized query with validated sequence name
        result = session.execute(
            text(f"SELECT nextval(:seq_name)"),
            {"seq_name": sequence_name}
        ).scalar()
        return int(result)
    except Exception:
        # Fallback: get max + 1
        table_name = allowed_sequences[sequence_name]
        result = session.execute(
            text(f"SELECT COALESCE(MAX(id), 0) + 1 FROM {table_name}")
        ).scalar()
        return int(result) if result else 1


def generate_user_id(role: Literal["customer", "tasker"]) -> str:
    """Generate user ID with role prefix: CUST_<uuid> or TSKR_<uuid>"""
    prefix = "CUST" if role == "customer" else "TSKR"
    return f"{prefix}_{uuid.uuid4().hex[:24]}"


def generate_task_id(session=None, customer_id: str = None) -> str:
    """Generate sequential task ID: TASK_000001, TASK_000002, ..."""
    if session:
        seq = _get_next_sequence(session, "tt_tasks_id_seq")
    else:
        # Fallback: use in-memory counter
        global _task_counter
        _task_counter += 1
        seq = _task_counter
    return f"TASK_{seq:06d}"


def generate_service_id(tasker_id: str = None) -> str:
    """Generate service ID: SERV_<uuid> (unique, no business meaning)"""
    return f"SERV_{uuid.uuid4().hex[:16]}"


def generate_booking_id(session=None, customer_id: str = None) -> str:
    """Generate sequential booking ID: BOOK_000001, BOOK_000002, ..."""
    if session:
        seq = _get_next_sequence(session, "tt_bookings_booking_id_seq")
    else:
        # Fallback: use in-memory counter
        global _booking_counter
        _booking_counter += 1
        seq = _booking_counter
    return f"BOOK_{seq:06d}"


def generate_application_id(tasker_id: str = None, task_id: str = None) -> str:
    """Generate application ID: APP_<uuid> (unique)"""
    return f"APP_{uuid.uuid4().hex[:12]}"


def generate_transaction_id() -> str:
    """Generate transaction ID: TXN_<timestamp>_<seq>"""
    import time
    ts = int(time.time() * 1000)
    return f"TXN_{ts}"


# In-memory fallback counters
_task_counter = 0
_booking_counter = 0


def get_user_role(user_id: str) -> Literal["customer", "tasker"] | None:
    """Extract role from user ID prefix"""
    if user_id.startswith("CUST_"):
        return "customer"
    elif user_id.startswith("TSKR_"):
        return "tasker"
    return None


def is_customer(user_id: str) -> bool:
    """Check if user ID belongs to customer"""
    return user_id.startswith("CUST_")


def is_tasker(user_id: str) -> bool:
    """Check if user ID belongs to tasker"""
    return user_id.startswith("TSKR_")

def _sqlalchemy_url(raw_url: str) -> str:
    if raw_url.startswith("postgresql+psycopg://"):
        return raw_url
    if raw_url.startswith("postgresql://"):
        return raw_url.replace("postgresql://", "postgresql+psycopg://", 1)
    return raw_url


DATABASE_URL = settings["DATABASE_URL"]
SQLALCHEMY_DATABASE_URL = _sqlalchemy_url(DATABASE_URL)

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
    pool_recycle=3600,
    pool_timeout=30,
    future=True,
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, expire_on_commit=False)
Base = declarative_base()


class User(Base):
    __tablename__ = "tt_users"
    __table_args__ = (
        Index("idx_users_type_created", "user_type", "created_at"),
    )

    # ID with role prefix: CUST_<uuid> or TSKR_<uuid>
    id = Column(String(64), primary_key=True)
    # Role for filtering: customer or tasker (separate from ID prefix for queries)
    user_type = Column(String(20), nullable=False, default="customer", index=True)
    name = Column(String(100), nullable=True)
    email = Column(String(255), nullable=True, unique=True, index=True)
    pending_email = Column(String(255), nullable=True, index=True)
    pending_email_token = Column(String(64), nullable=True)
    pending_email_expires_at = Column(DateTime, nullable=True)
    password = Column(String(255), nullable=True)
    phone = Column(String(20), nullable=True, unique=True, index=True)
    avatar_url = Column(String(500), nullable=True)
    location = Column(String(500), nullable=True)
    # Geolocation coordinates
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    last_location_at = Column(DateTime, nullable=True)
    bio = Column(Text, nullable=True)
    title = Column(String(10), nullable=True)
    gender = Column(String(16), nullable=True)
    rating = Column(Float, nullable=False, default=0.0)
    total_reviews = Column(Integer, nullable=False, default=0)
    coins = Column(Integer, nullable=False, default=0)
    wallet_balance = Column(Float, nullable=False, default=0.0)
    is_online = Column(Boolean, nullable=False, default=False)
    # Admin moderation: suspended users cannot log in.
    is_suspended = Column(Boolean, nullable=False, default=False)
    # Tasker KYC: set by an admin after reviewing the tasker's documents.
    is_verified = Column(Boolean, nullable=False, default=False)
    # Reliability signal: times this user cancelled/backed out of a committed job.
    cancel_count = Column(Integer, nullable=False, default=0)
    # Lifetime completed jobs — drives the tasker reputation level.
    completed_tasks = Column(Integer, nullable=False, default=0)
    # KYC identity numbers entered by an admin during verification. Sensitive
    # PII — only the last 4 digits are ever returned to the tasker.
    aadhaar_number = Column(String(32), nullable=True)
    pan_number = Column(String(32), nullable=True)
    email_verified_at = Column(DateTime, nullable=True)
    phone_verified_at = Column(DateTime, nullable=True)
    last_login_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)


class PendingLogin(Base):
    __tablename__ = "tt_pending_logins"

    token = Column(String(64), primary_key=True)
    # User who will be created/verified (CUST_* or TSKR_*)
    user_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    phone = Column(String(20), nullable=True)
    expires_at = Column(DateTime, nullable=False, index=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class Service(Base):
    __tablename__ = "tt_services"
    __table_args__ = (
        Index("idx_services_tasker_active", "tasker_id", "is_active"),
        Index("idx_services_category_rating", "category", "rating"),
    )

    # ID format: SERV_<tasker_short>_<uuid>
    id = Column(String(64), primary_key=True)
    name = Column(String(200), nullable=False)
    emoji = Column(String(16), nullable=True)
    icon_asset = Column(String(500), nullable=True)
    category = Column(String(50), nullable=False)
    description = Column(Text, nullable=False)
    price = Column(Float, nullable=False)
    original_price = Column(Float, nullable=False)
    rating = Column(Float, nullable=False, default=5.0)
    review_count = Column(Integer, nullable=False, default=0)
    is_hot = Column(Boolean, nullable=False, default=False)
    is_new = Column(Boolean, nullable=False, default=False)
    includes = Column(JSON, nullable=True)
    # Tasker who owns this service (must be TSKR_*). Null for platform-catalog
    # services created by admins rather than an individual tasker.
    tasker_id = Column(String(64), ForeignKey("tt_users.id"), nullable=True, index=True)
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class Task(Base):
    __tablename__ = "tt_tasks"
    __table_args__ = (
        Index("idx_tasks_status_created", "status", "created_at"),
        Index("idx_tasks_category_status", "category", "status"),
    )

    # ID: Sequential (TASK_000001)
    id = Column(String(64), primary_key=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    category = Column(String(50), nullable=False)
    budget = Column(Float, nullable=False)
    location = Column(String(500), nullable=False)
    # Geolocation coordinates for distance-based filtering
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    deadline = Column(DateTime, nullable=False)
    images = Column(JSON, nullable=True)
    status = Column(String(20), nullable=False, default="open", index=True)
    # Customer who posted this task (must be CUST_*)
    posted_by = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    # Tasker assigned to this task (must be TSKR_*)
    assigned_to = Column(String(64), ForeignKey("tt_users.id"), nullable=True, index=True)
    applicants_count = Column(Integer, nullable=False, default=0)
    completion_otp = Column(String(16), nullable=True)
    # Set when the assigned tasker taps "On my way" — powers the live ETA/track UI.
    on_the_way_at = Column(DateTime, nullable=True)
    # Cancellation audit: who cancelled and why (customer or tasker back-out).
    cancel_reason = Column(Text, nullable=True)
    cancelled_by = Column(String(64), nullable=True)
    # Moderation: reason shown to the customer when a task is rejected in review.
    review_reason = Column(Text, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)


class Application(Base):
    __tablename__ = "tt_applications"
    __table_args__ = (
        Index("idx_applications_task_status", "task_id", "status"),
        Index("idx_applications_applicant_status", "applicant_id", "status"),
    )

    # ID format: APP_<tasker_short>_<task_short>_<uuid>
    id = Column(String(64), primary_key=True)
    task_id = Column(String(64), ForeignKey("tt_tasks.id"), nullable=False, index=True)
    # Tasker who applied (must be TSKR_*)
    applicant_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    bid_amount = Column(Float, nullable=False)
    cover_letter = Column(Text, nullable=False)
    status = Column(String(20), nullable=False, default="pending", index=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships for eager loading (defined after columns)
    task = relationship("Task")


class Booking(Base):
    __tablename__ = "tt_bookings"
    __table_args__ = (
        Index("idx_bookings_customer_status", "customer_id", "status"),
        Index("idx_bookings_tasker_status", "tasker_id", "status"),
        Index("idx_bookings_scheduled", "scheduled_at"),
    )

    # ID: UUID (internal), booking_id: Sequential (external)
    id = Column(String(64), primary_key=True)
    booking_id = Column(String(32), nullable=False, unique=True, index=True)  # BOOK_000001
    # Customer who booked (must be CUST_*)
    customer_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    # Tasker who will provide service (must be TSKR_*). Null until one is
    # assigned — a customer books first, the tasker is matched afterwards.
    tasker_id = Column(String(64), ForeignKey("tt_users.id"), nullable=True, index=True)
    service_id = Column(String(64), ForeignKey("tt_services.id"), nullable=False, index=True)
    service = Column(JSON, nullable=True)
    scheduled_at = Column(DateTime, nullable=False)
    address = Column(Text, nullable=False)
    notes = Column(Text, nullable=True)
    status = Column(String(20), nullable=False, default="confirmed", index=True)
    total_amount = Column(Float, nullable=False)
    # True when the customer paid from their TaskTeddy wallet at booking time
    # (refunded automatically on cancellation).
    paid_with_wallet = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships for eager loading (defined after columns)
    tasker = relationship("User", foreign_keys=[tasker_id])


class Conversation(Base):
    __tablename__ = "tt_conversations"
    __table_args__ = (
        Index("idx_conversations_task_updated", "task_id", "last_message_at"),
    )

    id = Column(String(64), primary_key=True)
    # Store as JSON: {"customer_id": "CUST_...", "tasker_id": "TSKR_..."}
    participants = Column(JSON, nullable=False)
    task_id = Column(String(64), ForeignKey("tt_tasks.id"), nullable=True, index=True)
    last_message = Column(Text, nullable=True)
    last_message_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class Message(Base):
    __tablename__ = "tt_messages"
    __table_args__ = (
        Index("idx_messages_conversation_created", "conversation_id", "created_at"),
    )

    id = Column(String(64), primary_key=True)
    conversation_id = Column(String(64), ForeignKey("tt_conversations.id"), nullable=False, index=True)
    sender_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    # Sender type for quick filtering: customer or tasker
    sender_type = Column(String(20), nullable=False, index=True)
    text = Column(Text, nullable=True)
    image_url = Column(Text, nullable=True)
    is_read = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class Notification(Base):
    __tablename__ = "tt_notifications"
    __table_args__ = (
        Index("idx_notifications_user_read", "user_id", "is_read"),
    )

    id = Column(String(64), primary_key=True)
    # Target user (can be CUST_* or TSKR_*)
    user_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    # Sender type for filtering
    sender_type = Column(String(20), nullable=True)
    title = Column(String(200), nullable=False)
    body = Column(Text, nullable=False)
    emoji = Column(String(16), nullable=True)
    type = Column(String(50), nullable=False)
    related_id = Column(String(64), nullable=True, index=True)
    is_read = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class KycDocument(Base):
    """A KYC document uploaded by a tasker for admin review."""
    __tablename__ = "tt_kyc_documents"
    __table_args__ = (
        Index("idx_kyc_user_type", "user_id", "doc_type", unique=True),
    )

    id = Column(String(64), primary_key=True)
    user_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    doc_type = Column(String(20), nullable=False)  # aadhaar | pan | address | selfie
    file_url = Column(String(500), nullable=False)
    status = Column(String(20), nullable=False, default="pending", index=True)  # pending|approved|rejected
    reason = Column(Text, nullable=True)  # rejection reason
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)


class SupportTicket(Base):
    """A help-centre message from an app user, answered from the admin panel."""
    __tablename__ = "tt_support_tickets"

    id = Column(String(64), primary_key=True)
    user_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    subject = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    status = Column(String(20), nullable=False, default="open", index=True)  # open|resolved
    reply = Column(Text, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)


class AuditLog(Base):
    """Record of every mutating admin action, for accountability."""
    __tablename__ = "tt_audit_logs"

    id = Column(String(64), primary_key=True)
    admin_email = Column(String(255), nullable=False)
    action = Column(String(80), nullable=False, index=True)
    target_type = Column(String(40), nullable=True)
    target_id = Column(String(64), nullable=True, index=True)
    detail = Column(Text, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow, index=True)


class DeviceToken(Base):
    """Push (FCM) device registration token for a user's device."""
    __tablename__ = "tt_device_tokens"
    __table_args__ = (
        Index("idx_device_tokens_user", "user_id"),
    )

    id = Column(String(64), primary_key=True)
    user_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    # The FCM registration token (unique per device install).
    token = Column(String(512), nullable=False, unique=True)
    platform = Column(String(20), nullable=True)  # android | ios | web
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class Review(Base):
    __tablename__ = "tt_reviews"
    __table_args__ = (
        Index("idx_reviews_task_created", "task_id", "created_at"),
        Index("idx_reviews_user_created", "reviewed_user_id", "created_at"),
    )

    id = Column(String(64), primary_key=True)
    task_id = Column(String(64), ForeignKey("tt_tasks.id"), nullable=False, index=True)
    # Reviewer (can be CUST_* or TSKR_*)
    reviewer_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    # User being reviewed (can be CUST_* or TSKR_*)
    reviewed_user_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    rating = Column(Float, nullable=False)
    comment = Column(Text, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class Transaction(Base):
    __tablename__ = "tt_transactions"
    __table_args__ = (
        Index("idx_transactions_user_created", "user_id", "created_at"),
        Index("idx_transactions_task", "task_id"),
    )

    id = Column(String(64), primary_key=True)
    # User involved in transaction (CUST_* or TSKR_*)
    user_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    type = Column(String(50), nullable=False)  # credit, debit, booking_payment, etc.
    amount = Column(Float, nullable=False)
    description = Column(Text, nullable=True)
    task_id = Column(String(64), nullable=True, index=True)
    related_user_id = Column(String(64), nullable=True, index=True)  # Counterparty
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class Withdrawal(Base):
    __tablename__ = "tt_withdrawals"
    __table_args__ = (
        Index("idx_withdrawals_user_status", "user_id", "status"),
    )

    id = Column(String(64), primary_key=True)
    # Tasker requesting withdrawal (must be TSKR_*)
    user_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    amount = Column(Float, nullable=False)
    method = Column(String(50), nullable=False)  # bank_transfer, upi
    details = Column(JSON, nullable=True)
    status = Column(String(20), nullable=False, default="pending", index=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class Setting(Base):
    """Platform-wide key/value configuration editable from the admin panel."""
    __tablename__ = "tt_settings"

    key = Column(String(100), primary_key=True)
    value = Column(Text, nullable=True)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)


class Favorite(Base):
    """A customer's saved tasker or service, shown under "Favorites"."""
    __tablename__ = "tt_favorites"
    __table_args__ = (
        Index("idx_favorites_user_created", "user_id", "created_at"),
        Index("idx_favorites_unique", "user_id", "target_type", "target_id", unique=True),
    )

    id = Column(String(64), primary_key=True)
    # Owner of the favorite (usually CUST_*).
    user_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    target_type = Column(String(20), nullable=False)  # tasker | service
    target_id = Column(String(64), nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class SavedAddress(Base):
    """A reusable delivery/service address in a user's address book."""
    __tablename__ = "tt_addresses"
    __table_args__ = (
        Index("idx_addresses_user", "user_id", "is_default"),
    )

    id = Column(String(64), primary_key=True)
    user_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    label = Column(String(50), nullable=False, default="Home")  # Home | Work | Other
    address = Column(Text, nullable=False)
    landmark = Column(String(200), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    is_default = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)


class TaskerAvailability(Base):
    """A tasker's weekly working hours — one row per weekday."""
    __tablename__ = "tt_tasker_availability"
    __table_args__ = (
        Index("idx_availability_tasker_day", "tasker_id", "day_of_week", unique=True),
    )

    id = Column(String(64), primary_key=True)
    tasker_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    day_of_week = Column(Integer, nullable=False)  # 0=Mon .. 6=Sun
    # Working window expressed as minutes from midnight (e.g. 540 = 09:00).
    start_minute = Column(Integer, nullable=False, default=540)
    end_minute = Column(Integer, nullable=False, default=1080)
    is_available = Column(Boolean, nullable=False, default=True)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)


class UserReport(Base):
    """A safety report filed by one user against another."""
    __tablename__ = "tt_reports"
    __table_args__ = (
        Index("idx_reports_reported", "reported_id", "status"),
        Index("idx_reports_status_created", "status", "created_at"),
    )

    id = Column(String(64), primary_key=True)
    reporter_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    reported_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    # Optional context: the task/booking the report relates to.
    task_id = Column(String(64), nullable=True)
    reason = Column(String(60), nullable=False)  # short category
    detail = Column(Text, nullable=True)
    status = Column(String(20), nullable=False, default="open", index=True)  # open|reviewed|actioned|dismissed
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class UserBlock(Base):
    """A one-way block: `blocker` no longer sees or interacts with `blocked`."""
    __tablename__ = "tt_blocks"
    __table_args__ = (
        Index("idx_blocks_unique", "blocker_id", "blocked_id", unique=True),
    )

    id = Column(String(64), primary_key=True)
    blocker_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    blocked_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


class PortfolioItem(Base):
    """A photo of a tasker's past work, shown on their public profile."""
    __tablename__ = "tt_portfolio"
    __table_args__ = (
        Index("idx_portfolio_tasker_created", "tasker_id", "created_at"),
    )

    id = Column(String(64), primary_key=True)
    tasker_id = Column(String(64), ForeignKey("tt_users.id"), nullable=False, index=True)
    image_url = Column(String(500), nullable=False)
    caption = Column(String(300), nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)


def get_db_session():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


def init_db() -> None:
    """Initialize database: create tables and sequences."""
    Base.metadata.create_all(bind=engine)
    
    # Create sequences for sequential IDs
    with SessionLocal() as session:
        # Task sequence
        session.execute(text("""
            CREATE SEQUENCE IF NOT EXISTS tt_tasks_id_seq
            START WITH 1 INCREMENT BY 1 NO MAXVALUE NO CYCLE
        """))
        
        # Booking sequence
        session.execute(text("""
            CREATE SEQUENCE IF NOT EXISTS tt_bookings_booking_id_seq
            START WITH 1 INCREMENT BY 1 NO MAXVALUE NO CYCLE
        """))
        
        session.commit()


def health_check() -> bool:
    with SessionLocal() as session:
        session.execute(text("SELECT 1"))
    return True

"""Shared pytest fixtures for the TaskTeddy backend.

Tests run against an **isolated Postgres database** (the real schema, including
sequences and JSON columns, so behaviour matches production). The database URL
is redirected to ``<db>_test`` BEFORE the app is imported, the database is
created if missing, and every table is truncated between tests so each one
starts from a clean slate.

Run from inside the backend container (which already has the DB/Redis env):

    docker compose exec backend pip install -r requirements-dev.txt
    docker compose exec backend pytest
"""
import os
import uuid
from datetime import datetime, timedelta

import pytest

# ── Redirect to an isolated test database BEFORE importing the app ───────────
# Force development so send-otp returns the OTP and no real SMS is attempted.
os.environ["ENVIRONMENT"] = "development"

_raw = os.environ.get(
    "DATABASE_URL", "postgresql://postgres:postgres@postgres:5432/taskteddy"
)
_prefix, _, _dbname = _raw.rpartition("/")
if not _dbname.endswith("_test"):
    _dbname = f"{_dbname}_test"
os.environ["DATABASE_URL"] = f"{_prefix}/{_dbname}"


def _ensure_test_db() -> None:
    """Create the test database if it does not exist yet."""
    import psycopg

    admin_url = f"{_prefix}/postgres"
    with psycopg.connect(admin_url, autocommit=True) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (_dbname,))
            if cur.fetchone() is None:
                cur.execute(f'CREATE DATABASE "{_dbname}"')


_ensure_test_db()

# Safe to import the app now — its engine binds to the test database.
import database  # noqa: E402
from database import (  # noqa: E402
    Application,
    Conversation,
    SessionLocal,
    Task,
    User,
    engine,
)
from fastapi.testclient import TestClient  # noqa: E402
from server import app  # noqa: E402
from utils.auth import get_current_user  # noqa: E402
from routes.admin.main import get_current_admin  # noqa: E402

# Rebuild the schema from the current models so it always matches the code
# (create_all alone won't add new columns to a pre-existing test table).
from database import Base  # noqa: E402

Base.metadata.drop_all(bind=engine)
database.init_db()


def _truncate_all() -> None:
    from sqlalchemy import text

    with engine.begin() as conn:
        rows = conn.execute(
            text(
                "SELECT tablename FROM pg_tables "
                "WHERE schemaname='public' AND tablename LIKE 'tt_%'"
            )
        ).fetchall()
        names = [r[0] for r in rows]
        if names:
            conn.execute(
                text(f"TRUNCATE {', '.join(names)} RESTART IDENTITY CASCADE")
            )


@pytest.fixture(autouse=True)
def _clean_db():
    """Wipe every table before and after each test for full isolation."""
    _truncate_all()
    yield
    _truncate_all()


@pytest.fixture
def db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture
def client():
    app.dependency_overrides.clear()
    yield TestClient(app)
    app.dependency_overrides.clear()


@pytest.fixture
def auth_as():
    """Authenticate the TestClient as a given user id + role."""
    def _set(user_id: str, role: str = "customer"):
        app.dependency_overrides[get_current_user] = lambda: {
            "sub": user_id,
            "role": role,
            "user_type": role,
        }

    return _set


@pytest.fixture
def admin_as():
    """Authenticate the TestClient as an admin of a given portal role."""
    def _set(role: str = "superadmin", admin_id: str = "ADMIN_test"):
        app.dependency_overrides[get_current_admin] = lambda: {
            "role": role,
            "admin_id": admin_id,
            "sub": admin_id,
        }

    return _set


# ── Model factories ──────────────────────────────────────────────────────────
@pytest.fixture
def make_user(db):
    def _make(role: str = "customer", promo_balance: float = 0.0,
              wallet_balance: float = 0.0, **kw) -> User:
        prefix = "CUST" if role == "customer" else "TSKR"
        uid = f"{prefix}_{uuid.uuid4().hex[:12]}"
        user = User(
            id=uid,
            user_type=role,
            name=kw.get("name", "Test User"),
            phone=kw.get("phone", f"+9199{uuid.uuid4().int % 100000000:08d}"),
            rating=0.0,
            total_reviews=0,
            coins=0,
            wallet_balance=wallet_balance,
            promo_balance=promo_balance,
            is_online=False,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        return user

    return _make


@pytest.fixture
def make_task(db):
    def _make(poster_id: str, budget: float = 1000.0, status: str = "open",
              assigned_to: str | None = None, promo_discount: float = 0.0,
              otp: str | None = None, **kw) -> Task:
        tid = f"TASK_{uuid.uuid4().hex[:12]}"
        task = Task(
            id=tid,
            title=kw.get("title", "Test Task"),
            description="A test task description.",
            category="cleaning",
            budget=budget,
            location="Test City",
            deadline=datetime.utcnow() + timedelta(days=1),
            status=status,
            posted_by=poster_id,
            assigned_to=assigned_to,
            promo_discount=promo_discount,
            completion_otp=otp,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(task)
        db.commit()
        db.refresh(task)
        return task

    return _make


@pytest.fixture
def make_application(db):
    def _make(task_id: str, applicant_id: str, bid_amount: float = 1000.0,
              status: str = "pending") -> Application:
        aid = f"APP_{uuid.uuid4().hex[:12]}"
        app_row = Application(
            id=aid,
            task_id=task_id,
            applicant_id=applicant_id,
            bid_amount=bid_amount,
            cover_letter="",
            status=status,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(app_row)
        db.commit()
        db.refresh(app_row)
        return app_row

    return _make


@pytest.fixture
def make_conversation(db):
    def _make(participants: list[str], task_id: str | None = None) -> Conversation:
        conv = Conversation(
            id=uuid.uuid4().hex,
            participants=participants,
            task_id=task_id,
            last_message="",
            last_message_at=datetime.utcnow(),
            created_at=datetime.utcnow(),
        )
        db.add(conv)
        db.commit()
        db.refresh(conv)
        return conv

    return _make

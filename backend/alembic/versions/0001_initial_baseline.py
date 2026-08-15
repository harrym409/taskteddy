"""Initial baseline schema

Captures the existing TaskTeddy schema as the migration baseline. It builds the
tables from the SQLAlchemy models (the single source of truth) plus the two
sequences that init_db() used to create. Subsequent schema changes should be
produced with `alembic revision --autogenerate` and will diff cleanly against
this baseline.

For an EXISTING database whose tables were already created by the old
init_db()/create_all path, stamp this revision instead of running it:
    alembic stamp 0001_initial_baseline

Revision ID: 0001_initial_baseline
Revises:
Create Date: 2026-07-13

"""
from typing import Sequence, Union

from alembic import op

# Import the app metadata so the baseline always matches the models.
from database import Base

# revision identifiers, used by Alembic.
revision: str = "0001_initial_baseline"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_SEQUENCES = (
    "tt_tasks_id_seq",
    "tt_bookings_booking_id_seq",
)


def upgrade() -> None:
    bind = op.get_bind()
    Base.metadata.create_all(bind=bind)
    for seq in _SEQUENCES:
        op.execute(
            f"CREATE SEQUENCE IF NOT EXISTS {seq} "
            "START WITH 1 INCREMENT BY 1 NO MAXVALUE NO CYCLE"
        )


def downgrade() -> None:
    for seq in _SEQUENCES:
        op.execute(f"DROP SEQUENCE IF EXISTS {seq}")
    Base.metadata.drop_all(bind=op.get_bind())

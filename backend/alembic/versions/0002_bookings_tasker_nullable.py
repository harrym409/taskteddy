"""Make tt_bookings.tasker_id nullable

A booking is created by the customer before any tasker is assigned, so the
column must allow NULL. The old NOT NULL constraint made every
POST /api/bookings/ fail with an IntegrityError.

Revision ID: 0002_bookings_tasker_nullable
Revises: 0001_initial_baseline
Create Date: 2026-07-14

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0002_bookings_tasker_nullable"
down_revision: Union[str, None] = "0001_initial_baseline"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column(
        "tt_bookings",
        "tasker_id",
        existing_type=sa.String(64),
        nullable=True,
    )


def downgrade() -> None:
    op.alter_column(
        "tt_bookings",
        "tasker_id",
        existing_type=sa.String(64),
        nullable=False,
    )

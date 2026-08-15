"""Make tt_services.tasker_id nullable

Platform-catalog services created by admins have no owning tasker, so the
column must allow NULL (same reasoning as bookings in 0002).

Revision ID: 0004_services_tasker_nullable
Revises: 0003_bookings_paid_with_wallet
Create Date: 2026-07-14

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0004_services_tasker_nullable"
down_revision: Union[str, None] = "0003_bookings_paid_with_wallet"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column(
        "tt_services",
        "tasker_id",
        existing_type=sa.String(64),
        nullable=True,
    )


def downgrade() -> None:
    op.alter_column(
        "tt_services",
        "tasker_id",
        existing_type=sa.String(64),
        nullable=False,
    )

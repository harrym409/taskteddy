"""Add tt_bookings.paid_with_wallet

Tracks bookings paid from the customer's TaskTeddy wallet so cancellation can
refund them automatically.

Revision ID: 0003_bookings_paid_with_wallet
Revises: 0002_bookings_tasker_nullable
Create Date: 2026-07-14

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0003_bookings_paid_with_wallet"
down_revision: Union[str, None] = "0002_bookings_tasker_nullable"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None



def _has_column(table: str, column: str) -> bool:
    from sqlalchemy import inspect as _inspect
    bind = op.get_bind()
    insp = _inspect(bind)
    try:
        return any(c["name"] == column for c in insp.get_columns(table))
    except Exception:
        return False


def _has_table(table: str) -> bool:
    from sqlalchemy import inspect as _inspect
    return _inspect(op.get_bind()).has_table(table)

def upgrade() -> None:
    # The 0001 baseline builds the schema from live models, so on a fresh DB
    # this column may already exist — make the migration idempotent.
    if _has_column("tt_bookings", "paid_with_wallet"):
        return

    op.add_column(
        "tt_bookings",
        sa.Column(
            "paid_with_wallet",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )


def downgrade() -> None:
    if not _has_column("tt_bookings", "paid_with_wallet"):
        return
    op.drop_column("tt_bookings", "paid_with_wallet")

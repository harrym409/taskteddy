"""Add tt_messages.location (structured location share in chat)

Revision ID: 0017_message_location
Revises: 0016_pending_cash_jobs
Create Date: 2026-08-19

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0017_message_location"
down_revision: Union[str, None] = "0016_pending_cash_jobs"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_column(table: str, column: str) -> bool:
    from sqlalchemy import inspect as _inspect
    try:
        return any(c["name"] == column for c in _inspect(op.get_bind()).get_columns(table))
    except Exception:
        return False


def upgrade() -> None:
    if not _has_column("tt_messages", "location"):
        op.add_column("tt_messages", sa.Column("location", sa.JSON(), nullable=True))


def downgrade() -> None:
    if _has_column("tt_messages", "location"):
        op.drop_column("tt_messages", "location")

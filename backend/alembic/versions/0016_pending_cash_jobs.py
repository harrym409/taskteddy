"""Add tt_users.pending_cash_jobs (cash-dues browse gate)

Revision ID: 0016_pending_cash_jobs
Revises: 0015_admin_users
Create Date: 2026-08-19

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0016_pending_cash_jobs"
down_revision: Union[str, None] = "0015_admin_users"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_column(table: str, column: str) -> bool:
    from sqlalchemy import inspect as _inspect
    try:
        return any(c["name"] == column for c in _inspect(op.get_bind()).get_columns(table))
    except Exception:
        return False


def upgrade() -> None:
    if not _has_column("tt_users", "pending_cash_jobs"):
        op.add_column(
            "tt_users",
            sa.Column("pending_cash_jobs", sa.Integer(), nullable=False, server_default="0"),
        )


def downgrade() -> None:
    if _has_column("tt_users", "pending_cash_jobs"):
        op.drop_column("tt_users", "pending_cash_jobs")

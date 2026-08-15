"""Add task on-the-way + cancellation audit and user cancel_count

Revision ID: 0011_ontheway_cancel
Revises: 0010_reports_blocks
Create Date: 2026-08-03

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0011_ontheway_cancel"
down_revision: Union[str, None] = "0010_reports_blocks"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_column(table: str, column: str) -> bool:
    from sqlalchemy import inspect as _inspect
    try:
        return any(c["name"] == column for c in _inspect(op.get_bind()).get_columns(table))
    except Exception:
        return False


def upgrade() -> None:
    if not _has_column("tt_tasks", "on_the_way_at"):
        op.add_column("tt_tasks", sa.Column("on_the_way_at", sa.DateTime(), nullable=True))
    if not _has_column("tt_tasks", "cancel_reason"):
        op.add_column("tt_tasks", sa.Column("cancel_reason", sa.Text(), nullable=True))
    if not _has_column("tt_tasks", "cancelled_by"):
        op.add_column("tt_tasks", sa.Column("cancelled_by", sa.String(64), nullable=True))
    if not _has_column("tt_users", "cancel_count"):
        op.add_column(
            "tt_users",
            sa.Column("cancel_count", sa.Integer(), nullable=False, server_default="0"),
        )


def downgrade() -> None:
    if _has_column("tt_users", "cancel_count"):
        op.drop_column("tt_users", "cancel_count")
    if _has_column("tt_tasks", "cancelled_by"):
        op.drop_column("tt_tasks", "cancelled_by")
    if _has_column("tt_tasks", "cancel_reason"):
        op.drop_column("tt_tasks", "cancel_reason")
    if _has_column("tt_tasks", "on_the_way_at"):
        op.drop_column("tt_tasks", "on_the_way_at")

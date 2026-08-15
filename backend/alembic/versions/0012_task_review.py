"""Add tt_tasks.review_reason for task moderation

Revision ID: 0012_task_review
Revises: 0011_ontheway_cancel
Create Date: 2026-08-06

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0012_task_review"
down_revision: Union[str, None] = "0011_ontheway_cancel"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_column(table: str, column: str) -> bool:
    from sqlalchemy import inspect as _inspect
    try:
        return any(c["name"] == column for c in _inspect(op.get_bind()).get_columns(table))
    except Exception:
        return False


def upgrade() -> None:
    if not _has_column("tt_tasks", "review_reason"):
        op.add_column("tt_tasks", sa.Column("review_reason", sa.Text(), nullable=True))


def downgrade() -> None:
    if _has_column("tt_tasks", "review_reason"):
        op.drop_column("tt_tasks", "review_reason")

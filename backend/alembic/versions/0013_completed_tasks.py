"""Add tt_users.completed_tasks for tasker reputation

Revision ID: 0013_completed_tasks
Revises: 0012_task_review
Create Date: 2026-08-06

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0013_completed_tasks"
down_revision: Union[str, None] = "0012_task_review"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_column(table: str, column: str) -> bool:
    from sqlalchemy import inspect as _inspect
    try:
        return any(c["name"] == column for c in _inspect(op.get_bind()).get_columns(table))
    except Exception:
        return False


def upgrade() -> None:
    if not _has_column("tt_users", "completed_tasks"):
        op.add_column(
            "tt_users",
            sa.Column("completed_tasks", sa.Integer(), nullable=False, server_default="0"),
        )
    # Backfill from existing completed tasks so current taskers get their level.
    bind = op.get_bind()
    try:
        bind.execute(sa.text(
            "UPDATE tt_users u SET completed_tasks = ("
            "  SELECT COUNT(*) FROM tt_tasks t"
            "  WHERE t.assigned_to = u.id AND t.status = 'completed'"
            ")"
        ))
    except Exception:
        pass


def downgrade() -> None:
    if _has_column("tt_users", "completed_tasks"):
        op.drop_column("tt_users", "completed_tasks")

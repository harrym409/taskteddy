"""Add user reports and blocks (trust & safety)

Revision ID: 0010_reports_blocks
Revises: 0009_feature_scaling
Create Date: 2026-08-03

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0010_reports_blocks"
down_revision: Union[str, None] = "0009_feature_scaling"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_table(table: str) -> bool:
    from sqlalchemy import inspect as _inspect
    return _inspect(op.get_bind()).has_table(table)


def upgrade() -> None:
    if not _has_table("tt_reports"):
        op.create_table(
            "tt_reports",
            sa.Column("id", sa.String(64), primary_key=True),
            sa.Column("reporter_id", sa.String(64), sa.ForeignKey("tt_users.id"), nullable=False, index=True),
            sa.Column("reported_id", sa.String(64), sa.ForeignKey("tt_users.id"), nullable=False, index=True),
            sa.Column("task_id", sa.String(64), nullable=True),
            sa.Column("reason", sa.String(60), nullable=False),
            sa.Column("detail", sa.Text(), nullable=True),
            sa.Column("status", sa.String(20), nullable=False, server_default="open"),
            sa.Column("created_at", sa.DateTime(), nullable=False),
        )
        op.create_index("idx_reports_reported", "tt_reports", ["reported_id", "status"])
        op.create_index("idx_reports_status_created", "tt_reports", ["status", "created_at"])

    if not _has_table("tt_blocks"):
        op.create_table(
            "tt_blocks",
            sa.Column("id", sa.String(64), primary_key=True),
            sa.Column("blocker_id", sa.String(64), sa.ForeignKey("tt_users.id"), nullable=False, index=True),
            sa.Column("blocked_id", sa.String(64), sa.ForeignKey("tt_users.id"), nullable=False, index=True),
            sa.Column("created_at", sa.DateTime(), nullable=False),
        )
        op.create_index("idx_blocks_unique", "tt_blocks", ["blocker_id", "blocked_id"], unique=True)


def downgrade() -> None:
    if _has_table("tt_blocks"):
        op.drop_table("tt_blocks")
    if _has_table("tt_reports"):
        op.drop_table("tt_reports")

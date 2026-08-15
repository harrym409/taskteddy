"""Add tt_audit_logs for admin action tracking

Revision ID: 0007_audit_logs
Revises: 0006_users_is_verified
Create Date: 2026-07-15

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0007_audit_logs"
down_revision: Union[str, None] = "0006_users_is_verified"
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
    # Baseline may have created these from live models on a fresh DB.
    if _has_table("tt_audit_logs"):
        return

    op.create_table(
        "tt_audit_logs",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("admin_email", sa.String(255), nullable=False),
        sa.Column("action", sa.String(80), nullable=False, index=True),
        sa.Column("target_type", sa.String(40), nullable=True),
        sa.Column("target_id", sa.String(64), nullable=True, index=True),
        sa.Column("detail", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, index=True),
    )


def downgrade() -> None:
    if not _has_table("tt_audit_logs"):
        return
    op.drop_table("tt_audit_logs")

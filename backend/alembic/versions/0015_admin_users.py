"""Add tt_admin_users (portal RBAC: superadmin / admin / support)

Revision ID: 0015_admin_users
Revises: 0014_kyc_numbers
Create Date: 2026-08-19

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0015_admin_users"
down_revision: Union[str, None] = "0014_kyc_numbers"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_table(table: str) -> bool:
    from sqlalchemy import inspect as _inspect
    try:
        return _inspect(op.get_bind()).has_table(table)
    except Exception:
        return False


def upgrade() -> None:
    if _has_table("tt_admin_users"):
        return
    op.create_table(
        "tt_admin_users",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("name", sa.String(255), nullable=False, server_default=""),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("role", sa.String(32), nullable=False, server_default="support"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_by", sa.String(64), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_tt_admin_users_email", "tt_admin_users", ["email"], unique=True)


def downgrade() -> None:
    if _has_table("tt_admin_users"):
        op.drop_index("ix_tt_admin_users_email", table_name="tt_admin_users")
        op.drop_table("tt_admin_users")

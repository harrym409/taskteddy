"""Add tt_users.signup_bonus_granted (bonus granted after email verification)

Revision ID: 0019_signup_bonus_granted
Revises: 0018_signup_bonus_promo
Create Date: 2026-09-02

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0019_signup_bonus_granted"
down_revision: Union[str, None] = "0018_signup_bonus_promo"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_column(table: str, column: str) -> bool:
    from sqlalchemy import inspect as _inspect
    try:
        return any(c["name"] == column for c in _inspect(op.get_bind()).get_columns(table))
    except Exception:
        return False


def upgrade() -> None:
    if not _has_column("tt_users", "signup_bonus_granted"):
        op.add_column(
            "tt_users",
            sa.Column("signup_bonus_granted", sa.Boolean(), nullable=False,
                      server_default=sa.false()),
        )


def downgrade() -> None:
    if _has_column("tt_users", "signup_bonus_granted"):
        op.drop_column("tt_users", "signup_bonus_granted")

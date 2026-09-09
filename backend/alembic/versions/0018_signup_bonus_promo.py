"""Signup bonus / promo wallet: tt_users.promo_balance + tt_tasks.promo_discount

Revision ID: 0018_signup_bonus_promo
Revises: 0017_message_location
Create Date: 2026-08-19

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0018_signup_bonus_promo"
down_revision: Union[str, None] = "0017_message_location"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_column(table: str, column: str) -> bool:
    from sqlalchemy import inspect as _inspect
    try:
        return any(c["name"] == column for c in _inspect(op.get_bind()).get_columns(table))
    except Exception:
        return False


def upgrade() -> None:
    if not _has_column("tt_users", "promo_balance"):
        op.add_column(
            "tt_users",
            sa.Column("promo_balance", sa.Float(), nullable=False, server_default="0"),
        )
    if not _has_column("tt_tasks", "promo_discount"):
        op.add_column(
            "tt_tasks",
            sa.Column("promo_discount", sa.Float(), nullable=False, server_default="0"),
        )


def downgrade() -> None:
    if _has_column("tt_tasks", "promo_discount"):
        op.drop_column("tt_tasks", "promo_discount")
    if _has_column("tt_users", "promo_balance"):
        op.drop_column("tt_users", "promo_balance")

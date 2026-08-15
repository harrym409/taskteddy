"""Add tt_users.aadhaar_number / pan_number (admin-entered during KYC)

Revision ID: 0014_kyc_numbers
Revises: 0013_completed_tasks
Create Date: 2026-08-06

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0014_kyc_numbers"
down_revision: Union[str, None] = "0013_completed_tasks"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_column(table: str, column: str) -> bool:
    from sqlalchemy import inspect as _inspect
    try:
        return any(c["name"] == column for c in _inspect(op.get_bind()).get_columns(table))
    except Exception:
        return False


def upgrade() -> None:
    if not _has_column("tt_users", "aadhaar_number"):
        op.add_column("tt_users", sa.Column("aadhaar_number", sa.String(32), nullable=True))
    if not _has_column("tt_users", "pan_number"):
        op.add_column("tt_users", sa.Column("pan_number", sa.String(32), nullable=True))


def downgrade() -> None:
    if _has_column("tt_users", "pan_number"):
        op.drop_column("tt_users", "pan_number")
    if _has_column("tt_users", "aadhaar_number"):
        op.drop_column("tt_users", "aadhaar_number")

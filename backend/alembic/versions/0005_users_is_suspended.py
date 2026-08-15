"""Add tt_users.is_suspended for admin moderation

Suspended users are blocked at login; existing tokens are unaffected until
expiry (acceptable for the testing phase).

Revision ID: 0005_users_is_suspended
Revises: 0004_services_tasker_nullable
Create Date: 2026-07-15

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "0005_users_is_suspended"
down_revision: Union[str, None] = "0004_services_tasker_nullable"
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
    # The 0001 baseline builds the schema from live models, so on a fresh DB
    # this column may already exist — make the migration idempotent.
    if _has_column("tt_users", "is_suspended"):
        return

    op.add_column(
        "tt_users",
        sa.Column(
            "is_suspended",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )


def downgrade() -> None:
    if not _has_column("tt_users", "is_suspended"):
        return
    op.drop_column("tt_users", "is_suspended")

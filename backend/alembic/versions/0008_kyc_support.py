"""Add tt_kyc_documents and tt_support_tickets

Revision ID: 0008_kyc_support
Revises: 0007_audit_logs
Create Date: 2026-07-15

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0008_kyc_support"
down_revision: Union[str, None] = "0007_audit_logs"
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
    if _has_table("tt_kyc_documents"):
        return

    op.create_table(
        "tt_kyc_documents",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("user_id", sa.String(64), sa.ForeignKey("tt_users.id"), nullable=False, index=True),
        sa.Column("doc_type", sa.String(20), nullable=False),
        sa.Column("file_url", sa.String(500), nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("idx_kyc_user_type", "tt_kyc_documents", ["user_id", "doc_type"], unique=True)
    op.create_table(
        "tt_support_tickets",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("user_id", sa.String(64), sa.ForeignKey("tt_users.id"), nullable=False, index=True),
        sa.Column("subject", sa.String(200), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="open"),
        sa.Column("reply", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )


def downgrade() -> None:
    if not _has_table("tt_kyc_documents"):
        return
    op.drop_table("tt_support_tickets")
    op.drop_index("idx_kyc_user_type", table_name="tt_kyc_documents")
    op.drop_table("tt_kyc_documents")

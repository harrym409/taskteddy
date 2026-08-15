"""Add favorites, saved addresses, tasker availability, and portfolio tables

Revision ID: 0009_feature_scaling
Revises: 0008_kyc_support
Create Date: 2026-07-23

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0009_feature_scaling"
down_revision: Union[str, None] = "0008_kyc_support"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _has_table(table: str) -> bool:
    from sqlalchemy import inspect as _inspect
    return _inspect(op.get_bind()).has_table(table)


def upgrade() -> None:
    # The 0001 baseline builds the schema from live models, so on a fresh DB
    # these tables may already exist — make the migration idempotent.
    if not _has_table("tt_favorites"):
        op.create_table(
            "tt_favorites",
            sa.Column("id", sa.String(64), primary_key=True),
            sa.Column("user_id", sa.String(64), sa.ForeignKey("tt_users.id"), nullable=False, index=True),
            sa.Column("target_type", sa.String(20), nullable=False),
            sa.Column("target_id", sa.String(64), nullable=False),
            sa.Column("created_at", sa.DateTime(), nullable=False),
        )
        op.create_index("idx_favorites_user_created", "tt_favorites", ["user_id", "created_at"])
        op.create_index(
            "idx_favorites_unique", "tt_favorites",
            ["user_id", "target_type", "target_id"], unique=True,
        )

    if not _has_table("tt_addresses"):
        op.create_table(
            "tt_addresses",
            sa.Column("id", sa.String(64), primary_key=True),
            sa.Column("user_id", sa.String(64), sa.ForeignKey("tt_users.id"), nullable=False, index=True),
            sa.Column("label", sa.String(50), nullable=False, server_default="Home"),
            sa.Column("address", sa.Text(), nullable=False),
            sa.Column("landmark", sa.String(200), nullable=True),
            sa.Column("latitude", sa.Float(), nullable=True),
            sa.Column("longitude", sa.Float(), nullable=True),
            sa.Column("is_default", sa.Boolean(), nullable=False, server_default=sa.false()),
            sa.Column("created_at", sa.DateTime(), nullable=False),
            sa.Column("updated_at", sa.DateTime(), nullable=False),
        )
        op.create_index("idx_addresses_user", "tt_addresses", ["user_id", "is_default"])

    if not _has_table("tt_tasker_availability"):
        op.create_table(
            "tt_tasker_availability",
            sa.Column("id", sa.String(64), primary_key=True),
            sa.Column("tasker_id", sa.String(64), sa.ForeignKey("tt_users.id"), nullable=False, index=True),
            sa.Column("day_of_week", sa.Integer(), nullable=False),
            sa.Column("start_minute", sa.Integer(), nullable=False, server_default="540"),
            sa.Column("end_minute", sa.Integer(), nullable=False, server_default="1080"),
            sa.Column("is_available", sa.Boolean(), nullable=False, server_default=sa.true()),
            sa.Column("updated_at", sa.DateTime(), nullable=False),
        )
        op.create_index(
            "idx_availability_tasker_day", "tt_tasker_availability",
            ["tasker_id", "day_of_week"], unique=True,
        )

    if not _has_table("tt_portfolio"):
        op.create_table(
            "tt_portfolio",
            sa.Column("id", sa.String(64), primary_key=True),
            sa.Column("tasker_id", sa.String(64), sa.ForeignKey("tt_users.id"), nullable=False, index=True),
            sa.Column("image_url", sa.String(500), nullable=False),
            sa.Column("caption", sa.String(300), nullable=True),
            sa.Column("created_at", sa.DateTime(), nullable=False),
        )
        op.create_index("idx_portfolio_tasker_created", "tt_portfolio", ["tasker_id", "created_at"])


def downgrade() -> None:
    if _has_table("tt_portfolio"):
        op.drop_table("tt_portfolio")
    if _has_table("tt_tasker_availability"):
        op.drop_table("tt_tasker_availability")
    if _has_table("tt_addresses"):
        op.drop_table("tt_addresses")
    if _has_table("tt_favorites"):
        op.drop_table("tt_favorites")

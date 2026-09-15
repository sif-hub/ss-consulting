"""add updated_at to paiements

Revision ID: 6413fbf45760
Revises: 86da30c919a6
Create Date: 2026-09-01
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "6413fbf45760"
down_revision: Union[str, Sequence[str], None] = "86da30c919a6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "paiements",
        sa.Column(
            "updated_at",
            sa.DateTime(),
            nullable=True,
        ),
    )

    op.execute(
        "UPDATE paiements SET updated_at = created_at "
        "WHERE updated_at IS NULL"
    )

    op.alter_column(
        "paiements",
        "updated_at",
        existing_type=sa.DateTime(),
        nullable=False,
    )


def downgrade() -> None:
    op.drop_column("paiements", "updated_at")

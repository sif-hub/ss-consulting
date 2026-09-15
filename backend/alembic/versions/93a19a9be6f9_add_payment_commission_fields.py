"""add payment commission fields

Revision ID: 93a19a9be6f9
Revises: 820b4ef0a572
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "93a19a9be6f9"
down_revision: Union[str, Sequence[str], None] = "820b4ef0a572"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "paiements",
        sa.Column(
            "taux_commission",
            sa.Float(),
            nullable=False,
            server_default="2.0",
        ),
    )

    op.add_column(
        "paiements",
        sa.Column(
            "montant_commission",
            sa.Float(),
            nullable=False,
            server_default="0",
        ),
    )

    op.add_column(
        "paiements",
        sa.Column(
            "montant_total",
            sa.Float(),
            nullable=False,
            server_default="0",
        ),
    )


def downgrade() -> None:
    op.drop_column("paiements", "montant_total")
    op.drop_column("paiements", "montant_commission")
    op.drop_column("paiements", "taux_commission")


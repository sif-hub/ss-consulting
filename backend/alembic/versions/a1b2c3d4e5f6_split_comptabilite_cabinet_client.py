"""split comptabilite cabinet vs client

Revision ID: a1b2c3d4e5f6
Revises: ce529efdc7d4
Create Date: 2026-09-17 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "a1b2c3d4e5f6"
down_revision: Union[str, Sequence[str], None] = "ce529efdc7d4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:

    # ============================================================
    # PERIODES_COMPTABLES
    # ============================================================

    op.add_column(
        "periodes_comptables",
        sa.Column(
            "client_id",
            sa.Integer(),
            sa.ForeignKey("clients.id", ondelete="CASCADE"),
            nullable=True,
        ),
    )

    op.create_index(
        "ix_periodes_comptables_client_id",
        "periodes_comptables",
        ["client_id"],
    )

    op.drop_constraint(
        "uq_periode_comptable_exercice_mois",
        "periodes_comptables",
        type_="unique",
    )

    op.create_index(
        "uq_periode_client_exercice_mois",
        "periodes_comptables",
        ["client_id", "exercice", "mois"],
        unique=True,
        postgresql_where=sa.text("client_id IS NOT NULL"),
    )

    op.create_index(
        "uq_periode_cabinet_exercice_mois",
        "periodes_comptables",
        ["exercice", "mois"],
        unique=True,
        postgresql_where=sa.text("client_id IS NULL"),
    )

    # ============================================================
    # COMPTES_COMPTABLES
    # ============================================================

    op.add_column(
        "comptes_comptables",
        sa.Column(
            "client_id",
            sa.Integer(),
            sa.ForeignKey("clients.id", ondelete="CASCADE"),
            nullable=True,
        ),
    )

    op.create_index(
        "ix_comptes_comptables_client_id",
        "comptes_comptables",
        ["client_id"],
    )

    op.drop_index(
        "ix_comptes_comptables_numero",
        table_name="comptes_comptables",
    )

    op.create_index(
        "uq_compte_client_numero",
        "comptes_comptables",
        ["client_id", "numero"],
        unique=True,
        postgresql_where=sa.text("client_id IS NOT NULL"),
    )

    op.create_index(
        "uq_compte_cabinet_numero",
        "comptes_comptables",
        ["numero"],
        unique=True,
        postgresql_where=sa.text("client_id IS NULL"),
    )


def downgrade() -> None:

    op.drop_index(
        "uq_compte_cabinet_numero",
        table_name="comptes_comptables",
    )

    op.drop_index(
        "uq_compte_client_numero",
        table_name="comptes_comptables",
    )

    op.create_index(
        "ix_comptes_comptables_numero",
        "comptes_comptables",
        ["numero"],
        unique=True,
    )

    op.drop_index(
        "ix_comptes_comptables_client_id",
        table_name="comptes_comptables",
    )

    op.drop_column("comptes_comptables", "client_id")

    op.drop_index(
        "uq_periode_cabinet_exercice_mois",
        table_name="periodes_comptables",
    )

    op.drop_index(
        "uq_periode_client_exercice_mois",
        table_name="periodes_comptables",
    )

    op.create_unique_constraint(
        "uq_periode_comptable_exercice_mois",
        "periodes_comptables",
        ["exercice", "mois"],
    )

    op.drop_index(
        "ix_periodes_comptables_client_id",
        table_name="periodes_comptables",
    )

    op.drop_column("periodes_comptables", "client_id")

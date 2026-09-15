"""create taches table

Revision ID: 3f75053b48f9
Revises: 69348f4f482b
Create Date: 2026-09-01 09:09:05.811272
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "3f75053b48f9"
down_revision: Union[str, Sequence[str], None] = "69348f4f482b"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:

    op.create_table(
        "taches",

        sa.Column(
            "id",
            sa.Integer(),
            primary_key=True,
            nullable=False,
        ),

        sa.Column(
            "titre",
            sa.String(length=200),
            nullable=False,
        ),

        sa.Column(
            "description",
            sa.Text(),
            nullable=True,
        ),

        sa.Column(
            "statut",
            sa.String(length=50),
            nullable=False,
            server_default="À faire",
        ),

        sa.Column(
            "priorite",
            sa.String(length=30),
            nullable=False,
            server_default="Normale",
        ),

        sa.Column(
            "date_echeance",
            sa.DateTime(),
            nullable=True,
        ),

        sa.Column(
            "date_creation",
            sa.DateTime(),
            nullable=False,
            server_default=sa.func.now(),
        ),

        sa.Column(
            "date_terminaison",
            sa.DateTime(),
            nullable=True,
        ),

        sa.Column(
            "dossier_id",
            sa.Integer(),
            sa.ForeignKey(
                "dossiers.id",
                ondelete="CASCADE",
            ),
            nullable=False,
        ),

        sa.Column(
            "responsable_id",
            sa.Integer(),
            sa.ForeignKey(
                "users.id",
                ondelete="SET NULL",
            ),
            nullable=True,
        ),

        sa.Column(
            "actif",
            sa.Boolean(),
            nullable=False,
            server_default=sa.true(),
        ),
    )

    op.create_index(
        "ix_taches_id",
        "taches",
        ["id"],
        unique=False,
    )

    op.create_index(
        "ix_taches_dossier_id",
        "taches",
        ["dossier_id"],
        unique=False,
    )

    op.create_index(
        "ix_taches_responsable_id",
        "taches",
        ["responsable_id"],
        unique=False,
    )


def downgrade() -> None:

    op.drop_index(
        "ix_taches_responsable_id",
        table_name="taches",
    )

    op.drop_index(
        "ix_taches_dossier_id",
        table_name="taches",
    )

    op.drop_index(
        "ix_taches_id",
        table_name="taches",
    )

    op.drop_table("taches")

"""link documents to declarations

Revision ID: fa1fb7fb8f69
Revises: 4bb2d66e3055
Create Date: 2026-09-06
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "fa1fb7fb8f69"
down_revision: Union[str, Sequence[str], None] = "4bb2d66e3055"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Les documents peuvent maintenant être liés soit à un dossier,
    # soit directement à une déclaration.
    op.alter_column(
        "documents",
        "dossier_id",
        existing_type=sa.Integer(),
        nullable=True,
    )

    op.add_column(
        "documents",
        sa.Column(
            "declaration_id",
            sa.Integer(),
            nullable=True,
        ),
    )

    op.create_index(
        op.f("ix_documents_declaration_id"),
        "documents",
        ["declaration_id"],
        unique=False,
    )

    op.create_foreign_key(
        "documents_declaration_id_fkey",
        "documents",
        "declarations",
        ["declaration_id"],
        ["id"],
        ondelete="CASCADE",
    )


def downgrade() -> None:
    op.drop_constraint(
        "documents_declaration_id_fkey",
        "documents",
        type_="foreignkey",
    )

    op.drop_index(
        op.f("ix_documents_declaration_id"),
        table_name="documents",
    )

    op.drop_column(
        "documents",
        "declaration_id",
    )

    op.alter_column(
        "documents",
        "dossier_id",
        existing_type=sa.Integer(),
        nullable=False,
    )

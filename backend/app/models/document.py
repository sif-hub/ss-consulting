from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Document(Base):
    __tablename__ = "documents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    dossier_id: Mapped[int | None] = mapped_column(
        ForeignKey("dossiers.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )

    declaration_id: Mapped[int | None] = mapped_column(
        ForeignKey("declarations.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )

    nom: Mapped[str] = mapped_column(String(255), nullable=False)

    type_document: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    description: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    chemin_fichier: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True,
    )

    statut: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="Actif",
    )

    actif: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    declaration = relationship(
        "Declaration",
        back_populates="documents",
    )


    dossier = relationship(
        "Dossier",
        back_populates="documents",
    )

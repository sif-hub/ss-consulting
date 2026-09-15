from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Dossier(Base):
    __tablename__ = "dossiers"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    client_id: Mapped[int] = mapped_column(
        ForeignKey("clients.id"),
        nullable=False,
        index=True,
    )

    collaborateur_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id"),
        nullable=True,
        index=True,
    )

    titre: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
    )

    type_dossier: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    description: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    statut: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="En cours",
    )

    date_ouverture: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )

    date_cloture: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    priorite: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        default="Normale",
    )

    actif: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
    )

    documents = relationship(
        "Document",
        back_populates="dossier",
        cascade="all, delete-orphan",
    )

    taches = relationship(
        "Tache",
        back_populates="dossier",
        cascade="all, delete-orphan",
    )

    client = relationship(
        "Client",
        back_populates="dossiers",
    )

    collaborateur = relationship(
        "User",
        foreign_keys=[collaborateur_id],
    )

    factures = relationship(
        "Facture",
        back_populates="dossier",
    )

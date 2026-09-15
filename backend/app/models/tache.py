from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Tache(Base):
    __tablename__ = "taches"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    dossier_id: Mapped[int] = mapped_column(
        ForeignKey("dossiers.id"),
        nullable=False,
        index=True,
    )

    responsable_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id"),
        nullable=True,
        index=True,
    )

    titre: Mapped[str] = mapped_column(String(200), nullable=False)

    description: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    statut: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="À faire",
    )

    priorite: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="Normale",
    )

    date_echeance: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    date_creation: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )

    date_terminaison: Mapped[datetime | None] = mapped_column(
        DateTime,
        nullable=True,
    )

    actif: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
    )

    dossier = relationship(
        "Dossier",
        back_populates="taches",
    )

    responsable = relationship(
        "User",
        back_populates="taches",
    )

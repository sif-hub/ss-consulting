from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Client(Base):
    __tablename__ = "clients"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True,
    )

    nom: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    prenom: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    raison_sociale: Mapped[str | None] = mapped_column(
        String(200),
        nullable=True,
    )

    email: Mapped[str | None] = mapped_column(
        String(255),
        unique=True,
        nullable=True,
        index=True,
    )

    telephone: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
    )

    adresse: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    ville: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    numero_contribuable: Mapped[str | None] = mapped_column(
        String(100),
        unique=True,
        nullable=True,
        index=True,
    )

    registre_commerce: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    type_client: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="Entreprise",
    )

    secteur_activite: Mapped[str | None] = mapped_column(
        String(150),
        nullable=True,
    )

    assujetti_tva: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    marge_administree: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    regime_fiscal: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    commune: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    quartier: Mapped[str | None] = mapped_column(
        String(150),
        nullable=True,
    )

    lieu_dit: Mapped[str | None] = mapped_column(
        String(150),
        nullable=True,
    )

    statut_occupation: Mapped[str | None] = mapped_column(
        String(30),
        nullable=True,
    )

    notes: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    actif: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )

    updated_at: Mapped[datetime] = mapped_column(

        DateTime,
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )

    dossiers = relationship(
        "Dossier",
        back_populates="client",
        cascade="all, delete-orphan",
    )

    factures = relationship(
        "Facture",
        back_populates="client",
        cascade="all, delete-orphan",
    )

    declarations = relationship(
        "Declaration",
        back_populates="client",
        cascade="all, delete-orphan",
    )

    utilisateur = relationship(
        "User",
        back_populates="client",
        uselist=False,
    )

from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.core.database import Base


class Facture(Base):
    __tablename__ = "factures"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    numero = Column(
        String(50),
        unique=True,
        nullable=False,
        index=True,
    )

    client_id = Column(
        Integer,
        ForeignKey("clients.id"),
        nullable=False,
        index=True,
    )

    dossier_id = Column(
        Integer,
        ForeignKey("dossiers.id"),
        nullable=True,
        index=True,
    )

    date_emission = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )

    date_echeance = Column(
        DateTime,
        nullable=True,
    )

    montant_ht = Column(
        Float,
        nullable=False,
        default=0,
    )

    taux_tva = Column(
        Float,
        nullable=False,
        default=19.25,
    )

    montant_tva = Column(
        Float,
        nullable=False,
        default=0,
    )

    montant_ttc = Column(
        Float,
        nullable=False,
        default=0,
    )

    statut = Column(
        String(30),
        nullable=False,
        default="Brouillon",
    )

    mode_paiement = Column(
        String(50),
        nullable=True,
    )

    notes = Column(
        Text,
        nullable=True,
    )

    actif = Column(
        Boolean,
        nullable=False,
        default=True,
    )

    created_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )

    updated_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )

    client = relationship(
        "Client",
        back_populates="factures",
    )

    dossier = relationship(
        "Dossier",
        back_populates="factures",
    )

    paiements = relationship(
        "Paiement",
        back_populates="facture",
        cascade="all, delete-orphan",
    )

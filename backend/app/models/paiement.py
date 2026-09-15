from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.core.database import Base


class Paiement(Base):
    __tablename__ = "paiements"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    facture_id = Column(
        Integer,
        ForeignKey("factures.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    montant = Column(
        Float,
        nullable=False,
    )

    date_paiement = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )

    mode_paiement = Column(
        String(50),
        nullable=False,
    )

    operateur = Column(
        String(30),
        nullable=True,
    )

    transaction_id = Column(
        String(100),
        nullable=True,
        unique=True,
        index=True,
    )

    numero_client = Column(
        String(30),
        nullable=True,
    )

    taux_commission = Column(
        Float,
        nullable=False,
        default=2.0,
    )

    montant_commission = Column(
        Float,
        nullable=False,
        default=0.0,
    )

    montant_total = Column(
        Float,
        nullable=False,
        default=0.0,
    )

    frais = Column(
        Float,
        nullable=False,
        default=0,
    )

    reference = Column(
        String(100),
        nullable=True,
        index=True,
    )

    statut = Column(
        String(30),
        nullable=False,
        default="En attente",
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

    facture = relationship(
        "Facture",
        back_populates="paiements",
    )

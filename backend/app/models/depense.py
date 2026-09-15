from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.core.database import Base


class Depense(Base):
    __tablename__ = "depenses"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    # Fournisseur ou tiers concerné
    fournisseur = Column(
        String(150),
        nullable=True,
    )

    description = Column(
        String(255),
        nullable=False,
    )

    categorie = Column(
        String(100),
        nullable=False,
        index=True,
    )

    date_depense = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        index=True,
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

    mode_paiement = Column(
        String(50),
        nullable=True,
    )

    reference = Column(
        String(100),
        nullable=True,
        index=True,
    )

    statut = Column(
        String(30),
        nullable=False,
        default="Payée",
    )

    justificatif = Column(
        String(255),
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

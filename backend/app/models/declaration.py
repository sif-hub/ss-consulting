from datetime import datetime

from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from app.core.database import Base


class Declaration(Base):
    __tablename__ = "declarations"

    id = Column(Integer, primary_key=True, index=True)

    # Client concerné
    client_id = Column(
        Integer,
        ForeignKey("clients.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # Période de déclaration
    mois = Column(Integer, nullable=False)
    annee = Column(Integer, nullable=False)

    # Données déclarées
    chiffre_affaires = Column(
        Numeric(15, 2),
        nullable=False,
        default=0,
    )

    total_ventes = Column(
        Numeric(15, 2),
        nullable=False,
        default=0,
    )

    total_achats = Column(
        Numeric(15, 2),
        nullable=False,
        default=0,
    )

    nombre_employes = Column(
        Integer,
        nullable=False,
        default=0,
    )

    observations = Column(Text, nullable=True)

    # BROUILLON / SOUMISE / EN_VERIFICATION / VALIDEE / A_CORRIGER / REJETEE
    statut = Column(
        String(30),
        nullable=False,
        default="BROUILLON",
        index=True,
    )

    # Commentaire du fiscaliste/admin lors d'une correction ou d'un rejet
    commentaire_admin = Column(Text, nullable=True)

    date_creation = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )

    date_soumission = Column(
        DateTime,
        nullable=True,
    )

    date_validation = Column(
        DateTime,
        nullable=True,
    )

    # Utilisateur ayant traité la déclaration
    traite_par_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )

    client = relationship(
        "Client",
        back_populates="declarations",
    )

    traite_par = relationship(
        "User",
        foreign_keys=[traite_par_id],
    )

    documents = relationship(
        "Document",
        back_populates="declaration",
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        UniqueConstraint(
            "client_id",
            "mois",
            "annee",
            name="uq_declaration_client_mois_annee",
        ),
    )

from datetime import datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class PeriodeComptable(Base):
    __tablename__ = "periodes_comptables"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    # NULL = comptabilité propre du cabinet. Non NULL = comptabilité
    # tenue par le cabinet pour le compte de ce client.
    client_id: Mapped[int | None] = mapped_column(
        ForeignKey("clients.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )

    exercice: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    mois: Mapped[int] = mapped_column(Integer, nullable=False)
    date_debut: Mapped[datetime] = mapped_column(Date, nullable=False)
    date_fin: Mapped[datetime] = mapped_column(Date, nullable=False)
    statut: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="OUVERTE",
    )

    ecritures = relationship(
        "EcritureComptable",
        back_populates="periode",
        cascade="all, delete-orphan",
    )

    # Unicité (exercice, mois) par périmètre : deux index partiels car
    # NULL n'est jamais égal à NULL pour une contrainte UNIQUE classique
    # (plusieurs lignes "cabinet" sur le même mois passeraient sinon).
    __table_args__ = (
        Index(
            "uq_periode_client_exercice_mois",
            "client_id",
            "exercice",
            "mois",
            unique=True,
            postgresql_where=client_id.isnot(None),
        ),
        Index(
            "uq_periode_cabinet_exercice_mois",
            "exercice",
            "mois",
            unique=True,
            postgresql_where=client_id.is_(None),
        ),
    )


class CompteComptable(Base):
    __tablename__ = "comptes_comptables"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    # NULL = plan comptable du cabinet. Non NULL = plan comptable propre
    # à ce client (le cabinet tient sa comptabilité séparément).
    client_id: Mapped[int | None] = mapped_column(
        ForeignKey("clients.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )

    numero: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        index=True,
    )
    libelle: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )
    classe: Mapped[str] = mapped_column(
        String(10),
        nullable=False,
        index=True,
    )
    sous_classe: Mapped[str | None] = mapped_column(
        String(10),
        nullable=True,
    )
    actif: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
    )

    lignes = relationship(
        "LigneEcriture",
        back_populates="compte",
    )

    __table_args__ = (
        Index(
            "uq_compte_client_numero",
            "client_id",
            "numero",
            unique=True,
            postgresql_where=client_id.isnot(None),
        ),
        Index(
            "uq_compte_cabinet_numero",
            "numero",
            unique=True,
            postgresql_where=client_id.is_(None),
        ),
    )


class EcritureComptable(Base):
    __tablename__ = "ecritures_comptables"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    periode_id: Mapped[int] = mapped_column(
        ForeignKey("periodes_comptables.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )

    date_ecriture: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        index=True,
    )

    journal: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        index=True,
    )

    reference: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
        index=True,
    )

    libelle: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    statut: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="BROUILLON",
        index=True,
    )

    source_type: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )

    source_id: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )

    periode = relationship(
        "PeriodeComptable",
        back_populates="ecritures",
    )

    lignes = relationship(
        "LigneEcriture",
        back_populates="ecriture",
        cascade="all, delete-orphan",
    )


class LigneEcriture(Base):
    __tablename__ = "lignes_ecritures"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    ecriture_id: Mapped[int] = mapped_column(
        ForeignKey("ecritures_comptables.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    compte_id: Mapped[int] = mapped_column(
        ForeignKey("comptes_comptables.id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )

    libelle: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
    )

    debit: Mapped[float] = mapped_column(
        Numeric(18, 2),
        nullable=False,
        default=0,
    )

    credit: Mapped[float] = mapped_column(
        Numeric(18, 2),
        nullable=False,
        default=0,
    )

    ecriture = relationship(
        "EcritureComptable",
        back_populates="lignes",
    )

    compte = relationship(
        "CompteComptable",
        back_populates="lignes",
    )


class BalanceComptable(Base):
    __tablename__ = "balances_comptables"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    exercice: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        index=True,
    )

    date_balance: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
    )

    total_debit: Mapped[float] = mapped_column(
        Numeric(18, 2),
        nullable=False,
        default=0,
    )

    total_credit: Mapped[float] = mapped_column(
        Numeric(18, 2),
        nullable=False,
        default=0,
    )

    total_solde_debiteur: Mapped[float] = mapped_column(
        Numeric(18, 2),
        nullable=False,
        default=0,
    )

    total_solde_crediteur: Mapped[float] = mapped_column(
        Numeric(18, 2),
        nullable=False,
        default=0,
    )

    statut: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default="BROUILLON",
    )

from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


# ============================================================
# DASHBOARD EXISTANT
# ============================================================

class ComptabiliteDashboardResponse(BaseModel):
    annee: int
    mois: int | None = None

    total_recettes: float = Field(default=0)
    total_depenses: float = Field(default=0)
    resultat: float = Field(default=0)

    tva_collectee: float = Field(default=0)
    tva_deductible: float = Field(default=0)
    tva_a_payer: float = Field(default=0)

    nombre_factures: int = Field(default=0)
    nombre_paiements: int = Field(default=0)
    nombre_depenses: int = Field(default=0)


# ============================================================
# PERIODE COMPTABLE
# ============================================================

class PeriodeComptableBase(BaseModel):
    client_id: int | None = Field(
        default=None,
        description="Cabinet si absent, sinon comptabilité de ce client.",
    )
    exercice: int = Field(..., ge=2000, le=2100)
    mois: int = Field(..., ge=1, le=12)
    date_debut: date
    date_fin: date
    statut: str = Field(default="OUVERTE", max_length=20)


class PeriodeComptableCreate(PeriodeComptableBase):
    pass


class PeriodeComptableResponse(PeriodeComptableBase):
    id: int

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# COMPTE COMPTABLE
# ============================================================

class CompteComptableBase(BaseModel):
    client_id: int | None = Field(
        default=None,
        description="Cabinet si absent, sinon plan comptable de ce client.",
    )
    numero: str = Field(..., min_length=1, max_length=30)
    libelle: str = Field(..., min_length=1, max_length=255)
    classe: str = Field(..., min_length=1, max_length=10)
    sous_classe: str | None = Field(default=None, max_length=10)
    actif: bool = True


class CompteComptableCreate(CompteComptableBase):
    pass


class CompteComptableResponse(CompteComptableBase):
    id: int

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# LIGNE D'ECRITURE
# ============================================================

class LigneEcritureCreate(BaseModel):
    compte_id: int = Field(..., gt=0)
    libelle: str | None = Field(default=None, max_length=255)

    debit: Decimal = Field(default=Decimal("0"), ge=0)
    credit: Decimal = Field(default=Decimal("0"), ge=0)


class LigneEcritureResponse(BaseModel):
    id: int
    ecriture_id: int
    compte_id: int
    libelle: str | None = None
    debit: Decimal
    credit: Decimal

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# ECRITURE COMPTABLE
# ============================================================

class EcritureComptableCreate(BaseModel):
    periode_id: int = Field(..., gt=0)

    date_ecriture: datetime

    journal: str = Field(
        ...,
        min_length=1,
        max_length=20,
    )

    reference: str | None = Field(
        default=None,
        max_length=100,
    )

    libelle: str = Field(
        ...,
        min_length=1,
        max_length=255,
    )

    source_type: str | None = Field(
        default=None,
        max_length=50,
    )

    source_id: int | None = Field(
        default=None,
        gt=0,
    )

    lignes: list[LigneEcritureCreate] = Field(
        ...,
        min_length=2,
    )


class EcritureComptableResponse(BaseModel):
    id: int
    periode_id: int
    date_ecriture: datetime
    journal: str
    reference: str | None = None
    libelle: str
    statut: str
    source_type: str | None = None
    source_id: int | None = None

    lignes: list[LigneEcritureResponse] = Field(
        default_factory=list,
    )

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# VALIDATION D'ECRITURE
# ============================================================

class ValidationEcritureResponse(BaseModel):
    id: int
    statut: str
    total_debit: Decimal
    total_credit: Decimal
    equilibree: bool


# ============================================================
# JOURNAL COMPTABLE
# ============================================================

class JournalLigneResponse(BaseModel):
    ecriture_id: int
    date_ecriture: datetime
    journal: str
    reference: str | None = None
    libelle_ecriture: str

    compte_id: int
    compte_numero: str
    compte_libelle: str

    libelle_ligne: str | None = None
    debit: Decimal
    credit: Decimal


# ============================================================
# GRAND LIVRE
# ============================================================

class GrandLivreLigneResponse(BaseModel):
    date_ecriture: datetime
    journal: str
    reference: str | None = None
    libelle: str

    debit: Decimal
    credit: Decimal
    solde: Decimal


class GrandLivreCompteResponse(BaseModel):
    compte_id: int
    numero: str
    libelle: str

    total_debit: Decimal
    total_credit: Decimal
    solde_debiteur: Decimal
    solde_crediteur: Decimal

    lignes: list[GrandLivreLigneResponse] = Field(
        default_factory=list,
    )


# ============================================================
# BALANCE COMPTABLE
# ============================================================

class BalanceCompteResponse(BaseModel):
    compte_id: int
    numero: str
    libelle: str

    total_debit: Decimal
    total_credit: Decimal

    solde_debiteur: Decimal
    solde_crediteur: Decimal


class BalanceComptableResponse(BaseModel):
    exercice: int
    client_id: int | None = None

    total_debit: Decimal
    total_credit: Decimal

    total_solde_debiteur: Decimal
    total_solde_crediteur: Decimal

    comptes: list[BalanceCompteResponse] = Field(
        default_factory=list,
    )

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.document import DocumentResponse


def normalize_decimal(value):
    if value is None:
        return Decimal("0")

    if isinstance(value, str):
        value = value.strip()
        value = value.replace(" ", "")
        value = value.replace(",", ".")

    return Decimal(str(value))


class DeclarationCreate(BaseModel):
    client_id: int
    mois: int = Field(ge=1, le=12)
    annee: int = Field(ge=2000, le=2100)

    chiffre_affaires: Decimal = Field(default=Decimal("0"), ge=0)
    total_ventes: Decimal = Field(default=Decimal("0"), ge=0)
    total_achats: Decimal = Field(default=Decimal("0"), ge=0)

    nombre_employes: int = Field(default=0, ge=0)

    observations: str | None = None

    @field_validator(
        "chiffre_affaires",
        "total_ventes",
        "total_achats",
        mode="before",
    )
    @classmethod
    def parse_decimal(cls, value):
        return normalize_decimal(value)


class DeclarationUpdate(BaseModel):
    mois: int = Field(ge=1, le=12)
    annee: int = Field(ge=2000, le=2100)

    chiffre_affaires: Decimal = Field(default=Decimal("0"), ge=0)
    total_ventes: Decimal = Field(default=Decimal("0"), ge=0)
    total_achats: Decimal = Field(default=Decimal("0"), ge=0)

    nombre_employes: int = Field(default=0, ge=0)

    observations: str | None = None

    @field_validator(
        "chiffre_affaires",
        "total_ventes",
        "total_achats",
        mode="before",
    )
    @classmethod
    def parse_decimal(cls, value):
        return normalize_decimal(value)


class DeclarationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    client_id: int
    mois: int
    annee: int

    chiffre_affaires: Decimal
    total_ventes: Decimal
    total_achats: Decimal

    nombre_employes: int

    observations: str | None
    statut: str
    commentaire_admin: str | None

    date_creation: datetime
    date_soumission: datetime | None
    date_validation: datetime | None

    traite_par_id: int | None

    documents: list[DocumentResponse] = Field(default_factory=list)


class DeclarationReview(BaseModel):
    statut: str = Field(
        pattern="^(VALIDEE|A_CORRIGER|REJETEE)$"
    )
    commentaire_admin: str | None = None

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class DepenseBase(BaseModel):
    fournisseur: str | None = Field(
        default=None,
        max_length=150,
    )

    description: str = Field(
        min_length=2,
        max_length=255,
    )

    categorie: str = Field(
        min_length=2,
        max_length=100,
    )

    date_depense: datetime | None = None

    montant_ht: float = Field(
        default=0,
        ge=0,
    )

    taux_tva: float = Field(
        default=19.25,
        ge=0,
    )

    montant_tva: float | None = Field(
        default=None,
        ge=0,
    )

    montant_ttc: float | None = Field(
        default=None,
        ge=0,
    )

    mode_paiement: str | None = Field(
        default=None,
        max_length=50,
    )

    reference: str | None = Field(
        default=None,
        max_length=100,
    )

    statut: str = Field(
        default="Payée",
        max_length=30,
    )

    justificatif: str | None = Field(
        default=None,
        max_length=255,
    )

    notes: str | None = None


class DepenseCreate(DepenseBase):
    pass


class DepenseUpdate(BaseModel):
    fournisseur: str | None = Field(
        default=None,
        max_length=150,
    )

    description: str | None = Field(
        default=None,
        min_length=2,
        max_length=255,
    )

    categorie: str | None = Field(
        default=None,
        min_length=2,
        max_length=100,
    )

    date_depense: datetime | None = None

    montant_ht: float | None = Field(
        default=None,
        ge=0,
    )

    taux_tva: float | None = Field(
        default=None,
        ge=0,
    )

    montant_tva: float | None = Field(
        default=None,
        ge=0,
    )

    montant_ttc: float | None = Field(
        default=None,
        ge=0,
    )

    mode_paiement: str | None = Field(
        default=None,
        max_length=50,
    )

    reference: str | None = Field(
        default=None,
        max_length=100,
    )

    statut: str | None = Field(
        default=None,
        max_length=30,
    )

    justificatif: str | None = Field(
        default=None,
        max_length=255,
    )

    notes: str | None = None


class DepenseResponse(DepenseBase):
    id: int
    actif: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True,
    )

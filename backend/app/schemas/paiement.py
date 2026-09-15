from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class PaiementBase(BaseModel):
    facture_id: int

    montant: float = Field(
        gt=0,
        description="Montant du paiement en FCFA",
    )

    mode_paiement: str = Field(
        max_length=50,
    )

    operateur: str | None = Field(
        default=None,
        max_length=30,
    )

    transaction_id: str | None = Field(
        default=None,
        max_length=100,
    )

    numero_client: str | None = Field(
        default=None,
        max_length=30,
    )

    frais: float = Field(
        default=0,
        ge=0,
    )

    reference: str | None = Field(
        default=None,
        max_length=100,
    )

    date_paiement: datetime | None = None

    statut: str = Field(
        default="En attente",
        max_length=30,
    )

    notes: str | None = None


class PaiementCreate(PaiementBase):
    pass


class PaiementUpdate(BaseModel):
    montant: float | None = Field(
        default=None,
        gt=0,
    )

    mode_paiement: str | None = Field(
        default=None,
        max_length=50,
    )

    operateur: str | None = Field(
        default=None,
        max_length=30,
    )

    transaction_id: str | None = Field(
        default=None,
        max_length=100,
    )

    numero_client: str | None = Field(
        default=None,
        max_length=30,
    )

    frais: float | None = Field(
        default=None,
        ge=0,
    )

    reference: str | None = Field(
        default=None,
        max_length=100,
    )

    date_paiement: datetime | None = None

    statut: str | None = Field(
        default=None,
        max_length=30,
    )

    notes: str | None = None


class PaiementResponse(PaiementBase):
    id: int
    actif: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True,
    )

class PaiementResponse(BaseModel):
    facture_id: int
    montant: float

    mode_paiement: str
    operateur: str | None = None
    transaction_id: str | None = None
    numero_client: str | None = None

    frais: float = 0

    taux_commission: float
    montant_commission: float
    montant_total: float

    reference: str | None = None
    date_paiement: datetime | None = None
    statut: str
    notes: str | None = None

    id: int
    actif: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True,
    )

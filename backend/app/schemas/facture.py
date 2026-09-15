from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class FactureBase(BaseModel):
    numero: str | None = Field(default=None, max_length=50)
    client_id: int
    dossier_id: int | None = None

    date_emission: datetime | None = None
    date_echeance: datetime | None = None

    montant_ht: float = Field(default=0, ge=0)
    taux_tva: float = Field(default=19.25, ge=0)
    montant_tva: float | None = None
    montant_ttc: float | None = None

    statut: str = Field(default="Brouillon", max_length=30)
    mode_paiement: str | None = Field(default=None, max_length=50)
    notes: str | None = None


class FactureCreate(FactureBase):
    pass


class FactureUpdate(BaseModel):
    numero: str | None = Field(default=None, max_length=50)
    client_id: int | None = None
    dossier_id: int | None = None

    date_emission: datetime | None = None
    date_echeance: datetime | None = None

    montant_ht: float | None = Field(default=None, ge=0)
    taux_tva: float | None = Field(default=None, ge=0)
    montant_tva: float | None = Field(default=None, ge=0)
    montant_ttc: float | None = Field(default=None, ge=0)

    statut: str | None = Field(default=None, max_length=30)
    mode_paiement: str | None = Field(default=None, max_length=50)
    notes: str | None = None
    actif: bool | None = None


class FactureResponse(FactureBase):
    numero: str
    model_config = ConfigDict(from_attributes=True)

    id: int
    actif: bool
    created_at: datetime
    updated_at: datetime

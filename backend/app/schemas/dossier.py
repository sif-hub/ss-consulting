from datetime import datetime

from pydantic import BaseModel, ConfigDict


class DossierBase(BaseModel):
    titre: str
    type_dossier: str
    description: str | None = None
    statut: str = "En cours"
    priorite: str = "Normale"
    date_cloture: datetime | None = None
    actif: bool = True


class DossierCreate(DossierBase):
    client_id: int
    collaborateur_id: int | None = None


class DossierUpdate(BaseModel):
    titre: str | None = None
    type_dossier: str | None = None
    description: str | None = None
    statut: str | None = None
    priorite: str | None = None
    date_cloture: datetime | None = None
    actif: bool | None = None
    collaborateur_id: int | None = None


class DossierResponse(DossierBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    client_id: int
    collaborateur_id: int | None = None
    date_ouverture: datetime


class DossierAffectation(BaseModel):
    collaborateur_id: int

from datetime import datetime

from pydantic import BaseModel, ConfigDict


class TacheBase(BaseModel):
    titre: str
    description: str | None = None
    statut: str = "À faire"
    priorite: str = "Normale"
    date_echeance: datetime | None = None
    dossier_id: int
    responsable_id: int | None = None


class TacheCreate(TacheBase):
    pass


class TacheUpdate(BaseModel):
    titre: str | None = None
    description: str | None = None
    statut: str | None = None
    priorite: str | None = None
    date_echeance: datetime | None = None
    date_terminaison: datetime | None = None
    responsable_id: int | None = None
    actif: bool | None = None


class TacheResponse(TacheBase):
    id: int
    date_creation: datetime
    date_terminaison: datetime | None = None
    actif: bool

    model_config = ConfigDict(from_attributes=True)

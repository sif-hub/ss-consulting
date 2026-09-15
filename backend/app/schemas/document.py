from datetime import datetime

from pydantic import BaseModel, ConfigDict


class DocumentCreate(BaseModel):
    dossier_id: int | None = None
    declaration_id: int | None = None

    nom: str
    type_document: str
    description: str | None = None
    chemin_fichier: str | None = None
    statut: str = "Actif"


class DocumentUpdate(BaseModel):
    nom: str | None = None
    type_document: str | None = None
    description: str | None = None
    chemin_fichier: str | None = None
    statut: str | None = None
    actif: bool | None = None


class DocumentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    dossier_id: int | None
    declaration_id: int | None

    nom: str
    type_document: str
    description: str | None
    chemin_fichier: str | None
    statut: str
    actif: bool

    created_at: datetime
    updated_at: datetime

from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr


class ClientBase(BaseModel):
    nom: str
    prenom: str | None = None
    raison_sociale: str | None = None
    email: EmailStr | None = None
    telephone: str
    adresse: str | None = None
    ville: str | None = None
    numero_contribuable: str | None = None
    registre_commerce: str | None = None
    type_client: str = "Entreprise"

    secteur_activite: str | None = None
    assujetti_tva: bool = False
    marge_administree: bool = False
    regime_fiscal: str | None = None
    commune: str | None = None
    quartier: str | None = None
    lieu_dit: str | None = None
    statut_occupation: str | None = None

    notes: str | None = None


class ClientCreate(ClientBase):
    pass


class ClientUpdate(BaseModel):
    nom: str | None = None
    prenom: str | None = None
    raison_sociale: str | None = None
    email: EmailStr | None = None
    telephone: str | None = None
    adresse: str | None = None
    ville: str | None = None
    numero_contribuable: str | None = None
    registre_commerce: str | None = None
    type_client: str | None = None

    secteur_activite: str | None = None
    assujetti_tva: bool | None = None
    marge_administree: bool | None = None
    regime_fiscal: str | None = None
    commune: str | None = None
    quartier: str | None = None
    lieu_dit: str | None = None
    statut_occupation: str | None = None

    notes: str | None = None
    actif: bool | None = None


class ClientResponse(ClientBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    actif: bool
    created_at: datetime
    updated_at: datetime

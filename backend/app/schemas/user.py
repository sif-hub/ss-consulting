from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True
    )

    id: int
    nom: str
    prenom: str
    email: EmailStr
    telephone: str | None
    role_id: int
    client_id: int | None = None
    actif: bool
    date_creation: datetime
    derniere_connexion: datetime | None
    role: str


class UserCreate(BaseModel):
    nom: str = Field(min_length=2, max_length=100)
    prenom: str = Field(min_length=2, max_length=100)
    email: EmailStr
    telephone: str | None = None
    mot_de_passe: str = Field(min_length=6, max_length=255)
    role_id: int
    client_id: int | None = None


class UserUpdate(BaseModel):
    nom: str = Field(min_length=2, max_length=100)
    prenom: str = Field(min_length=2, max_length=100)
    email: EmailStr
    telephone: str | None = None
    role_id: int
    client_id: int | None = None


class UserPasswordUpdate(BaseModel):
    mot_de_passe: str = Field(min_length=6, max_length=255)


class RoleResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True
    )

    id: int
    nom: str
    description: str | None

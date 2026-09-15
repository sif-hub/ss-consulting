from pydantic import BaseModel, ConfigDict, EmailStr, Field


class RegisterRequest(BaseModel):
    nom: str = Field(min_length=2, max_length=100)
    prenom: str = Field(min_length=2, max_length=100)
    email: EmailStr
    telephone: str | None = Field(
        default=None,
        max_length=30,
    )
    mot_de_passe: str = Field(
        min_length=8,
        max_length=128,
    )


class LoginRequest(BaseModel):
    email: EmailStr
    mot_de_passe: str


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
    role: str
    actif: bool


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

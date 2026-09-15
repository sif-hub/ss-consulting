from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.auth import (
    LoginRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
)
from app.services.auth_service import (
    authenticate_user,
    create_user_token,
    register_user,
)


router = APIRouter(
    prefix="/auth",
    tags=["Authentification"],
)


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def register(
    data: RegisterRequest,
    db: Session = Depends(get_db),
):
    user = register_user(db, data)
    return {
        "id": user.id,
        "nom": user.nom,
        "prenom": user.prenom,
        "email": user.email,
        "telephone": user.telephone,
        "role_id": user.role_id,
        "client_id": user.client_id,
        "role": user.role.nom,
        "actif": user.actif,
    }


@router.post(
    "/login",
    response_model=TokenResponse,
)
def login(
    data: LoginRequest,
    db: Session = Depends(get_db),
):

    user = authenticate_user(
        db,
        data.email,
        data.mot_de_passe,
    )

    token = create_user_token(user)

    return TokenResponse(
        access_token=token,
        user={
            "id": user.id,
            "nom": user.nom,
            "prenom": user.prenom,
            "email": user.email,
            "telephone": user.telephone,
            "role_id": user.role_id,
            "client_id": user.client_id,
            "role": user.role.nom,
            "actif": user.actif,
        },
    )


@router.get(
    "/me",
    response_model=UserResponse,
)
def me(
    current_user: User = Depends(get_current_user),
):
    return {
        "id": current_user.id,
        "nom": current_user.nom,
        "prenom": current_user.prenom,
        "email": current_user.email,
        "telephone": current_user.telephone,
        "role_id": current_user.role_id,
        "client_id": current_user.client_id,
        "role": current_user.role.nom,
        "actif": current_user.actif,
    }

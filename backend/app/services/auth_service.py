from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import (
    create_access_token,
    hash_password,
    verify_password,
)
from app.models.role import Role
from app.models.user import User
from app.schemas.auth import RegisterRequest
from app.services.client_service import ensure_client_for_user


DEFAULT_ROLE = "Client"


def register_user(
    db: Session,
    data: RegisterRequest,
) -> User:

    existing_user = (
        db.query(User)
        .filter(User.email == data.email)
        .first()
    )

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cette adresse email est déjà utilisée",
        )

    role = (
        db.query(Role)
        .filter(Role.nom == DEFAULT_ROLE)
        .first()
    )

    if role is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Le rôle par défaut n'existe pas",
        )

    user = User(
        nom=data.nom,
        prenom=data.prenom,
        email=data.email,
        telephone=data.telephone,
        mot_de_passe=hash_password(data.mot_de_passe),
        role_id=role.id,
        actif=True,
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    if role.nom == "Client":
        ensure_client_for_user(db, user)

    return user


def authenticate_user(
    db: Session,
    email: str,
    password: str,
) -> User:

    user = (
        db.query(User)
        .filter(User.email == email)
        .first()
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect",
        )

    if not verify_password(
        password,
        user.mot_de_passe,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect",
        )

    if not user.actif:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Compte désactivé",
        )

    return user


def create_user_token(user: User) -> str:

    return create_access_token(
        {
            "sub": str(user.id),
            "email": user.email,
            "role_id": user.role_id,
        }
    )

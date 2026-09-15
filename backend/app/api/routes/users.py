from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.models.user import User
from app.schemas.user import (
    RoleResponse,
    UserCreate,
    UserPasswordUpdate,
    UserResponse,
    UserUpdate,
)
from app.services.user_service import (
    change_password,
    create_user,
    get_roles,
    get_user_by_id,
    get_users,
    set_user_status,
    update_user,
)


router = APIRouter(
    prefix="/users",
    tags=["Utilisateurs"],
)


def user_to_response(user: User) -> dict:
    return {
        "id": user.id,
        "nom": user.nom,
        "prenom": user.prenom,
        "email": user.email,
        "telephone": user.telephone,
        "role_id": user.role_id,
        "client_id": user.client_id,
        "actif": user.actif,
        "date_creation": user.date_creation,
        "derniere_connexion": user.derniere_connexion,
        "role": user.role.nom if user.role else "Inconnu",
    }


@router.get(
    "",
    response_model=list[UserResponse],
)
def list_users(
    actif: bool | None = Query(default=None),
    role_id: int | None = Query(default=None),
    search: str | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    users = get_users(
        db=db,
        actif=actif,
        role_id=role_id,
        search=search,
    )

    return [user_to_response(user) for user in users]


@router.get(
    "/roles",
    response_model=list[RoleResponse],
)
def list_roles(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    return get_roles(db)


@router.get(
    "/{user_id}",
    response_model=UserResponse,
)
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    user = get_user_by_id(db, user_id)

    return user_to_response(user)


@router.post(
    "",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_new_user(
    data: UserCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    user = create_user(
        db=db,
        nom=data.nom,
        prenom=data.prenom,
        email=str(data.email),
        telephone=data.telephone,
        mot_de_passe=data.mot_de_passe,
        role_id=data.role_id,
        client_id=data.client_id,
    )

    return user_to_response(user)


@router.put(
    "/{user_id}",
    response_model=UserResponse,
)
def update_existing_user(
    user_id: int,
    data: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    user = update_user(
        db=db,
        user_id=user_id,
        nom=data.nom,
        prenom=data.prenom,
        email=str(data.email),
        telephone=data.telephone,
        role_id=data.role_id,
        client_id=data.client_id,
    )

    return user_to_response(user)


@router.patch(
    "/{user_id}/mot-de-passe",
    response_model=UserResponse,
)
def update_user_password(
    user_id: int,
    data: UserPasswordUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    user = change_password(
        db=db,
        user_id=user_id,
        mot_de_passe=data.mot_de_passe,
    )

    return user_to_response(user)


@router.patch(
    "/{user_id}/activer",
    response_model=UserResponse,
)
def activate_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    user = set_user_status(
        db=db,
        user_id=user_id,
        actif=True,
        current_user_id=current_user.id,
    )

    return user_to_response(user)


@router.patch(
    "/{user_id}/desactiver",
    response_model=UserResponse,
)
def deactivate_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    user = set_user_status(
        db=db,
        user_id=user_id,
        actif=False,
        current_user_id=current_user.id,
    )

    return user_to_response(user)

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_roles
from app.models.client import Client
from app.models.user import User
from app.schemas.client import (
    ClientCreate,
    ClientResponse,
    ClientUpdate,
)
from app.services.client_service import (
    create_client,
    delete_client,
    get_client,
    get_clients,
    get_client_situation,
    update_client,
)


router = APIRouter(
    prefix="/clients",
    tags=["Clients"],
)


def ensure_client_access(current_user: User, client_id: int):
    """
    Vérifie qu'un utilisateur Client (role_id=6)
    n'accède qu'à son propre compte client.
    """

    if current_user.role_id == 6:
        if current_user.client_id != client_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Vous n'avez pas accès à ce client.",
            )


@router.post(
    "",
    response_model=ClientResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_client_route(
    data: ClientCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 5)),
):
    return create_client(db, data)


@router.get(
    "",
    response_model=List[ClientResponse],
)
def list_clients(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role_id == 6:
        if current_user.client_id is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Votre compte Client n'est associé à aucun client.",
            )

        client = get_client(db, current_user.client_id)

        return [client] if client else []

    return get_clients(db)


@router.get(
    "/{client_id}",
    response_model=ClientResponse,
)
def get_client_route(
    client_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_client_access(current_user, client_id)

    client = get_client(db, client_id)

    if client is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client introuvable",
        )

    return client


@router.put(
    "/{client_id}",
    response_model=ClientResponse,
)
def update_client_route(
    client_id: int,
    data: ClientUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 5)),
):
    client = update_client(db, client_id, data)

    if client is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client introuvable",
        )

    return client


@router.delete(
    "/{client_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete_client_route(
    client_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 5)),
):
    deleted = delete_client(db, client_id)

    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client introuvable",
        )

    return None


@router.get("/{client_id}/situation")
def client_situation(
    client_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_client_access(current_user, client_id)

    try:
        return get_client_situation(
            db,
            client_id,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e),
        )

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_roles
from app.models.user import User
from app.schemas.facture import (
    FactureCreate,
    FactureResponse,
    FactureUpdate,
)
from app.services.facture_service import (
    create_facture,
    delete_facture,
    get_facture,
    get_facture_by_numero,
    get_factures,
    update_facture,
)


router = APIRouter(
    prefix="/factures",
    tags=["Factures"],
)


def ensure_facture_access(current_user: User, facture):
    """
    Vérifie qu'un utilisateur Client (role_id=6)
    n'accède qu'aux factures de son propre compte client.
    """

    if current_user.role_id == 6:
        if current_user.client_id is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Votre compte Client n'est associé à aucun client.",
            )

        if facture.client_id != current_user.client_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Vous n'avez pas accès à cette facture.",
            )


@router.post(
    "",
    response_model=FactureResponse,
    status_code=status.HTTP_201_CREATED,
)
def create(
    data: FactureCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 5)),
):
    if data.numero:
        existing = get_facture_by_numero(db, data.numero)

        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Une facture avec ce numéro existe déjà",
            )

    return create_facture(db, data)


@router.get(
    "",
    response_model=list[FactureResponse],
)
def list_all(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    client_id = None

    if current_user.role_id == 6:
        if current_user.client_id is None:
            return []

        client_id = current_user.client_id

    return get_factures(
        db,
        skip=skip,
        limit=limit,
        client_id=client_id,
    )


@router.get(
    "/{facture_id}",
    response_model=FactureResponse,
)
def get_one(
    facture_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    facture = get_facture(db, facture_id)

    if facture is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Facture introuvable",
        )

    ensure_facture_access(current_user, facture)

    return facture


@router.put(
    "/{facture_id}",
    response_model=FactureResponse,
)
def update(
    facture_id: int,
    data: FactureUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 5)),
):
    facture = get_facture(db, facture_id)

    if facture is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Facture introuvable",
        )

    if data.numero and data.numero != facture.numero:
        existing = get_facture_by_numero(db, data.numero)

        if existing and existing.id != facture.id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Une facture avec ce numéro existe déjà",
            )

    return update_facture(db, facture, data)


@router.delete(
    "/{facture_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete(
    facture_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 5)),
):
    facture = get_facture(db, facture_id)

    if facture is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Facture introuvable",
        )

    delete_facture(db, facture)

    return None

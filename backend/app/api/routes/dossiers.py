from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_admin, require_roles
from app.models.user import User
from app.schemas.dossier import (
    DossierAffectation,
    DossierCreate,
    DossierResponse,
    DossierUpdate,
)
from app.services.dossier_service import (
    affecter_dossier,
    create_dossier,
    desaffecter_dossier,
    delete_dossier,
    get_dossier,
    get_dossiers,
    get_dossiers_collaborateur,
    update_dossier,
)



def ensure_dossier_access(current_user: User, dossier):
    # Administrateur : accès à tous les dossiers.
    if current_user.role_id == 1:
        return

    # Collaborateurs : uniquement les dossiers qui leur sont affectés.
    if current_user.role_id in (2, 3, 4, 5):
        if dossier.collaborateur_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Vous n'avez pas accès à ce dossier. "
                "Il ne vous est pas affecté.",
            )
        return

    # Client : uniquement les dossiers de son propre compte client.
    if current_user.role_id == 6:
        if current_user.client_id is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Votre compte Client n'est associé à aucun client.",
            )

        if dossier.client_id != current_user.client_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Vous n'avez pas accès à ce dossier.",
            )
        return

    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="Vous n'avez pas accès à ce dossier.",
    )

router = APIRouter(
    prefix="/dossiers",
    tags=["Dossiers"],
)


@router.post(
    "",
    response_model=DossierResponse,
    status_code=status.HTTP_201_CREATED,
)
def create(
    data: DossierCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 5)),
):
    return create_dossier(db, data)



@router.put(
    "/{dossier_id}/affecter",
    response_model=DossierResponse,
)
def affecter_dossier_route(
    dossier_id: int,
    data: DossierAffectation,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    return affecter_dossier(
        db,
        dossier_id,
        data.collaborateur_id,
    )


@router.put(
    "/{dossier_id}/desaffecter",
    response_model=DossierResponse,
)
def desaffecter_dossier_route(
    dossier_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    return desaffecter_dossier(
        db,
        dossier_id,
    )


@router.get(
    "/mes-dossiers",
    response_model=list[DossierResponse],
)
def mes_dossiers(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role_id not in (2, 3, 4, 5):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cette fonctionnalité est réservée aux collaborateurs.",
        )

    return get_dossiers_collaborateur(
        db,
        current_user.id,
    )

@router.get(
    "",
    response_model=list[DossierResponse],
)
def list_all(
    client_id: int | None = Query(
        default=None,
        description="Filtrer les dossiers par client",
    ),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Collaborateurs : uniquement leurs dossiers affectés.
    if current_user.role_id in (2, 3, 4, 5):
        return get_dossiers_collaborateur(
            db,
            current_user.id,
        )

    # Client : uniquement ses propres dossiers.
    if current_user.role_id == 6:
        if current_user.client_id is None:
            return []

        client_id = current_user.client_id

    # Administrateur : tous les dossiers,
    # avec possibilité de filtrer par client.
    return get_dossiers(
        db,
        client_id=client_id,
    )


@router.get(
    "/{dossier_id}",
    response_model=DossierResponse,
)
def get_one(
    dossier_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    dossier = get_dossier(
        db,
        dossier_id,
    )

    ensure_dossier_access(current_user, dossier)

    return dossier


@router.put(
    "/{dossier_id}",
    response_model=DossierResponse,
)
def update(
    dossier_id: int,
    data: DossierUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    dossier = get_dossier(
        db,
        dossier_id,
    )

    ensure_dossier_access(
        current_user,
        dossier,
    )

    return update_dossier(
        db,
        dossier_id,
        data,
    )


@router.delete(
    "/{dossier_id}",
)
def delete(
    dossier_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    return delete_dossier(
        db,
        dossier_id,
    )

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import require_roles
from app.models.dossier import Dossier
from app.models.user import User
from app.schemas.tache import (
    TacheCreate,
    TacheResponse,
    TacheUpdate,
)
from app.services.tache_service import (
    create_tache,
    get_taches,
    get_tache,
    update_tache,
    delete_tache,
    terminer_tache,
)

router = APIRouter(
    prefix="/taches",
    tags=["Tâches"],
)


# Les tâches sont un outil de suivi interne : les comptes Client
# (role_id=6) n'y ont jamais accès.
def ensure_tache_access(db: Session, current_user: User, tache):
    if current_user.role_id == 1:
        return

    dossier = (
        db.query(Dossier)
        .filter(Dossier.id == tache.dossier_id)
        .first()
    )

    if dossier is None or dossier.collaborateur_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous n'avez pas accès à cette tâche.",
        )


@router.post(
    "",
    response_model=TacheResponse,
    status_code=status.HTTP_201_CREATED,
)
def create(
    data: TacheCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    return create_tache(db, data)


@router.get(
    "",
    response_model=list[TacheResponse],
)
def list_all(
    dossier_id: int | None = None,
    responsable_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    if current_user.role_id != 1:
        if dossier_id is not None:
            dossier = (
                db.query(Dossier)
                .filter(Dossier.id == dossier_id)
                .first()
            )

            if dossier is None or dossier.collaborateur_id != current_user.id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Vous n'avez pas accès à ce dossier.",
                )
        else:
            responsable_id = current_user.id

    return get_taches(
        db,
        dossier_id=dossier_id,
        responsable_id=responsable_id,
    )


@router.get(
    "/{tache_id}",
    response_model=TacheResponse,
)
def get_one(
    tache_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    tache = get_tache(db, tache_id)

    if tache is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tâche introuvable",
        )

    ensure_tache_access(db, current_user, tache)

    return tache


@router.put(
    "/{tache_id}",
    response_model=TacheResponse,
)
def update(
    tache_id: int,
    data: TacheUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    tache = get_tache(db, tache_id)

    if tache is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tâche introuvable",
        )

    ensure_tache_access(db, current_user, tache)

    return update_tache(db, tache, data)


@router.patch(
    "/{tache_id}/terminer",
    response_model=TacheResponse,
)
def complete(
    tache_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    tache = get_tache(db, tache_id)

    if tache is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tâche introuvable",
        )

    ensure_tache_access(db, current_user, tache)

    return terminer_tache(db, tache)


@router.delete(
    "/{tache_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete(
    tache_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    tache = get_tache(db, tache_id)

    if tache is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tâche introuvable",
        )

    ensure_tache_access(db, current_user, tache)

    delete_tache(db, tache)


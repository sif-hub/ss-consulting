from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import require_roles
from app.models.user import User
from app.schemas.depense import (
    DepenseCreate,
    DepenseResponse,
    DepenseUpdate,
)
from app.services.depense_service import (
    create_depense,
    delete_depense,
    get_depense,
    get_depenses,
    get_depenses_par_categorie,
    get_total_depenses,
    get_total_depenses_ht,
    get_total_tva_depenses,
    update_depense,
)


router = APIRouter(
    prefix="/depenses",
    tags=["Dépenses"],
)


# ============================================================
# CREATION
# ============================================================

@router.post(
    "",
    response_model=DepenseResponse,
    status_code=status.HTTP_201_CREATED,
)
def create(
    data: DepenseCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 5)),
):
    return create_depense(db, data)


# ============================================================
# LISTE
# ============================================================

@router.get(
    "",
    response_model=list[DepenseResponse],
)
def list_all(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    return get_depenses(db, skip, limit)


# ============================================================
# STATISTIQUES
# ============================================================

@router.get(
    "/statistiques/total",
)
def statistiques_total(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    return {
        "total_ht": get_total_depenses_ht(db),
        "total_tva": get_total_tva_depenses(db),
        "total_ttc": get_total_depenses(db),
    }


@router.get(
    "/statistiques/categories",
)
def statistiques_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    return get_depenses_par_categorie(db)


# ============================================================
# DETAIL
# ============================================================

@router.get(
    "/{depense_id}",
    response_model=DepenseResponse,
)
def get_one(
    depense_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    depense = get_depense(db, depense_id)

    if depense is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Dépense introuvable",
        )

    return depense


# ============================================================
# MODIFICATION
# ============================================================

@router.put(
    "/{depense_id}",
    response_model=DepenseResponse,
)
def update(
    depense_id: int,
    data: DepenseUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 5)),
):
    depense = get_depense(db, depense_id)

    if depense is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Dépense introuvable",
        )

    return update_depense(db, depense, data)


# ============================================================
# SUPPRESSION LOGIQUE
# ============================================================

@router.delete(
    "/{depense_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete(
    depense_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 5)),
):
    depense = get_depense(db, depense_id)

    if depense is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Dépense introuvable",
        )

    delete_depense(db, depense)

    return None

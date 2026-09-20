from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_roles
from app.models.user import User
from app.schemas.declaration import (
    DeclarationCreate,
    DeclarationResponse,
    DeclarationReview,
    DeclarationUpdate,
)
from app.services.client_service import ensure_client_for_user
from app.services.declaration_service import (
    create_declaration,
    get_declaration,
    get_declarations,
    review_declaration,
    start_review,
    submit_declaration,
    update_declaration,
)


def ensure_declaration_access(current_user: User, declaration):
    if current_user.role_id == 6:
        if current_user.client_id is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Votre compte Client n'est associé à aucun client.",
            )

        if declaration.client_id != current_user.client_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Vous n'avez pas accès à cette déclaration.",
            )

router = APIRouter(
    prefix="/declarations",
    tags=["Déclarations"],
)


# ============================================================
# LISTE
# ============================================================

@router.get(
    "",
    response_model=list[DeclarationResponse],
)
def list_declarations(
    client_id: int | None = Query(default=None),
    mois: int | None = Query(default=None, ge=1, le=12),
    annee: int | None = Query(default=None),
    statut: str | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(1, 2, 4, 5, 6)
    ),
):
    if current_user.role_id == 6:
        if current_user.client_id is None:
            return []
        client_id = current_user.client_id

    return get_declarations(
        db=db,
        client_id=client_id,
        mois=mois,
        annee=annee,
        statut=statut,
    )


# ============================================================
# DETAIL
# ============================================================

@router.get(
    "/{declaration_id}",
    response_model=DeclarationResponse,
)
def declaration_detail(
    declaration_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(1, 2, 4, 5, 6)
    ),
):
    declaration = get_declaration(
        db=db,
        declaration_id=declaration_id,
    )

    ensure_declaration_access(current_user, declaration)

    return declaration


# ============================================================
# CREATION
# ============================================================

@router.post(
    "",
    response_model=DeclarationResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_new_declaration(
    data: DeclarationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(1, 6)
    ),
):
    if current_user.role_id == 6:
        client_id = ensure_client_for_user(db, current_user)
    else:
        client_id = data.client_id

        if client_id is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Sélectionnez le client concerné par cette déclaration.",
            )

    return create_declaration(
        db=db,
        client_id=client_id,
        mois=data.mois,
        annee=data.annee,
        chiffre_affaires=data.chiffre_affaires,
        total_ventes=data.total_ventes,
        total_achats=data.total_achats,
        nombre_employes=data.nombre_employes,
        observations=data.observations,
    )


# ============================================================
# MODIFICATION
# ============================================================

@router.put(
    "/{declaration_id}",
    response_model=DeclarationResponse,
)
def update_existing_declaration(
    declaration_id: int,
    data: DeclarationUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(1, 6)
    ),
):
    declaration = get_declaration(
        db=db,
        declaration_id=declaration_id,
    )

    ensure_declaration_access(current_user, declaration)

    return update_declaration(
        db=db,
        declaration_id=declaration_id,
        mois=data.mois,
        annee=data.annee,
        chiffre_affaires=data.chiffre_affaires,
        total_ventes=data.total_ventes,
        total_achats=data.total_achats,
        nombre_employes=data.nombre_employes,
        observations=data.observations,
    )


# ============================================================
# SOUMISSION
# ============================================================

@router.post(
    "/{declaration_id}/soumettre",
    response_model=DeclarationResponse,
)
def submit_existing_declaration(
    declaration_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(1, 6)
    ),
):
    declaration = get_declaration(
        db=db,
        declaration_id=declaration_id,
    )

    ensure_declaration_access(current_user, declaration)

    return submit_declaration(
        db=db,
        declaration_id=declaration_id,
    )


# ============================================================
# MISE EN VERIFICATION
# ============================================================

@router.post(
    "/{declaration_id}/verification",
    response_model=DeclarationResponse,
)
def put_declaration_under_review(
    declaration_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(1, 4)
    ),
):
    return start_review(
        db=db,
        declaration_id=declaration_id,
        current_user_id=current_user.id,
    )


# ============================================================
# TRAITEMENT
# ============================================================

@router.post(
    "/{declaration_id}/traiter",
    response_model=DeclarationResponse,
)
def process_declaration(
    declaration_id: int,
    data: DeclarationReview,
    db: Session = Depends(get_db),
    current_user: User = Depends(
        require_roles(1, 4)
    ),
):
    return review_declaration(
        db=db,
        declaration_id=declaration_id,
        statut=data.statut,
        commentaire_admin=data.commentaire_admin,
        current_user=current_user,
    )

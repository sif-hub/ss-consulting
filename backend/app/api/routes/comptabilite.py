from datetime import date, datetime
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import require_roles
from app.models.user import User
from app.schemas.comptabilite import (
    PeriodeComptableCreate,
    PeriodeComptableResponse,
    CompteComptableResponse,
    EcritureComptableCreate,
    EcritureComptableResponse,
    ValidationEcritureResponse,
    JournalLigneResponse,
    GrandLivreCompteResponse,
    BalanceComptableResponse,
)
from app.services.comptabilite_service import (
    dashboard_financier,
    recettes_mensuelles,
    depenses_mensuelles,
    depenses_par_categorie,
    rapport_annuel,
    rapport_tva,
    rapport_tresorerie,
    lister_comptes,
    creer_periode,
    get_periode,
    creer_ecriture,
    valider_ecriture,
    journal_comptable,
    grand_livre,
    balance_comptable,
)
from app.models.client import Client
from app.models.comptabilite_syscohada import (
    PeriodeComptable,
    EcritureComptable,
    CompteComptable,
)
from app.seeds.plan_comptable_syscohada import seed_plan_comptable


router = APIRouter(
    prefix="/comptabilite",
    tags=["Comptabilité"],
)


# ============================================================
# ANCIENNES ROUTES — CONSERVÉES
# ============================================================

@router.get("/dashboard")
def dashboard(
    annee: int | None = None,
    mois: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    try:
        return dashboard_financier(db, annee, mois)

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        )


@router.get("/recettes-mensuelles")
def recettes(
    annee: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    return recettes_mensuelles(db, annee)


@router.get("/depenses-mensuelles")
def depenses(
    annee: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    return depenses_mensuelles(db, annee)


@router.get("/depenses-categories")
def categories(
    annee: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    return depenses_par_categorie(db, annee)


@router.get("/rapport-annuel")
def rapport(
    annee: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    return rapport_annuel(db, annee)


@router.get("/tva")
def tva(
    annee: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    return rapport_tva(db, annee)


@router.get("/tresorerie")
def tresorerie(
    annee: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    return rapport_tresorerie(db, annee)


# ============================================================
# PÉRIODES COMPTABLES
# ============================================================

@router.post(
    "/periodes",
    response_model=PeriodeComptableResponse,
    status_code=201,
)
def creer_periode_comptable(
    data: PeriodeComptableCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 5)),
):
    try:
        periode = creer_periode(
            db,
            exercice=data.exercice,
            mois=data.mois,
            client_id=data.client_id,
        )

        return periode

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        )


@router.get(
    "/periodes/{exercice}",
    response_model=list[PeriodeComptableResponse],
)
def lister_periodes(
    exercice: int,
    client_id: int | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    return (
        db.query(PeriodeComptable)
        .filter(
            PeriodeComptable.exercice == exercice,
            PeriodeComptable.client_id == client_id,
        )
        .order_by(PeriodeComptable.mois.asc())
        .all()
    )


# ============================================================
# ÉCRITURES COMPTABLES
# ============================================================

@router.post(
    "/ecritures",
    response_model=EcritureComptableResponse,
    status_code=201,
)
def creer_ecriture_comptable(
    data: EcritureComptableCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 5)),
):
    try:
        ecriture = creer_ecriture(
            db,
            periode_id=data.periode_id,
            date_ecriture=data.date_ecriture,
            journal=data.journal,
            reference=data.reference,
            libelle=data.libelle,
            lignes=data.lignes,
            source_type=data.source_type,
            source_id=data.source_id,
        )

        return ecriture

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        )


@router.get(
    "/ecritures/{ecriture_id}",
    response_model=EcritureComptableResponse,
)
def obtenir_ecriture(
    ecriture_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    ecriture = (
        db.query(EcritureComptable)
        .filter(EcritureComptable.id == ecriture_id)
        .first()
    )

    if not ecriture:
        raise HTTPException(
            status_code=404,
            detail="Écriture comptable introuvable.",
        )

    return ecriture


@router.post(
    "/ecritures/{ecriture_id}/valider",
    response_model=ValidationEcritureResponse,
)
def valider_ecriture_comptable(
    ecriture_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 5)),
):
    try:
        ecriture = valider_ecriture(
            db,
            ecriture_id=ecriture_id,
        )

        total_debit = sum(
            (Decimal(str(ligne.debit or 0)) for ligne in ecriture.lignes),
            Decimal("0"),
        )

        total_credit = sum(
            (Decimal(str(ligne.credit or 0)) for ligne in ecriture.lignes),
            Decimal("0"),
        )

        return ValidationEcritureResponse(
            id=ecriture.id,
            statut=ecriture.statut,
            total_debit=total_debit,
            total_credit=total_credit,
            equilibree=total_debit == total_credit,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        )


# ============================================================
# JOURNAL COMPTABLE
# ============================================================

@router.get(
    "/journal",
    response_model=list[JournalLigneResponse],
)
def journal(
    exercice: int,
    journal: str | None = None,
    mois: int | None = Query(default=None, ge=1, le=12),
    client_id: int | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    try:
        return journal_comptable(
            db,
            exercice=exercice,
            journal=journal,
            mois=mois,
            client_id=client_id,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        )


# ============================================================
# GRAND LIVRE
# ============================================================

@router.get(
    "/grand-livre",
    response_model=list[GrandLivreCompteResponse],
)
def grand_livre_comptable(
    exercice: int,
    compte: str | None = None,
    client_id: int | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    try:
        return grand_livre(
            db,
            exercice=exercice,
            compte_numero=compte,
            client_id=client_id,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        )


# ============================================================
# BALANCE COMPTABLE
# ============================================================

@router.get(
    "/balance",
    response_model=BalanceComptableResponse,
)
def balance(
    exercice: int,
    client_id: int | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    try:
        return balance_comptable(
            db,
            exercice=exercice,
            client_id=client_id,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        )


# ============================================================
# PLAN COMPTABLE
# ============================================================

@router.get(
    "/comptes",
    response_model=list[CompteComptableResponse],
)
def comptes(
    client_id: int | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    return lister_comptes(db, client_id=client_id)


# ============================================================
# COMPTABILITÉ CLIENT — INITIALISATION
# ============================================================

@router.get(
    "/clients",
    response_model=list[dict],
)
def clients_avec_comptabilite(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    """
    Liste les clients pour lesquels une comptabilité SYSCOHADA a déjà
    été initialisée par le cabinet (au moins un compte leur appartient).
    """

    client_ids = (
        db.query(CompteComptable.client_id)
        .filter(CompteComptable.client_id.isnot(None))
        .distinct()
        .all()
    )

    ids = [row[0] for row in client_ids]

    if not ids:
        return []

    clients = (
        db.query(Client)
        .filter(Client.id.in_(ids))
        .order_by(Client.nom.asc())
        .all()
    )

    return [
        {
            "id": client.id,
            "nom": client.nom,
            "raison_sociale": client.raison_sociale,
        }
        for client in clients
    ]


@router.post(
    "/clients/{client_id}/initialiser",
    status_code=status.HTTP_201_CREATED,
)
def initialiser_comptabilite_client(
    client_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 5)),
):
    """
    Crée le plan comptable SYSCOHADA complet (126 comptes) pour ce
    client, séparé de celui du cabinet et de celui des autres clients.
    Sans effet si déjà initialisé (idempotent).
    """

    client = (
        db.query(Client)
        .filter(Client.id == client_id)
        .first()
    )

    if client is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client introuvable.",
        )

    nombre = seed_plan_comptable(db, client_id=client_id)

    return {
        "client_id": client_id,
        "comptes_crees": nombre,
    }

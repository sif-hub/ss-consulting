from datetime import datetime

from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.depense import Depense
from app.schemas.depense import DepenseCreate, DepenseUpdate


# ============================================================
# CALCULS
# ============================================================

def calculate_amounts(
    montant_ht: float,
    taux_tva: float,
):
    montant_tva = round(montant_ht * taux_tva / 100, 2)
    montant_ttc = round(montant_ht + montant_tva, 2)

    return montant_tva, montant_ttc


# ============================================================
# CREATION
# ============================================================

def create_depense(
    db: Session,
    data: DepenseCreate,
):
    montant_tva, montant_ttc = calculate_amounts(
        data.montant_ht,
        data.taux_tva,
    )

    depense = Depense(
        fournisseur=data.fournisseur,
        description=data.description,
        categorie=data.categorie,
        date_depense=data.date_depense or datetime.utcnow(),
        montant_ht=data.montant_ht,
        taux_tva=data.taux_tva,
        montant_tva=(
            data.montant_tva
            if data.montant_tva is not None
            else montant_tva
        ),
        montant_ttc=(
            data.montant_ttc
            if data.montant_ttc is not None
            else montant_ttc
        ),
        mode_paiement=data.mode_paiement,
        reference=data.reference,
        statut=data.statut,
        justificatif=data.justificatif,
        notes=data.notes,
        actif=True,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )

    db.add(depense)
    db.commit()
    db.refresh(depense)

    return depense


# ============================================================
# LECTURE
# ============================================================

def get_depenses(
    db: Session,
    skip: int = 0,
    limit: int = 100,
):
    return (
        db.query(Depense)
        .filter(Depense.actif.is_(True))
        .order_by(Depense.date_depense.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


def get_depense(
    db: Session,
    depense_id: int,
):
    return (
        db.query(Depense)
        .filter(
            Depense.id == depense_id,
            Depense.actif.is_(True),
        )
        .first()
    )


# ============================================================
# MODIFICATION
# ============================================================

def update_depense(
    db: Session,
    depense: Depense,
    data: DepenseUpdate,
):
    values = data.model_dump(exclude_unset=True)

    for key, value in values.items():
        setattr(depense, key, value)

    if "montant_ht" in values or "taux_tva" in values:
        montant_tva, montant_ttc = calculate_amounts(
            depense.montant_ht,
            depense.taux_tva,
        )

        depense.montant_tva = montant_tva
        depense.montant_ttc = montant_ttc

    depense.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(depense)

    return depense


# ============================================================
# SUPPRESSION LOGIQUE
# ============================================================

def delete_depense(
    db: Session,
    depense: Depense,
):
    depense.actif = False
    depense.updated_at = datetime.utcnow()

    db.commit()


# ============================================================
# STATISTIQUES
# ============================================================

def get_total_depenses(
    db: Session,
):
    total = (
        db.query(func.coalesce(func.sum(Depense.montant_ttc), 0))
        .filter(Depense.actif.is_(True))
        .scalar()
    )

    return round(float(total or 0), 2)


def get_total_depenses_ht(
    db: Session,
):
    total = (
        db.query(func.coalesce(func.sum(Depense.montant_ht), 0))
        .filter(Depense.actif.is_(True))
        .scalar()
    )

    return round(float(total or 0), 2)


def get_total_tva_depenses(
    db: Session,
):
    total = (
        db.query(func.coalesce(func.sum(Depense.montant_tva), 0))
        .filter(Depense.actif.is_(True))
        .scalar()
    )

    return round(float(total or 0), 2)


def get_depenses_par_categorie(
    db: Session,
):
    results = (
        db.query(
            Depense.categorie,
            func.sum(Depense.montant_ttc).label("total"),
        )
        .filter(Depense.actif.is_(True))
        .group_by(Depense.categorie)
        .order_by(func.sum(Depense.montant_ttc).desc())
        .all()
    )

    return [
        {
            "categorie": categorie,
            "total": round(float(total or 0), 2),
        }
        for categorie, total in results
    ]

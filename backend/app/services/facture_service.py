from datetime import datetime
from fastapi import HTTPException

from sqlalchemy.orm import Session
from app.models.client import Client
from app.models.dossier import Dossier

from app.models.facture import Facture
from app.schemas.facture import FactureCreate, FactureUpdate



def calculate_amounts(montant_ht: float, taux_tva: float):
    montant_tva = montant_ht * taux_tva / 100
    montant_ttc = montant_ht + montant_tva

    return round(montant_tva, 2), round(montant_ttc, 2)


def generate_facture_numero(db: Session) -> str:
    """Génère automatiquement le numéro de facture."""
    year = datetime.utcnow().year
    prefix = f"SS CONSULTING FAC {year}-"

    last_facture = (
        db.query(Facture)
        .filter(Facture.numero.like(f"{prefix}%"))
        .order_by(Facture.id.desc())
        .first()
    )

    if last_facture is None:
        numero = 1
    else:
        try:
            numero = int(last_facture.numero.split("-")[-1]) + 1
        except (ValueError, IndexError):
            numero = last_facture.id + 1

    return f"{prefix}{numero:05d}"


def get_factures(
    db: Session,
    skip: int = 0,
    limit: int = 100,
    client_id: int | None = None,
):
    query = db.query(Facture).filter(Facture.actif.is_(True))

    if client_id is not None:
        query = query.filter(Facture.client_id == client_id)

    return (
        query
        .order_by(Facture.id.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )


def get_facture(db: Session, facture_id: int):
    return (
        db.query(Facture)
        .filter(
            Facture.id == facture_id,
            Facture.actif.is_(True),
        )
        .first()
    )


def get_facture_by_numero(db: Session, numero: str):
    return (
        db.query(Facture)
        .filter(Facture.numero == numero)
        .first()
    )


def create_facture(db: Session, data: FactureCreate):
    # Vérifier que le client existe
    client = (
        db.query(Client)
        .filter(Client.id == data.client_id)
        .first()
    )

    if client is None:
        raise HTTPException(
            status_code=404,
            detail="Client introuvable",
        )

    # Vérifier le dossier s'il est fourni
    if data.dossier_id is not None:
        dossier = (
            db.query(Dossier)
            .filter(Dossier.id == data.dossier_id)
            .first()
        )

        if dossier is None:
            raise HTTPException(
                status_code=404,
                detail="Dossier introuvable",
            )

        # Le dossier doit appartenir au même client
        if dossier.client_id != data.client_id:
            raise HTTPException(
                status_code=400,
                detail="Le dossier sélectionné n'appartient pas à ce client.",
            )

    montant_tva, montant_ttc = calculate_amounts(
        data.montant_ht,
        data.taux_tva,
    )

    numero = data.numero or generate_facture_numero(db)

    facture = Facture(
        numero=numero,
        client_id=data.client_id,
        dossier_id=data.dossier_id,
        date_emission=data.date_emission or datetime.utcnow(),
        date_echeance=data.date_echeance,
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
        statut=data.statut,
        mode_paiement=data.mode_paiement,
        notes=data.notes,
        actif=True,
    )

    db.add(facture)
    db.commit()
    db.refresh(facture)

    return facture

def update_facture(
    db: Session,
    facture: Facture,
    data: FactureUpdate,
):
    values = data.model_dump(exclude_unset=True)

    for key, value in values.items():
        setattr(facture, key, value)

    if "montant_ht" in values or "taux_tva" in values:
        montant_ht = facture.montant_ht
        taux_tva = facture.taux_tva

        montant_tva, montant_ttc = calculate_amounts(
            montant_ht,
            taux_tva,
        )

        facture.montant_tva = montant_tva
        facture.montant_ttc = montant_ttc

    facture.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(facture)

    return facture


def delete_facture(db: Session, facture: Facture):
    facture.actif = False
    facture.updated_at = datetime.utcnow()

    db.commit()

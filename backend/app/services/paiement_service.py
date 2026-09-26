import math
from datetime import datetime

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.facture import Facture
from app.models.paiement import Paiement
from app.schemas.paiement import PaiementCreate, PaiementUpdate
from app.services.notification_service import create_notification


# ============================================================
# CALCULS
# ============================================================

def calculate_commission(montant: float, taux: float = 2.0):
    commission = round(montant * taux / 100, 2)
    total = round(montant + commission, 2)
    return commission, total


def commission_fapshi(montant: float, taux: float):
    """Commission payée par le client en plus de la facture, en FCFA entiers
    (Fapshi n'accepte pas de décimales) et arrondie au-dessus pour ne jamais
    percevoir moins que le taux prévu."""
    commission = math.ceil(montant * taux / 100)
    return float(commission), float(montant + commission)




def get_total_paye(db: Session, facture_id: int) -> float:
    paiements = (
        db.query(Paiement)
        .filter(
            Paiement.facture_id == facture_id,
            Paiement.actif.is_(True),
            Paiement.statut == "Validé",
        )
        .all()
    )

    return round(sum(p.montant for p in paiements), 2)


def get_total_frais(db: Session, facture_id: int) -> float:
    paiements = (
        db.query(Paiement)
        .filter(
            Paiement.facture_id == facture_id,
            Paiement.actif.is_(True),
            Paiement.statut == "Validé",
        )
        .all()
    )

    return round(sum(p.frais or 0 for p in paiements), 2)


def get_reste_a_payer(db: Session, facture: Facture) -> float:
    total_paye = get_total_paye(db, facture.id)

    return round(
        max(0, facture.montant_ttc - total_paye),
        2,
    )


# ============================================================
# STATUT FACTURE
# ============================================================

def update_facture_statut(
    db: Session,
    facture: Facture,
) -> None:

    total_paye = get_total_paye(
        db,
        facture.id,
    )

    if total_paye <= 0:
        facture.statut = "Brouillon"

    elif total_paye < facture.montant_ttc:
        facture.statut = "Partiellement payée"

    else:
        facture.statut = "Payée"

    facture.updated_at = datetime.utcnow()


# ============================================================
# LISTE
# ============================================================

def get_paiements(
    db: Session,
    facture_id: int | None = None,
    client_id: int | None = None,
):

    query = (
        db.query(Paiement)
        .filter(Paiement.actif.is_(True))
    )

    if facture_id is not None:
        query = query.filter(
            Paiement.facture_id == facture_id
        )

    if client_id is not None:
        query = query.join(Facture).filter(
            Facture.client_id == client_id
        )

    return (
        query
        .order_by(Paiement.id.desc())
        .all()
    )


# ============================================================
# DETAIL
# ============================================================

def get_paiement(
    db: Session,
    paiement_id: int,
):

    return (
        db.query(Paiement)
        .filter(
            Paiement.id == paiement_id,
            Paiement.actif.is_(True),
        )
        .first()
    )


# ============================================================
# CREATION
# ============================================================

def create_paiement(
    db: Session,
    data: PaiementCreate,
    utilisateur_id: int,
):

    facture = (
        db.query(Facture)
        .filter(
            Facture.id == data.facture_id,
        )
        .first()
    )

    if facture is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Facture introuvable",
        )

    if not facture.actif:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cette facture est inactive",
        )

    # --------------------------------------------------------
    # VALIDATION OPERATEUR
    # --------------------------------------------------------

    operateur = data.operateur

    if operateur:
        operateur = operateur.strip()

        operateurs_autorises = {
            "Orange Money",
            "MTN MoMo",
            "Orange",
            "MTN",
        }

        if (
            data.mode_paiement in {
                "Orange Money",
                "MTN MoMo",
            }
            and operateur not in operateurs_autorises
        ):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Opérateur de paiement invalide",
            )

    # --------------------------------------------------------
    # VERIFICATION DU RESTE
    # --------------------------------------------------------

    # Un paiement en attente ne réduit pas le solde.
    if data.statut == "Validé":

        reste = get_reste_a_payer(
            db,
            facture,
        )

        if data.montant > reste:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Le montant du paiement "
                    f"({data.montant:.0f} FCFA) "
                    f"dépasse le reste à payer "
                    f"({reste:.0f} FCFA)"
                ),
            )

    # --------------------------------------------------------
    # CREATION
    # --------------------------------------------------------

    taux_commission = 2.0
    montant_commission, montant_total = calculate_commission(
        data.montant,
        taux_commission,
    )


    paiement = Paiement(
        facture_id=data.facture_id,
        montant=data.montant,
        taux_commission=taux_commission,
        montant_commission=montant_commission,
        montant_total=montant_total,


        mode_paiement=data.mode_paiement,
        operateur=data.operateur,
        transaction_id=data.transaction_id,
        numero_client=data.numero_client,
        frais=data.frais,
        reference=data.reference,
        date_paiement=(
            data.date_paiement
            or datetime.utcnow()
        ),
        statut=data.statut,
        notes=data.notes,
        actif=True,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )

    db.add(paiement)

    db.flush()

    # --------------------------------------------------------
    # MISE A JOUR FACTURE
    # --------------------------------------------------------

    if data.statut == "Validé":
        update_facture_statut(
            db,
            facture,
        )

    db.commit()

    db.refresh(paiement)

    # --------------------------------------------------------
    # NOTIFICATIONS
    # --------------------------------------------------------

    if paiement.statut == "Validé":

        create_notification(
            db=db,
            utilisateur_id=utilisateur_id,
            type="PAIEMENT_RECU",
            titre="Paiement reçu",
            message=(
                f"Un paiement de {paiement.montant:.0f} FCFA "
                f"a été enregistré pour la facture "
                f"{facture.numero}."
            ),
            reference_type="paiement",
            reference_id=paiement.id,
        )

        if facture.statut == "Payée":
            create_notification(
                db=db,
                utilisateur_id=utilisateur_id,
                type="PAIEMENT_COMPLET",
                titre="Paiement complet",
                message=(
                    f"La facture {facture.numero} "
                    f"est maintenant entièrement payée."
                ),
                reference_type="facture",
                reference_id=facture.id,
            )

    return paiement


# ============================================================
# MODIFICATION
# ============================================================

def update_paiement(
    db: Session,
    paiement: Paiement,
    data: PaiementUpdate,
):

    facture = (
        db.query(Facture)
        .filter(
            Facture.id == paiement.facture_id,
        )
        .first()
    )

    if facture is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Facture introuvable",
        )

    # --------------------------------------------------------
    # NOUVELLES VALEURS
    # --------------------------------------------------------

    nouveau_montant = (
        data.montant
        if data.montant is not None
        else paiement.montant
    )

    nouveau_statut = (
        data.statut
        if data.statut is not None
        else paiement.statut
    )

    # --------------------------------------------------------
    # VERIFICATION DU MONTANT
    # --------------------------------------------------------

    if nouveau_statut == "Validé":

        autres_paiements = (
            db.query(Paiement)
            .filter(
                Paiement.facture_id == facture.id,
                Paiement.id != paiement.id,
                Paiement.actif.is_(True),
                Paiement.statut == "Validé",
            )
            .all()
        )

        total_autres = sum(
            p.montant
            for p in autres_paiements
        )

        reste_disponible = round(
            max(0, facture.montant_ttc - total_autres),
            2,
        )

        if nouveau_montant > reste_disponible:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Le nouveau montant "
                    f"({nouveau_montant:.0f} FCFA) "
                    f"dépasse le reste à payer "
                    f"({reste_disponible:.0f} FCFA)"
                ),
            )

    # --------------------------------------------------------
    # APPLICATION DES MODIFICATIONS
    # --------------------------------------------------------

    if data.montant is not None:
        paiement.montant = data.montant

    if data.mode_paiement is not None:
        paiement.mode_paiement = data.mode_paiement

    if data.operateur is not None:
        paiement.operateur = data.operateur

    if data.transaction_id is not None:
        paiement.transaction_id = data.transaction_id

    if data.numero_client is not None:
        paiement.numero_client = data.numero_client

    if data.frais is not None:
        paiement.frais = data.frais

    if data.reference is not None:
        paiement.reference = data.reference

    if data.date_paiement is not None:
        paiement.date_paiement = data.date_paiement

    if data.statut is not None:
        paiement.statut = data.statut

    if data.notes is not None:
        paiement.notes = data.notes

    # --------------------------------------------------------
    # RECALCUL COMMISSION
    # --------------------------------------------------------

    commission, total = calculate_commission(
        paiement.montant,
        paiement.taux_commission,
    )

    paiement.montant_commission = commission
    paiement.montant_total = total

    paiement.updated_at = datetime.utcnow()

    # --------------------------------------------------------
    # MISE A JOUR DU STATUT DE LA FACTURE
    # --------------------------------------------------------

    update_facture_statut(
        db,
        facture,
    )

    db.commit()

    db.refresh(paiement)

    return paiement


# ============================================================
# SUPPRESSION LOGIQUE
# ============================================================

def delete_paiement(
    db: Session,
    paiement: Paiement,
):

    facture = (
        db.query(Facture)
        .filter(
            Facture.id == paiement.facture_id,
        )
        .first()
    )

    paiement.actif = False
    paiement.updated_at = datetime.utcnow()

    if facture:
        update_facture_statut(
            db,
            facture,
        )

    db.commit()


# ============================================================
# RESUME FACTURE
# ============================================================

def get_resume_facture(
    db: Session,
    facture: Facture,
):

    total_paye = get_total_paye(
        db,
        facture.id,
    )

    total_frais = get_total_frais(
        db,
        facture.id,
    )

    reste = get_reste_a_payer(
        db,
        facture,
    )

    return {
        "facture_id": facture.id,
        "numero": facture.numero,
        "montant_ttc": facture.montant_ttc,
        "total_paye": total_paye,
        "total_frais": total_frais,
        "reste_a_payer": reste,
        "statut": facture.statut,
    }

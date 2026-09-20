import re

from fastapi import APIRouter, Depends, HTTPException, Request, status, Query
from datetime import datetime
from uuid import uuid4

from app.schemas.fapshi import (
    FapshiInitRequest,
    FapshiInitResponse,
    FapshiStatutResponse,
)
from app.services.fapshi_service import fapshi_service
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.dependencies import get_current_user, require_roles
from app.core.database import get_db
from app.models.user import User
from app.models.facture import Facture
from app.models.paiement import Paiement
from app.schemas.paiement import (
    PaiementCreate,
    PaiementUpdate,
    PaiementResponse,
)
from app.services.paiement_service import (
    get_paiements,
    get_paiement,
    create_paiement,
    update_paiement,
    delete_paiement,
    get_total_paye,
    get_reste_a_payer,
    calculate_commission,
    update_facture_statut,
)


def ensure_paiement_access(current_user: User, paiement):
    facture = paiement.facture

    if current_user.role_id == 6:
        if current_user.client_id is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Votre compte Client n'est associé à aucun client.",
            )

        if facture is None or facture.client_id != current_user.client_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Vous n'avez pas accès à ce paiement.",
            )


def ensure_facture_access_for_client(current_user: User, facture):
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

router = APIRouter(
    prefix="/paiements",
    tags=["Paiements"],
)


@router.get(
    "",
    response_model=list[PaiementResponse],
)
def list_paiements(
    facture_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role_id == 6:
        if current_user.client_id is None:
            return []

        return get_paiements(
            db,
            facture_id=facture_id,
            client_id=current_user.client_id,
        )

    if current_user.role_id not in (1, 2, 3, 5):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous n'avez pas les permissions nécessaires",
        )

    return get_paiements(db, facture_id)


@router.get(
    "/{paiement_id}",
    response_model=PaiementResponse,
)
def read_paiement(
    paiement_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    paiement = get_paiement(db, paiement_id)

    if paiement is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paiement introuvable",
        )

    ensure_paiement_access(current_user, paiement)

    return paiement


@router.post(
    "",
    response_model=PaiementResponse,
    status_code=status.HTTP_201_CREATED,
)
def create(
    data: PaiementCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 5)),
):
    return create_paiement(
        db,
        data,
        current_user.id,
    )


@router.put(
    "/{paiement_id}",
    response_model=PaiementResponse,
)
def update(
    paiement_id: int,
    data: PaiementUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 5)),
):
    paiement = get_paiement(db, paiement_id)

    if paiement is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paiement introuvable",
        )

    return update_paiement(db, paiement, data)


@router.delete(
    "/{paiement_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def delete(
    paiement_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 5)),
):
    paiement = get_paiement(db, paiement_id)

    if paiement is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paiement introuvable",
        )

    delete_paiement(db, paiement)


@router.get(
    "/facture/{facture_id}/resume",
)
def resume_facture(
    facture_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    facture = (
        db.query(Facture)
        .filter(Facture.id == facture_id)
        .first()
    )

    if facture is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Facture introuvable",
        )

    total_paye = get_total_paye(db, facture_id)
    reste = get_reste_a_payer(db, facture)

    return {
        "facture_id": facture.id,
        "numero": facture.numero,
        "montant_ttc": facture.montant_ttc,
        "total_paye": total_paye,
        "reste_a_payer": reste,
        "statut": facture.statut,
    }


# ============================================================
# PAIEMENT MOBILE
# ============================================================

@router.post(
    "/mobile/initier",
    response_model=PaiementResponse,
    status_code=status.HTTP_201_CREATED,
)
def initier_paiement_mobile(
    data: PaiementCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if data.mode_paiement not in {
        "Orange Money",
        "MTN MoMo",
    }:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Le mode de paiement doit être "
                "Orange Money ou MTN MoMo"
            ),
        )

    facture = (
        db.query(Facture)
        .filter(Facture.id == data.facture_id)
        .first()
    )

    if facture is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Facture introuvable",
        )

    ensure_facture_access_for_client(current_user, facture)

    data.statut = "En attente"

    return create_paiement(
        db,
        data,
        current_user.id,
    )


@router.post(
    "/mobile/{paiement_id}/confirmer",
    response_model=PaiementResponse,
)
def confirmer_paiement_mobile(
    paiement_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    paiement = get_paiement(
        db,
        paiement_id,
    )

    if paiement is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paiement introuvable",
        )

    if paiement.mode_paiement not in {
        "Orange Money",
        "MTN MoMo",
    }:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ce paiement n'est pas un paiement mobile",
        )

    if paiement.statut == "Validé":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ce paiement est déjà validé",
        )

    ensure_paiement_access(current_user, paiement)

    paiement.statut = "Validé"
    paiement.updated_at = datetime.utcnow()

    facture = (
        db.query(Facture)
        .filter(
            Facture.id == paiement.facture_id,
        )
        .first()
    )

    if facture:
        from app.services.paiement_service import (
            update_facture_statut,
        )

        update_facture_statut(
            db,
            facture,
        )

    db.commit()
    db.refresh(paiement)

    return paiement


# ============================================================
# FAPSHI
# ============================================================

@router.post(
    "/fapshi/initier",
    response_model=FapshiInitResponse,
    status_code=status.HTTP_201_CREATED,
)
async def initier_paiement_fapshi(
    data: FapshiInitRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # --------------------------------------------------------
    # FACTURE
    # --------------------------------------------------------

    facture = (
        db.query(Facture)
        .filter(
            Facture.id == data.facture_id,
            Facture.actif.is_(True),
        )
        .first()
    )

    if facture is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Facture introuvable ou inactive.",
        )

    # --------------------------------------------------------
    # ACCES CLIENT
    # --------------------------------------------------------

    ensure_facture_access_for_client(
        current_user,
        facture,
    )

    # --------------------------------------------------------
    # CLIENT
    # --------------------------------------------------------

    client = facture.client

    if client is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Aucun client associé à cette facture.",
        )

    # --------------------------------------------------------
    # RESTE A PAYER
    # --------------------------------------------------------

    reste = get_reste_a_payer(
        db,
        facture,
    )

    if reste <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cette facture est déjà entièrement payée.",
        )

    if data.montant > reste:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Le montant demandé ({data.montant:.0f} FCFA) "
                f"dépasse le reste à payer "
                f"({reste:.0f} FCFA)."
            ),
        )

    # --------------------------------------------------------
    # REFERENCE UNIQUE
    # --------------------------------------------------------

    numero_clean = re.sub(r"[^A-Za-z0-9]+", "", facture.numero)

    reference = (
        f"SS-{numero_clean}-"
        f"{uuid4().hex[:12].upper()}"
    )

    # --------------------------------------------------------
    # INITIALISATION FAPSHI
    # --------------------------------------------------------

    fapshi_response = await fapshi_service.initiate_payment(
        amount=data.montant,
        external_id=reference,
        email=client.email,
        redirect_url=settings.FAPSHI_REDIRECT_URL or None,
        message=f"Facture {facture.numero}",
    )

    payment_link = fapshi_response.get("link")

    if not payment_link:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={
                "message": (
                    "Fapshi a répondu mais "
                    "aucun lien de paiement n'a été trouvé."
                ),
                "response": fapshi_response,
            },
        )

    # --------------------------------------------------------
    # CREATION PAIEMENT LOCAL
    # --------------------------------------------------------

    taux_commission = 2.0

    montant_commission, montant_total = (
        calculate_commission(
            data.montant,
            taux_commission,
        )
    )

    paiement = Paiement(
        facture_id=facture.id,
        montant=data.montant,
        taux_commission=taux_commission,
        montant_commission=montant_commission,
        montant_total=montant_total,
        mode_paiement="Fapshi",
        operateur=None,
        transaction_id=fapshi_response.get("transId"),
        numero_client=client.telephone,
        frais=0,
        reference=reference,
        date_paiement=datetime.utcnow(),
        statut="En attente",
        notes="Paiement initié via Fapshi.",
        actif=True,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )

    db.add(paiement)
    db.commit()
    db.refresh(paiement)

    return FapshiInitResponse(
        paiement_id=paiement.id,
        facture_id=facture.id,
        reference=reference,
        montant=data.montant,
        statut=paiement.statut,
        payment_link=payment_link,
    )


@router.get(
    "/fapshi/{paiement_id}/statut",
    response_model=FapshiStatutResponse,
)
async def verifier_statut_fapshi(
    paiement_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Interroge directement l'API Fapshi pour connaître l'état réel d'un
    paiement et met à jour l'enregistrement local en conséquence.

    Sert de filet de sécurité (et d'outil de test en développement, où
    le webhook Fapshi ne peut pas atteindre la machine locale) : le
    webhook POST reste la source d'autorité en production, mais ce
    endpoint permet à l'admin ou au client de rafraîchir manuellement
    le statut affiché sans attendre.
    """

    paiement = get_paiement(db, paiement_id)

    if paiement is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paiement introuvable",
        )

    ensure_paiement_access(current_user, paiement)

    if paiement.mode_paiement != "Fapshi":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ce paiement n'est pas un paiement Fapshi.",
        )

    if not paiement.transaction_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Aucun identifiant de transaction Fapshi pour ce paiement.",
        )

    fapshi_data = await fapshi_service.get_payment_status(
        paiement.transaction_id,
    )

    fapshi_status = fapshi_data.get("status", "")

    if fapshi_status == "SUCCESSFUL" and paiement.statut != "Validé":
        paiement.statut = "Validé"
        paiement.updated_at = datetime.utcnow()

        facture = (
            db.query(Facture)
            .filter(Facture.id == paiement.facture_id)
            .first()
        )

        if facture:
            update_facture_statut(db, facture)

        db.commit()
        db.refresh(paiement)

    elif fapshi_status == "FAILED" and paiement.statut not in {"Validé", "Échec"}:
        paiement.statut = "Échec"
        paiement.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(paiement)

    elif fapshi_status == "EXPIRED" and paiement.statut not in {"Validé", "Expiré"}:
        paiement.statut = "Expiré"
        paiement.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(paiement)

    return FapshiStatutResponse(
        paiement_id=paiement.id,
        facture_id=paiement.facture_id,
        reference=paiement.reference or "",
        statut=paiement.statut,
        fapshi_status=fapshi_status,
    )


@router.post(
    "/fapshi/webhook",
)
async def fapshi_webhook(
    request: Request,
    db: Session = Depends(get_db),
):
    """
    Webhook serveur-à-serveur Fapshi : seule source d'autorité pour
    valider un paiement en production. Authentifié par correspondance
    exacte du secret configuré sur le tableau de bord Fapshi (en-tête
    x-wh-secret), pas par signature HMAC du corps.
    """

    secret_header = request.headers.get("x-wh-secret")

    if not fapshi_service.verify_webhook_secret(secret_header):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Secret Fapshi invalide.",
        )

    try:
        event = await request.json()
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payload JSON invalide.",
        )

    external_id = event.get("externalId")
    trans_id = event.get("transId")
    fapshi_status = event.get("status")
    fapshi_amount = event.get("amount")

    if not external_id:
        return {
            "status": "ignored",
            "message": "Aucun externalId dans le payload.",
        }

    paiement = (
        db.query(Paiement)
        .filter(
            Paiement.reference == external_id,
            Paiement.actif.is_(True),
        )
        .first()
    )

    if paiement is None:
        return {
            "status": "ignored",
            "message": "Paiement SS Consulting introuvable.",
            "external_id": external_id,
        }

    if (
        fapshi_status == "SUCCESSFUL"
        and paiement.statut == "Validé"
    ):
        return {
            "status": "already_processed",
            "paiement_id": paiement.id,
        }

    if trans_id:
        paiement.transaction_id = str(trans_id)[:100]

    paiement.updated_at = datetime.utcnow()

    if fapshi_status == "SUCCESSFUL":

        if fapshi_amount is not None:
            try:
                fapshi_amount = float(fapshi_amount)
            except (TypeError, ValueError):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Montant Fapshi invalide.",
                )

            if round(fapshi_amount, 2) != round(paiement.montant, 2):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail={
                        "message": "Le montant Fapshi ne correspond pas au paiement.",
                        "montant_attendu": paiement.montant,
                        "montant_recu": fapshi_amount,
                    },
                )

        paiement.statut = "Validé"

        facture = (
            db.query(Facture)
            .filter(
                Facture.id == paiement.facture_id,
            )
            .first()
        )

        if facture:
            update_facture_statut(
                db,
                facture,
            )

    elif fapshi_status == "FAILED":

        paiement.statut = "Échec"

    elif fapshi_status == "EXPIRED":

        paiement.statut = "Expiré"

    else:
        db.commit()

        return {
            "status": "ignored",
            "fapshi_status": fapshi_status,
        }

    db.commit()
    db.refresh(paiement)

    return {
        "status": "success",
        "fapshi_status": fapshi_status,
        "paiement_id": paiement.id,
        "reference": paiement.reference,
        "statut": paiement.statut,
    }

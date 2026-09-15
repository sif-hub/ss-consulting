from fastapi import APIRouter, Depends, HTTPException, status, Query
from datetime import datetime
from uuid import uuid4

from app.schemas.notchpay import NotchPayInitRequest, NotchPayInitResponse
from app.services.notchpay_service import notchpay_service
from sqlalchemy.orm import Session

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
    current_user: User = Depends(require_roles(1, 2, 3, 5)),
):
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
# NOTCH PAY
# ============================================================

@router.post(
    "/notchpay/initier",
    response_model=NotchPayInitResponse,
    status_code=status.HTTP_201_CREATED,
)
async def initier_paiement_notchpay(
    data: NotchPayInitRequest,
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

    if not client.email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Le client doit avoir une adresse e-mail "
                "pour effectuer un paiement Notch Pay."
            ),
        )

    if not client.telephone:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Le client doit avoir un numéro de téléphone "
                "pour effectuer un paiement Notch Pay."
            ),
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

    reference = (
        f"SS-{facture.numero}-"
        f"{uuid4().hex[:12].upper()}"
    )

    # --------------------------------------------------------
    # INITIALISATION NOTCH PAY
    # --------------------------------------------------------

    notchpay_response = await notchpay_service.create_payment(
        amount=data.montant,
        currency="XAF",
        email=client.email,
        phone=client.telephone,
        reference=reference,
    )

    authorization_url = (
        notchpay_service.extract_authorization_url(
            notchpay_response
        )
    )

    if not authorization_url:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={
                "message": (
                    "Notch Pay a répondu mais "
                    "aucune URL de paiement n'a été trouvée."
                ),
                "response": notchpay_response,
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
        mode_paiement="Notch Pay",
        operateur=None,
        transaction_id=None,
        numero_client=client.telephone,
        frais=0,
        reference=reference,
        date_paiement=datetime.utcnow(),
        statut="En attente",
        notes="Paiement initié via Notch Pay.",
        actif=True,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )

    db.add(paiement)
    db.commit()
    db.refresh(paiement)

    return NotchPayInitResponse(
        paiement_id=paiement.id,
        facture_id=facture.id,
        reference=reference,
        montant=data.montant,
        statut=paiement.statut,
        authorization_url=authorization_url,
    )


# ============================================================
# NOTCH PAY WEBHOOK
# ============================================================

from fastapi import Request


@router.get(
    "/notchpay/webhook",
)
async def notchpay_webhook_callback(
    reference: str | None = None,
    trxref: str | None = None,
    notchpay_trxref: str | None = None,
    status_callback: str | None = Query(default=None, alias="status"),
    db: Session = Depends(get_db),
):
    """
    Callback GET de redirection Notch Pay (retour navigateur du client
    après paiement).

    Ce endpoint est purement informatif : il ne fait QUE lire le statut
    déjà enregistré en base. Le paramètre `status` fourni ici vient du
    navigateur du client et n'est donc pas fiable — il ne doit jamais
    servir à valider un paiement ou une facture. Seul le webhook POST,
    signé HMAC (`/notchpay/webhook`), a l'autorité pour faire cette mise
    à jour.
    """

    payment_reference = (
        reference
        or trxref
        or notchpay_trxref
    )

    if not payment_reference:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Référence Notch Pay absente.",
        )

    paiement = (
        db.query(Paiement)
        .filter(
            Paiement.reference == payment_reference,
            Paiement.actif.is_(True),
        )
        .first()
    )

    if paiement is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paiement SS Consulting introuvable.",
        )

    return {
        "status": "received",
        "message": (
            "Statut réel du paiement (confirmé uniquement par le "
            "webhook Notch Pay signé)."
        ),
        "paiement_id": paiement.id,
        "facture_id": paiement.facture_id,
        "reference": paiement.reference,
        "statut": paiement.statut,
        "callback_status": status_callback,
    }


@router.post(
    "/notchpay/webhook",
)
async def notchpay_webhook(
    request: Request,
    db: Session = Depends(get_db),
):
    # --------------------------------------------------------
    # PAYLOAD BRUT
    # --------------------------------------------------------

    payload = await request.body()

    # --------------------------------------------------------
    # SIGNATURE
    # --------------------------------------------------------

    signature = request.headers.get(
        "x-notch-signature"
    )

    if not signature:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Signature Notch Pay absente.",
        )

    # --------------------------------------------------------
    # VERIFICATION HMAC
    # --------------------------------------------------------

    if not notchpay_service.verify_webhook_signature(
        payload,
        signature,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Signature Notch Pay invalide.",
        )

    # --------------------------------------------------------
    # JSON
    # --------------------------------------------------------

    try:
        event = await request.json()
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payload JSON invalide.",
        )

    event_type = event.get("type")

    payment_data = event.get("data") or {}

    reference = payment_data.get("reference")

    transaction_id = payment_data.get("id")

    notchpay_amount = payment_data.get("amount")

    # --------------------------------------------------------
    # REFERENCE OBLIGATOIRE
    # --------------------------------------------------------

    if not reference:
        return {
            "status": "ignored",
            "message": "Aucune référence de paiement.",
        }

    # --------------------------------------------------------
    # RECHERCHE DU PAIEMENT
    # --------------------------------------------------------

    paiement = (
        db.query(Paiement)
        .filter(
            Paiement.reference == reference,
            Paiement.actif.is_(True),
        )
        .first()
    )

    if paiement is None:
        return {
            "status": "ignored",
            "message": "Paiement SS Consulting introuvable.",
            "reference": reference,
        }

    # --------------------------------------------------------
    # IDEMPOTENCE
    # --------------------------------------------------------

    if (
        event_type == "payment.complete"
        and paiement.statut == "Validé"
    ):
        return {
            "status": "already_processed",
            "paiement_id": paiement.id,
        }

    # --------------------------------------------------------
    # TRANSACTION NOTCH PAY
    # --------------------------------------------------------

    if transaction_id:
        paiement.transaction_id = str(
            transaction_id
        )[:100]

    paiement.updated_at = datetime.utcnow()

    # --------------------------------------------------------
    # EVENEMENTS
    # --------------------------------------------------------

    if event_type == "payment.complete":

        if notchpay_amount is not None:
            try:
                notchpay_amount = float(notchpay_amount)
            except (TypeError, ValueError):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Montant Notch Pay invalide.",
                )

            if round(notchpay_amount, 2) != round(paiement.montant, 2):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail={
                        "message": "Le montant Notch Pay ne correspond pas au paiement.",
                        "montant_attendu": paiement.montant,
                        "montant_recu": notchpay_amount,
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

    elif event_type == "payment.failed":

        paiement.statut = "Échec"

    elif event_type == "payment.canceled":

        paiement.statut = "Annulé"

    elif event_type == "payment.expired":

        paiement.statut = "Expiré"

    else:
        db.commit()

        return {
            "status": "ignored",
            "event": event_type,
        }

    db.commit()
    db.refresh(paiement)

    return {
        "status": "success",
        "event": event_type,
        "paiement_id": paiement.id,
        "reference": paiement.reference,
        "statut": paiement.statut,
    }

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_roles
from app.models.user import User
from app.services.pdf_service import (
    generer_facture_pdf,
    generer_recu_paiement_pdf,
    generer_depense_pdf,
    generer_client_pdf,
    generer_dossier_pdf,
    generer_comptabilite_pdf,
    generer_dsf_pdf,
)


router = APIRouter(
    prefix="/pdf",
    tags=["PDF"],
)


@router.get("/factures/{facture_id}")
def facture_pdf(
    facture_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):

    try:
        pdf = generer_facture_pdf(
            db,
            facture_id,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=404,
            detail=str(e),
        )

    return StreamingResponse(
        pdf,
        media_type="application/pdf",
        headers={
            "Content-Disposition": (
                f'inline; filename="facture-{facture_id}.pdf"'
            )
        },
    )


@router.get("/paiements/{paiement_id}")
def paiement_pdf(
    paiement_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):

    try:
        pdf = generer_recu_paiement_pdf(
            db,
            paiement_id,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=404,
            detail=str(e),
        )

    return StreamingResponse(
        pdf,
        media_type="application/pdf",
        headers={
            "Content-Disposition": (
                f'inline; filename="recu-paiement-{paiement_id}.pdf"'
            )
        },
    )


# ============================================================
# DEPENSE
# ============================================================

@router.get("/depenses/{depense_id}")
def depense_pdf(
    depense_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):

    try:
        pdf = generer_depense_pdf(db, depense_id)

    except ValueError as e:
        raise HTTPException(
            status_code=404,
            detail=str(e),
        )

    return StreamingResponse(
        pdf,
        media_type="application/pdf",
        headers={
            "Content-Disposition":
                f'inline; filename="depense-{depense_id}.pdf"'
        },
    )


# ============================================================
# CLIENT
# ============================================================

@router.get("/clients/{client_id}")
def client_pdf(
    client_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):

    try:
        pdf = generer_client_pdf(db, client_id)

    except ValueError as e:
        raise HTTPException(
            status_code=404,
            detail=str(e),
        )

    return StreamingResponse(
        pdf,
        media_type="application/pdf",
        headers={
            "Content-Disposition":
                f'inline; filename="client-{client_id}.pdf"'
        },
    )


# ============================================================
# DOSSIER
# ============================================================

@router.get("/dossiers/{dossier_id}")
def dossier_pdf(
    dossier_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):

    try:
        pdf = generer_dossier_pdf(db, dossier_id)

    except ValueError as e:
        raise HTTPException(
            status_code=404,
            detail=str(e),
        )

    return StreamingResponse(
        pdf,
        media_type="application/pdf",
        headers={
            "Content-Disposition":
                f'inline; filename="dossier-{dossier_id}.pdf"'
        },
    )


# ============================================================
# COMPTABILITE
# ============================================================

@router.get("/comptabilite")
def comptabilite_pdf(
    annee: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):

    try:
        pdf = generer_comptabilite_pdf(
            db,
            annee,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        )

    return StreamingResponse(
        pdf,
        media_type="application/pdf",
        headers={
            "Content-Disposition":
                f'inline; filename="rapport-comptable-{annee}.pdf"'
        },
    )


# ============================================================
# DSF (DÉCLARATION STATISTIQUE ET FISCALE)
# ============================================================

@router.get("/dsf/{client_id}")
def dsf_pdf(
    client_id: int,
    annee: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 4, 5)),
):

    try:
        pdf = generer_dsf_pdf(
            db,
            client_id,
            annee,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=404,
            detail=str(e),
        )

    return StreamingResponse(
        pdf,
        media_type="application/pdf",
        headers={
            "Content-Disposition":
                f'inline; filename="dsf-client-{client_id}-{annee}.pdf"'
        },
    )

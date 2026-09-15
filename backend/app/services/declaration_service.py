from datetime import datetime

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.client import Client
from app.models.notification import Notification
from app.models.declaration import Declaration
from app.models.user import User


STATUTS = {
    "BROUILLON",
    "SOUMISE",
    "EN_VERIFICATION",
    "VALIDEE",
    "A_CORRIGER",
    "REJETEE",
}


def get_declaration(
    db: Session,
    declaration_id: int,
) -> Declaration:
    declaration = (
        db.query(Declaration)
        .filter(Declaration.id == declaration_id)
        .first()
    )

    if declaration is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Déclaration introuvable",
        )

    return declaration


def get_client(
    db: Session,
    client_id: int,
) -> Client:
    client = (
        db.query(Client)
        .filter(Client.id == client_id)
        .first()
    )

    if client is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client introuvable",
        )

    return client


def get_declarations(
    db: Session,
    client_id: int | None = None,
    mois: int | None = None,
    annee: int | None = None,
    statut: str | None = None,
):
    query = db.query(Declaration)

    if client_id is not None:
        query = query.filter(
            Declaration.client_id == client_id
        )

    if mois is not None:
        query = query.filter(
            Declaration.mois == mois
        )

    if annee is not None:
        query = query.filter(
            Declaration.annee == annee
        )

    if statut is not None:
        statut = statut.upper()

        if statut not in STATUTS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Statut de déclaration invalide",
            )

        query = query.filter(
            Declaration.statut == statut
        )

    return (
        query
        .order_by(
            Declaration.annee.desc(),
            Declaration.mois.desc(),
            Declaration.id.desc(),
        )
        .all()
    )


def create_declaration(
    db: Session,
    client_id: int,
    mois: int,
    annee: int,
    chiffre_affaires,
    total_ventes,
    total_achats,
    nombre_employes: int,
    observations: str | None = None,
) -> Declaration:

    get_client(db, client_id)

    existing = (
        db.query(Declaration)
        .filter(
            Declaration.client_id == client_id,
            Declaration.mois == mois,
            Declaration.annee == annee,
        )
        .first()
    )

    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "Une déclaration existe déjà pour ce client "
                "et cette période"
            ),
        )

    declaration = Declaration(
        client_id=client_id,
        mois=mois,
        annee=annee,
        chiffre_affaires=chiffre_affaires,
        total_ventes=total_ventes,
        total_achats=total_achats,
        nombre_employes=nombre_employes,
        observations=observations,
        statut="BROUILLON",
        date_creation=datetime.utcnow(),
    )

    db.add(declaration)
    db.commit()
    db.refresh(declaration)

    return declaration


def update_declaration(
    db: Session,
    declaration_id: int,
    mois: int,
    annee: int,
    chiffre_affaires,
    total_ventes,
    total_achats,
    nombre_employes: int,
    observations: str | None = None,
) -> Declaration:

    declaration = get_declaration(
        db,
        declaration_id,
    )

    if declaration.statut not in {
        "BROUILLON",
        "A_CORRIGER",
    }:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Cette déclaration ne peut plus être modifiée "
                "dans son état actuel"
            ),
        )

    duplicate = (
        db.query(Declaration)
        .filter(
            Declaration.client_id == declaration.client_id,
            Declaration.mois == mois,
            Declaration.annee == annee,
            Declaration.id != declaration_id,
        )
        .first()
    )

    if duplicate:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "Une autre déclaration existe déjà "
                "pour cette période"
            ),
        )

    declaration.mois = mois
    declaration.annee = annee
    declaration.chiffre_affaires = chiffre_affaires
    declaration.total_ventes = total_ventes
    declaration.total_achats = total_achats
    declaration.nombre_employes = nombre_employes
    declaration.observations = observations

    # Une correction renvoie la déclaration en brouillon.
    if declaration.statut == "A_CORRIGER":
        declaration.statut = "BROUILLON"
        declaration.commentaire_admin = None
        declaration.date_soumission = None

    db.commit()
    db.refresh(declaration)

    return declaration


def submit_declaration(
    db: Session,
    declaration_id: int,
) -> Declaration:

    declaration = get_declaration(
        db,
        declaration_id,
    )

    if declaration.statut not in {
        "BROUILLON",
        "A_CORRIGER",
    }:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Seule une déclaration en brouillon "
                "peut être soumise"
            ),
        )

    declaration.statut = "SOUMISE"
    declaration.date_soumission = datetime.utcnow()
    declaration.commentaire_admin = None

    # ========================================================
    # NOTIFICATIONS ADMINISTRATEUR + FISCALISTE
    # ========================================================

    destinataires = (
        db.query(User)
        .filter(
            User.role_id.in_([1, 4]),
            User.actif == True,
        )
        .all()
    )

    client = get_client(
        db,
        declaration.client_id,
    )

    client_nom = (
        client.raison_sociale
        or f"{client.prenom or ''} {client.nom}".strip()
    )

    mois_label = [
        "",
        "Janvier",
        "Février",
        "Mars",
        "Avril",
        "Mai",
        "Juin",
        "Juillet",
        "Août",
        "Septembre",
        "Octobre",
        "Novembre",
        "Décembre",
    ][declaration.mois]

    for destinataire in destinataires:
        notification = Notification(
            utilisateur_id=destinataire.id,
            type="DECLARATION_SOUMISE",
            titre="Nouvelle déclaration mensuelle",
            message=(
                f"La déclaration de {client_nom} pour "
                f"{mois_label} {declaration.annee} "
                f"vient d'être soumise et nécessite votre traitement."
            ),
            reference_type="declaration",
            reference_id=declaration.id,
            lu=False,
            actif=True,
        )

        db.add(notification)

    # Déclaration + notifications dans la même transaction.
    db.commit()
    db.refresh(declaration)

    return declaration


def start_review(
    db: Session,
    declaration_id: int,
    current_user_id: int,
) -> Declaration:

    declaration = get_declaration(
        db,
        declaration_id,
    )

    if declaration.statut != "SOUMISE":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Seule une déclaration soumise "
                "peut être mise en vérification"
            ),
        )

    declaration.statut = "EN_VERIFICATION"
    declaration.traite_par_id = current_user_id

    db.commit()
    db.refresh(declaration)

    return declaration


def review_declaration(
    db: Session,
    declaration_id: int,
    statut: str,
    commentaire_admin: str | None,
    current_user: User,
) -> Declaration:

    declaration = get_declaration(
        db,
        declaration_id,
    )

    statut = statut.upper()

    if statut not in {
        "VALIDEE",
        "A_CORRIGER",
        "REJETEE",
    }:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Décision de traitement invalide",
        )

    if declaration.statut not in {
        "SOUMISE",
        "EN_VERIFICATION",
    }:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Cette déclaration ne peut pas "
                "être traitée dans son état actuel"
            ),
        )

    if statut in {"A_CORRIGER", "REJETEE"}:
        if not commentaire_admin or not commentaire_admin.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    "Un commentaire est obligatoire "
                    "pour demander une correction ou rejeter "
                    "une déclaration"
                ),
            )

    declaration.statut = statut
    declaration.commentaire_admin = (
        commentaire_admin.strip()
        if commentaire_admin
        else None
    )
    declaration.traite_par_id = current_user.id

    if statut == "VALIDEE":
        declaration.date_validation = datetime.utcnow()
    else:
        declaration.date_validation = None

    # ========================================================
    # INFORMATIONS DU CLIENT
    # ========================================================

    client = get_client(
        db,
        declaration.client_id,
    )

    client_nom = (
        client.raison_sociale
        or f"{client.prenom or ''} {client.nom or ''}".strip()
    )

    mois_labels = [
        "",
        "Janvier",
        "Février",
        "Mars",
        "Avril",
        "Mai",
        "Juin",
        "Juillet",
        "Août",
        "Septembre",
        "Octobre",
        "Novembre",
        "Décembre",
    ]

    mois_label = mois_labels[declaration.mois]

    # ========================================================
    # NOTIFICATION DU CLIENT
    # ========================================================

    client_users = (
        db.query(User)
        .filter(
            User.client_id == declaration.client_id,
            User.role_id == 6,
            User.actif == True,
        )
        .all()
    )

    if statut == "VALIDEE":
        titre = "Déclaration validée"

        message = (
            f"Votre déclaration de {client_nom} pour "
            f"{mois_label} {declaration.annee} "
            f"a été validée par SS Consulting."
        )

        notification_type = "DECLARATION_VALIDEE"

    elif statut == "REJETEE":
        titre = "Déclaration rejetée"

        message = (
            f"Votre déclaration de {client_nom} pour "
            f"{mois_label} {declaration.annee} "
            f"a été rejetée."
        )

        if declaration.commentaire_admin:
            message += (
                f" Motif : {declaration.commentaire_admin}"
            )

        notification_type = "DECLARATION_REJETEE"

    else:
        titre = "Correction demandée"

        message = (
            f"Votre déclaration de {client_nom} pour "
            f"{mois_label} {declaration.annee} "
            f"nécessite une correction."
        )

        if declaration.commentaire_admin:
            message += (
                f" Commentaire de l'administrateur : "
                f"{declaration.commentaire_admin}"
            )

        notification_type = "DECLARATION_CORRECTION"

    for client_user in client_users:
        notification = Notification(
            utilisateur_id=client_user.id,
            type=notification_type,
            titre=titre,
            message=message,
            reference_type="declaration",
            reference_id=declaration.id,
            lu=False,
            actif=True,
        )

        db.add(notification)

    # ========================================================
    # ENREGISTREMENT
    # ========================================================

    db.commit()
    db.refresh(declaration)

    return declaration


from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.models.notification import Notification
from app.models.user import User
from app.models.facture import Facture
from app.models.tache import Tache


# ============================================================
# CRÉATION
# ============================================================

def create_notification(
    db: Session,
    utilisateur_id: int,
    type: str,
    titre: str,
    message: str,
    reference_type: str | None = None,
    reference_id: int | None = None,
    date_echeance: datetime | None = None,
):
    """
    Crée une notification uniquement si une notification
    identique n'existe pas déjà.
    """

    existing = (
        db.query(Notification)
        .filter(
            Notification.utilisateur_id == utilisateur_id,
            Notification.type == type,
            Notification.reference_type == reference_type,
            Notification.reference_id == reference_id,
            Notification.actif == True,
        )
        .first()
    )

    if existing:
        return existing

    notification = Notification(
        utilisateur_id=utilisateur_id,
        type=type,
        titre=titre,
        message=message,
        reference_type=reference_type,
        reference_id=reference_id,
        date_echeance=date_echeance,
        lu=False,
        actif=True,
    )

    db.add(notification)
    db.commit()
    db.refresh(notification)

    return notification


# ============================================================
# RÉCUPÉRATION
# ============================================================

def get_notifications(
    db: Session,
    utilisateur_id: int,
    non_lues_only: bool = False,
    type_filter: str | None = None,
    limit: int = 100,
):
    query = (
        db.query(Notification)
        .filter(
            Notification.utilisateur_id == utilisateur_id,
            Notification.actif == True,
        )
    )

    if non_lues_only:
        query = query.filter(Notification.lu == False)

    if type_filter:
        query = query.filter(Notification.type == type_filter)

    return (
        query
        .order_by(
            Notification.lu.asc(),
            Notification.created_at.desc(),
        )
        .limit(limit)
        .all()
    )


def count_unread(
    db: Session,
    utilisateur_id: int,
):
    return (
        db.query(Notification)
        .filter(
            Notification.utilisateur_id == utilisateur_id,
            Notification.lu == False,
            Notification.actif == True,
        )
        .count()
    )


# ============================================================
# LECTURE
# ============================================================

def mark_as_read(
    db: Session,
    notification: Notification,
):
    notification.lu = True
    notification.date_lecture = datetime.utcnow()

    db.commit()
    db.refresh(notification)

    return notification


def mark_all_as_read(
    db: Session,
    utilisateur_id: int,
):
    notifications = (
        db.query(Notification)
        .filter(
            Notification.utilisateur_id == utilisateur_id,
            Notification.lu == False,
            Notification.actif == True,
        )
        .all()
    )

    now = datetime.utcnow()

    for notification in notifications:
        notification.lu = True
        notification.date_lecture = now

    db.commit()

    return len(notifications)


# ============================================================
# SUPPRESSION
# ============================================================

def delete_notification(
    db: Session,
    notification: Notification,
):
    notification.actif = False

    db.commit()


# ============================================================
# RAPPELS FACTURES
# ============================================================

def generate_invoice_reminders(
    db: Session,
    utilisateur_id: int,
):
    """
    Génère les rappels pour les factures non réglées.

    J-3  : échéance dans 3 jours
    J-1  : échéance demain
    J    : échéance aujourd'hui
    J+1  : facture échue
    """

    now = datetime.utcnow()

    today = datetime(
        now.year,
        now.month,
        now.day,
    )

    tomorrow = today + timedelta(days=1)
    in_three_days = today + timedelta(days=3)
    yesterday = today - timedelta(days=1)

    factures = (
        db.query(Facture)
        .filter(
            Facture.actif == True,
            Facture.date_echeance.isnot(None),
            Facture.statut.notin_(
                ["Payée", "Annulée"]
            ),
        )
        .all()
    )

    created = 0

    for facture in factures:
        echeance = facture.date_echeance

        if echeance is None:
            continue

        date_echeance = datetime(
            echeance.year,
            echeance.month,
            echeance.day,
        )

        notification_type = None
        titre = None
        message = None

        # ----------------------------------------------------
        # Échéance dans 3 jours
        # ----------------------------------------------------

        if date_echeance == in_three_days:
            notification_type = "FACTURE_ECHEANCE"

            titre = "Échéance de facture proche"

            message = (
                f"La facture {facture.numero} "
                f"arrive à échéance dans 3 jours."
            )

        # ----------------------------------------------------
        # Échéance demain
        # ----------------------------------------------------

        elif date_echeance == tomorrow:
            notification_type = "FACTURE_ECHEANCE"

            titre = "Facture à échéance demain"

            message = (
                f"La facture {facture.numero} "
                f"arrive à échéance demain."
            )

        # ----------------------------------------------------
        # Échéance aujourd'hui
        # ----------------------------------------------------

        elif date_echeance == today:
            notification_type = "FACTURE_ECHEANCE"

            titre = "Facture à échéance aujourd'hui"

            message = (
                f"La facture {facture.numero} "
                f"arrive à échéance aujourd'hui."
            )

        # ----------------------------------------------------
        # Facture échue
        # ----------------------------------------------------

        elif date_echeance <= yesterday:
            notification_type = "FACTURE_ECHUE"

            titre = "Facture échue"

            jours = (today - date_echeance).days

            if jours == 1:
                message = (
                    f"La facture {facture.numero} "
                    f"est échue depuis 1 jour."
                )
            else:
                message = (
                    f"La facture {facture.numero} "
                    f"est échue depuis {jours} jours."
                )

        if notification_type:
            existing = (
                db.query(Notification)
                .filter(
                    Notification.utilisateur_id == utilisateur_id,
                    Notification.type == notification_type,
                    Notification.reference_type == "facture",
                    Notification.reference_id == facture.id,
                    Notification.date_echeance == facture.date_echeance,
                    Notification.actif == True,
                )
                .first()
            )

            if existing:
                continue

            create_notification(
                db=db,
                utilisateur_id=utilisateur_id,
                type=notification_type,
                titre=titre,
                message=message,
                reference_type="facture",
                reference_id=facture.id,
                date_echeance=facture.date_echeance,
            )

            created += 1

    return created


# ============================================================
# RAPPELS TÂCHES
# ============================================================

def generate_task_reminders(
    db: Session,
    utilisateur_id: int,
):
    """
    Génère les rappels pour les tâches non terminées.

    J-1 : tâche demain
    J   : tâche aujourd'hui
    J+1 : tâche échue
    """

    now = datetime.utcnow()

    today = datetime(
        now.year,
        now.month,
        now.day,
    )

    tomorrow = today + timedelta(days=1)
    yesterday = today - timedelta(days=1)

    taches = (
        db.query(Tache)
        .filter(
            Tache.actif == True,
            Tache.date_echeance.isnot(None),
            Tache.statut != "Terminée",
        )
        .all()
    )

    created = 0

    for tache in taches:
        if tache.date_echeance is None:
            continue

        echeance = datetime(
            tache.date_echeance.year,
            tache.date_echeance.month,
            tache.date_echeance.day,
        )

        notification_type = None
        titre = None
        message = None

        # ----------------------------------------------------
        # Tâche demain
        # ----------------------------------------------------

        if echeance == tomorrow:
            notification_type = "TACHE_ECHEANCE"

            titre = "Tâche à échéance demain"

            message = (
                f"La tâche « {tache.titre} » "
                f"arrive à échéance demain."
            )

        # ----------------------------------------------------
        # Tâche aujourd'hui
        # ----------------------------------------------------

        elif echeance == today:
            notification_type = "TACHE_ECHEANCE"

            titre = "Tâche à terminer aujourd'hui"

            message = (
                f"La tâche « {tache.titre} » "
                f"arrive à échéance aujourd'hui."
            )

        # ----------------------------------------------------
        # Tâche échue
        # ----------------------------------------------------

        elif echeance <= yesterday:
            notification_type = "TACHE_ECHUE"

            titre = "Tâche échue"

            jours = (today - echeance).days

            if jours == 1:
                message = (
                    f"La tâche « {tache.titre} » "
                    f"est échue depuis 1 jour."
                )
            else:
                message = (
                    f"La tâche « {tache.titre} » "
                    f"est échue depuis {jours} jours."
                )

        if notification_type:
            existing = (
                db.query(Notification)
                .filter(
                    Notification.utilisateur_id == utilisateur_id,
                    Notification.type == notification_type,
                    Notification.reference_type == "tache",
                    Notification.reference_id == tache.id,
                    Notification.date_echeance == tache.date_echeance,
                    Notification.actif == True,
                )
                .first()
            )

            if existing:
                continue

            create_notification(
                db=db,
                utilisateur_id=utilisateur_id,
                type=notification_type,
                titre=titre,
                message=message,
                reference_type="tache",
                reference_id=tache.id,
                date_echeance=tache.date_echeance,
            )

            created += 1

    return created


# ============================================================
# GÉNÉRATION GLOBALE POUR UN UTILISATEUR
# ============================================================

def generate_reminders(
    db: Session,
    utilisateur_id: int,
):
    invoice_count = generate_invoice_reminders(
        db,
        utilisateur_id,
    )

    task_count = generate_task_reminders(
        db,
        utilisateur_id,
    )

    return {
        "factures": invoice_count,
        "taches": task_count,
        "total": invoice_count + task_count,
    }

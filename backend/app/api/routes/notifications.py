from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.notification import NotificationResponse
from app.services.notification_service import (
    count_unread,
    delete_notification,
    generate_reminders,
    get_notifications,
    mark_all_as_read,
    mark_as_read,
)
from app.models.notification import Notification


router = APIRouter(
    prefix="/notifications",
    tags=["Notifications"],
)


# ============================================================
# LISTE DES NOTIFICATIONS
# ============================================================

@router.get(
    "",
    response_model=list[NotificationResponse],
)
def list_notifications(
    non_lues: bool = Query(
        False,
        description="Afficher uniquement les notifications non lues",
    ),
    type: str | None = Query(
        None,
        description="Filtrer par type de notification",
    ),
    limit: int = Query(
        100,
        ge=1,
        le=200,
    ),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Générer les rappels avant de récupérer la liste.
    generate_reminders(
        db,
        current_user.id,
    )

    return get_notifications(
        db=db,
        utilisateur_id=current_user.id,
        non_lues_only=non_lues,
        type_filter=type,
        limit=limit,
    )


# ============================================================
# COMPTEUR DES NOTIFICATIONS NON LUES
# ============================================================

@router.get(
    "/non-lues/count",
)
def unread_count(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    generate_reminders(
        db,
        current_user.id,
    )

    return {
        "count": count_unread(
            db,
            current_user.id,
        )
    }


# ============================================================
# MARQUER UNE NOTIFICATION COMME LUE
# ============================================================

@router.patch(
    "/{notification_id}/lire",
    response_model=NotificationResponse,
)
def read_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    notification = (
        db.query(Notification)
        .filter(
            Notification.id == notification_id,
            Notification.utilisateur_id == current_user.id,
            Notification.actif == True,
        )
        .first()
    )

    if notification is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification introuvable",
        )

    return mark_as_read(
        db,
        notification,
    )


# ============================================================
# MARQUER TOUTES LES NOTIFICATIONS COMME LUES
# ============================================================

@router.patch(
    "/lire-toutes",
)
def read_all_notifications(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    count = mark_all_as_read(
        db,
        current_user.id,
    )

    return {
        "message": "Toutes les notifications ont été marquées comme lues",
        "count": count,
    }


# ============================================================
# SUPPRIMER UNE NOTIFICATION
# ============================================================

@router.delete(
    "/{notification_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def remove_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    notification = (
        db.query(Notification)
        .filter(
            Notification.id == notification_id,
            Notification.utilisateur_id == current_user.id,
            Notification.actif == True,
        )
        .first()
    )

    if notification is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification introuvable",
        )

    delete_notification(
        db,
        notification,
    )

    return None

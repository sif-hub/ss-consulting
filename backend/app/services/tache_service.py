from datetime import datetime

from sqlalchemy.orm import Session

from app.models.tache import Tache
from app.schemas.tache import TacheCreate, TacheUpdate


def create_tache(
    db: Session,
    data: TacheCreate,
) -> Tache:

    tache = Tache(
        titre=data.titre,
        description=data.description,
        statut=data.statut,
        priorite=data.priorite,
        date_echeance=data.date_echeance,
        dossier_id=data.dossier_id,
        responsable_id=data.responsable_id,
    )

    db.add(tache)
    db.commit()
    db.refresh(tache)

    return tache


def get_taches(
    db: Session,
    dossier_id: int | None = None,
    responsable_id: int | None = None,
) -> list[Tache]:

    query = db.query(Tache).filter(Tache.actif == True)

    if dossier_id is not None:
        query = query.filter(
            Tache.dossier_id == dossier_id
        )

    if responsable_id is not None:
        query = query.filter(
            Tache.responsable_id == responsable_id
        )

    return query.order_by(
        Tache.date_creation.desc()
    ).all()


def get_tache(
    db: Session,
    tache_id: int,
) -> Tache | None:

    return (
        db.query(Tache)
        .filter(
            Tache.id == tache_id,
            Tache.actif == True,
        )
        .first()
    )


def update_tache(
    db: Session,
    tache: Tache,
    data: TacheUpdate,
) -> Tache:

    values = data.model_dump(
        exclude_unset=True
    )

    for field, value in values.items():
        setattr(tache, field, value)

    db.commit()
    db.refresh(tache)

    return tache


def delete_tache(
    db: Session,
    tache: Tache,
) -> None:

    tache.actif = False

    db.commit()


def terminer_tache(
    db: Session,
    tache: Tache,
) -> Tache:

    tache.statut = "Terminée"
    tache.date_terminaison = datetime.utcnow()

    db.commit()
    db.refresh(tache)

    return tache

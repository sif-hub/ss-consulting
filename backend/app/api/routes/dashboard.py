from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import require_admin
from app.models.client import Client
from app.models.depense import Depense
from app.models.document import Document
from app.models.dossier import Dossier
from app.models.facture import Facture
from app.models.paiement import Paiement
from app.models.user import User

router = APIRouter(
    prefix="/dashboard",
    tags=["Dashboard"],
)


def _count(db: Session, model, *filters) -> int:
    return (
        db.query(func.count(model.id))
        .filter(*filters)
        .scalar()
        or 0
    )


@router.get("/stats")
def get_dashboard_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    return {
        "clients": _count(db, Client, Client.actif.is_(True)),
        "dossiers": _count(db, Dossier, Dossier.actif.is_(True)),
        "documents": _count(db, Document, Document.actif.is_(True)),
        "factures": _count(db, Facture, Facture.actif.is_(True)),
        "paiements": _count(
            db,
            Paiement,
            Paiement.actif.is_(True),
            Paiement.statut == "Validé",
        ),
        "depenses": _count(db, Depense, Depense.actif.is_(True)),
        "impayes": _count(
            db,
            Facture,
            Facture.actif.is_(True),
            Facture.statut != "Payée",
        ),
    }

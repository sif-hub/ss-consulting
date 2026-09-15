from sqlalchemy.orm import Session

from app.models.client import Client
from app.schemas.client import ClientCreate, ClientUpdate


def create_client(
    db: Session,
    data: ClientCreate,
) -> Client:

    client = Client(**data.model_dump())

    db.add(client)
    db.commit()
    db.refresh(client)

    return client


def get_clients(
    db: Session,
) -> list[Client]:

    return (
        db.query(Client)
        .filter(Client.actif.is_(True))
        .order_by(Client.id.desc())
        .all()
    )


def get_client(
    db: Session,
    client_id: int,
) -> Client | None:

    return (
        db.query(Client)
        .filter(Client.id == client_id)
        .first()
    )


def update_client(
    db: Session,
    client_id: int,
    data: ClientUpdate,
) -> Client | None:

    client = (
        db.query(Client)
        .filter(Client.id == client_id)
        .first()
    )

    if client is None:
        return None

    updates = data.model_dump(exclude_unset=True)

    for field, value in updates.items():
        setattr(client, field, value)

    db.commit()
    db.refresh(client)

    return client


def delete_client(
    db: Session,
    client_id: int,
) -> bool:

    client = (
        db.query(Client)
        .filter(Client.id == client_id)
        .first()
    )

    if client is None:
        return False

    client.actif = False

    db.commit()

    return True


def get_client_situation(
    db: Session,
    client_id: int,
):
    """
    Retourne la situation complète d'un client :
    dossiers, factures, paiements, documents, tâches et créances.
    """

    from app.models.dossier import Dossier
    from app.models.facture import Facture
    from app.models.paiement import Paiement

    client = (
        db.query(Client)
        .filter(
            Client.id == client_id,
            Client.actif.is_(True),
        )
        .first()
    )

    if client is None:
        raise ValueError("Client introuvable")

    dossiers = (
        db.query(Dossier)
        .filter(
            Dossier.client_id == client_id,
        )
        .all()
    )

    factures = (
        db.query(Facture)
        .filter(
            Facture.client_id == client_id,
            Facture.actif.is_(True),
        )
        .all()
    )

    facture_ids = [facture.id for facture in factures]

    paiements = []

    if facture_ids:
        paiements = (
            db.query(Paiement)
            .filter(
                Paiement.facture_id.in_(facture_ids),
                Paiement.actif.is_(True),
            )
            .all()
        )

    total_facture_ttc = round(
        sum(f.montant_ttc or 0 for f in factures),
        2,
    )

    total_paye = round(
        sum(
            p.montant or 0
            for p in paiements
            if p.statut == "Validé"
        ),
        2,
    )

    creance = round(
        max(total_facture_ttc - total_paye, 0),
        2,
    )

    total_commissions = round(
        sum(
            p.montant_commission or 0
            for p in paiements
            if p.statut == "Validé"
        ),
        2,
    )

    documents = []

    for dossier in dossiers:
        documents.extend(dossier.documents or [])

    taches = []

    for dossier in dossiers:
        taches.extend(dossier.taches or [])

    return {
        "client": {
            "id": client.id,
            "nom": client.nom,
            "prenom": client.prenom,
            "raison_sociale": client.raison_sociale,
            "email": client.email,
            "telephone": client.telephone,
            "adresse": client.adresse,
            "ville": client.ville,
            "numero_contribuable": client.numero_contribuable,
            "registre_commerce": client.registre_commerce,
            "type_client": client.type_client,
            "actif": client.actif,
        },

        "statistiques": {
            "nombre_dossiers": len(dossiers),
            "nombre_factures": len(factures),
            "nombre_paiements": len(paiements),
            "nombre_documents": len(documents),
            "nombre_taches": len(taches),
        },

        "factures": {
            "total_ttc": total_facture_ttc,
            "total_paye": total_paye,
            "creance": creance,
        },

        "paiements": {
            "total": total_paye,
            "commissions": total_commissions,
        },

        "dossiers": [
            {
                "id": dossier.id,
                "reference": getattr(dossier, "reference", None),
                "statut": getattr(dossier, "statut", None),
            }
            for dossier in dossiers
        ],

        "documents": [
            {
                "id": document.id,
                "nom": getattr(document, "nom", None),
                "type": getattr(document, "type", None),
            }
            for document in documents
        ],

        "taches": [
            {
                "id": tache.id,
                "titre": getattr(tache, "titre", None),
                "statut": getattr(tache, "statut", None),
            }
            for tache in taches
        ],
    }

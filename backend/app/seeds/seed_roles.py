from app.models.role import Role


ROLES = [
    (1, "Administrateur", "Accès complet à la plateforme"),
    (2, "Manager Secretariat", "Supervision des dossiers et du secrétariat"),
    (3, "Secretaire", "Gestion administrative des dossiers clients"),
    (4, "Fiscaliste", "Traitement des déclarations fiscales"),
    (5, "Comptable", "Gestion de la comptabilité SYSCOHADA"),
    (6, "Client", "Accès client au suivi de son dossier"),
]


def seed_roles(db) -> int:
    """
    Insère les 6 rôles de référence de l'application s'ils n'existent pas
    déjà (idempotent — nécessaire une seule fois sur une base neuve).
    """

    nombre_crees = 0

    for role_id, nom, description in ROLES:
        existe = db.query(Role).filter(Role.id == role_id).first()

        if existe is not None:
            continue

        db.add(
            Role(
                id=role_id,
                nom=nom,
                description=description,
            )
        )
        nombre_crees += 1

    db.commit()

    return nombre_crees

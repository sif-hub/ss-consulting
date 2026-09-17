from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import hash_password
from app.models.role import Role
from app.models.client import Client
from app.models.user import User


def get_users(
    db: Session,
    actif: bool | None = None,
    role_id: int | None = None,
    search: str | None = None,
):
    query = db.query(User)

    if actif is not None:
        query = query.filter(User.actif == actif)

    if role_id is not None:
        query = query.filter(User.role_id == role_id)

    if search:
        search_value = f"%{search.strip()}%"
        query = query.filter(
            (User.nom.ilike(search_value))
            | (User.prenom.ilike(search_value))
            | (User.email.ilike(search_value))
        )

    return query.order_by(User.nom.asc(), User.prenom.asc()).all()


def get_user_by_id(
    db: Session,
    user_id: int,
) -> User:
    user = db.query(User).filter(User.id == user_id).first()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur introuvable",
        )

    return user


def get_role_by_id(
    db: Session,
    role_id: int,
) -> Role:
    role = db.query(Role).filter(Role.id == role_id).first()

    if role is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Rôle introuvable",
        )

    return role


def get_roles(db: Session):
    return db.query(Role).order_by(Role.id.asc()).all()


def create_user(
    db: Session,
    nom: str,
    prenom: str,
    email: str,
    telephone: str | None,
    mot_de_passe: str,
    role_id: int,
    client_id: int | None = None,
) -> User:
    existing_user = (
        db.query(User)
        .filter(User.email == email)
        .first()
    )

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cette adresse email est déjà utilisée",
        )

    role = get_role_by_id(db, role_id)

    # L'association à un client est optionnelle, y compris pour le
    # rôle Client : l'admin peut créer le compte d'abord et l'associer
    # plus tard. Si un client_id est fourni, on le valide quand même.
    if role_id == 6 and client_id is not None:
        client = db.query(Client).filter(Client.id == client_id).first()

        if client is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Client introuvable.",
            )

        existing_client_user = (
            db.query(User)
            .filter(User.client_id == client_id)
            .first()
        )

        if existing_client_user:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Ce client possède déjà un compte utilisateur.",
            )

    user = User(
        nom=nom.strip(),
        prenom=prenom.strip(),
        email=email.strip().lower(),
        telephone=telephone.strip() if telephone else None,
        mot_de_passe=hash_password(mot_de_passe),
        role_id=role.id,
        client_id=client_id if role_id == 6 else None,
        actif=True,
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    return user


def update_user(
    db: Session,
    user_id: int,
    nom: str,
    prenom: str,
    email: str,
    telephone: str | None,
    role_id: int,
    client_id: int | None = None,
) -> User:
    user = get_user_by_id(db, user_id)

    existing_user = (
        db.query(User)
        .filter(
            User.email == email.strip().lower(),
            User.id != user_id,
        )
        .first()
    )

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cette adresse email est déjà utilisée",
        )

    role = get_role_by_id(db, role_id)

    if role_id == 6 and client_id is not None:
        client = db.query(Client).filter(Client.id == client_id).first()

        if client is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Client introuvable.",
            )

        existing_client_user = (
            db.query(User)
            .filter(
                User.client_id == client_id,
                User.id != user_id,
            )
            .first()
        )

        if existing_client_user:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Ce client possède déjà un compte utilisateur.",
            )

    user.nom = nom.strip()
    user.prenom = prenom.strip()
    user.email = email.strip().lower()
    user.telephone = telephone.strip() if telephone else None
    user.role_id = role.id
    user.client_id = client_id if role_id == 6 else None

    db.commit()
    db.refresh(user)

    return user


def change_password(
    db: Session,
    user_id: int,
    mot_de_passe: str,
) -> User:
    user = get_user_by_id(db, user_id)

    user.mot_de_passe = hash_password(mot_de_passe)

    db.commit()
    db.refresh(user)

    return user


def set_user_status(
    db: Session,
    user_id: int,
    actif: bool,
    current_user_id: int,
) -> User:
    user = get_user_by_id(db, user_id)

    if user.id == current_user_id and not actif:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Vous ne pouvez pas désactiver votre propre compte",
        )

    user.actif = actif

    db.commit()
    db.refresh(user)

    return user

from typing import Generator

from fastapi import Depends, HTTPException, Query, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import decode_access_token
from app.models.user import User


oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/api/v1/auth/login"
)

# Variante qui ne déclenche pas automatiquement une 401 quand l'en-tête
# Authorization est absent : utilisée uniquement pour les liens de
# téléchargement directs (ex : ouverture d'un fichier dans un nouvel
# onglet), où le jeton est passé en repli via le paramètre `token`.
oauth2_scheme_optional = OAuth2PasswordBearer(
    tokenUrl="/api/v1/auth/login",
    auto_error=False,
)


def _resolve_current_user(
    token: str | None,
    db: Session,
) -> User:

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token invalide ou expiré",
        headers={
            "WWW-Authenticate": "Bearer"
        },
    )

    if not token:
        raise credentials_exception

    payload = decode_access_token(token)

    if payload is None:
        raise credentials_exception

    user_id = payload.get("sub")

    if user_id is None:
        raise credentials_exception

    try:
        user_id = int(user_id)
    except (TypeError, ValueError):
        raise credentials_exception

    user = (
        db.query(User)
        .filter(User.id == user_id)
        .first()
    )

    if user is None:
        raise credentials_exception

    if not user.actif:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Compte désactivé",
        )

    return user


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:

    return _resolve_current_user(token, db)


def get_current_user_header_or_query(
    header_token: str | None = Depends(oauth2_scheme_optional),
    query_token: str | None = Query(default=None, alias="token"),
    db: Session = Depends(get_db),
) -> User:
    """
    Comme `get_current_user`, mais accepte aussi le jeton en paramètre
    d'URL (`?token=...`) quand l'en-tête Authorization ne peut pas être
    positionné — cas des liens de téléchargement/ouverture de fichier
    ouverts directement dans un navigateur.
    """

    return _resolve_current_user(
        header_token or query_token,
        db,
    )


def require_roles(*allowed_roles: int):

    def role_checker(
        current_user: User = Depends(get_current_user),
    ) -> User:

        if current_user.role_id not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Vous n'avez pas les permissions nécessaires",
            )

        return current_user

    return role_checker


def require_admin(
    current_user: User = Depends(get_current_user),
) -> User:

    if current_user.role_id != 1:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès réservé à l'administrateur",
        )

    return current_user

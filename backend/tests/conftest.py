import os

os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
os.environ.setdefault("SECRET_KEY", "test-secret-key")

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

from app.core.database import Base, get_db
from app.core.security import hash_password
from app.main import app
from app.models.role import Role
from app.models.user import User


@pytest.fixture()
def db_session():
    """Base SQLite en mémoire, isolée de la vraie base à chaque test."""

    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    TestingSessionLocal = sessionmaker(bind=engine)
    session = TestingSessionLocal()

    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def client(db_session):
    """Client de test FastAPI, branché sur la base en mémoire du test."""

    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()


@pytest.fixture()
def roles(db_session):
    """Les 6 rôles réels de l'application, insérés une seule fois par test."""
    from app.seeds.seed_roles import seed_roles

    seed_roles(db_session)
    return {role.nom: role for role in db_session.query(Role).all()}


@pytest.fixture()
def role_client(roles):
    return roles["Client"]


@pytest.fixture()
def make_user(db_session, roles):
    """Fabrique un utilisateur actif avec le rôle demandé (par son nom exact,
    voir app/seeds/seed_roles.py), avec un email unique par défaut."""

    compteur = {"n": 0}

    def _make(role_nom: str, **overrides):
        compteur["n"] += 1

        defaults = {
            "nom": role_nom,
            "prenom": "Test",
            "email": f"{role_nom.lower().replace(' ', '-')}-{compteur['n']}@example.com",
            "telephone": None,
            "mot_de_passe": hash_password("motdepasse123"),
            "role_id": roles[role_nom].id,
            "actif": True,
        }
        defaults.update(overrides)

        user = User(**defaults)
        db_session.add(user)
        db_session.commit()
        db_session.refresh(user)
        return user

    return _make


@pytest.fixture()
def auth_headers():
    """En-tête Authorization Bearer valide pour l'utilisateur donné, sans
    passer par /auth/login (plus rapide, et teste un autre chemin)."""
    from app.core.security import create_access_token

    def _headers(user):
        token = create_access_token(
            {
                "sub": str(user.id),
                "email": user.email,
                "role_id": user.role_id,
            }
        )
        return {"Authorization": f"Bearer {token}"}

    return _headers


@pytest.fixture()
def utilisateur_actif(db_session, role_client):
    user = User(
        nom="Test",
        prenom="Utilisateur",
        email="test@example.com",
        telephone=None,
        mot_de_passe=hash_password("motdepasse123"),
        role_id=role_client.id,
        actif=True,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture()
def utilisateur_desactive(db_session, role_client):
    user = User(
        nom="Inactif",
        prenom="Utilisateur",
        email="inactif@example.com",
        telephone=None,
        mot_de_passe=hash_password("motdepasse123"),
        role_id=role_client.id,
        actif=False,
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user

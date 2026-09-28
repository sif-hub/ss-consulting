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
def role_client(db_session):
    role = Role(nom="Client", description="Accès client")
    db_session.add(role)
    db_session.commit()
    db_session.refresh(role)
    return role


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

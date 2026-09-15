from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
)
from sqlalchemy.orm import relationship

from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    nom = Column(
        String(100),
        nullable=False,
    )

    prenom = Column(
        String(100),
        nullable=False,
    )

    email = Column(
        String(255),
        unique=True,
        nullable=False,
        index=True,
    )

    telephone = Column(
        String(30),
        nullable=True,
    )

    mot_de_passe = Column(
        String(255),
        nullable=False,
    )

    client_id = Column(
        Integer,
        ForeignKey("clients.id"),
        nullable=True,
        index=True,
    )

    role_id = Column(
        Integer,
        ForeignKey("roles.id"),
        nullable=False,
    )

    actif = Column(
        Boolean,
        default=True,
        nullable=False,
    )

    date_creation = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )

    derniere_connexion = Column(
        DateTime,
        nullable=True,
    )

    client = relationship(
        "Client",
        back_populates="utilisateur",
        uselist=False,
    )

    role = relationship(
        "Role",
        back_populates="utilisateurs",
    )

    taches = relationship(
        "Tache",
        back_populates="responsable",
    )

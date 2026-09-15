from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Integer,
    String,
    Text,
)

from app.core.database import Base


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    utilisateur_id = Column(
        Integer,
        nullable=False,
        index=True,
    )

    type = Column(
        String(50),
        nullable=False,
        index=True,
    )

    titre = Column(
        String(200),
        nullable=False,
    )

    message = Column(
        Text,
        nullable=False,
    )

    reference_type = Column(
        String(50),
        nullable=True,
        index=True,
    )

    reference_id = Column(
        Integer,
        nullable=True,
        index=True,
    )

    date_echeance = Column(
        DateTime,
        nullable=True,
        index=True,
    )

    lu = Column(
        Boolean,
        nullable=False,
        default=False,
        index=True,
    )

    date_lecture = Column(
        DateTime,
        nullable=True,
    )

    actif = Column(
        Boolean,
        nullable=False,
        default=True,
    )

    created_at = Column(
        DateTime,
        nullable=False,
        default=datetime.utcnow,
        index=True,
    )

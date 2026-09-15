from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.pool import NullPool

from app.core.config import settings


# En environnement serverless (Vercel), chaque instance de fonction est
# éphémère : garder un pool de connexions côté application n'a pas de sens
# et provoque des erreurs de connexion "stale" après une mise en veille.
# Neon (et la plupart des Postgres managés pensés pour le serverless)
# gèrent déjà leur propre pooling côté serveur (PgBouncer) ; on désactive
# donc le pool applicatif via NullPool, qui ouvre/ferme une connexion par
# requête.
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
    poolclass=NullPool,
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

Base = declarative_base()


def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()

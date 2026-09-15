from contextlib import asynccontextmanager
from app.api.routes import comptabilite
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import paiements
from app.core.config import settings
from app.api.routes import auth
from app.api.routes import users
from app.api.routes import clients
from app.api.routes import dossiers
from app.api.routes import factures
from app.api.routes import taches
from app.api.routes import documents
from app.api.routes.dashboard import router as dashboard_router
from app.api.routes import depenses
from app.api.routes import pdf
from app.api.routes import notifications
from app.api.routes import declarations
from app.api.routes import ia

@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"🚀 {settings.APP_NAME}")
    print(f"📦 Version : {settings.APP_VERSION}")
    print(f"🌍 Environnement : {settings.ENVIRONMENT}")

    yield

    print("🛑 Arrêt du serveur")


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description=settings.APP_DESCRIPTION,
    debug=settings.DEBUG,
    lifespan=lifespan,
)


# ============================================================
# ROUTES API
# ============================================================

app.include_router(
    auth.router,
    prefix=settings.API_V1_PREFIX,
)
app.include_router(
    dashboard_router,
    prefix="/api/v1",
)
app.include_router(
    users.router,
    prefix=settings.API_V1_PREFIX,
)

app.include_router(
    clients.router,
    prefix=settings.API_V1_PREFIX,
)

app.include_router(
    dossiers.router,
    prefix=settings.API_V1_PREFIX,
)

app.include_router(
    documents.router,
    prefix=settings.API_V1_PREFIX,
)

app.include_router(
    taches.router,
    prefix=settings.API_V1_PREFIX,
)

app.include_router(
    factures.router,
    prefix=settings.API_V1_PREFIX,
)

app.include_router(
    paiements.router,
    prefix=settings.API_V1_PREFIX,
)

app.include_router(
    depenses.router,
    prefix=settings.API_V1_PREFIX,
)

app.include_router(
    pdf.router,
    prefix=settings.API_V1_PREFIX,
)
app.include_router(
    notifications.router,
    prefix=settings.API_V1_PREFIX,
)
app.include_router(
    comptabilite.router,
    prefix=settings.API_V1_PREFIX,
)
app.include_router(
    declarations.router,
    prefix=settings.API_V1_PREFIX,
)
app.include_router(
    ia.router,
    prefix=settings.API_V1_PREFIX,
)
# ============================================================
# CORS
# ============================================================
# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================
# ROUTES SYSTEM
# ============================================================

@app.get("/", tags=["System"])
def root():
    return {
        "application": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "online",
    }


@app.get(
    f"{settings.API_V1_PREFIX}/health",
    tags=["System"],
)
def health_check():
    return {
        "status": "healthy",
        "application": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "database": "configured",
    }

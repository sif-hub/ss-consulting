from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, require_roles
from app.models.document import Document
from app.models.user import User
from app.services import ai_service


router = APIRouter(
    prefix="/ia",
    tags=["Intelligence artificielle"],
)


ROLE_LABELS = {
    1: "Administrateur",
    2: "Manager Secrétariat",
    3: "Secrétaire",
    4: "Fiscaliste",
    5: "Comptable",
    6: "Client",
}


# ============================================================
# ASSISTANT CONVERSATIONNEL
# ============================================================

class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    messages: list[ChatMessage] = Field(..., min_length=1)


class ChatResponse(BaseModel):
    reponse: str


@router.post(
    "/chat",
    response_model=ChatResponse,
)
def chat(
    data: ChatRequest,
    current_user: User = Depends(get_current_user),
):
    role_label = ROLE_LABELS.get(current_user.role_id, "Utilisateur")

    reponse = ai_service.chat(
        [message.model_dump() for message in data.messages],
        role_label,
    )

    return ChatResponse(reponse=reponse)


@router.post("/chat/stream")
def chat_stream(
    data: ChatRequest,
    current_user: User = Depends(get_current_user),
):
    role_label = ROLE_LABELS.get(current_user.role_id, "Utilisateur")

    return StreamingResponse(
        ai_service.chat_stream(
            [message.model_dump() for message in data.messages],
            role_label,
        ),
        media_type="text/plain",
    )


# ============================================================
# AIDE A LA REDACTION DE DECLARATIONS
# ============================================================

class SuggestionResponse(BaseModel):
    suggestion: str


class DeclarationObservationsRequest(BaseModel):
    mois: int = Field(..., ge=1, le=12)
    annee: int = Field(..., ge=2000, le=2100)
    chiffre_affaires: float = 0
    total_ventes: float = 0
    total_achats: float = 0
    nombre_employes: int = 0


@router.post(
    "/declarations/observations",
    response_model=SuggestionResponse,
)
def suggerer_observations(
    data: DeclarationObservationsRequest,
    current_user: User = Depends(get_current_user),
):
    suggestion = ai_service.suggerer_observations_declaration(data)

    return SuggestionResponse(suggestion=suggestion)


# ============================================================
# ANALYSE AUTOMATIQUE DE DOCUMENTS
# ============================================================

@router.post("/documents/{document_id}/analyser")
def analyser_document(
    document_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    document = (
        db.query(Document)
        .filter(Document.id == document_id)
        .first()
    )

    if document is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document introuvable",
        )

    return ai_service.analyser_document(document)

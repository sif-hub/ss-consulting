from fastapi.responses import Response
from pathlib import Path

from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    UploadFile,
    status,
)
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import (
    get_current_user,
    get_current_user_header_or_query,
    require_roles,
)
from app.models.dossier import Dossier
from app.models.user import User
from app.schemas.document import DocumentCreate, DocumentResponse
from app.services import file_storage
from app.services.document_service import (
    create_declaration_document,
    create_document,
    delete_document,
    get_declaration_documents,
    get_document,
    get_documents,
    list_all_documents,
    save_declaration_file,
)


router = APIRouter(
    tags=["Documents"],
)


def ensure_document_access(db: Session, current_user: User, document):
    """
    Vérifie l'accès à un document lié à un dossier ou à une déclaration :
    - Administrateur : accès total.
    - Collaborateurs : uniquement les documents des dossiers qui leur
      sont affectés.
    - Client : uniquement les documents de ses propres dossiers ou
      déclarations.
    """

    if current_user.role_id == 1:
        return

    if document.dossier_id is not None:
        dossier = (
            db.query(Dossier)
            .filter(Dossier.id == document.dossier_id)
            .first()
        )

        if dossier is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Dossier introuvable",
            )

        if current_user.role_id in (2, 3, 4, 5):
            if dossier.collaborateur_id != current_user.id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Vous n'avez pas accès à ce document.",
                )
            return

        if current_user.role_id == 6:
            if (
                current_user.client_id is None
                or dossier.client_id != current_user.client_id
            ):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Vous n'avez pas accès à ce document.",
                )
            return

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous n'avez pas accès à ce document.",
        )

    if document.declaration_id is not None:
        from app.models.declaration import Declaration

        declaration = (
            db.query(Declaration)
            .filter(Declaration.id == document.declaration_id)
            .first()
        )

        if declaration is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Déclaration introuvable",
            )

        if current_user.role_id == 6:
            if (
                current_user.client_id is None
                or declaration.client_id != current_user.client_id
            ):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Vous n'avez pas accès à ce document.",
                )

        return


ALLOWED_EXTENSIONS = {
    ".pdf",
    ".jpg",
    ".jpeg",
    ".png",
    ".webp",
    ".doc",
    ".docx",
    ".xls",
    ".xlsx",
}

MAX_FILE_SIZE = 10 * 1024 * 1024


def _ensure_dossier_document_access(db: Session, current_user: User, dossier_id: int):
    from app.api.routes.dossiers import ensure_dossier_access

    dossier = (
        db.query(Dossier)
        .filter(Dossier.id == dossier_id)
        .first()
    )

    if dossier is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Dossier introuvable",
        )

    ensure_dossier_access(current_user, dossier)


@router.get(
    "/documents",
    response_model=list[DocumentResponse],
)
def list_documents_all(
    search: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(1, 2, 3, 4, 5)),
):
    return list_all_documents(db, search=search)


@router.post(
    "/dossiers/{dossier_id}/documents",
    response_model=DocumentResponse,
    status_code=status.HTTP_201_CREATED,
)
def create(
    dossier_id: int,
    data: DocumentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ensure_dossier_document_access(db, current_user, dossier_id)

    return create_document(db, dossier_id, data)


@router.get(
    "/dossiers/{dossier_id}/documents",
    response_model=list[DocumentResponse],
)
def list_documents(
    dossier_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ensure_dossier_document_access(db, current_user, dossier_id)

    return get_documents(db, dossier_id)


@router.post(
    "/declarations/{declaration_id}/documents",
    response_model=DocumentResponse,
    status_code=status.HTTP_201_CREATED,
)
async def upload_declaration_document(
    declaration_id: int,
    fichier: UploadFile = File(...),
    description: str | None = Form(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # --------------------------------------------------------
    # Vérification de la déclaration
    # --------------------------------------------------------

    from app.models.declaration import Declaration

    declaration = (
        db.query(Declaration)
        .filter(Declaration.id == declaration_id)
        .first()
    )

    if declaration is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Déclaration introuvable",
        )

    # --------------------------------------------------------
    # Un client ne peut envoyer un document que pour
    # sa propre déclaration.
    # --------------------------------------------------------

    if current_user.role_id == 6:
        if current_user.client_id is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Votre compte Client n'est associé à aucun client.",
            )

        if declaration.client_id != current_user.client_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Vous n'avez pas accès à cette déclaration.",
            )

    # --------------------------------------------------------
    # Vérification du nom de fichier
    # --------------------------------------------------------

    if not fichier.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Nom de fichier invalide.",
        )

    extension = Path(fichier.filename).suffix.lower()

    if extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Type de fichier non autorisé. "
                "Formats acceptés : PDF, JPG, JPEG, PNG, WEBP, "
                "DOC, DOCX, XLS et XLSX."
            ),
        )

    # --------------------------------------------------------
    # Lecture du fichier avec limite de taille
    # --------------------------------------------------------

    content = await fichier.read()

    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Le fichier ne doit pas dépasser 10 Mo.",
        )

    if len(content) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le fichier est vide.",
        )

    # --------------------------------------------------------
    # Sauvegarde physique
    # --------------------------------------------------------

    chemin_fichier = save_declaration_file(
        declaration_id=declaration_id,
        filename=fichier.filename,
        content=content,
        content_type=fichier.content_type,
    )

    # --------------------------------------------------------
    # Création dans la table documents existante
    # --------------------------------------------------------

    document = create_declaration_document(
        db=db,
        declaration_id=declaration_id,
        nom=fichier.filename,
        type_document=fichier.content_type or extension,
        description=description,
        chemin_fichier=chemin_fichier,
    )

    return document


@router.get(
    "/declarations/{declaration_id}/documents",
    response_model=list[DocumentResponse],
)
def list_declaration_documents(
    declaration_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from app.models.declaration import Declaration

    declaration = (
        db.query(Declaration)
        .filter(Declaration.id == declaration_id)
        .first()
    )

    if declaration is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Déclaration introuvable",
        )

    if current_user.role_id == 6:
        if current_user.client_id != declaration.client_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Vous n'avez pas accès à cette déclaration.",
            )

    return get_declaration_documents(
        db,
        declaration_id,
    )


@router.get(
    "/documents/{document_id}",
    response_model=DocumentResponse,
)
def get_one(
    document_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    document = get_document(db, document_id)

    ensure_document_access(db, current_user, document)

    return document


@router.delete(
    "/documents/{document_id}",
)
def delete(
    document_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    document = get_document(db, document_id)

    ensure_document_access(db, current_user, document)

    return delete_document(db, document_id)


@router.get(
    "/documents/{document_id}/fichier",
)
def download_document_file(
    document_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_header_or_query),
):
    document = get_document(db, document_id)

    if not document.chemin_fichier:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Aucun fichier associé à ce document.",
        )

    if not file_storage.file_exists(document.chemin_fichier):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Fichier introuvable sur le serveur.",
        )

    ensure_document_access(db, current_user, document)

    content = file_storage.read_file(document.chemin_fichier)

    return Response(
        content=content,
        media_type=document.type_document or "application/octet-stream",
        headers={
            "Content-Disposition": f'attachment; filename="{document.nom}"',
        },
    )

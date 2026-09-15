from pathlib import Path
from uuid import uuid4

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.declaration import Declaration
from app.models.document import Document
from app.models.dossier import Dossier
from app.schemas.document import DocumentCreate


UPLOAD_DIR = Path("uploads")


def create_document(
    db: Session,
    dossier_id: int,
    data: DocumentCreate,
):
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

    document = Document(
        dossier_id=dossier_id,
        declaration_id=None,
        nom=data.nom,
        type_document=data.type_document,
        description=data.description,
        chemin_fichier=data.chemin_fichier,
        statut=data.statut,
    )

    db.add(document)
    db.commit()
    db.refresh(document)

    return document


def list_all_documents(
    db: Session,
    search: str | None = None,
):
    query = db.query(Document).filter(Document.actif.is_(True))

    if search:
        query = query.filter(Document.nom.ilike(f"%{search}%"))

    return (
        query
        .order_by(Document.created_at.desc())
        .all()
    )


def get_documents(
    db: Session,
    dossier_id: int,
):
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

    return (
        db.query(Document)
        .filter(Document.dossier_id == dossier_id)
        .order_by(Document.id.desc())
        .all()
    )


def get_declaration_documents(
    db: Session,
    declaration_id: int,
):
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

    return (
        db.query(Document)
        .filter(Document.declaration_id == declaration_id)
        .order_by(Document.id.desc())
        .all()
    )


def create_declaration_document(
    db: Session,
    declaration_id: int,
    nom: str,
    type_document: str,
    description: str | None,
    chemin_fichier: str,
):
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

    document = Document(
        dossier_id=None,
        declaration_id=declaration_id,
        nom=nom,
        type_document=type_document,
        description=description,
        chemin_fichier=chemin_fichier,
        statut="Actif",
        actif=True,
    )

    db.add(document)
    db.commit()
    db.refresh(document)

    return document


def save_declaration_file(
    declaration_id: int,
    filename: str,
    content: bytes,
) -> str:
    declaration_dir = (
        UPLOAD_DIR
        / "declarations"
        / str(declaration_id)
    )

    declaration_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    extension = Path(filename).suffix.lower()

    safe_filename = (
        f"{uuid4().hex}{extension}"
    )

    file_path = declaration_dir / safe_filename

    file_path.write_bytes(content)

    return str(file_path)


def get_document(
    db: Session,
    document_id: int,
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

    return document


def delete_document(
    db: Session,
    document_id: int,
):
    document = get_document(db, document_id)

    if document.chemin_fichier:
        file_path = Path(document.chemin_fichier)

        if file_path.exists():
            file_path.unlink()

    db.delete(document)
    db.commit()

    return {
        "message": "Document supprimé",
        "document_id": document_id,
    }

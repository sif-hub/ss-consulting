"""
Stockage des fichiers uploadés (documents, pièces jointes de déclarations).

En local, les fichiers sont écrits sur le disque (dossier "uploads/"),
comme avant. Dès que la variable d'environnement BLOB_READ_WRITE_TOKEN est
présente (fournie automatiquement par Vercel quand un store Blob est
raccordé au projet), les nouveaux fichiers sont envoyés vers Vercel Blob à
la place — nécessaire car le système de fichiers d'une fonction serverless
n'est pas persistant. La lecture/suppression détecte le mode à partir de
la valeur stockée (URL http(s) = Blob, chemin local sinon), donc les deux
types de documents coexistent sans problème sur une même base.
"""

import os
from pathlib import Path
from uuid import uuid4


UPLOAD_DIR = Path("uploads")


def _blob_enabled() -> bool:
    return bool(os.environ.get("BLOB_READ_WRITE_TOKEN"))


def _is_blob_url(chemin: str) -> bool:
    return chemin.startswith("http://") or chemin.startswith("https://")


def save_file(
    folder: str,
    filename: str,
    content: bytes,
    content_type: str | None = None,
) -> str:
    extension = Path(filename).suffix.lower()
    safe_filename = f"{uuid4().hex}{extension}"

    if _blob_enabled():
        from vercel import blob

        result = blob.put(
            f"{folder}/{safe_filename}",
            content,
            access="public",
            content_type=content_type,
        )

        return result.url

    local_dir = UPLOAD_DIR / folder
    local_dir.mkdir(parents=True, exist_ok=True)

    file_path = local_dir / safe_filename
    file_path.write_bytes(content)

    return str(file_path)


def read_file(chemin: str) -> bytes:
    if _is_blob_url(chemin):
        from vercel import blob

        return blob.get(chemin).content

    return Path(chemin).read_bytes()


def file_exists(chemin: str) -> bool:
    if _is_blob_url(chemin):
        from vercel import blob
        from vercel.blob import BlobNotFoundError

        try:
            blob.head(chemin)
            return True
        except BlobNotFoundError:
            return False

    path = Path(chemin)

    return path.exists() and path.is_file()


def delete_file(chemin: str) -> None:
    if _is_blob_url(chemin):
        from vercel import blob

        blob.delete(chemin)
        return

    path = Path(chemin)

    if path.exists():
        path.unlink()

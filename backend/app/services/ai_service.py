import json
import time
from pathlib import Path

from fastapi import HTTPException, status
from google import genai
from google.genai import errors, types

from app.core.config import settings


_client: genai.Client | None = None


def _generate(client: genai.Client, **kwargs):
    """
    Appelle generate_content avec une nouvelle tentative en cas de
    surcharge temporaire (fréquente sur le niveau gratuit de Gemini).
    """

    last_exc: Exception | None = None

    for attempt in range(3):
        try:
            return client.models.generate_content(**kwargs)
        except errors.ServerError as exc:
            last_exc = exc
            if attempt < 2:
                time.sleep(1.5 * (attempt + 1))
                continue
            raise
        except Exception as exc:
            raise exc

    raise last_exc


def _handle_error(exc: Exception) -> HTTPException:
    if isinstance(exc, errors.APIError):
        code = getattr(exc, "code", None)

        if code in (401, 403):
            return HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Clé API de l'assistant IA invalide ou refusée.",
            )

        if code == 429:
            return HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=(
                    "Limite de requêtes de l'assistant IA atteinte "
                    "(quota gratuit). Réessayez dans quelques instants."
                ),
            )

        if code == 503:
            return HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=(
                    "L'assistant IA est momentanément surchargé. "
                    "Réessayez dans quelques instants."
                ),
            )

    return HTTPException(
        status_code=status.HTTP_502_BAD_GATEWAY,
        detail="Impossible de contacter l'assistant IA pour le moment.",
    )


def _get_client() -> genai.Client:
    if not settings.GEMINI_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "L'assistant IA n'est pas configuré. "
                "Contactez l'administrateur du cabinet."
            ),
        )

    global _client

    if _client is None:
        _client = genai.Client(api_key=settings.GEMINI_API_KEY)

    return _client


SYSTEM_PROMPT_BASE = (
    "Tu es l'assistant intégré à SS Consulting, un logiciel de gestion pour "
    "un cabinet de conseil et de comptabilité au Cameroun (gestion des "
    "clients, dossiers, factures, paiements, dépenses, déclarations "
    "fiscales et comptabilité SYSCOHADA). Réponds toujours en français, de "
    "façon concise, professionnelle et directement utile. Si une question "
    "sort du cadre du cabinet, de la fiscalité ou de la comptabilité, "
    "réponds brièvement puis recentre sur l'usage de l'application. "
    "N'utilise jamais de formatage Markdown (pas d'astérisques, pas de "
    "dièses, pas de tableaux) : réponds uniquement en texte brut, avec des "
    "tirets simples pour les listes si besoin."
)


def chat(
    messages: list[dict],
    role_label: str,
) -> str:
    """
    Assistant conversationnel général, avec le contexte du rôle de
    l'utilisateur connecté.
    """

    client = _get_client()

    system = f"{SYSTEM_PROMPT_BASE}\nL'utilisateur actuel a le rôle : {role_label}."

    contents = [
        types.Content(
            role="model" if message["role"] == "assistant" else "user",
            parts=[types.Part.from_text(text=message["content"])],
        )
        for message in messages
    ]

    try:
        response = _generate(client, 
            model=settings.GEMINI_MODEL,
            contents=contents,
            config=types.GenerateContentConfig(
                system_instruction=system,
            ),
        )
    except Exception as exc:
        raise _handle_error(exc)

    return (response.text or "").strip()


def suggerer_observations_declaration(declaration) -> str:
    """
    Suggère un paragraphe d'observations professionnelles pour une
    déclaration fiscale, à partir de ses données chiffrées.
    """

    client = _get_client()

    prompt = (
        "Voici les données d'une déclaration fiscale mensuelle :\n"
        f"- Période : {declaration.mois}/{declaration.annee}\n"
        f"- Chiffre d'affaires : {declaration.chiffre_affaires} FCFA\n"
        f"- Total des ventes : {declaration.total_ventes} FCFA\n"
        f"- Total des achats : {declaration.total_achats} FCFA\n"
        f"- Nombre d'employés : {declaration.nombre_employes}\n\n"
        "Rédige un court paragraphe d'observations professionnelles (3 à 5 "
        "phrases, en français) résumant la situation de cette période, à "
        "l'intention du fiscaliste qui va vérifier cette déclaration. "
        "Ne donne que le paragraphe, sans titre ni formule d'introduction."
    )

    try:
        response = _generate(client, 
            model=settings.GEMINI_MODEL,
            contents=prompt,
            config=types.GenerateContentConfig(
                system_instruction=SYSTEM_PROMPT_BASE,
            ),
        )
    except Exception as exc:
        raise _handle_error(exc)

    return (response.text or "").strip()


ALLOWED_ANALYSE_EXTENSIONS = {
    ".pdf": "application/pdf",
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".webp": "image/webp",
}


def analyser_document(document) -> dict:
    """
    Envoie le fichier d'un document à Gemini pour en extraire un résumé
    structuré (type, résumé, montants détectés, date, points d'attention).
    """

    client = _get_client()

    if not document.chemin_fichier:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ce document n'a pas de fichier associé.",
        )

    from app.services import file_storage

    if not file_storage.file_exists(document.chemin_fichier):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Fichier introuvable sur le serveur.",
        )

    extension = Path(document.chemin_fichier).suffix.lower()
    media_type = ALLOWED_ANALYSE_EXTENSIONS.get(extension)

    if media_type is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Ce type de fichier n'est pas pris en charge par "
                "l'analyse IA (PDF, PNG, JPG, WEBP uniquement)."
            ),
        )

    prompt = (
        "Analyse ce document administratif ou comptable et réponds "
        "UNIQUEMENT avec un objet JSON valide (rien d'autre, pas de texte "
        "autour, pas de balises markdown), avec exactement ces clés :\n"
        '{"type_document": "...", "resume": "...", "montants_detectes": '
        '["..."], "date_detectee": "...", "points_attention": "..."}\n'
        "Réponds en français. Si une information n'est pas présente dans "
        "le document, mets une chaîne vide (ou une liste vide) pour cette "
        "clé."
    )

    try:
        response = _generate(client, 
            model=settings.GEMINI_MODEL,
            contents=[
                types.Part.from_bytes(
                    data=file_storage.read_file(document.chemin_fichier),
                    mime_type=media_type,
                ),
                types.Part.from_text(text=prompt),
            ],
        )
    except Exception as exc:
        raise _handle_error(exc)

    texte = (response.text or "").strip()

    if texte.startswith("```"):
        texte = texte.strip("`")
        if texte.lower().startswith("json"):
            texte = texte[4:]
        texte = texte.strip()

    try:
        resultat = json.loads(texte)
    except (json.JSONDecodeError, ValueError):
        resultat = {
            "type_document": "",
            "resume": texte,
            "montants_detectes": [],
            "date_detectee": "",
            "points_attention": "",
        }

    return resultat

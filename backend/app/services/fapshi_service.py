import hmac

import httpx

from fastapi import HTTPException, status

from app.core.config import settings


class FapshiService:

    def __init__(self):
        self.base_url = settings.FAPSHI_BASE_URL.rstrip("/")
        self.api_user = settings.FAPSHI_API_USER
        self.api_key = settings.FAPSHI_API_KEY
        self.webhook_secret = settings.FAPSHI_WEBHOOK_SECRET

    def _check_configuration(self):
        if not self.api_user:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="FAPSHI_API_USER n'est pas configurée.",
            )

        if not self.api_key:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="FAPSHI_API_KEY n'est pas configurée.",
            )

    def _headers(self) -> dict:
        return {
            "apiuser": self.api_user,
            "apikey": self.api_key,
            "Content-Type": "application/json",
        }

    async def initiate_payment(
        self,
        amount: float,
        external_id: str,
        email: str | None = None,
        redirect_url: str | None = None,
        message: str | None = None,
    ) -> dict:
        self._check_configuration()

        payload = {
            "amount": int(round(amount)),
            "externalId": external_id,
        }

        if email:
            payload["email"] = email

        if redirect_url:
            payload["redirectUrl"] = redirect_url

        if message:
            payload["message"] = message

        url = f"{self.base_url}/initiate-pay"

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    url,
                    json=payload,
                    headers=self._headers(),
                )

        except httpx.RequestError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Impossible de contacter Fapshi : {exc}",
            )

        if response.status_code >= 400:
            try:
                error_data = response.json()
            except Exception:
                error_data = response.text

            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail={
                    "message": "Erreur lors de l'initialisation Fapshi",
                    "fapshi": error_data,
                },
            )

        return response.json()

    async def get_payment_status(self, trans_id: str) -> dict:
        self._check_configuration()

        url = f"{self.base_url}/payment-status/{trans_id}"

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.get(
                    url,
                    headers=self._headers(),
                )

        except httpx.RequestError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Impossible de contacter Fapshi : {exc}",
            )

        if response.status_code >= 400:
            try:
                error_data = response.json()
            except Exception:
                error_data = response.text

            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail={
                    "message": "Erreur lors de la vérification du paiement Fapshi",
                    "fapshi": error_data,
                },
            )

        return response.json()

    def verify_webhook_secret(self, header_value: str | None) -> bool:
        if not self.webhook_secret:
            return False

        return hmac.compare_digest(
            self.webhook_secret,
            header_value or "",
        )


fapshi_service = FapshiService()

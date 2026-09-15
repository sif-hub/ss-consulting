import hashlib
import hmac

import httpx

from fastapi import HTTPException, status

from app.core.config import settings


class NotchPayService:

    def __init__(self):
        self.base_url = settings.NOTCHPAY_BASE_URL.rstrip("/")
        self.public_key = settings.NOTCHPAY_PUBLIC_KEY
        self.private_key = settings.NOTCHPAY_PRIVATE_KEY
        self.hash_key = settings.NOTCHPAY_HASH_KEY

    def _check_configuration(self):
        if not self.public_key:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="NOTCHPAY_PUBLIC_KEY n'est pas configurée.",
            )

        if not self.private_key:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="NOTCHPAY_PRIVATE_KEY n'est pas configurée.",
            )

        if not self.hash_key:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="NOTCHPAY_HASH_KEY n'est pas configurée.",
            )

        if not settings.NOTCHPAY_CALLBACK_URL:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="NOTCHPAY_CALLBACK_URL n'est pas configurée.",
            )

    async def create_payment(
        self,
        amount: float,
        currency: str,
        email: str,
        phone: str,
        reference: str,
    ):
        self._check_configuration()

        payload = {
            "amount": int(round(amount)),
            "currency": currency,
            "email": email,
            "phone": phone,
            "reference": reference,
            "callback": settings.NOTCHPAY_CALLBACK_URL,
        }

        headers = {
            "Authorization": self.public_key,
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

        url = f"{self.base_url}/payments"

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    url,
                    json=payload,
                    headers=headers,
                )

        except httpx.RequestError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Impossible de contacter Notch Pay : {exc}",
            )

        if response.status_code >= 400:
            try:
                error_data = response.json()
            except Exception:
                error_data = response.text

            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail={
                    "message": "Erreur lors de l'initialisation Notch Pay",
                    "notchpay": error_data,
                },
            )

        return response.json()

    @staticmethod
    def extract_authorization_url(data: dict) -> str | None:
        candidates = [
            data.get("authorization_url"),
            data.get("authorizationUrl"),
        ]

        nested_data = data.get("data")

        if isinstance(nested_data, dict):
            candidates.extend(
                [
                    nested_data.get("authorization_url"),
                    nested_data.get("authorizationUrl"),
                ]
            )

            authorization = nested_data.get("authorization")

            if isinstance(authorization, dict):
                candidates.extend(
                    [
                        authorization.get("url"),
                        authorization.get("authorization_url"),
                    ]
                )

        authorization = data.get("authorization")

        if isinstance(authorization, dict):
            candidates.extend(
                [
                    authorization.get("url"),
                    authorization.get("authorization_url"),
                ]
            )

        for candidate in candidates:
            if isinstance(candidate, str) and candidate.strip():
                return candidate.strip()

        return None

    def verify_webhook_signature(
        self,
        payload: bytes,
        signature: str,
    ) -> bool:
        if not self.hash_key:
            return False

        expected_signature = hmac.new(
            self.hash_key.encode("utf-8"),
            payload,
            hashlib.sha256,
        ).hexdigest()

        return hmac.compare_digest(
            expected_signature,
            signature.strip(),
        )


notchpay_service = NotchPayService()

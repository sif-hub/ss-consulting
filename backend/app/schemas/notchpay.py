from pydantic import BaseModel, Field


class NotchPayInitRequest(BaseModel):
    facture_id: int = Field(gt=0)
    montant: float = Field(gt=0)


class NotchPayInitResponse(BaseModel):
    paiement_id: int
    facture_id: int
    reference: str
    montant: float
    statut: str
    authorization_url: str

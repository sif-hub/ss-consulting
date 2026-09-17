from pydantic import BaseModel, Field


class FapshiInitRequest(BaseModel):
    facture_id: int = Field(gt=0)
    montant: float = Field(gt=0)


class FapshiInitResponse(BaseModel):
    paiement_id: int
    facture_id: int
    reference: str
    montant: float
    statut: str
    payment_link: str


class FapshiStatutResponse(BaseModel):
    paiement_id: int
    facture_id: int
    reference: str
    statut: str
    fapshi_status: str

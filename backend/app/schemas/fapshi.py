from pydantic import BaseModel, Field


class FapshiInitRequest(BaseModel):
    facture_id: int = Field(gt=0)
    montant: float = Field(gt=0)


class FapshiDirectRequest(BaseModel):
    facture_id: int = Field(gt=0)
    montant: float = Field(gt=0)
    telephone: str = Field(min_length=9, max_length=15)


class FapshiDirectResponse(BaseModel):
    paiement_id: int
    facture_id: int
    reference: str
    montant: float
    statut: str


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

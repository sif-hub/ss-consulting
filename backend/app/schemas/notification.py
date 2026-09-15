from datetime import datetime

from pydantic import BaseModel, ConfigDict


class NotificationCreate(BaseModel):
    utilisateur_id: int
    type: str
    titre: str
    message: str
    reference_type: str | None = None
    reference_id: int | None = None
    date_echeance: datetime | None = None


class NotificationResponse(BaseModel):
    model_config = ConfigDict(
        from_attributes=True
    )

    id: int
    utilisateur_id: int
    type: str
    titre: str
    message: str
    reference_type: str | None
    reference_id: int | None
    date_echeance: datetime | None
    lu: bool
    date_lecture: datetime | None
    actif: bool
    created_at: datetime

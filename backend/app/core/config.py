from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Application
    APP_NAME: str = "SS Consulting API"
    APP_VERSION: str = "1.0.0"
    API_V1_PREFIX: str = "/api/v1"
    APP_DESCRIPTION: str = "API de gestion intégrée pour SS Consulting"
    DEBUG: bool = True

    # Database
    DATABASE_URL: str = (
        "postgresql+psycopg2://ss_consulting:ss_consulting_pass"
        "@localhost:5432/ss_consulting_db"
    )

    # JWT
    SECRET_KEY: str = "change-this-secret-key"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440

    # CORS
    BACKEND_CORS_ORIGINS: str = "*"

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.BACKEND_CORS_ORIGINS.split(",") if origin.strip()]

    # Paiements et commissions
    # Fapshi
    FAPSHI_API_USER: str = ""
    FAPSHI_API_KEY: str = ""
    FAPSHI_BASE_URL: str = "https://sandbox.fapshi.com"
    FAPSHI_WEBHOOK_SECRET: str = ""
    FAPSHI_REDIRECT_URL: str = ""
    PAYMENT_COMMISSION_RATE: float = 2.0
    PAYMENT_COMMISSION_ACCOUNT: str = ""

    # Intelligence artificielle (Google Gemini)
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL: str = "gemini-3.6-flash"

    # Environment
    ENVIRONMENT: str = "development"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()

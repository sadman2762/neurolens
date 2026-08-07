from functools import lru_cache

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "NeuroLens API"
    app_version: str = "0.1.0"
    environment: str = "development"

    allowed_origins: str = "*"
    revenuecat_webhook_secret: str = ""

    openai_api_key: SecretStr

    # Existing vision/text model
    openai_model: str = "gpt-5-mini"

    # Image editing model
    openai_image_model: str = "gpt-image-2"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @property
    def cors_origins(self) -> list[str]:
        if self.allowed_origins.strip() == "*":
            return ["*"]

        return [
            origin.strip()
            for origin in self.allowed_origins.split(",")
            if origin.strip()
        ]


@lru_cache
def get_settings() -> Settings:
    return Settings()
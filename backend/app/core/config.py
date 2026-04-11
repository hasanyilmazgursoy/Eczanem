"""Eczanem Backend — Uygulama yapılandırması."""

from functools import lru_cache
from pathlib import Path

from pydantic import field_validator
from pydantic_settings import BaseSettings

# backend klasörünün yolu (.env dosyası burada)
BACKEND_DIR = Path(__file__).resolve().parent.parent.parent


class Settings(BaseSettings):
    # Google AI Studio (Gemini)
    gemini_api_key: str = ""
    gemini_model: str = "gemini-2.5-flash"

    # İlaç arama performans / koruma ayarları
    drug_search_cache_ttl_seconds: int = 60 * 30
    drug_search_rate_limit_window_seconds: int = 60
    drug_search_rate_limit_max_requests: int = 10

    # JWT (geliştirme varsayılanı; prod'da env ile override edilmeli)
    jwt_secret_key: str = "eczanem-dev-secret-key-change-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24 * 7

    # PostgreSQL
    postgres_host: str = "localhost"
    postgres_port: int = 5432
    postgres_db: str = "eczanem"
    postgres_user: str = "eczanem_user"
    postgres_password: str = "eczanem_pass_123"

    # Redis
    redis_host: str = "localhost"
    redis_port: int = 6379

    # API
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    debug: bool = True

    @field_validator("debug", mode="before")
    @classmethod
    def _normalize_debug_value(cls, value: object) -> object:
        if isinstance(value, str):
            normalized = value.strip().lower()
            if normalized == "release":
                return False
            if normalized == "debug":
                return True

        return value

    @property
    def database_url(self) -> str:
        return (
            f"postgresql+asyncpg://{self.postgres_user}:{self.postgres_password}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )

    @property
    def redis_url(self) -> str:
        return f"redis://{self.redis_host}:{self.redis_port}"

    model_config = {
        "env_file": str(BACKEND_DIR / ".env"),
        "env_file_encoding": "utf-8",
    }


@lru_cache
def get_settings() -> Settings:
    return Settings()

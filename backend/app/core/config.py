"""Eczanem Backend — Uygulama yapılandırması."""

from functools import lru_cache
from pathlib import Path

from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings

# backend klasörünün yolu (.env dosyası burada)
BACKEND_DIR = Path(__file__).resolve().parent.parent.parent


class Settings(BaseSettings):
    # Google AI Studio (Gemini)
    gemini_api_key: str = ""
    gemini_model: str = "gemini-2.5-flash"

    # İlaç arama performans / koruma ayarları
    drug_search_cache_ttl_seconds: int = 60 * 60 * 24
    drug_search_rate_limit_window_seconds: int = 60
    drug_search_rate_limit_max_requests: int = 10
    drug_search_redis_enabled: bool = True

    # Nöbetçi eczane (CollectAPI) — .env'e COLLECT_API_KEY=apikey <key> ekle
    collect_api_key: str = ""

    # JWT — .env'de JWT_SECRET_KEY tanımlanmalı; bu fallback yalnızca geliştirme içindir
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
    redis_db: int = 0

    # API
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    # Güvenli production varsayılanı; geliştirmede .env ile DEBUG=True override edilir
    debug: bool = False

    # CORS — virgülle ayrılmış domain listesi; prod'da .env'den override edilmeli
    # Örnek: ALLOWED_ORIGINS=http://localhost:3000,https://eczanem.app
    allowed_origins: list[str] = ["*"]

    @model_validator(mode="after")
    def _check_production_jwt_secret(self) -> "Settings":
        """Production modunda varsayılan JWT secret'in kullanılmasını engeller.

        Varsayılan anahtar herkese açık olduğundan saldırganlar geçerli token
        üretebilir. .env dosyasında JWT_SECRET_KEY tanımlanması zorunludur.
        """
        _default = "eczanem-dev-secret-key-change-in-production"
        if not self.debug and self.jwt_secret_key == _default:
            raise ValueError(
                "Production modunda (DEBUG=False) JWT_SECRET_KEY varsayılan değeri "
                "kullananamaz. .env dosyasında güçlü bir JWT_SECRET_KEY tanımlayın."
            )
        return self

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

    class Config:
        env_file = str(BACKEND_DIR / ".env")
        env_file_encoding = "utf-8"
        extra = "ignore"


@lru_cache
def get_settings() -> Settings:
    return Settings()

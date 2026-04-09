"""Eczanem Backend — Uygulama yapılandırması."""

from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # OpenRouter
    openrouter_api_key: str = ""
    openrouter_model: str = "google/gemini-2.0-flash-001"

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

    @property
    def database_url(self) -> str:
        return (
            f"postgresql+asyncpg://{self.postgres_user}:{self.postgres_password}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )

    @property
    def redis_url(self) -> str:
        return f"redis://{self.redis_host}:{self.redis_port}"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


@lru_cache
def get_settings() -> Settings:
    return Settings()

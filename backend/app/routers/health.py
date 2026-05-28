"""Health check endpoint."""

import logging

import redis as redis_lib
from fastapi import APIRouter
from fastapi.responses import JSONResponse

from app.core.config import get_settings

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/health")
async def health_check() -> JSONResponse:
    """Servis ve bağımlılık sağlık kontrolü.

    Docker HEALTHCHECK, load balancer ve uptime monitörleri tarafından kullanılır.
    Tüm bağımlılıklar sağlıklıysa 200, herhangi biri sorunluysa 503 döner.
    """
    settings = get_settings()
    checks: dict[str, str] = {}
    healthy = True

    # Redis ping — yalnızca etkinse denetlenir
    if settings.drug_search_redis_enabled:
        try:
            r = redis_lib.Redis(
                host=settings.redis_host,
                port=settings.redis_port,
                db=settings.redis_db,
                socket_timeout=2,
                socket_connect_timeout=2,
            )
            r.ping()
            checks["redis"] = "ok"
        except Exception as exc:
            # Redis sadece cache olduğundan servisi tamamen durdurmayalım
            logger.warning("Redis health check başarısız: %s", exc)
            checks["redis"] = "degraded"

    status_code = 200 if healthy else 503
    return JSONResponse(
        status_code=status_code,
        content={
            "status": "ok" if healthy else "degraded",
            "service": "eczanem-api",
            "version": "0.1.0",
            "checks": checks,
        },
    )

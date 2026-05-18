"""Eczanem Backend — Ana uygulama."""

import logging

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import get_settings
from app.routers import auth, health, drug, profile, pharmacy

logger = logging.getLogger(__name__)


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title="Eczanem API",
        description="Kişisel İlaç Asistanı Backend API",
        version="0.1.0",
        docs_url="/docs" if settings.debug else None,
        redoc_url="/redoc" if settings.debug else None,
    )

    # Flutter'dan gelen isteklere izin ver
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,  # Prod'da .env ile kısıtlanır
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Yakalanmamış istisnalar için genel hata handler'ı.
    # Kullanıcıya ham traceback sızdırmaz; 500 ile sade bir mesaj döner.
    @app.exception_handler(Exception)
    async def unhandled_exception_handler(
        request: Request, exc: Exception
    ) -> JSONResponse:
        logger.exception("Unhandled exception for %s %s", request.method, request.url)
        return JSONResponse(
            status_code=500,
            content={
                "detail": "Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin."
            },
        )

    # Router'ları bağla
    app.include_router(health.router, tags=["Health"])
    app.include_router(auth.router, prefix="/auth", tags=["Auth"])
    app.include_router(drug.router, prefix="/api/drug", tags=["Drug"])
    app.include_router(profile.router, prefix="/api/profile", tags=["Profile"])
    app.include_router(pharmacy.router, prefix="/api/pharmacy", tags=["Pharmacy"])

    return app


app = create_app()

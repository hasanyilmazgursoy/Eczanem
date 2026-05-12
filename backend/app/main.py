"""Eczanem Backend — Ana uygulama."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.routers import auth, health, drug, profile, pharmacy


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

    # Router'ları bağla
    app.include_router(health.router, tags=["Health"])
    app.include_router(auth.router, prefix="/auth", tags=["Auth"])
    app.include_router(auth.router, prefix="/api/auth", tags=["Auth"])
    app.include_router(drug.router, prefix="/api/drug", tags=["Drug"])
    app.include_router(profile.router, prefix="/api/profile", tags=["Profile"])
    app.include_router(pharmacy.router, prefix="/api/pharmacy", tags=["Pharmacy"])

    return app


app = create_app()

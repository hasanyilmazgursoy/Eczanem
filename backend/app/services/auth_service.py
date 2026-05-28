"""Geliştirme ortamı için basit dosya tabanlı kimlik doğrulama servisi.

Bu servis PostgreSQL kurulmadan auth akışını ayağa kaldırmak için kullanılır.
FAZ 3'te kalıcı veritabanı katmanına taşınabilir.
"""

from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
from threading import RLock
from uuid import uuid4

from fastapi import HTTPException, status
from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import get_settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
# RLock, change_password gibi iç çağrı zincirinde re-entrant kullanımı destekler
_store_lock = RLock()
_users_file = Path(__file__).resolve().parent.parent.parent / "data" / "users.json"


def _ensure_user_store() -> None:
    _users_file.parent.mkdir(parents=True, exist_ok=True)
    if not _users_file.exists():
        _users_file.write_text("[]", encoding="utf-8")


def _load_users() -> list[dict]:
    _ensure_user_store()
    with _store_lock:
        try:
            return json.loads(_users_file.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            # Bozuk dosya durumda geliştirme akışını tamamen kilitlememek için sıfırla.
            _users_file.write_text("[]", encoding="utf-8")
            return []


def _save_users(users: list[dict]) -> None:
    _ensure_user_store()
    with _store_lock:
        _users_file.write_text(
            json.dumps(users, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )


def _normalize_email(email: str) -> str:
    return email.strip().lower()


def _public_user(user: dict) -> dict:
    return {
        "id": user["id"],
        "name": user["name"],
        "email": user["email"],
        "created_at": user["created_at"],
    }


def _find_user_by_email(email: str) -> dict | None:
    normalized_email = _normalize_email(email)
    users = _load_users()
    return next((user for user in users if user["email"] == normalized_email), None)


def _find_user_by_id(user_id: str) -> dict | None:
    users = _load_users()
    return next((user for user in users if user["id"] == user_id), None)


def create_user(name: str, email: str, password: str) -> dict:
    name = name.strip()
    normalized_email = _normalize_email(email)

    if not name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ad soyad boş olamaz.",
        )

    if len(password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Şifre en az 6 karakter olmalıdır.",
        )

    new_user = {
        "id": uuid4().hex,
        "name": name,
        "email": normalized_email,
        "password_hash": pwd_context.hash(password),
        "created_at": datetime.now(timezone.utc).isoformat(),
    }

    # Lock tüm oku-kontrol-yaz döngüsünü kapsar; aynı e-postayla eş zamanlı
    # iki signup isteği arasında TOCTOU yarışını önler.
    with _store_lock:
        users = _load_users()
        if any(user["email"] == normalized_email for user in users):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Bu e-posta adresiyle kayıtlı bir hesap zaten var.",
            )
        users.append(new_user)
        _save_users(users)

    return _public_user(new_user)


def authenticate_user(email: str, password: str) -> dict:
    user = _find_user_by_email(email)
    if user is None or not pwd_context.verify(password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="E-posta veya şifre hatalı.",
        )

    return _public_user(user)


def create_access_token(user_id: str) -> str:
    settings = get_settings()
    expire_at = datetime.now(timezone.utc) + timedelta(
        minutes=settings.jwt_expire_minutes
    )
    payload = {
        "sub": user_id,
        "exp": expire_at,
    }
    return jwt.encode(
        payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm
    )


def change_password(user_id: str, current_password: str, new_password: str) -> None:
    """Mevcut şifreyi doğrular, yeni şifreyi hash'leyerek günceller.

    İşlem _store_lock ile atomik tutulur; aynı lock içinde yükleme ve kayıt
    yapıldığından race condition oluşmaz.
    """
    if len(new_password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Yeni şifre en az 6 karakter olmalıdır.",
        )

    _ensure_user_store()
    with _store_lock:
        try:
            users: list[dict] = json.loads(_users_file.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            users = []

        idx = next((i for i, u in enumerate(users) if u["id"] == user_id), -1)
        if idx == -1:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Kullanıcı bulunamadı.",
            )

        if not pwd_context.verify(current_password, users[idx]["password_hash"]):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Mevcut şifre hatalı.",
            )

        users[idx] = {**users[idx], "password_hash": pwd_context.hash(new_password)}
        _users_file.write_text(
            json.dumps(users, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )


def get_current_user(token: str) -> dict:
    settings = get_settings()

    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
    except JWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Oturum doğrulanamadı. Lütfen tekrar giriş yapın.",
        ) from exc

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Geçersiz oturum bilgisi.",
        )

    user = _find_user_by_id(user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Kullanıcı bulunamadı.",
        )

    return _public_user(user)

"""Auth endpoint'leri."""

from collections import deque
from threading import Lock
from time import time

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field

from app.services.auth_service import (
    authenticate_user,
    create_access_token,
    create_user,
    get_current_user,
)
from app.services.auth_service import (
    change_password as change_password_service,
)

router = APIRouter()
security = HTTPBearer(auto_error=False)

# ---------------------------------------------------------------------------
# Auth endpoint'leri için kayan pencere (sliding window) rate limiter.
# Ayrı bir servis dosyası gerektirmeyecek kadar küçük olduğundan burada tutulur.
# ---------------------------------------------------------------------------
_auth_rate_limit_lock = Lock()
_auth_rate_limit_buckets: dict[str, deque[float]] = {}
_AUTH_WINDOW_SECONDS = 60
_AUTH_MAX_REQUESTS = 20


def _resolve_client_key(http_request: Request) -> str:
    """Proxy arkasında gerçek istemci IP'sini belirler."""
    forwarded_for = http_request.headers.get("x-forwarded-for")
    if forwarded_for:
        return forwarded_for.split(",", 1)[0].strip()
    return http_request.client.host if http_request.client else "unknown-client"


def _enforce_auth_rate_limit(client_key: str) -> None:
    now = time()
    window_start = now - _AUTH_WINDOW_SECONDS

    with _auth_rate_limit_lock:
        bucket = _auth_rate_limit_buckets.setdefault(client_key, deque())

        # Pencere dışına çıkmış kayıtları temizle
        while bucket and bucket[0] <= window_start:
            bucket.popleft()

        if len(bucket) >= _AUTH_MAX_REQUESTS:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Çok fazla istek gönderildi. Lütfen bir süre bekleyin.",
            )

        bucket.append(now)

        # Uzun süre hiç istek gelmeyen IP girişlerini ara sıra temizle (bellek sızıntısı önleme).
        if len(_auth_rate_limit_buckets) > 5_000:
            stale = [
                k
                for k, v in _auth_rate_limit_buckets.items()
                if not v or v[-1] <= window_start
            ]
            for k in stale:
                _auth_rate_limit_buckets.pop(k, None)


class SignupRequest(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    email: str = Field(min_length=3, max_length=255)
    password: str = Field(min_length=6, max_length=255)


class LoginRequest(BaseModel):
    email: str = Field(min_length=3, max_length=255)
    password: str = Field(min_length=6, max_length=255)


class ForgotPasswordRequest(BaseModel):
    email: str = Field(min_length=3, max_length=255)


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(min_length=1, max_length=255)
    new_password: str = Field(min_length=6, max_length=255)


class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    created_at: str


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class MessageResponse(BaseModel):
    message: str


def _resolve_token(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
) -> str:
    if credentials is None or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Yetkilendirme başlığı bulunamadı.",
        )
    return credentials.credentials


@router.post("/signup", response_model=AuthResponse)
async def signup(request: SignupRequest, http_request: Request):
    _enforce_auth_rate_limit(_resolve_client_key(http_request))
    user = create_user(request.name, request.email, request.password)
    access_token = create_access_token(user["id"])
    return AuthResponse(access_token=access_token, user=UserResponse(**user))


@router.post("/register", response_model=AuthResponse)
async def register(request: SignupRequest, http_request: Request):
    """FAZ 3 planındaki endpoint ismini şimdiden destekle."""
    return await signup(request, http_request)


@router.post("/login", response_model=AuthResponse)
async def login(request: LoginRequest, http_request: Request):
    _enforce_auth_rate_limit(_resolve_client_key(http_request))
    user = authenticate_user(request.email, request.password)
    access_token = create_access_token(user["id"])
    return AuthResponse(access_token=access_token, user=UserResponse(**user))


@router.get("/me", response_model=UserResponse)
async def me(token: str = Depends(_resolve_token)):
    user = get_current_user(token)
    return UserResponse(**user)


@router.post("/logout", response_model=MessageResponse)
async def logout(_: str = Depends(_resolve_token)):
    # JWT stateless olduğu için backend tarafında ekstra iş yok.
    return MessageResponse(message="Çıkış başarılı.")


@router.post("/forgot-password", response_model=MessageResponse)
async def forgot_password(_: ForgotPasswordRequest, http_request: Request):
    # Rate limit: e-posta enumeration ve DoS saldırılarını sınırla.
    _enforce_auth_rate_limit(_resolve_client_key(http_request))
    # Şimdiki zaman: stub. FAZ 3'te e-posta sağlayıcısıyla gerçek akış bağlanacak.
    return MessageResponse(message="Şifre sıfırlama bağlantısı gönderildi.")


@router.put("/change-password", response_model=MessageResponse)
async def change_password(
    request: ChangePasswordRequest,
    token: str = Depends(_resolve_token),
):
    """Giriş yapmış kullanıcının şifresini değiştirir."""
    user = get_current_user(token)
    change_password_service(user["id"], request.current_password, request.new_password)
    return MessageResponse(message="Şifre başarıyla güncellendi.")

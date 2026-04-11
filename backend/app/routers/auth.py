"""Auth endpoint'leri."""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field

from app.services.auth_service import (
    authenticate_user,
    create_access_token,
    create_user,
    get_current_user,
)

router = APIRouter()
security = HTTPBearer(auto_error=False)


class SignupRequest(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    email: str = Field(min_length=3, max_length=255)
    password: str = Field(min_length=6, max_length=255)


class LoginRequest(BaseModel):
    email: str = Field(min_length=3, max_length=255)
    password: str = Field(min_length=6, max_length=255)


class ForgotPasswordRequest(BaseModel):
    email: str = Field(min_length=3, max_length=255)


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
async def signup(request: SignupRequest):
    user = create_user(request.name, request.email, request.password)
    access_token = create_access_token(user["id"])
    return AuthResponse(access_token=access_token, user=UserResponse(**user))


@router.post("/register", response_model=AuthResponse)
async def register(request: SignupRequest):
    """FAZ 3 planındaki endpoint ismini şimdiden destekle."""
    return await signup(request)


@router.post("/login", response_model=AuthResponse)
async def login(request: LoginRequest):
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
async def forgot_password(_: ForgotPasswordRequest):
    # Şimdilik stub. FAZ 3'te e-posta sağlayıcısı ile gerçek akış bağlanacak.
    return MessageResponse(message="Şifre sıfırlama bağlantısı gönderildi.")

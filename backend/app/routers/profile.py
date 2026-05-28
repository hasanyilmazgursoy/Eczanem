"""Aile profili endpoint'leri (FAZ 3)."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, Field

from app.services.auth_service import get_current_user
from app.services.profile_service import (
    add_member_drug,
    create_family_member,
    delete_family_member,
    list_family_members,
    list_member_drugs,
    remove_member_drug,
    update_family_member,
)

router = APIRouter()
security = HTTPBearer(auto_error=False)


# ---------------------------------------------------------------------------
# Token çözümleme yardımcısı
# ---------------------------------------------------------------------------


def _resolve_token(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
) -> str:
    if credentials is None or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Yetkilendirme başlığı bulunamadı.",
        )
    return credentials.credentials


def _get_user_id(token: str = Depends(_resolve_token)) -> str:
    user = get_current_user(token)
    return user["id"]


# ---------------------------------------------------------------------------
# Pydantic modeller
# ---------------------------------------------------------------------------


class FamilyMemberDrugResponse(BaseModel):
    id: str
    drug_name: str
    dosage: str
    frequency: str
    notes: str
    added_at: str


class FamilyMemberResponse(BaseModel):
    id: str
    user_id: str
    name: str
    relationship: str
    age: int | None
    emoji: str
    drugs: list[FamilyMemberDrugResponse] = []
    created_at: str
    updated_at: str


class CreateFamilyMemberRequest(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    relationship: str = Field(default="", max_length=40)
    age: int | None = Field(default=None, ge=0, le=130)
    emoji: str = Field(default="👤", max_length=10)


class UpdateFamilyMemberRequest(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=80)
    relationship: str | None = Field(default=None, max_length=40)
    age: int | None = Field(default=None, ge=0, le=130)
    emoji: str | None = Field(default=None, max_length=10)


class AddMemberDrugRequest(BaseModel):
    drug_name: str = Field(min_length=1, max_length=120)
    dosage: str = Field(default="", max_length=80)
    frequency: str = Field(default="", max_length=80)
    notes: str = Field(default="", max_length=300)


class MessageResponse(BaseModel):
    message: str


# ---------------------------------------------------------------------------
# Aile üyesi CRUD endpoint'leri
# ---------------------------------------------------------------------------


@router.get("/family/", response_model=list[FamilyMemberResponse])
async def get_family_members(user_id: str = Depends(_get_user_id)):
    """Giriş yapmış kullanıcının tüm aile üyelerini listeler."""
    return list_family_members(user_id)


@router.post(
    "/family/",
    response_model=FamilyMemberResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_member(
    request: CreateFamilyMemberRequest,
    user_id: str = Depends(_get_user_id),
):
    """Yeni aile üyesi ekler."""
    return create_family_member(
        user_id=user_id,
        name=request.name,
        relationship=request.relationship,
        age=request.age,
        emoji=request.emoji,
    )


@router.put("/family/{member_id}", response_model=FamilyMemberResponse)
async def update_member(
    member_id: str,
    request: UpdateFamilyMemberRequest,
    user_id: str = Depends(_get_user_id),
):
    """Mevcut aile üyesini günceller.

    Sadece gönderilen alanlar güncellenir (PATCH semantikler).
    age: null gönderilirse yaş alanı temizlenir.
    """
    return update_family_member(
        user_id=user_id,
        member_id=member_id,
        updates=request.model_dump(exclude_unset=True),
    )


@router.delete("/family/{member_id}", response_model=MessageResponse)
async def delete_member(
    member_id: str,
    user_id: str = Depends(_get_user_id),
):
    """Aile üyesini ve ilişkili ilaç kayıtlarını siler."""
    delete_family_member(user_id=user_id, member_id=member_id)
    return MessageResponse(message="Aile üyesi silindi.")


# ---------------------------------------------------------------------------
# Aile üyesi ilaç listesi endpoint'leri
# ---------------------------------------------------------------------------


@router.get(
    "/family/{member_id}/drugs/",
    response_model=list[FamilyMemberDrugResponse],
)
async def get_member_drugs(
    member_id: str,
    user_id: str = Depends(_get_user_id),
):
    """Bir aile üyesinin ilaç listesini döndürür."""
    return list_member_drugs(user_id=user_id, member_id=member_id)


@router.post(
    "/family/{member_id}/drugs/",
    response_model=FamilyMemberDrugResponse,
    status_code=status.HTTP_201_CREATED,
)
async def add_drug(
    member_id: str,
    request: AddMemberDrugRequest,
    user_id: str = Depends(_get_user_id),
):
    """Aile üyesine yeni ilaç kaydı ekler."""
    return add_member_drug(
        user_id=user_id,
        member_id=member_id,
        drug_name=request.drug_name,
        dosage=request.dosage,
        frequency=request.frequency,
        notes=request.notes,
    )


@router.delete(
    "/family/{member_id}/drugs/{drug_id}",
    response_model=MessageResponse,
)
async def remove_drug(
    member_id: str,
    drug_id: str,
    user_id: str = Depends(_get_user_id),
):
    """Aile üyesinden ilaç kaydını siler."""
    remove_member_drug(user_id=user_id, member_id=member_id, drug_id=drug_id)
    return MessageResponse(message="İlaç kaydı silindi.")

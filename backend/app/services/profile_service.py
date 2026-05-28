"""Aile profili yönetimi için dosya tabanlı servis.

auth_service.py ile aynı pattern'ı izler — geliştirme ortamı için JSON
dosyası tabanlı veri deposu. FAZ 8'de PostgreSQL'e taşınabilir.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from threading import RLock
from uuid import uuid4

from fastapi import HTTPException, status

# RLock, CRUD fonksiyonlarının lock içinden _load_all/_save_all çağırabilmesi için gerekli
_store_lock = RLock()
_profiles_file = (
    Path(__file__).resolve().parent.parent.parent / "data" / "family_profiles.json"
)


# ---------------------------------------------------------------------------
# Dosya tabanlı veri deposu yardımcıları
# ---------------------------------------------------------------------------


def _ensure_store() -> None:
    _profiles_file.parent.mkdir(parents=True, exist_ok=True)
    if not _profiles_file.exists():
        _profiles_file.write_text("{}", encoding="utf-8")


def _load_all() -> dict[str, list[dict]]:
    """Tüm kullanıcıların aile verilerini döndürür. {user_id: [member, ...]}"""
    _ensure_store()
    with _store_lock:
        try:
            return json.loads(_profiles_file.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            _profiles_file.write_text("{}", encoding="utf-8")
            return {}


def _save_all(data: dict[str, list[dict]]) -> None:
    _ensure_store()
    with _store_lock:
        _profiles_file.write_text(
            json.dumps(data, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )


def _load_members(user_id: str) -> list[dict]:
    return _load_all().get(user_id, [])


def _save_members(user_id: str, members: list[dict]) -> None:
    data = _load_all()
    data[user_id] = members
    _save_all(data)


def _find_member(user_id: str, member_id: str) -> dict | None:
    return next((m for m in _load_members(user_id) if m["id"] == member_id), None)


# ---------------------------------------------------------------------------
# Aile üyesi CRUD
# ---------------------------------------------------------------------------


def list_family_members(user_id: str) -> list[dict]:
    return _load_members(user_id)


def create_family_member(
    user_id: str,
    name: str,
    relationship: str,
    age: int | None,
    emoji: str,
) -> dict:
    name = name.strip()
    if not name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Aile üyesi adı boş olamaz.",
        )

    member: dict = {
        "id": uuid4().hex,
        "user_id": user_id,
        "name": name,
        "relationship": relationship.strip(),
        "age": age,
        "emoji": emoji or "👤",
        "drugs": [],
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }

    # Oku-ekle-yaz tek atomik işlem; eş zamanlı yazışma veri kaybını önler.
    with _store_lock:
        members = _load_members(user_id)
        members.append(member)
        _save_members(user_id, members)
    return member


def update_family_member(
    user_id: str,
    member_id: str,
    name: str | None,
    relationship: str | None,
    age: int | None,
    emoji: str | None,
) -> dict:
    with _store_lock:
        members = _load_members(user_id)
        idx = next((i for i, m in enumerate(members) if m["id"] == member_id), None)

        if idx is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Aile üyesi bulunamadı.",
            )

        member = dict(members[idx])
        if name is not None:
            member["name"] = name.strip()
        if relationship is not None:
            member["relationship"] = relationship.strip()
        if age is not None:
            member["age"] = age
        if emoji is not None:
            member["emoji"] = emoji
        member["updated_at"] = datetime.now(timezone.utc).isoformat()

        members[idx] = member
        _save_members(user_id, members)
    return member


def delete_family_member(user_id: str, member_id: str) -> None:
    with _store_lock:
        members = _load_members(user_id)
        updated = [m for m in members if m["id"] != member_id]

        if len(updated) == len(members):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Aile üyesi bulunamadı.",
            )

        _save_members(user_id, updated)


# ---------------------------------------------------------------------------
# Aile üyesi ilaç listesi CRUD
# ---------------------------------------------------------------------------


def list_member_drugs(user_id: str, member_id: str) -> list[dict]:
    member = _find_member(user_id, member_id)
    if member is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Aile üyesi bulunamadı.",
        )
    return member.get("drugs", [])


def add_member_drug(
    user_id: str,
    member_id: str,
    drug_name: str,
    dosage: str,
    frequency: str,
    notes: str,
) -> dict:
    drug: dict = {
        "id": uuid4().hex,
        "drug_name": drug_name.strip(),
        "dosage": dosage.strip(),
        "frequency": frequency.strip(),
        "notes": notes.strip(),
        "added_at": datetime.now(timezone.utc).isoformat(),
    }

    with _store_lock:
        members = _load_members(user_id)
        idx = next((i for i, m in enumerate(members) if m["id"] == member_id), None)

        if idx is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Aile üyesi bulunamadı.",
            )

        member = dict(members[idx])
        member["drugs"] = list(member.get("drugs", []))
        member["drugs"].append(drug)
        member["updated_at"] = datetime.now(timezone.utc).isoformat()

        members[idx] = member
        _save_members(user_id, members)
    return drug


def remove_member_drug(user_id: str, member_id: str, drug_id: str) -> None:
    with _store_lock:
        members = _load_members(user_id)
        idx = next((i for i, m in enumerate(members) if m["id"] == member_id), None)

        if idx is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Aile üyesi bulunamadı.",
            )

        member = dict(members[idx])
        drugs = list(member.get("drugs", []))
        updated_drugs = [d for d in drugs if d["id"] != drug_id]

        if len(updated_drugs) == len(drugs):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="İlaç kaydı bulunamadı.",
            )

        member["drugs"] = updated_drugs
        member["updated_at"] = datetime.now(timezone.utc).isoformat()
        members[idx] = member
        _save_members(user_id, members)

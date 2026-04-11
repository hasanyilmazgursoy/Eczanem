"""İlaç arama için bellek içi cache ve rate limit yardımcıları.

FAZ 1 için Redis zorunluluğu getirmeden hızlı yanıt ve temel koruma sağlar.
İleride Redis eklenirse aynı arayüz kalıp kalıcı katmana taşınabilir.
"""

from __future__ import annotations

from collections import deque
from copy import deepcopy
from dataclasses import dataclass
from threading import Lock
from time import time

from fastapi import HTTPException, status

from app.core.config import get_settings
from app.services.gemini_service import query_drug_info


@dataclass
class _CacheEntry:
    expires_at: float
    payload: dict


_cache_lock = Lock()
_rate_limit_lock = Lock()
_query_cache: dict[str, _CacheEntry] = {}
_rate_limit_buckets: dict[str, deque[float]] = {}


def _normalize_query(query: str) -> str:
    return " ".join(query.strip().lower().split())


def _clone_payload(payload: dict) -> dict:
    # Cache içeriğinin çağıran kod tarafından yanlışlıkla mutate edilmesini önler.
    return deepcopy(payload)


def _get_cached_response(query: str) -> dict | None:
    normalized_query = _normalize_query(query)
    now = time()

    with _cache_lock:
        entry = _query_cache.get(normalized_query)
        if entry is None:
            return None

        if entry.expires_at <= now:
            _query_cache.pop(normalized_query, None)
            return None

        return _clone_payload(entry.payload)


def _cache_response(query: str, payload: dict) -> None:
    settings = get_settings()
    normalized_query = _normalize_query(query)

    with _cache_lock:
        _query_cache[normalized_query] = _CacheEntry(
            expires_at=time() + settings.drug_search_cache_ttl_seconds,
            payload=_clone_payload(payload),
        )


def _enforce_rate_limit(client_key: str) -> None:
    settings = get_settings()
    now = time()
    window_start = now - settings.drug_search_rate_limit_window_seconds

    with _rate_limit_lock:
        bucket = _rate_limit_buckets.setdefault(client_key, deque())

        while bucket and bucket[0] <= window_start:
            bucket.popleft()

        if len(bucket) >= settings.drug_search_rate_limit_max_requests:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Çok fazla ilaç arama isteği gönderdiniz. Lütfen kısa süre sonra tekrar deneyin.",
            )

        bucket.append(now)


async def query_drug_info_with_guard(drug_name: str, client_key: str) -> dict:
    """Cache hit varsa onu döndürür, yoksa rate limit sonrası Gemini'ye gider."""
    cached_response = _get_cached_response(drug_name)
    if cached_response is not None:
        return cached_response

    # Cache hit'lerini limite saymıyoruz; Gemini maliyetini korumak istediğimiz yer miss akışı.
    _enforce_rate_limit(client_key)

    response = await query_drug_info(drug_name)
    _cache_response(drug_name, response)
    return _clone_payload(response)

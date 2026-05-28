"""İlaç arama için cache ve rate limit yardımcıları.

Öncelik Redis cache'tir. Redis erişilemezse geliştirme akışını kırmamak için
bellek içi cache'e otomatik düşülür.
"""

from __future__ import annotations

from collections import deque
from copy import deepcopy
from dataclasses import dataclass
import json
from threading import Lock
from time import time

from fastapi import HTTPException, status
from redis import asyncio as redis_async
from redis.exceptions import RedisError

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
_redis_client: redis_async.Redis | None = None
_redis_lock = Lock()


def _normalize_query(query: str) -> str:
    return " ".join(query.strip().lower().split())


def _clone_payload(payload: dict) -> dict:
    # Cache içeriğinin çağıran kod tarafından yanlışlıkla mutate edilmesini önler.
    return deepcopy(payload)


def _build_cache_key(query: str) -> str:
    return f"drug-search:{_normalize_query(query)}"


def _get_redis_client() -> redis_async.Redis | None:
    settings = get_settings()
    if not settings.drug_search_redis_enabled:
        return None

    global _redis_client

    if _redis_client is not None:
        return _redis_client

    with _redis_lock:
        if _redis_client is None:
            # Settings'te redis_host/port/db ayrı tutulduğundan URL burada üretilir
            redis_url = f"redis://{settings.redis_host}:{settings.redis_port}/{settings.redis_db}"
            _redis_client = redis_async.from_url(
                redis_url,
                encoding="utf-8",
                decode_responses=True,
            )

    return _redis_client


async def _get_cached_response_from_redis(query: str) -> dict | None:
    redis_client = _get_redis_client()
    if redis_client is None:
        return None

    try:
        cached_payload = await redis_client.get(_build_cache_key(query))
        if not cached_payload:
            return None

        return json.loads(cached_payload)
    except (RedisError, json.JSONDecodeError):
        return None


async def _cache_response_in_redis(query: str, payload: dict) -> bool:
    redis_client = _get_redis_client()
    if redis_client is None:
        return False

    settings = get_settings()

    try:
        await redis_client.set(
            _build_cache_key(query),
            json.dumps(payload, ensure_ascii=False),
            ex=settings.drug_search_cache_ttl_seconds,
        )
        return True
    except RedisError:
        return False


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

        # Uzun süredir istek gelmeyen IP girişlerini ara sıra temizle.
        if len(_rate_limit_buckets) > 5_000:
            stale = [
                k for k, v in _rate_limit_buckets.items()
                if not v or v[-1] <= window_start
            ]
            for k in stale:
                _rate_limit_buckets.pop(k, None)


async def query_drug_info_with_guard(drug_name: str, client_key: str) -> dict:
    """Cache hit varsa onu döndürür, yoksa rate limit sonrası Gemini'ye gider."""
    cached_response = await _get_cached_response_from_redis(drug_name)
    if cached_response is None:
        cached_response = _get_cached_response(drug_name)

    if cached_response is not None:
        return _clone_payload(cached_response)

    # Cache hit'lerini limite saymıyoruz; Gemini maliyetini korumak istediğimiz yer miss akışı.
    _enforce_rate_limit(client_key)

    response = await query_drug_info(drug_name)
    await _cache_response_in_redis(drug_name, response)
    _cache_response(drug_name, response)
    return _clone_payload(response)

"""GOAL v1 transport: backend-only credentials, shared cache and hard daily cap.

Contract: https://goal-api.com/openapi.json (Bearer authentication).
Failed calls consume budget too. No response body or credentials enter logs.
"""

from datetime import datetime, timedelta, timezone
from email.utils import parsedate_to_datetime
from hashlib import sha256
import json

import requests
from sqlalchemy import update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert

from app import models
from app.config import settings
from app.match_sync import utc, utc_now


class GoalError(RuntimeError):
    pass


class GoalClient:
    def __init__(self, session_factory, *, key=None, daily_limit=None, now=utc_now):
        self.sessions = session_factory
        self.key = key if key is not None else (
            settings.GOAL_API_KEY.get_secret_value() if settings.GOAL_API_KEY else "")
        self.daily_limit = min(daily_limit or settings.GOAL_API_DAILY_LIMIT, 1000)
        self.now = now

    @property
    def configured(self):
        return bool(self.key.strip())

    def _reserve(self, now):
        # Insert/update is atomic across API workers, schedulers and restarts.
        with self.sessions() as db:
            insert = pg_insert if db.get_bind().dialect.name == "postgresql" else sqlite_insert
            db.execute(insert(models.ProviderUsage).values(
                provider="goal", day=now.date(), requests=0
            ).on_conflict_do_nothing())
            row = db.get(models.ProviderUsage, ("goal", now.date()))
            if row.blocked_until and utc(row.blocked_until) > now:
                raise GoalError("GOAL cooldown is active")
            changed = db.execute(update(models.ProviderUsage).where(
                models.ProviderUsage.provider == "goal", models.ProviderUsage.day == now.date(),
                models.ProviderUsage.requests < self.daily_limit,
            ).values(requests=models.ProviderUsage.requests + 1)).rowcount
            if not changed:
                raise GoalError("GOAL daily request budget exhausted")
            db.commit()

    def _cooldown(self, now, retry_after):
        try:
            until = now + timedelta(seconds=max(1, int(retry_after)))
        except (TypeError, ValueError):
            try:
                until = utc(parsedate_to_datetime(retry_after))
            except (TypeError, ValueError):
                until = now + timedelta(minutes=5)
        with self.sessions() as db:
            db.execute(update(models.ProviderUsage).where(
                models.ProviderUsage.provider == "goal", models.ProviderUsage.day == now.date(),
            ).values(blocked_until=max(until, now + timedelta(seconds=1))))
            db.commit()

    def get(self, path, params=None, *, ttl=timedelta(hours=6), force=False):
        if not self.configured:
            raise GoalError("GOAL_API_KEY is not configured")
        if not path.startswith("/") or ".." in path or "?" in path:
            raise GoalError("Invalid GOAL endpoint")
        now = self.now()
        key = "goal:" + sha256(json.dumps([path, params or {}], sort_keys=True).encode()).hexdigest()
        with self.sessions() as db:
            cached = db.get(models.ProviderCache, key)
            if cached and not force and utc(cached.expires_at) > now:
                return cached.payload
        self._reserve(now)
        try:
            response = requests.get("https://api.goal-api.com/v1" + path, params=params,
                                    headers={"Authorization": f"Bearer {self.key}"}, timeout=20)
        except requests.RequestException:
            raise GoalError("GOAL transport failed") from None
        if response.status_code == 429:
            self._cooldown(now, response.headers.get("Retry-After"))
        if response.status_code != 200:
            raise GoalError(f"GOAL HTTP {response.status_code}")
        try:
            payload = response.json()
        except ValueError:
            raise GoalError("Invalid GOAL JSON") from None
        if not isinstance(payload, dict) or payload.get("success") is not True or "data" not in payload:
            raise GoalError("Invalid GOAL response envelope")
        with self.sessions() as db:
            insert = pg_insert if db.get_bind().dialect.name == "postgresql" else sqlite_insert
            db.execute(insert(models.ProviderCache).values(
                key=key, payload=payload, expires_at=now + ttl
            ).on_conflict_do_update(index_elements=["key"], set_={
                "payload": payload, "expires_at": now + ttl}))
            db.commit()
        return payload

    def pages(self, path, params=None, **kwargs):
        rows, seen = [], set()
        # The published OpenAPI says 500, but the live v1 validator caps at 100.
        page_size = 100
        for _ in range(30):
            payload = self.get(path, {**(params or {}), "limit": page_size, "offset": len(rows)}, **kwargs)
            page = payload["data"]
            if not isinstance(page, list) or any(not isinstance(row, dict) for row in page):
                raise GoalError("Invalid GOAL collection")
            ids = [str(row.get("id")) for row in page]
            if len(set(ids)) != len(ids) or seen.intersection(ids):
                raise GoalError("GOAL pagination repeated a page")
            rows.extend(page)
            seen.update(ids)
            pagination = payload.get("pagination") or {}
            more = pagination.get("hasMore")
            if more is False or (more is None and len(page) < page_size):
                if pagination.get("total") is not None and len(rows) != pagination["total"]:
                    raise GoalError("GOAL pagination total mismatch")
                return rows
            if not page or more is None:
                raise GoalError("GOAL pagination did not advance")
        raise GoalError("GOAL pagination exceeded safety bound")

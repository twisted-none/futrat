"""A small independent ESPN-first live cycle; season imports never hold its lock."""
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from datetime import timedelta
import logging
from threading import Lock
from urllib.parse import quote

import requests
from sqlalchemy import text, or_

from app import models, live_clock
from app.match_sync import utc, utc_now
from app.seasons import current_matches

logger = logging.getLogger(__name__)
_lock = Lock()


@contextmanager
def writer_lock(db):
    if db.get_bind().dialect.name != "postgresql":
        yield True
        return
    with db.get_bind().connect() as connection:
        acquired = connection.execute(text("SELECT pg_try_advisory_lock(728613412)")).scalar()
        connection.commit()
        try:
            yield acquired
        finally:
            if acquired:
                connection.execute(text("SELECT pg_advisory_unlock(728613412)"))
                connection.commit()


def scoreboard(code, day):
    response = requests.get(
        f"https://site.api.espn.com/apis/site/v2/sports/soccer/{quote(code, safe='.')}/scoreboard",
        params={"dates": day, "limit": 1000}, timeout=10,
    )
    if response.status_code != 200:
        raise ValueError("ESPN live feed unavailable")
    data = response.json()
    if not isinstance(data.get("events"), list):
        raise ValueError("Invalid ESPN live feed")
    return data["events"]


def find_event(game, events):
    exact = [event for event in events if str(event.get("id")) == game.api_id]
    if len(exact) == 1:
        return exact[0]
    from app.goal_sync import team_key
    matches = []
    for event in events:
        try:
            competitors = event["competitions"][0]["competitors"]
            names = {c["homeAway"]: team_key(c["team"].get("displayName") or c["team"]["name"]) for c in competitors}
            if (names.get("home") == team_key(game.home_team.name)
                and names.get("away") == team_key(game.away_team.name)
                and abs(utc(event["date"]) - utc(game.date_time)) <= timedelta(minutes=5)):
                matches.append(event)
        except (KeyError, IndexError, TypeError, ValueError):
            continue
    return matches[0] if len(matches) == 1 else None


def apply_espn(db, game, event):
    status = event.get("status") or {}
    info = status.get("type") or {}
    normalized = {"STATUS_POSTPONED": "POSTPONED", "STATUS_DELAYED": "DELAYED",
                  "STATUS_CANCELED": "CANCELLED", "STATUS_SUSPENDED": "SUSPENDED"}.get(info.get("name"))
    normalized = normalized or {"pre": "SCHEDULED", "in": "IN_PLAY", "post": "FINISHED"}.get(info.get("state"))
    if normalized is None:
        raise ValueError("Unknown ESPN status")
    competitors = event["competitions"][0]["competitors"]
    scores = {}
    for c in competitors:
        raw = c.get("score")
        if isinstance(raw, dict):
            raw = raw.get("value", raw.get("displayValue"))
        try:
            value = int(raw)
            if not 0 <= value <= 99:
                continue
            scores[c["homeAway"]] = value
        except (ValueError, TypeError):
            continue
    before = (game.status, game.score_home, game.score_away)
    game.status = normalized
    game.date_time = utc(event["date"])
    for side in ("home", "away"):
        if normalized == "SCHEDULED":
            setattr(game, f"score_{side}", None)
        elif side in scores:
            setattr(game, f"score_{side}", scores[side])
    clock_ready = live_clock.espn(db, game, status)
    from app.forecasts import observe_espn
    if normalized != "FINISHED" or all(side in scores for side in ("home", "away")):
        observe_espn(db, game, status)
    if before != (game.status, game.score_home, game.score_away):
        game.is_detailed = False
    missing = {
        "clock": normalized == "IN_PLAY" and not clock_ready,
        "home": normalized in {"IN_PLAY", "FINISHED"} and "home" not in scores,
        "away": normalized in {"IN_PLAY", "FINISHED"} and "away" not in scores,
    }
    if normalized == "FINISHED" and (missing["home"] or missing["away"]):
        missing["result_status"] = status
    return missing


def apply_goal(db, game, row, missing=None):
    # A fallback must fill only the fields missing from a matching ESPN event.
    if missing is None:
        status = {"LIVE": "IN_PLAY", "HALF_TIME": "IN_PLAY", "AFTER_ET": "FINISHED",
                  "AFTER_PEN": "FINISHED", "AWARDED": "FINISHED"}.get(row.get("matchStatus"), row.get("matchStatus"))
        if status not in {"SCHEDULED", "IN_PLAY", "FINISHED", "POSTPONED", "CANCELLED", "SUSPENDED", "ABANDONED"}:
            raise ValueError("Unknown GOAL status")
        game.status = status
    filled = set()
    for side in ("home", "away"):
        if missing is None or missing[side]:
            value = row.get(f"{side}TeamScore")
            raw = str(value) if value is not None else ""
            if raw.isdecimal() and len(raw) <= 2:
                setattr(game, f"score_{side}", int(raw))
                filled.add(side)
    if missing is None or missing["clock"]:
        live_clock.goal(db, game, row, fill_missing=missing is not None)
    if missing is None:
        from app.forecasts import observe_goal
        observe_goal(db, game, row.get("matchStatus"))
    elif missing.get("result_status") and all(not missing[side] or side in filled for side in ("home", "away")):
        from app.forecasts import observe_espn
        observe_espn(db, game, missing["result_status"])
    game.is_detailed = False


def goal_fallback(db, games, missing, sessions):
    from app.goal_api import GoalClient, GoalError
    from app.goal_sync import find_league
    from app.competitions import GOAL_COMPETITIONS
    api = GoalClient(sessions)
    if not api.configured:
        return
    grouped = {}
    for game in games:
        if game.id in missing and game.tournament.api_code in GOAL_COMPETITIONS:
            key = (game.tournament.api_code, utc(game.date_time).date().isoformat())
            grouped.setdefault(key, []).append(game)
    for (code, day), rows in grouped.items():
        try:
            league = find_league(api, code)
            fixtures = api.pages("/fixtures", {"leagueId": league["id"], "from": day, "to": day},
                                 ttl=timedelta(seconds=55))
            by_id = {str(row.get("id")): row for row in fixtures}
            for game in rows:
                mapping = db.query(models.ProviderMatch).filter_by(provider="goal", match_id=game.id).first()
                row = by_id.get(mapping.external_id) if mapping else None
                if row:
                    apply_goal(db, game, row, missing[game.id])
            db.commit()
        except (GoalError, ValueError, KeyError, TypeError):
            db.rollback()
            logger.warning("%s: live fallback unavailable; existing data kept", code)


def refresh(sessions):
    if not _lock.acquire(blocking=False):
        return
    try:
        with sessions() as db, writer_lock(db) as acquired:
            # This lock is independent of the six-hour calendar import lock.
            if not acquired:
                return
            now = utc_now()
            checkpoint = db.get(models.ProviderCache, "live-cycle")
            if checkpoint and utc(checkpoint.expires_at) > now:
                return
            games = current_matches(db).filter(
                models.Match.date_time >= now - timedelta(hours=6),
                models.Match.date_time <= now + timedelta(minutes=10),
                models.Match.status.notin_(["CANCELLED", "ABANDONED", "POSTPONED", "DELAYED"]),
                or_(models.Match.status != "FINISHED", models.Match.id.in_(
                    db.query(models.MatchResult.match_id).filter(
                        models.MatchResult.kind == "UNKNOWN", models.MatchResult.regular_home.is_(None)))),
            ).all()
            groups = {}
            for game in games:
                if game.tournament.api_code:
                    key = (game.tournament.api_code, utc(game.date_time).strftime("%Y%m%d"))
                    groups.setdefault(key, []).append(game)
            missing = {}
            with ThreadPoolExecutor(max_workers=4) as pool:
                futures = {key: pool.submit(scoreboard, *key) for key in groups}
                for key, future in futures.items():
                    try:
                        events = future.result()
                    except Exception:
                        events = []
                        logger.warning("%s: ESPN live fetch unavailable", key[0])
                    for game in groups[key]:
                        event = find_event(game, events)
                        if event is None:
                            missing[game.id] = None
                            continue
                        try:
                            with db.begin_nested():
                                needed = apply_espn(db, game, event)
                            if any(needed.values()):
                                missing[game.id] = needed
                        except (ValueError, KeyError, IndexError, TypeError):
                            missing[game.id] = None
            db.commit()
            if missing:
                goal_fallback(db, games, missing, sessions)
            checkpoint = db.get(models.ProviderCache, "live-cycle")
            if checkpoint is None:
                checkpoint = models.ProviderCache(key="live-cycle")
                db.add(checkpoint)
            checkpoint.payload = {"updated_at": now.isoformat()}
            checkpoint.expires_at = now + timedelta(seconds=55)
            db.commit()
    finally:
        _lock.release()

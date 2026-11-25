"""Fill missing artwork without replacing club IDs or changing match history."""

from collections import defaultdict
from datetime import timedelta
import logging
from urllib.parse import urlsplit

import requests

from app import models, match_sync

logger = logging.getLogger(__name__)


def usable_badge(value):
    if not isinstance(value, str) or not value.strip():
        return None
    value = value.strip()
    try:
        uri = urlsplit(value)
        return value if (uri.scheme in {"http", "https"} and uri.hostname
                         and uri.username is None and uri.password is None) else None
    except ValueError:
        return None


def fill_badge(team, badge):
    badge = usable_badge(badge)
    if team is not None and not usable_badge(team.logo_url) and badge:
        team.logo_url = badge
        return True
    return False


def russian_teams(db):
    pairs = db.query(models.Match.home_team_id, models.Match.away_team_id).join(
        models.Tournament
    ).filter(models.Tournament.api_code.in_(["rus.1", "rus.cup"])).all()
    ids = {team_id for pair in pairs for team_id in pair}
    return db.query(models.Team).filter(models.Team.id.in_(ids)).all() if ids else []


def apply_espn_catalog(db, rows):
    from app.goal_sync import team_key
    teams = defaultdict(list)
    for team in russian_teams(db):
        teams[team_key(team.name)].append(team)
    updated = 0
    for row in rows:
        source = row.get("team", {})
        name = source.get("displayName") or source.get("name")
        candidates = teams.get(team_key(name), []) if name else []
        # Exact normalized aliases only; never guess between ambiguous clubs.
        if len(candidates) != 1:
            continue
        badge = next((usable_badge(item.get("href")) for item in source.get("logos", [])
                      if usable_badge(item.get("href"))), None)
        updated += fill_badge(candidates[0], badge or source.get("logo"))
    return updated


def repair_russian_badges(sessions):
    """One free ESPN catalog request, including existing checkpointed teams."""
    if not match_sync._sync_lock.acquire(blocking=False):
        return
    try:
        with sessions() as db, match_sync.database_lock(db) as acquired:
            if not acquired or not any(not usable_badge(t.logo_url) for t in russian_teams(db)):
                return
            response = requests.get(
                "https://site.api.espn.com/apis/site/v2/sports/soccer/rus.1/teams",
                params={"limit": 1000}, timeout=20,
            )
            response.raise_for_status()
            rows = response.json()["sports"][0]["leagues"][0]["teams"]
            updated = apply_espn_catalog(db, rows)
            db.commit()
            logger.info("Russian club badges: %s missing images filled from ESPN", updated)
    except Exception as error:
        logger.warning("Russian club badge repair unavailable: %s", type(error).__name__)
    finally:
        match_sync._sync_lock.release()


def goal_catalog_needed(db, fixtures):
    from app.goal_sync import team_key
    teams = defaultdict(list)
    for team in russian_teams(db):
        teams[team_key(team.name)].append(team)
    for row in fixtures:
        for side in ("home", "away"):
            if usable_badge(row.get(f"{side}TeamBadge")):
                continue
            name = row.get(f"{side}TeamName")
            candidates = teams.get(team_key(name), []) if name else []
            if len(candidates) != 1 or not usable_badge(candidates[0].logo_url):
                return True
    return False


def apply_goal_catalog(db, rows):
    updated = 0
    for row in rows:
        mapping = db.get(models.ProviderTeam, ("goal", str(row.get("id"))))
        if mapping:
            updated += fill_badge(db.get(models.Team, mapping.team_id), row.get("badge"))
    return updated


def goal_team_catalog(api, league_id):
    # A paginated league catalog, not one quota-consuming call per football club.
    return api.pages(f"/leagues/{league_id}/teams", ttl=timedelta(days=7))

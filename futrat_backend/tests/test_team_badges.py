from types import SimpleNamespace
import pytest

from sqlalchemy.orm import sessionmaker

from app import models
from app.goal_sync import resolve_team
from app.team_badges import (
    apply_espn_catalog, apply_goal_catalog, goal_catalog_needed,
    goal_team_catalog, repair_russian_badges,
)


def russian_match(match):
    match.tournament.api_code = "rus.cup"
    match.home_team.name = "Krasnodar"
    match.away_team.name = "CSKA Moscow"
    return match


def test_espn_repairs_existing_russian_clubs_without_replacing_ids(db, match):
    russian_match(match)
    db.flush()
    original = (match.id, match.home_team_id, match.away_team_id)
    updated = apply_espn_catalog(db, [{"team": {"displayName": "FC Krasnodar", "logos": [
        {"href": "https://a.espncdn.com/i/teamlogos/soccer/500/11336.png"}]}}])
    db.flush()
    assert updated == 1
    assert match.home_team.logo_url.endswith("11336.png")
    assert (match.id, match.home_team_id, match.away_team_id) == original
    assert db.query(models.Team).count() == 2


def test_existing_artwork_is_not_overwritten_by_other_sources(db, match):
    russian_match(match)
    match.home_team.logo_url = "https://espn.test/krasnodar.png"
    db.add(models.ProviderTeam(provider="goal", external_id="goal-home", team_id=match.home_team_id))
    db.flush()
    assert apply_goal_catalog(db, [{"id": "goal-home", "badge": "https://goal.test/club.jpg"}]) == 0
    assert match.home_team.logo_url == "https://espn.test/krasnodar.png"


def test_goal_updates_both_existing_mapping_and_existing_named_club(db, match):
    russian_match(match)
    db.flush()
    home = resolve_team(db, "goal-home", "FC Krasnodar", "https://goal.test/home.jpg")
    assert home.id == match.home_team_id
    home.logo_url = None
    home_again = resolve_team(db, "goal-home", "FC Krasnodar", "https://goal.test/new.jpg")
    assert home_again.id == home.id
    assert home_again.logo_url == "https://goal.test/new.jpg"


def test_goal_catalog_uses_verified_ids_and_fills_missing_only(db, match):
    russian_match(match)
    db.add(models.ProviderTeam(provider="goal", external_id="verified-id", team_id=match.home_team_id))
    db.flush()
    assert apply_goal_catalog(db, [
        {"id": "unknown-id", "name": "CSKA Moscow", "badge": "https://goal.test/wrong.jpg"},
        {"id": "verified-id", "badge": "https://goal.test/club.jpg"},
    ]) == 1
    assert match.away_team.logo_url is None
    assert match.home_team.logo_url == "https://goal.test/club.jpg"


def test_goal_catalog_is_not_requested_when_espn_has_all_badges(db, match):
    russian_match(match)
    match.home_team.logo_url = "https://espn.test/home.png"
    match.away_team.logo_url = "https://espn.test/away.png"
    db.flush()
    rows = [{"homeTeamName": "FC Krasnodar", "awayTeamName": "CSKA Moscow"}]
    assert not goal_catalog_needed(db, rows)
    match.away_team.logo_url = None
    assert goal_catalog_needed(db, rows)


def test_existing_checkpointed_teams_backfill_from_one_espn_catalog(db, match, monkeypatch):
    russian_match(match)
    db.commit()
    calls = []
    def get(url, **kwargs):
        calls.append(url)
        return SimpleNamespace(raise_for_status=lambda: None,
            json=lambda: {"sports": [{"leagues": [{"teams": [{"team": {
                "displayName": "Krasnodar", "logos": [{"href": "https://espn.test/krasnodar.png"}]
            }}]}]}]})
    monkeypatch.setattr("app.team_badges.requests.get", get)
    repair_russian_badges(sessionmaker(bind=db.get_bind()))
    db.expire_all()
    assert len(calls) == 1
    assert match.home_team.logo_url == "https://espn.test/krasnodar.png"


def test_goal_catalog_fetch_is_batched_cached_and_bounded_by_existing_client():
    calls = []
    api = SimpleNamespace(pages=lambda path, **kwargs: calls.append((path, kwargs)) or [])
    assert goal_team_catalog(api, "cup-id") == []
    assert calls[0][0] == "/leagues/cup-id/teams"
    assert calls[0][1]["ttl"].days == 7


def test_espn_match_refresh_fills_an_existing_club_badge(db, match):
    from app.match_sync import store_day
    from test_season_sync import event
    from datetime import datetime, timezone
    match.home_team.name = "Home"
    match.away_team.name = "Away"
    state = models.TournamentSyncState(tournament_id=match.tournament_id,
        season_start=datetime(2026, 7, 1, tzinfo=timezone.utc),
        season_end=datetime(2027, 7, 1, tzinfo=timezone.utc),
        calendar_updated_at=datetime(2026, 10, 1, tzinfo=timezone.utc))
    db.add(state)
    db.flush()
    row = event("test-match", "2026-10-01T00:00:00Z")
    row["competitions"][0]["competitors"][0]["team"]["logos"] = [
        {"href": "https://espn.test/home.png"}]
    store_day(db, match.tournament, state, "20261001", {"events": [row]})
    assert match.home_team.logo_url == "https://espn.test/home.png"
    assert db.query(models.Team).count() == 2


def test_public_badge_endpoint_filters_ids_and_does_not_require_login(client, db, match):
    match.home_team.logo_url = "https://espn.test/krasnodar.png"
    db.commit()
    response = client.get("/api/team-badges", params={"ids": [match.home_team_id, match.away_team_id]})
    assert response.status_code == 200
    assert response.json() == [{"id": match.home_team_id, "logo_url": match.home_team.logo_url}]
    assert client.get("/api/team-badges").json() == []
    assert client.get("/api/team-badges", params=[("ids", i) for i in range(101)]).status_code == 422


@pytest.mark.parametrize("catalog_fails", [False, True])
def test_goal_full_sync_fills_catalog_artwork_but_keeps_fixtures_if_catalog_fails(
    db, match, monkeypatch, catalog_fails
):
    from app import goal_sync
    from app.goal_api import GoalError
    from test_goal_api import fixture
    russian_match(match)
    db.commit()
    def pages(path, params=None, **kwargs):
        if path == "/fixtures":
            return [fixture(homeTeamName="Krasnodar", awayTeamName="CSKA Moscow")]
        if catalog_fails:
            raise GoalError("GOAL daily request budget exhausted")
        return [{"id": "goal-home", "badge": "https://goal.test/krasnodar.jpg"}]
    api = SimpleNamespace(configured=True, pages=pages)
    monkeypatch.setattr(goal_sync, "GoalClient", lambda sessions: api)
    monkeypatch.setattr(goal_sync, "find_league", lambda *args: {"id": "goal-league"})
    goal_sync.sync_goal({"rus.cup": "Cup"}, sessionmaker(bind=db.get_bind()))
    db.expire_all()
    assert db.query(models.Match).count() == 1
    assert match.score_home == 3
    assert match.home_team.logo_url == (None if catalog_fails else "https://goal.test/krasnodar.jpg")

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import pytest

from app import initial_data, models
from app.goal_api import GoalClient, GoalError
from app.goal_sync import store_fixtures, store_details
from sqlalchemy.orm import sessionmaker


NOW = datetime(2026, 10, 17, tzinfo=timezone.utc)


def client(db, monkeypatch, payload=None, limit=900, status=200):
    calls = []

    def get(url, **kwargs):
        calls.append((url, kwargs))
        return SimpleNamespace(status_code=status, headers={"Retry-After": "120"},
                               json=lambda: payload or {"success": True, "data": []})

    monkeypatch.setattr("app.goal_api.requests.get", get)
    return GoalClient(sessionmaker(bind=db.get_bind()), key="fake-key",
                      daily_limit=limit, now=lambda: NOW), calls


def test_goal_cache_and_persistent_budget(db, monkeypatch):
    api, calls = client(db, monkeypatch, limit=1)
    assert api.get("/leagues")["data"] == []
    assert api.get("/leagues")["data"] == []
    with pytest.raises(GoalError, match="budget"):
        api.get("/fixtures")
    assert len(calls) == 1
    assert calls[0][0] == "https://api.goal-api.com/v1/leagues"
    assert calls[0][1]["headers"]["Authorization"] == "Bearer fake-key"
    assert db.query(models.ProviderUsage).one().requests == 1


def test_goal_429_honors_persistent_cooldown(db, monkeypatch):
    api, calls = client(db, monkeypatch, status=429)
    with pytest.raises(GoalError, match="429"):
        api.get("/fixtures")
    with pytest.raises(GoalError, match="cooldown"):
        api.get("/leagues")
    assert len(calls) == 1


def test_failed_or_invalid_goal_payload_is_not_cached(db, monkeypatch):
    api, calls = client(db, monkeypatch, payload={"success": False, "data": []})
    for _ in range(2):
        with pytest.raises(GoalError):
            api.get("/fixtures")
    assert len(calls) == 2
    assert db.query(models.ProviderCache).count() == 0


def test_goal_pagination_reads_every_page_and_rejects_stuck_offsets(db, monkeypatch):
    api, _ = client(db, monkeypatch)
    offsets = []

    def page(path, params=None, **kwargs):
        assert params["limit"] == 100
        offsets.append(params["offset"])
        return {"success": True, "data": [{"id": str(params["offset"])}],
                "pagination": {"hasMore": params["offset"] == 0, "total": 2}}

    monkeypatch.setattr(api, "get", page)
    assert len(api.pages("/fixtures")) == 2
    assert offsets == [0, 1]
    monkeypatch.setattr(api, "get", lambda *a, **kw: {
        "data": [], "pagination": {"hasMore": True}})
    with pytest.raises(GoalError):
        api.pages("/fixtures")


def fixture(**changes):
    row = {"id": "goal-fixture", "leagueId": "goal-league", "kickoffUtc": "2026-10-01T00:00:00Z",
           "homeTeamId": "goal-home", "awayTeamId": "goal-away", "homeTeamName": "Home",
           "awayTeamName": "Away", "matchStatus": "FINISHED", "matchLive": "1",
           "homeTeamScore": "3", "awayTeamScore": "1", "matchRound": "Round 2"}
    row.update(changes)
    return row


def test_goal_reuses_existing_match_and_keeps_ratings_predictions(db, match):
    user = models.User(email="test@example.test", username="test", hashed_password="fake")
    lineup = models.MatchLineup(match=match, team_id=match.home_team_id, player_name="Rated Player")
    db.add_all([user, lineup])
    db.flush()
    rating = models.UserPlayerRating(user=user, lineup=lineup, rating=8)
    prediction = models.Prediction(user=user, match=match, predicted_home_score=2, predicted_away_score=1)
    db.add_all([rating, prediction])
    db.commit()
    original_id, lineup_id = match.id, lineup.id
    for _ in range(2):
        store_fixtures(db, match.tournament, [fixture()], NOW.replace(month=7, day=1),
                       NOW.replace(year=2027, month=7, day=1), league_id="goal-league")
        db.commit()
    assert db.query(models.Match).count() == 1
    assert db.query(models.Match).one().id == original_id
    assert match.api_id == "test-match"
    assert match.status == "FINISHED"  # matchLive=1 must not turn a final into live.
    assert db.query(models.UserPlayerRating).one().lineup_id == lineup_id
    assert db.query(models.Prediction).one().match_id == original_id
    assert db.query(models.ProviderMatch).one().match_id == original_id


def test_goal_updates_postponed_match_by_provider_id_without_duplicate(db, match):
    start, end = NOW - timedelta(days=100), NOW + timedelta(days=300)
    store_fixtures(db, match.tournament, [fixture()], start, end, league_id="goal-league")
    db.commit()
    store_fixtures(db, match.tournament, [fixture(kickoffUtc="2026-11-03T17:00:00Z", matchStatus="POSTPONED")],
                   start, end, league_id="goal-league")
    db.commit()
    assert db.query(models.Match).count() == 1
    assert match.status == "POSTPONED"
    assert match.score_home is None
    assert match.date_time.day == 3


def test_goal_rejects_other_league_and_history_without_hiding_existing_season(db, match):
    start, end = NOW - timedelta(days=100), NOW + timedelta(days=300)
    assert store_fixtures(db, match.tournament, [fixture(leagueId="wrong")], start, end,
                          league_id="goal-league") == 0
    assert store_fixtures(db, match.tournament, [fixture(kickoffUtc="2024-01-01T12:00Z")], start, end,
                          league_id="goal-league") == 0
    assert db.query(models.ProviderMatch).count() == 0
    assert db.query(models.Match).count() == 1


def test_goal_details_upsert_lineup_without_losing_rating(db, match):
    data = {"home": {"startingLineups": [{"lineupPlayer": "Player One", "lineupNumber": "9"}]}, "away": {}}
    stats = {"match": {"fullTime": [{"type": "Ball Possession", "home": "65%", "away": "35%"}]}}
    events = [{"type": "goal", "time": "45+2", "homeScorer": "Player One"}]
    store_details(db, match, data, stats, events)
    db.commit()
    lineup = db.query(models.MatchLineup).one()
    original_id = lineup.id
    user = models.User(email="r@example.test", username="rating", hashed_password="fake")
    db.add(models.UserPlayerRating(user=user, lineup=lineup, rating=9))
    db.commit()
    store_details(db, match, data, stats, events)
    db.commit()
    assert db.query(models.MatchLineup).one().id == original_id
    assert db.query(models.UserPlayerRating).one().rating == 9
    assert db.query(models.MatchEvent).count() == 1
    assert match.possession_home == 65


def test_registry_seeds_31_tournaments_and_preserves_ids(db, match):
    initial_data.seed_tournaments(db)
    ids = {row.api_code: row.id for row in db.query(models.Tournament) if row.api_code}
    assert len(ids) == 31
    initial_data.seed_tournaments(db)
    assert ids == {row.api_code: row.id for row in db.query(models.Tournament) if row.api_code}
    euro = db.query(models.Tournament).filter_by(api_code="uefa.euro").one()
    assert euro.type == "PendingDraw" and euro.current_season == "2028"


def test_pending_euro_api_has_no_fictional_standings(client, db):
    initial_data.seed_tournaments(db)
    euro = db.query(models.Tournament).filter_by(api_code="uefa.euro").one()
    assert client.get(f"/api/tournaments/{euro.id}/standings").json() == []


def test_placeholder_hides_old_matches_but_keeps_detail_ids(client, db, match):
    match.tournament.type = "PendingDraw"
    db.commit()
    assert client.get("/api/matches").json() == []
    # Historical details remain addressable, e.g. from saved predictions.
    match.api_id = None
    db.commit()
    assert client.get(f"/api/matches/{match.id}").status_code == 200


def test_euro_qualifying_rejects_old_2024_feed(db, monkeypatch):
    from app.match_sync import discover_calendar
    monkeypatch.setattr("app.match_sync.fetch_day", lambda *a: {"events": [], "leagues": [{
        "season": {"startDate": "2023-03-01T00:00Z", "endDate": "2024-05-01T00:00Z"}}]})
    with pytest.raises(ValueError, match="2028"):
        discover_calendar(db, "uefa.euroq", "Отбор Евро", NOW)
    assert db.query(models.Match).count() == 0


def test_national_groups_use_official_points_instead_of_knockout_results(client, db, match):
    match.tournament.api_code = "caf.nations"
    db.add(models.OfficialStandings(tournament_id=match.tournament_id,
        season=match.tournament.current_season, updated_at=NOW,
        rows=[{"team_id": match.home_team_id, "group_name": "Группа A", "rank": 1,
               "played": 3, "won": 1, "draw": 2, "lost": 0, "points": 5,
               "goals_for": 4, "goals_against": 2, "form": []}]))
    db.commit()
    row = client.get(f"/api/tournaments/{match.tournament_id}/standings").json()[0]
    assert row["played"] == 3 and row["points"] == 5 and row["group_name"] == "Группа A"


def test_goal_mapped_match_never_sends_goal_id_to_espn(client, db, match, monkeypatch):
    from app.config import settings
    monkeypatch.setattr(settings, "GOAL_API_KEY", None)
    calls = []
    def unexpected_http(*args, **kwargs):
        calls.append(args)
        raise AssertionError("Unexpected external request")
    monkeypatch.setattr("app.routers.data.requests.get", unexpected_http)
    db.add(models.ProviderMatch(provider="goal", external_id="goal-id", match_id=match.id))
    db.commit()
    # The autouse fixture forbids external HTTP, so an ESPN call would fail this test.
    response = client.get(f"/api/matches/{match.id}")
    assert response.status_code == 200
    assert response.json()["id"] == match.id
    assert calls == []

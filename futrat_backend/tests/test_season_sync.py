from copy import deepcopy
from datetime import datetime, timezone
from types import SimpleNamespace
from urllib.parse import parse_qs, urlparse

import requests

from app import initial_data, models
from app.match_sync import database_lock


CALENDAR = ["2026-09-12T07:00Z", "2026-10-17T07:00Z"]


def event(event_id, date, state="post", score="2"):
    return {
        "id": event_id, "date": date,
        "status": {"type": {"state": state, "name": "STATUS_FINAL"}},
        "competitions": [{"competitors": [
            {"homeAway": "home", "score": score, "team": {"displayName": "Home"}},
            {"homeAway": "away", "score": "1", "team": {"displayName": "Away"}},
        ]}],
    }


def scoreboard(events):
    return {
        "leagues": [{
            "season": {"year": 2026, "displayName": "2026-27 Test League"},
            "calendarType": "day", "calendarIsWhitelist": True,
            "calendarStartDate": "2026-06-01T00:00Z",
            "calendarEndDate": "2027-06-01T00:00Z",
            "calendar": CALENDAR,
        }],
        "events": events,
    }


def mock_source(monkeypatch, days):
    calls = []

    def get(url, **kwargs):
        date = parse_qs(urlparse(url).query).get("dates", [None])[0]
        calls.append(date)
        if date and "-" in date:
            return SimpleNamespace(status_code=400, json=lambda: {})
        payload = scoreboard(deepcopy(days.get(date, days.get("20261017", []))))
        return SimpleNamespace(status_code=200, json=lambda: payload)

    monkeypatch.setattr(initial_data, "TARGET_LEAGUES", {"test.1": "Test League"})
    monkeypatch.setattr(initial_data.requests, "get", get)
    return calls


def test_season_loads_calendar_days_instead_of_falling_back_to_today(db, monkeypatch):
    calls = mock_source(monkeypatch, {
        "20260912": [event("past", "2026-09-12T14:00Z")],
        "20261017": [event("next", "2026-10-17T14:00Z", "pre")],
    })
    initial_data.update_all_data()
    assert db.query(models.Match).count() == 2
    assert db.query(models.Match).filter_by(status="FINISHED").count() == 1
    assert "20260912" in calls
    assert None not in calls


def test_distinct_events_with_same_teams_keep_their_ids_and_results(db, monkeypatch):
    mock_source(monkeypatch, {
        "20260912": [event("first", "2026-09-12T14:00Z")],
        "20261017": [event("second", "2026-10-17T14:00Z", score="4")],
    })
    initial_data.update_all_data()
    rows = db.query(models.Match).order_by(models.Match.date_time).all()
    assert [(m.api_id, m.score_home) for m in rows] == [("first", 2), ("second", 4)]
    original_ids = {m.api_id: m.id for m in rows}
    initial_data.update_all_data()
    db.expire_all()
    assert {m.api_id: m.id for m in db.query(models.Match)} == original_ids


def test_failed_day_is_retried_without_reimporting_completed_history(db, monkeypatch):
    calls = mock_source(monkeypatch, {
        "20260912": [event("past", "2026-09-12T14:00Z")],
        "20261017": [event("next", "2026-10-17T14:00Z", "pre")],
    })
    original_get = initial_data.requests.get
    failing = True

    def get(url, **kwargs):
        if failing and "dates=20260912" in url:
            return SimpleNamespace(status_code=400, json=lambda: {})
        return original_get(url, **kwargs)

    monkeypatch.setattr(initial_data.requests, "get", get)
    initial_data.update_all_data()
    state = db.query(models.TournamentSyncState).one()
    assert state.completed_dates == ["20261017"]
    assert db.query(models.Match).count() == 1

    failing = False
    initial_data.update_all_data()
    db.expire_all()
    assert state.completed_dates == ["20260912", "20261017"]
    assert db.query(models.Match).count() == 2
    calls.clear()
    initial_data.update_all_data()
    assert "20260912" not in calls


def test_one_bad_league_does_not_stop_other_leagues(db, monkeypatch):
    mock_source(monkeypatch, {"20260912": [event("past", "2026-09-12T14:00Z")]})
    original_get = initial_data.requests.get
    monkeypatch.setattr(initial_data, "TARGET_LEAGUES", {"broken.1": "Broken", "test.1": "Test League"})

    def get(url, **kwargs):
        if "/broken.1/" in url:
            return SimpleNamespace(status_code=404, json=lambda: {})
        return original_get(url, **kwargs)

    monkeypatch.setattr(initial_data.requests, "get", get)
    initial_data.update_all_data()
    assert db.query(models.Match).one().api_id == "past"


def test_live_refresh_does_not_reload_history_or_reset_rounds(db, monkeypatch):
    calls = mock_source(monkeypatch, {
        "20260912": [event("past", "2026-09-12T14:00Z")],
        "20261017": [event("next", "2026-10-17T14:00Z", "pre")],
    })
    initial_data.update_all_data()
    calls.clear()
    initial_data.update_live_data()
    assert calls == ["20261017"]
    db.expire_all()
    assert [m.round for m in db.query(models.Match).order_by(models.Match.date_time)] == [1, 2]


def test_rescheduled_event_updates_date_and_preserves_local_id(db, match, monkeypatch):
    match.tournament.api_code = "test.1"
    match.api_id = "moved"
    original_id = match.id
    db.commit()
    mock_source(monkeypatch, {"20260912": [event("moved", "2026-09-12T14:00Z", score="4")]})
    initial_data.update_all_data()
    db.expire_all()
    row = db.query(models.Match).one()
    assert row.id == original_id
    assert row.date_time.date().isoformat() == "2026-09-12"
    assert row.score_home == 4


def test_lists_and_standings_exclude_previous_season_but_keep_detail(client, db, monkeypatch):
    mock_source(monkeypatch, {
        "20260912": [event("current", "2026-09-12T14:00Z")],
        "20261017": [event("next", "2026-10-17T14:00Z", "pre")],
    })
    initial_data.update_all_data()
    current = db.query(models.Match).filter_by(api_id="current").one()
    old = models.Match(
        api_id="old", tournament_id=current.tournament_id,
        home_team_id=current.home_team_id, away_team_id=current.away_team_id,
        date_time=datetime(2025, 9, 12, tzinfo=timezone.utc), status="FINISHED",
        score_home=9, score_away=0, is_detailed=True,
    )
    db.add(old)
    db.commit()
    assert {item["api_id"] for item in client.get("/api/matches").json()} == {"current", "next"}
    rows = client.get(f"/api/tournaments/{current.tournament_id}/standings").json()
    assert len(rows) == 2
    assert [item["played"] for item in rows] == [1, 1]
    assert sorted(item["points"] for item in rows) == [0, 3]
    assert sum(item["goals_for"] for item in rows) == 3
    assert client.get(f"/api/matches/{old.id}").status_code == 200


def test_transient_source_error_is_retried(db, monkeypatch):
    mock_source(monkeypatch, {"20260912": [event("past", "2026-09-12T14:00Z")]})
    original_get = initial_data.requests.get
    attempts = 0

    def get(url, **kwargs):
        nonlocal attempts
        attempts += 1
        if attempts == 1:
            raise requests.ConnectionError("temporary test outage")
        return original_get(url, **kwargs)

    monkeypatch.setattr(initial_data.requests, "get", get)
    initial_data.update_all_data()
    assert attempts >= 3
    assert db.query(models.Match).one().api_id == "past"


def test_restarted_import_keeps_completed_future_checkpoints(db, monkeypatch):
    calls = mock_source(monkeypatch, {
        "20260912": [event("past", "2026-09-12T14:00Z")],
        "20261017": [event("next", "2026-10-17T14:00Z", "pre")],
    })
    initial_data.update_all_data()
    calls.clear()
    initial_data.update_all_data()
    assert calls == []
    assert db.query(models.Match).count() == 2


def test_repeated_event_in_source_response_is_saved_once(db, monkeypatch):
    item = event("repeated", "2026-09-12T14:00Z")
    mock_source(monkeypatch, {"20260912": [item, item]})
    initial_data.update_all_data()
    assert db.query(models.Match).one().api_id == "repeated"


def test_postgresql_serializes_separate_sync_connections(db):
    with database_lock(db) as acquired:
        assert acquired
        with database_lock(db) as second:
            assert second == (db.get_bind().dialect.name != "postgresql")
    with database_lock(db) as released:
        assert released


def test_grouped_cup_calendar_discovers_fixture_days_from_year_feeds(db, monkeypatch):
    calls = []
    current = event("current", "2026-09-12T14:00Z")
    next_game = event("next", "2026-10-17T14:00Z", "pre")
    outside = event("old-season", "2026-01-01T14:00Z")

    def get(url, **kwargs):
        day = parse_qs(urlparse(url).query)["dates"][0]
        calls.append(day)
        events = {"2026": [outside, current, next_game], "2027": [],
                  "20260912": [current], "20261017": [next_game]}.get(day, [])
        payload = scoreboard(events)
        payload["leagues"][0]["calendar"] = [{
            "label": "Cup", "entries": [{"label": "Group", "value": "1",
                "startDate": "2026-06-01T00:00Z", "endDate": "2027-06-01T00:00Z"}],
        }]
        return SimpleNamespace(status_code=200, json=lambda: payload)

    monkeypatch.setattr(initial_data, "TARGET_LEAGUES", {"test.cup": "Test Cup"})
    monkeypatch.setattr(initial_data.requests, "get", get)
    initial_data.update_all_data()
    assert {m.api_id for m in db.query(models.Match)} == {"current", "next"}
    assert db.query(models.TournamentSyncState).one().calendar == ["20260912", "20261017"]
    assert "2026" in calls and "2027" in calls

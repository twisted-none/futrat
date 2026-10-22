from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import sessionmaker

from app import models, live_clock, live_sync

NOW = datetime(2026, 10, 17, 16, tzinfo=timezone.utc)


def event(clock="47'", name="STATUS_IN_PROGRESS", state="in", score="2"):
    return {"id": "test-match", "date": (NOW - timedelta(hours=1)).isoformat(),
        "status": {"displayClock": clock, "period": 2,
                   "type": {"state": state, "name": name}},
        "competitions": [{"competitors": [
            {"homeAway": "home", "score": score, "team": {"displayName": "Home"}},
            {"homeAway": "away", "score": "1", "team": {"displayName": "Away"}},
        ]}]}


def prepare(db, match, monkeypatch, code="eng.1"):
    match.date_time = NOW - timedelta(hours=1)
    match.status = "IN_PLAY"
    match.tournament.api_code = code
    db.commit()
    monkeypatch.setattr(live_sync, "utc_now", lambda: NOW)
    monkeypatch.setattr(live_clock, "utc_now", lambda: NOW)
    return sessionmaker(bind=db.get_bind(), autoflush=False)


def test_espn_live_cycle_preserves_minutes_and_never_calls_goal_when_complete(db, match, monkeypatch):
    sessions = prepare(db, match, monkeypatch, "rus.cup")
    calls = []
    monkeypatch.setattr(live_sync, "scoreboard", lambda code, day: calls.append((code, day)) or [event("90'+3'")])
    monkeypatch.setattr(live_sync, "goal_fallback", lambda *args: (_ for _ in ()).throw(AssertionError("GOAL must not be used")))
    live_sync.refresh(sessions)
    live_sync.refresh(sessions)
    db.expire_all()
    assert match.clock == "90+3" and match.phase == "SECOND_HALF"
    assert (match.score_home, match.score_away) == (2, 1)
    assert calls == [("rus.cup", "20261017")]


def test_halftime_is_a_phase_and_never_counts_as_extra_minutes(db, match, monkeypatch):
    prepare(db, match, monkeypatch)
    live_sync.apply_espn(db, match, event("45'+5'", "STATUS_HALFTIME"))
    db.commit()
    assert match.phase == "HALF_TIME" and match.clock is None
    assert match.status == "IN_PLAY"


def test_goal_only_fills_missing_clock_without_overwriting_espn_score(db, match, monkeypatch):
    prepare(db, match, monkeypatch, "rus.cup")
    missing = live_sync.apply_espn(db, match, event(clock="", score="4"))
    live_sync.apply_goal(db, match, {
        "matchStatus": "LIVE", "matchMinute": "52", "matchPeriod": "SECOND_HALF",
        "clockUpdatedAt": (NOW - timedelta(seconds=5)).isoformat(),
        "homeTeamScore": "0", "awayTeamScore": "0",
    }, missing)
    db.commit()
    assert match.clock == "52"
    assert (match.score_home, match.score_away) == (4, 1)


def test_goal_fallback_is_used_when_espn_has_no_matching_fixture(db, match, monkeypatch):
    sessions = prepare(db, match, monkeypatch, "rus.cup")
    monkeypatch.setattr(live_sync, "scoreboard", lambda *args: [])
    calls = []
    def fallback(session, games, missing, factory):
        calls.append(missing)
        live_sync.apply_goal(session, games[0], {"matchStatus": "HALF_TIME",
            "homeTeamScore": "3", "awayTeamScore": "1", "matchPeriod": "HALF_TIME"})
        session.commit()
    monkeypatch.setattr(live_sync, "goal_fallback", fallback)
    live_sync.refresh(sessions)
    db.expire_all()
    assert calls == [{match.id: None}]
    assert match.phase == "HALF_TIME" and match.score_home == 3


def test_unknown_espn_event_cannot_be_attached_on_team_names_only(db, match, monkeypatch):
    prepare(db, match, monkeypatch)
    row = event()
    row["id"] = "other-id"
    row["date"] = (NOW - timedelta(days=1)).isoformat()
    assert live_sync.find_event(match, [row]) is None


def test_light_update_contains_final_status_and_rescheduled_requested_id(client, db, match):
    match.date_time = datetime.now(timezone.utc) + timedelta(days=2)
    db.commit()
    data = client.get(f"/api/matches/updates?ids={match.id}").json()
    assert len(data) == 1 and data[0]["status"] == "FINISHED"
    assert "lineups" not in data[0] and "home_team" not in data[0]
    assert client.get('/api/matches/updates?ids=invalid').status_code == 422


def test_older_goal_clock_cannot_replace_a_newer_espn_clock(db, match, monkeypatch):
    prepare(db, match, monkeypatch)
    live_clock.espn(db, match, event()["status"])
    live_clock.goal(db, match, {"matchMinute": "20", "clockUpdatedAt": (NOW - timedelta(minutes=5)).isoformat()})
    db.commit()
    assert match.clock == "47"


def test_final_missing_score_is_not_settled_from_old_live_score(db, match, monkeypatch):
    prepare(db, match, monkeypatch)
    live_sync.apply_espn(db, match, event(score="1"))
    final = event(name="STATUS_FULL_TIME", state="post", score=None)
    missing = live_sync.apply_espn(db, match, final)
    assert db.get(models.MatchResult, match.id).kind == 'UNKNOWN'
    live_sync.apply_goal(db, match, {'matchStatus': 'FINISHED', 'homeTeamScore': '3', 'awayTeamScore': '8'}, missing)
    db.commit()
    result = db.get(models.MatchResult, match.id)
    assert (result.regular_home, result.regular_away) == (3, 1)


def test_goal_fallback_uses_one_short_cached_batch_per_league(db, match, monkeypatch):
    from app import goal_api, goal_sync
    sessions = prepare(db, match, monkeypatch, 'rus.cup')
    db.add(models.ProviderMatch(provider='goal', external_id='g1', match_id=match.id))
    db.commit()
    calls = []
    class FakeGoal:
        configured = True
        def __init__(self, *args): pass
        def pages(self, path, params, *, ttl):
            calls.append((path, params, ttl.total_seconds()))
            return [{'id': 'g1', 'matchStatus': 'LIVE', 'matchMinute': '52',
                     'homeTeamScore': '2', 'awayTeamScore': '1'}]
    monkeypatch.setattr(goal_api, 'GoalClient', FakeGoal)
    monkeypatch.setattr(goal_sync, 'find_league', lambda *args: {'id': 'cup'})
    live_sync.goal_fallback(db, [match], {match.id: None}, sessions)
    assert len(calls) == 1 and calls[0][2] == 55
    assert calls[0][1] == {'leagueId': 'cup', 'from': '2026-10-17', 'to': '2026-10-17'}
    assert match.clock == '52'


def test_bulk_goal_cache_does_not_override_a_recent_espn_live_result(db, match, monkeypatch):
    from app.goal_sync import store_fixtures
    from tests.test_goal_api import fixture
    prepare(db, match, monkeypatch)
    live_sync.apply_espn(db, match, event(score='4'))
    db.commit()
    row = fixture(kickoffUtc=match.date_time.isoformat(), homeTeamScore='0', awayTeamScore='0')
    store_fixtures(db, match.tournament, [row], NOW.replace(month=7, day=1),
                   NOW.replace(year=2027, month=7, day=1), league_id='goal-league')
    db.commit()
    assert match.status == 'IN_PLAY' and (match.score_home, match.score_away) == (4, 1)
    assert match.clock == '47'


def test_live_cycle_runs_while_calendar_import_owns_its_locks(db, match, monkeypatch):
    from app import match_sync
    sessions = prepare(db, match, monkeypatch)
    monkeypatch.setattr(live_sync, 'scoreboard', lambda *args: [event()])
    with match_sync._sync_lock, match_sync.database_lock(db) as acquired:
        assert acquired
        live_sync.refresh(sessions)
    db.expire_all()
    assert match.clock == '47'

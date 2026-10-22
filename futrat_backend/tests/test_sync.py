from types import SimpleNamespace
from threading import Event

from app import initial_data, main, models
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.events import EVENT_JOB_ERROR, EVENT_JOB_EXECUTED
from fastapi.testclient import TestClient


def fake_scoreboard(score="2"):
    return {
        "leagues": [{
            "logos": [{"href": "https://example.test/logo.png"}],
            "calendarStartDate": "2026-06-01T00:00Z",
            "calendarEndDate": "2027-06-01T00:00Z",
            "calendar": ["2026-10-01T00:00Z"],
        }],
        "events": [{
            "id": "fake-event", "date": "2026-10-01T12:00:00Z",
            "status": {"type": {"state": "post", "name": "STATUS_FINAL"}},
            "competitions": [{"competitors": [
                {"homeAway": "home", "score": score, "team": {"displayName": "Home"}},
                {"homeAway": "away", "score": "1", "team": {"displayName": "Away"}},
            ]}],
        }],
    }


def test_match_sync_inserts_and_updates_without_duplicates(db, monkeypatch):
    monkeypatch.setattr(initial_data, "TARGET_LEAGUES", {"test.1": "Test League"})
    scoreboard = fake_scoreboard()
    monkeypatch.setattr(initial_data.requests, "get", lambda *a, **kw: SimpleNamespace(status_code=200, json=lambda: scoreboard))
    initial_data.update_all_data()
    assert db.query(models.Match).one().score_home == 2
    scoreboard["events"][0]["competitions"][0]["competitors"][0]["score"] = "3"
    initial_data.update_all_data(force=True)
    db.expire_all()
    assert db.query(models.Match).one().score_home == 3
    assert db.query(models.Team).count() == 2
    assert db.query(models.Tournament).count() == 1


def test_startup_initializes_database_and_stops_scheduler(db, monkeypatch):
    # StaticPool SQLite has one connection; exercise the two writers separately.
    # The live writer itself is covered by test_live_feed.py and PostgreSQL tests.
    monkeypatch.setattr(main, "update_live_feed", lambda: None)
    monkeypatch.setattr(initial_data, "TARGET_LEAGUES", {"test.1": "Test League"})
    monkeypatch.setattr(initial_data.requests, "get", lambda *a, **kw: SimpleNamespace(status_code=200, json=lambda: fake_scoreboard()))
    scheduler = BackgroundScheduler()
    completed = Event()
    scheduler.add_listener(lambda event: completed.set() if event.job_id == 'season-sync' else None,
                           EVENT_JOB_ERROR | EVENT_JOB_EXECUTED)
    monkeypatch.setattr(main, "scheduler", scheduler)
    with TestClient(main.app) as client:
        assert client.get("/").json() == {"message": "Futrat LIVE API Running"}
        assert scheduler.running
        jobs = {job.id: job for job in scheduler.get_jobs()}
        assert jobs["live-feed"].trigger.interval.total_seconds() == 60
        assert jobs["live-sync"].trigger.interval.total_seconds() == 900
        assert jobs["season-sync"].trigger.interval.total_seconds() == 6 * 3600
        assert completed.wait(5), "Background season import did not finish"
        assert db.query(models.User).filter_by(email="admin@futrat.com").one().username == "Admin"
        assert db.query(models.Match).count() == 1
    assert not scheduler.running


def test_scheduler_executes_match_sync_in_background(db, monkeypatch):
    monkeypatch.setattr(initial_data, "TARGET_LEAGUES", {"test.1": "Test League"})
    monkeypatch.setattr(initial_data.requests, "get", lambda *a, **kw: SimpleNamespace(status_code=200, json=lambda: fake_scoreboard()))
    completed = Event()
    scheduler = BackgroundScheduler()
    scheduler.add_listener(lambda event: completed.set(), EVENT_JOB_ERROR | EVENT_JOB_EXECUTED)
    scheduler.add_job(initial_data.update_all_data, "date")
    scheduler.start()
    try:
        assert completed.wait(timeout=5), "The scheduled synchronization did not finish"
        assert db.query(models.Match).one().api_id == "fake-event"
    finally:
        scheduler.shutdown()


def test_api_starts_while_season_source_is_still_waiting(db, monkeypatch):
    requested, release = Event(), Event()
    monkeypatch.setattr(initial_data, "TARGET_LEAGUES", {"test.1": "Test League"})

    def get(*args, **kwargs):
        requested.set()
        assert release.wait(5), "Test source was not released"
        return SimpleNamespace(status_code=200, json=lambda: fake_scoreboard())

    monkeypatch.setattr(initial_data.requests, "get", get)
    monkeypatch.setattr(main, "scheduler", BackgroundScheduler())
    with TestClient(main.app) as client:
        try:
            assert requested.wait(5)
            assert client.get("/").status_code == 200
        finally:
            release.set()

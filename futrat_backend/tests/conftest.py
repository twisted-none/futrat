"""Isolated databases and fake settings; never load the project's .env."""

import os
from datetime import datetime, timezone
from threading import Event
from unittest.mock import patch

import pytest
import requests
from apscheduler.schedulers.background import BackgroundScheduler
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.engine import make_url
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool


TEST_DATABASE_URL = os.environ.get("FUTRAT_TEST_DATABASE_URL", "sqlite+pysqlite://")
test_url = make_url(TEST_DATABASE_URL)
if test_url.get_backend_name() != "sqlite":
    if (
        test_url.get_backend_name() != "postgresql"
        or test_url.database != "futrat_upgrade_test"
        or test_url.host not in {"localhost", "127.0.0.1", "db"}
    ):
        raise RuntimeError("Tests require an isolated futrat_upgrade_test database")

os.environ.update(
    DATABASE_URL=TEST_DATABASE_URL,
    SECRET_KEY="fake-test-signing-key-not-for-production",
    ALGORITHM="HS256",
    ACCESS_TOKEN_EXPIRE_MINUTES="30",
)

# Patch the file reader before importing Settings, including when run in /app.
with patch(
    "pydantic_settings.sources.DotEnvSettingsSource._read_env_files", return_value={}
):
    from app import database, initial_data, main, models, match_sync


@pytest.fixture(autouse=True)
def block_external_http(monkeypatch):
    def blocked(*args, **kwargs):
        raise AssertionError("External HTTP is forbidden in regression tests")

    monkeypatch.setattr(requests.sessions.Session, "request", blocked)


@pytest.fixture
def db(monkeypatch):
    monkeypatch.setattr(match_sync, "_stop_event", Event())
    monkeypatch.setattr(match_sync, "utc_now", lambda: datetime(2026, 10, 17, tzinfo=timezone.utc))
    options = {}
    if test_url.get_backend_name() == "sqlite":
        options = {"poolclass": StaticPool, "connect_args": {"check_same_thread": False}}
    engine = create_engine(TEST_DATABASE_URL, **options)
    sessions = sessionmaker(bind=engine, autoflush=False)
    for module in (database, initial_data, main):
        monkeypatch.setattr(module, "engine", engine)
    monkeypatch.setattr(database, "SessionLocal", sessions)
    monkeypatch.setattr(initial_data, "SessionLocal", sessions)
    database.Base.metadata.create_all(engine)
    try:
        with sessions() as session:
            yield session
    finally:
        database.Base.metadata.drop_all(engine)
        engine.dispose()


@pytest.fixture
def client(db, monkeypatch):
    monkeypatch.setattr(main, "init_db", lambda: None)
    monkeypatch.setattr(main, "update_all_data", lambda: None)
    monkeypatch.setattr(main, "update_live_data", lambda: None)
    monkeypatch.setattr(main, "update_live_feed", lambda: None)
    monkeypatch.setattr(main, "scheduler", BackgroundScheduler())
    with TestClient(main.app) as test_client:
        yield test_client


@pytest.fixture
def match(db):
    from datetime import datetime, timezone

    tournament = models.Tournament(
        name="Test League", country="Global", type="League", current_season="26/27"
    )
    home = models.Team(name="Home", country="Global")
    away = models.Team(name="Away", country="Global")
    item = models.Match(
        api_id="test-match", date_time=datetime(2026, 10, 1, tzinfo=timezone.utc),
        tournament=tournament, home_team=home, away_team=away,
        score_home=2, score_away=1, status="FINISHED",
    )
    db.add(item)
    db.commit()
    return item

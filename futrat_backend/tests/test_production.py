"""Production startup must isolate Futrat and reject development credentials."""

from types import SimpleNamespace

import pytest
from pydantic import ValidationError
from sqlalchemy.exc import OperationalError

from app import initial_data, main, models
from app.config import Settings
from app.security import get_password_hash


def production_settings(**overrides):
    values = dict(
        APP_ENV="production",
        DATABASE_URL="postgresql+psycopg2://futrat:generated-password@postgresql:5432/futrat",
        SECRET_KEY="0123456789abcdef" * 4,
        ALGORITHM="HS256",
        ACCESS_TOKEN_EXPIRE_MINUTES=1440,
    )
    values.update(overrides)
    return Settings(_env_file=None, **values)


def test_production_accepts_dedicated_database():
    assert production_settings().APP_ENV == "production"


@pytest.mark.parametrize("changes", [
    {"SECRET_KEY": "short"},
    {"SECRET_KEY": "REPLACE_WITH_GENERATED_SECRET_KEY_64_HEX"},
    {"DATABASE_URL": "postgresql://postgres:password@postgresql/other_project"},
    {"DATABASE_URL": "postgresql://futrat:password@postgresql/other_project"},
    {"DATABASE_URL": "postgresql://postgres:password@postgresql/futrat"},
    {"DATABASE_URL": "postgresql://futrat:REPLACE_WITH_PASSWORD@postgresql/futrat"},
    {"DATABASE_URL": "sqlite+pysqlite://"},
    {"ALGORITHM": "HS512"},
    {"ACCESS_TOKEN_EXPIRE_MINUTES": 0},
])
def test_production_rejects_unsafe_settings_without_echoing_secrets(changes):
    with pytest.raises(ValidationError) as caught:
        production_settings(**changes)
    assert "input_value" not in str(caught.value)
    assert "generated-password" not in str(caught.value)


def test_production_seeds_tournaments_without_a_test_user(db, monkeypatch):
    monkeypatch.setattr(initial_data, "settings", SimpleNamespace(APP_ENV="production"), raising=False)
    initial_data.init_db()
    assert db.query(models.Tournament).count() > 0
    assert db.query(models.User).count() == 0


def test_production_refuses_imported_development_account(db, monkeypatch):
    monkeypatch.setattr(initial_data, "settings", SimpleNamespace(APP_ENV="production"), raising=False)
    account = models.User(username="Admin", email="admin@futrat.com",
                          hashed_password=get_password_hash("admin"))
    db.add(account)
    db.commit()
    with pytest.raises(RuntimeError, match="development account"):
        initial_data.init_db()
    assert db.query(models.User).count() == 1  # Startup never deletes users.


def test_production_accepts_admin_with_changed_password(db, monkeypatch):
    monkeypatch.setattr(initial_data, "settings", SimpleNamespace(APP_ENV="production"), raising=False)
    db.add(models.User(username="Admin", email="admin@futrat.com",
                       hashed_password=get_password_hash("a-new-private-password")))
    db.commit()
    initial_data.init_db()
    assert db.query(models.User).count() == 1


def test_readiness_checks_database(client, monkeypatch):
    assert client.get("/health/ready").status_code == 200

    class DisconnectedEngine:
        def connect(self):
            raise OperationalError("connection failed", None, Exception("private-db-details"))

    monkeypatch.setattr(main, "engine", DisconnectedEngine())
    response = client.get("/health/ready")
    assert response.status_code == 503
    assert response.json() == {"status": "unavailable"}
    assert "private-db-details" not in response.text

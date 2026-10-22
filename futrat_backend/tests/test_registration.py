import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.exc import IntegrityError

from app import models, security


def signup(client, username="Player", password="secret123"):
    return client.post("/auth/register", json={"username": username, "password": password})


@pytest.mark.parametrize("payload,message", [
    ({}, "никнейм"),
    ({"username": "", "password": ""}, "никнейм"),
    ({"username": "  ab  ", "password": "secret"}, "3"),
    ({"username": "Player", "password": ""}, "6"),
    ({"username": "Player", "password": "12345"}, "6"),
    ({"username": "Player", "password": "      "}, "пробел"),
    ({"username": "Player", "password": "abc\x00def"}, "символ"),
    ({"username": "Player", "password": "я" * 40}, "длин"),
])
def test_invalid_registration_is_rejected_without_echoing_password(client, db, payload, message):
    result = client.post("/auth/register", json=payload)
    assert result.status_code == 422
    assert message in result.json()["detail"].lower()
    assert "input" not in result.json()
    assert db.query(models.User).count() == 0


def test_two_field_registration_trimmed_nickname_and_exact_password(client, db):
    result = signup(client, "  Игрок  ", " secret ")
    assert result.status_code == 200
    headers = {"Authorization": "Bearer " + result.json()["access_token"]}
    profile = client.get("/auth/me", headers=headers).json()
    assert profile["username"] == "Игрок" and profile["email"] is None
    assert signup(client, "Second").status_code == 200
    assert client.post("/auth/login", json={"username": "игРОК", "password": " secret "}).status_code == 200
    assert client.post("/auth/login", json={"username": "Игрок", "password": "secret"}).status_code == 401
    user = db.query(models.User).filter_by(username="Игрок").one()
    assert user.hashed_password != " secret "


@pytest.mark.parametrize("nickname", ["PLAYER", " player ", "Ｐｌａｙｅｒ"])
def test_nickname_is_unique_after_normalization(client, nickname):
    assert signup(client).status_code == 200
    result = signup(client, nickname)
    assert result.status_code == 409
    assert result.json()["detail"] == "Этот никнейм уже занят"


def test_database_guards_nickname_races(db):
    db.add(models.User(username="Игрок", hashed_password="test"))
    db.commit()
    db.add(models.User(username="игРОК", hashed_password="test"))
    with pytest.raises(IntegrityError):
        db.commit()
    db.rollback()
    assert db.query(models.User).count() == 1


def test_profile_cannot_bypass_registration_nickname_rules(client):
    one = signup(client).json()["access_token"]
    two = signup(client, "Second").json()["access_token"]
    headers = {"Authorization": "Bearer " + two}
    assert client.put("/users/me", headers=headers, json={"username": " "}).status_code == 422
    assert client.put("/users/me", headers=headers, json={"username": "pLaYeR"}).status_code == 409
    assert client.put("/users/me", headers=headers, json={"username": "THIRD"}).status_code == 200
    assert client.get("/auth/me", headers=headers).json()["username"] == "THIRD"
    assert client.get("/auth/me", headers={"Authorization": "Bearer " + one}).status_code == 200


def test_login_errors_are_readable_and_do_not_disclose_account_existence(client):
    assert signup(client).status_code == 200
    for name in ["Player", "unknown"]:
        result = client.post("/auth/login", json={"username": name, "password": "wrong"})
        assert result.status_code == 401
        assert result.json()["detail"] == "Неверный никнейм или пароль"
    for data in [{}, {"username": "", "password": ""}, {"username": "Player", "password": ""}]:
        result = client.post("/auth/login", json=data)
        assert result.status_code == 422 and isinstance(result.json()["detail"], str)


def test_existing_short_password_and_legacy_email_session_still_work(client, db):
    user = models.User(username="Old", email="old@example.test", hashed_password=security.get_password_hash("old"))
    db.add(user)
    db.commit()
    token = security.create_access_token({"sub": user.email})
    assert client.get("/auth/me", headers={"Authorization": "Bearer " + token}).status_code == 200
    for body in [{"email": user.email, "password": "old"}, {"username": "oLD", "password": "old"}]:
        assert client.post("/auth/login", json=body).status_code == 200


def test_registration_handles_unique_collision_after_precheck(client, monkeypatch):
    from app.routers import auth
    assert signup(client).status_code == 200
    monkeypatch.setattr(auth, "nickname_taken", lambda *a, **kw: False)
    result = signup(client, "PLAYER")
    assert result.status_code == 409
    assert signup(client, "Other").status_code == 200


def test_legacy_nickname_migration_is_idempotent_and_refuses_collisions():
    from app.user_migration import ensure_user_schema
    engine = create_engine("sqlite+pysqlite://")
    with engine.begin() as connection:
        connection.execute(text("CREATE TABLE users (id INTEGER PRIMARY KEY, username VARCHAR NOT NULL, email VARCHAR)"))
        connection.execute(text("INSERT INTO users (id, username) VALUES (1, 'Player')"))
    ensure_user_schema(engine)
    ensure_user_schema(engine)
    with engine.connect() as connection:
        assert connection.execute(text("SELECT username_key FROM users WHERE id=1")).scalar_one() == "player"
    with engine.begin() as connection:
        connection.execute(text("DROP INDEX ix_users_username_key"))
        connection.execute(text("INSERT INTO users (id, username) VALUES (2, 'PLAYER')"))
    with pytest.raises(RuntimeError, match="nickname"):
        ensure_user_schema(engine)
    engine.dispose()


def test_empty_account_cleanup_only_removes_verified_target_and_its_favorites(db, match):
    from app.user_cleanup import delete_empty_account
    empty = models.User(username="", email="", hashed_password=security.get_password_hash(""))
    normal = models.User(username="Keep", hashed_password=security.get_password_hash("secret"))
    db.add_all([empty, normal])
    db.flush()
    empty.favorite_teams.append(match.home_team)
    db.commit()
    empty_id, normal_id = empty.id, normal.id
    assert delete_empty_account(db, normal_id) is False
    assert delete_empty_account(db, empty_id) is True
    db.expire_all()
    assert db.get(models.User, empty_id) is None and db.get(models.User, normal_id) is not None
    assert db.query(models.Match).count() == 1


def test_postgres_upgrade_retains_users_and_allows_new_accounts_without_email(db):
    if db.get_bind().dialect.name != "postgresql":
        pytest.skip("Legacy PostgreSQL DDL integration requires the isolated Docker database")
    from app.user_migration import ensure_user_schema
    engine = db.get_bind()
    with engine.begin() as connection:
        connection.execute(text("CREATE SCHEMA auth_migration_check"))
    isolated = create_engine(engine.url, connect_args={"options": "-c search_path=auth_migration_check"})
    try:
        with isolated.begin() as connection:
            connection.execute(text("CREATE TABLE users (id INTEGER PRIMARY KEY, username VARCHAR NOT NULL UNIQUE, email VARCHAR NOT NULL UNIQUE)"))
            connection.execute(text("INSERT INTO users VALUES (1, 'Игрок', 'old@example.test')"))
        ensure_user_schema(isolated)
        ensure_user_schema(isolated)
        with isolated.begin() as connection:
            assert connection.execute(text("SELECT username_key FROM users WHERE id=1")).scalar_one() == "игрок"
            connection.execute(text("INSERT INTO users (id,username,username_key) VALUES (2,'New','new')"))
        with pytest.raises(IntegrityError), isolated.begin() as connection:
            connection.execute(text("INSERT INTO users (id,username,username_key) VALUES (3,'NEW','new')"))
    finally:
        isolated.dispose()
        with engine.begin() as connection:
            connection.execute(text("DROP SCHEMA auth_migration_check CASCADE"))

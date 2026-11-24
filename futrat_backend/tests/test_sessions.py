from datetime import datetime, timedelta, timezone
import hashlib

from jose import jwt

from app import models, security
from app.config import settings


def register(client):
    result = client.post('/auth/register', json={'username': 'SessionUser', 'password': 'secret123'})
    assert result.status_code == 200
    return result.json()


def bearer(token):
    return {'Authorization': 'Bearer ' + token}


def test_login_creates_hashed_revocable_session(client, db):
    tokens = register(client)
    refresh = tokens['refresh_token']
    assert len(refresh) >= 32
    row = db.query(models.AuthSession).one()
    assert row.token_hash == hashlib.sha256(refresh.encode()).hexdigest()
    assert row.token_hash != refresh
    assert row.revoked_at is None
    payload = jwt.decode(tokens['access_token'], settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    assert payload['sid'] == row.id
    assert tokens['expires_in'] == settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60


def test_expired_access_refreshes_without_password_even_after_long_absence(client, db):
    tokens = register(client)
    row = db.query(models.AuthSession).one()
    row.created_at = row.last_used_at = datetime(2020, 1, 1, tzinfo=timezone.utc)
    db.commit()
    expired = security.create_access_token(
        {'sub': str(row.user_id), 'subject_type': 'user_id', 'sid': row.id}, timedelta(seconds=-1))
    assert client.get('/auth/me', headers=bearer(expired)).status_code == 401
    result = client.post('/auth/refresh', json={'refresh_token': tokens['refresh_token']})
    assert result.status_code == 200
    assert result.json()['refresh_token'] == tokens['refresh_token']
    assert client.get('/auth/me', headers=bearer(result.json()['access_token'])).json()['username'] == 'SessionUser'
    # Lost refresh responses and concurrent clients can safely retry the same key.
    assert client.post('/auth/refresh', json={'refresh_token': tokens['refresh_token']}).status_code == 200


def test_logout_revokes_only_this_device_and_its_access_token(client, db):
    first = register(client)
    second = client.post('/auth/login', json={'username': 'SessionUser', 'password': 'secret123'}).json()
    assert client.post('/auth/logout', json={'refresh_token': first['refresh_token']}).status_code == 204
    assert client.post('/auth/logout', json={'refresh_token': first['refresh_token']}).status_code == 204
    assert client.post('/auth/refresh', json={'refresh_token': first['refresh_token']}).status_code == 401
    assert client.get('/auth/me', headers=bearer(first['access_token'])).status_code == 401
    assert client.get('/auth/me', headers=bearer(second['access_token'])).status_code == 200


def test_unknown_refresh_key_is_rejected_and_cannot_be_used_as_access(client):
    tokens = register(client)
    result = client.post('/auth/refresh', json={'refresh_token': 'x' * 64})
    assert result.status_code == 401
    assert 'x' * 64 not in result.text
    assert client.get('/auth/me', headers=bearer(tokens['refresh_token'])).status_code == 401


def test_access_cannot_use_another_users_session(client, db):
    register(client)
    second = client.post('/auth/register', json={'username': 'SecondUser', 'password': 'secret123'}).json()
    payload = jwt.decode(second['access_token'], settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    forged = security.create_access_token({'sub': '1', 'subject_type': 'user_id', 'sid': payload['sid']})
    assert client.get('/auth/me', headers=bearer(forged)).status_code == 401


def test_invalid_session_key_validation_does_not_echo_input(client):
    response = client.post('/auth/refresh', json={'refresh_token': 'private-short-key'})
    assert response.status_code == 422
    assert 'private-short-key' not in response.text


def test_configured_access_lifetime_is_used():
    token = security.create_access_token({'sub': '1'})
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    remaining = payload['exp'] - datetime.now(timezone.utc).timestamp()
    assert settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60 - 3 < remaining <= settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60

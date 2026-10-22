from datetime import timedelta
import json
from pathlib import Path

from app import models
from app.security import create_access_token


def register(client):
    result = client.post("/auth/register", json={
        "email": "test@example.test", "username": "Тест", "password": "Пароль ⚽"
    })
    assert result.status_code == 200
    assert set(result.json()) == {"access_token", "token_type"}
    assert result.json()["token_type"] == "bearer"
    return {"Authorization": "Bearer " + result.json()["access_token"]}


def test_register_login_and_current_user(client):
    headers = register(client)
    result = client.get("/auth/me", headers=headers)
    assert result.status_code == 200
    assert result.json() == {"id": result.json()["id"], "username": "Тест", "email": "test@example.test"}
    for login in ("test@example.test", "Тест"):
        result = client.post("/auth/login", json={"email": login, "password": "Пароль ⚽"})
        assert result.status_code == 200
        assert result.json()["token_type"] == "bearer"
    assert client.post("/auth/login", json={"email": "Тест", "password": "wrong"}).status_code == 401


def test_duplicate_registration_is_rejected(client):
    register(client)
    result = client.post("/auth/register", json={
        "email": "test@example.test", "username": "Other", "password": "test-password"
    })
    assert result.status_code == 409


def test_existing_password_hash_can_log_in(client, db):
    legacy = json.loads((Path(__file__).parent / "fixtures/legacy_security.json").read_text(encoding="utf-8"))
    user = models.User(email="legacy@example.test", username="Legacy", hashed_password=legacy["hashes"][0]["hash"])
    db.add(user)
    db.commit()
    result = client.post("/auth/login", json={"email": "legacy@example.test", "password": "legacy-password"})
    assert result.status_code == 200
    assert client.get("/auth/me", headers={"Authorization": "Bearer " + legacy["jwt"]}).status_code == 200


def test_invalid_expired_and_missing_tokens_are_rejected(client):
    assert client.get("/auth/me").status_code == 401
    for token in ("invalid", create_access_token({"sub": "test@example.test"}, timedelta(seconds=-1))):
        assert client.get("/auth/me", headers={"Authorization": "Bearer " + token}).status_code == 401


def test_match_and_tournament_responses(client, match):
    response = client.get("/api/matches")
    assert response.status_code == 200
    item = response.json()[0]
    assert item["id"] == match.id
    assert (item["score_home"], item["score_away"], item["status"]) == (2, 1, "FINISHED")
    assert item["home_team"]["name"] == "Home"
    assert item["away_team"]["name"] == "Away"
    assert item["tournament"]["name"] == "Test League"
    assert item["events"] == item["lineups"] == []
    assert client.get("/api/tournaments").json()[0]["id"] == match.tournament_id


def test_prediction_and_favorite_persist(client, db, match):
    from datetime import datetime, timezone
    match.status="SCHEDULED"
    match.date_time=datetime.now(timezone.utc)+timedelta(days=1)
    db.commit()
    headers = register(client)
    payload = {"match_id": match.id, "predicted_home_score": 2, "predicted_away_score": 1}
    result = client.post("/interactive/predict", json=payload, headers=headers)
    assert result.status_code == 200
    assert result.json()["match"]["id"] == match.id
    assert result.json()["points_awarded"] == 0
    assert client.post("/interactive/predict", json=payload, headers=headers).status_code == 400
    assert len(client.get("/interactive/my-predictions", headers=headers).json()) == 1
    endpoint = f"/users/favorites/teams/{match.home_team_id}"
    assert client.post(endpoint, headers=headers).status_code == 200
    assert client.get("/users/me/favorites/teams", headers=headers).json()[0]["name"] == "Home"
    assert client.delete(endpoint, headers=headers).status_code == 200
    assert client.get("/users/me/favorites/teams", headers=headers).json() == []


def test_openapi_keeps_flutter_auth_contract(client):
    schema = client.get("/openapi.json").json()
    assert "application/json" in schema["paths"]["/auth/login"]["post"]["requestBody"]["content"]
    assert set(schema["components"]["schemas"]["Token"]["properties"]) == {"access_token", "token_type"}


def test_lineup_player_can_be_favorited(client, db, match):
    match.is_detailed = True
    db.add(models.MatchLineup(
        match_id=match.id, team_id=match.home_team_id,
        player_name="Test Striker", jersey_number="9", is_starter=True,
    ))
    db.commit()

    response = client.get(f"/api/matches/{match.id}")
    assert response.status_code == 200
    player_id = response.json()["lineups"][0]["player_id"]
    assert player_id > 0

    headers = register(client)
    assert client.post(f"/users/favorites/players/{player_id}", headers=headers).status_code == 200
    favorite = client.get("/users/me/favorites/players", headers=headers).json()[0]
    assert (favorite["id"], favorite["name"]) == (player_id, "Test Striker")

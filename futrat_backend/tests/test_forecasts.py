from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException

from app import forecasts, models

NOW = datetime(2026, 10, 17, 12, tzinfo=timezone.utc)


@pytest.fixture
def user(db):
    row = models.User(username="forecaster", email="forecast@example.test", hashed_password="fake")
    db.add(row)
    db.commit()
    return row


def game(db, template, offset=0, when=None):
    row = models.Match(tournament_id=template.tournament_id,
        home_team_id=template.home_team_id, away_team_id=template.away_team_id,
        date_time=when or NOW + timedelta(hours=3, minutes=offset), status="SCHEDULED")
    db.add(row)
    db.commit()
    return row


def test_daily_quota_is_kickoff_date_in_moscow_and_not_submission_date(db, user, match):
    # 21:30 UTC is already the following date in Moscow.
    games = [game(db, match, i, NOW.replace(hour=21, minute=30)+timedelta(minutes=i)) for i in range(11)]
    for row in games[:10]:
        forecasts.choose(db, user.id, row.id, "HOME", now=NOW)
    assert forecasts.quota(db, user.id, datetime(2026, 10, 18).date())["used"] == 10
    assert forecasts.quota(db, user.id, NOW.date())["used"] == 0
    with pytest.raises(HTTPException) as error:
        forecasts.choose(db, user.id, games[10].id, "DRAW", now=NOW)
    assert error.value.status_code == 409
    db.rollback()
    next_day = game(db, match, when=NOW + timedelta(days=2))
    assert forecasts.choose(db, user.id, next_day.id, "AWAY", now=NOW).outcome == "AWAY"


def test_edit_is_idempotent_cancel_frees_slot_and_started_game_is_locked(db, user, match):
    row = game(db, match)
    first = forecasts.choose(db, user.id, row.id, "HOME", now=NOW)
    second = forecasts.choose(db, user.id, row.id, "DRAW", now=NOW)
    assert first.id == second.id
    assert forecasts.quota(db, user.id, NOW.date())["used"] == 1
    forecasts.cancel(db, user.id, row.id, now=NOW)
    forecasts.cancel(db, user.id, row.id, now=NOW)
    assert forecasts.quota(db, user.id, NOW.date())["used"] == 0
    forecasts.choose(db, user.id, row.id, "AWAY", now=NOW)
    with pytest.raises(HTTPException):
        forecasts.choose(db, user.id, row.id, "HOME", now=NOW+timedelta(hours=3))


def test_finished_match_and_another_users_cancellation_are_rejected(db, user, match):
    with pytest.raises(HTTPException):
        forecasts.choose(db, user.id, match.id, "HOME", now=NOW)
    row = game(db, match)
    with pytest.raises(HTTPException) as error:
        forecasts.cancel(db, user.id, row.id, now=NOW)
    assert error.value.status_code == 404


def test_regular_time_settlement_is_idempotent_correctable_and_month_pinned(db, user, match):
    row = game(db, match, when=datetime(2026, 10, 31, 20, tzinfo=timezone.utc))
    prediction = forecasts.choose(db, user.id, row.id, "DRAW", now=NOW)
    row.status, row.score_home, row.score_away = "FINISHED", 3, 2
    forecasts.record_result(db, row, regular_home=1, regular_away=1, kind="EXTRA_TIME", source="test")
    db.commit()
    assert prediction.points == 10 and prediction.status == "WON"
    forecasts.settle(db, row)
    db.commit()
    assert db.query(models.ForecastLedger).count() == 1
    board = forecasts.leaderboard(db, month="2026-10", now=NOW)
    assert board[0]["total_points"] == 10
    assert forecasts.leaderboard(db, month="2026-11", now=NOW) == []
    forecasts.record_result(db, row, regular_home=1, regular_away=0, kind="REGULAR", source="test")
    db.commit()
    assert prediction.points == 0 and prediction.status == "LOST"
    assert sum(entry.delta for entry in db.query(models.ForecastLedger)) == 0


def test_unknown_extra_time_score_is_not_treated_as_90_minutes(db, user, match):
    row = game(db, match)
    prediction = forecasts.choose(db, user.id, row.id, "HOME", now=NOW)
    row.status, row.score_home, row.score_away = "FINISHED", 2, 1
    forecasts.record_result(db, row, kind="EXTRA_TIME", source="test")
    db.commit()
    assert prediction.status == "PENDING" and prediction.points == 0


def test_reschedule_requires_confirmation_and_uses_new_days_quota(db, user, match):
    row = game(db, match)
    prediction = forecasts.choose(db, user.id, row.id, "HOME", now=NOW)
    row.date_time += timedelta(days=1)
    forecasts.settle(db, row)
    db.commit()
    assert prediction.status == "RECONFIRM"
    assert forecasts.quota(db, user.id, NOW.date())["used"] == 0
    forecasts.choose(db, user.id, row.id, "HOME", now=NOW)
    assert forecasts.quota(db, user.id, (NOW+timedelta(days=1)).date())["used"] == 1
    row.status = "CANCELLED"
    forecasts.settle(db, row)
    db.commit()
    assert prediction.status == "VOID"


def test_forecast_api_is_public_for_rankings_and_private_for_choices(client, db, match):
    assert client.get("/interactive/rankings").status_code == 200
    assert client.get("/interactive/predictions").status_code == 401
    row = game(db, match, when=datetime.now(timezone.utc)+timedelta(days=2))
    assert client.put(f"/interactive/predictions/{row.id}", json={"outcome":"HOME"}).status_code == 401
    result = client.post("/auth/register", json={"username":"api-forecaster", "email":"api@example.test", "password":"test-pass"})
    headers={"Authorization":"Bearer "+result.json()["access_token"]}
    assert client.put(f"/interactive/predictions/{row.id}", headers=headers, json={"outcome":"HOME"}).status_code == 200
    assert client.put(f"/interactive/predictions/{row.id}", headers=headers, json={"outcome":"INVALID"}).status_code == 422
    assert client.get("/interactive/predictions", headers=headers).json()[0]["outcome"] == "HOME"


def test_parallel_postgres_requests_accept_exactly_ten(db, user, match):
    if db.get_bind().dialect.name != "postgresql":
        pytest.skip("Row-lock concurrency is verified on isolated PostgreSQL")
    from concurrent.futures import ThreadPoolExecutor
    from sqlalchemy.orm import sessionmaker
    games = [game(db, match, i) for i in range(11)]
    ids, user_id = [row.id for row in games], user.id
    sessions = sessionmaker(bind=db.get_bind())
    def submit(match_id):
        with sessions() as session:
            try:
                forecasts.choose(session, user_id, match_id, "HOME", now=NOW)
                return True
            except HTTPException as error:
                session.rollback()
                assert error.status_code == 409
                return False
    with ThreadPoolExecutor(max_workers=11) as pool:
        results = list(pool.map(submit, ids))
    assert sum(results) == 10
    db.expire_all()
    assert db.query(models.Forecast).count() == 10
    assert forecasts.quota(db, user_id, NOW.date())["used"] == 10


def test_complete_timeline_resolves_90_minutes_and_survives_next_scoreboard(db,user,match):
    row=game(db,match)
    prediction=forecasts.choose(db,user.id,row.id,"DRAW",now=NOW)
    row.status,row.score_home,row.score_away="FINISHED",2,1
    forecasts.record_result(db,row,kind="EXTRA_TIME",source="ESPN")
    forecasts.regular_from_timeline(db,row,[(0,True),(1,True),(0,False)],"ESPN timeline")
    db.commit()
    assert prediction.points==10
    forecasts.observe_espn(db,row,{"type":{"name":"STATUS_FINAL_EXTRA_TIME"},"period":4})
    db.commit()
    assert prediction.status=="WON" and prediction.points==10
    assert db.query(models.ForecastLedger).count()==1


def test_incomplete_timeline_cannot_award_points(db,user,match):
    row=game(db,match)
    prediction=forecasts.choose(db,user.id,row.id,"DRAW",now=NOW)
    row.status,row.score_home,row.score_away="FINISHED",2,1
    forecasts.record_result(db,row,kind="EXTRA_TIME",source="ESPN")
    forecasts.regular_from_timeline(db,row,[(0,True),(1,True)],"ESPN timeline")
    db.commit()
    assert prediction.status=="PENDING" and prediction.points==0


def test_legacy_api_cannot_bypass_started_match_guard(client,match):
    response=client.post('/auth/register',json={'username':'legacy','email':'legacy-forecast@example.test','password':'test-pass'})
    headers={'Authorization':'Bearer '+response.json()['access_token']}
    assert client.post('/interactive/predict',headers=headers,json={
        'match_id':match.id,'predicted_home_score':2,'predicted_away_score':1}).status_code==409


def test_waiting_for_database_lock_does_not_allow_a_late_prediction(db,user,match,monkeypatch):
    row=game(db,match)
    clock=[NOW]
    monkeypatch.setattr(forecasts,'utc_now',lambda:clock[0])
    original=forecasts._lock_day
    def waited(*args):
        bucket=original(*args)
        clock[0]=NOW+timedelta(hours=3)
        return bucket
    monkeypatch.setattr(forecasts,'_lock_day',waited)
    with pytest.raises(HTTPException) as error:
        forecasts.choose(db,user.id,row.id,'HOME')
    assert error.value.status_code==409
    db.rollback()
    assert db.query(models.Forecast).count()==0

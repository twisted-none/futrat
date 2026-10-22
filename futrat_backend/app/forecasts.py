"""1X2 rules, Moscow kickoff-day quota and correction-safe scoring."""

from datetime import datetime, timedelta, timezone, date

from fastapi import HTTPException
from sqlalchemy import func, update, case
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.orm import selectinload

from app import models
from app.match_sync import utc, utc_now

MOSCOW = timezone(timedelta(hours=3), "MSK")
ACTIVE = {"OPEN", "PENDING", "WON", "LOST"}
VOID_STATUSES = {"CANCELLED", "ABANDONED"}


def match_day(match):
    return utc(match.date_time).astimezone(MOSCOW).date()


def quota(db, user_id, day):
    row = db.get(models.ForecastDay, (user_id, day))
    used = row.used if row else 0
    return {"day": day.isoformat(), "timezone": "Europe/Moscow", "used": used, "limit": 10, "remaining": 10-used}


def _lock_day(db, user_id, day):
    insert = pg_insert if db.get_bind().dialect.name == "postgresql" else sqlite_insert
    db.execute(insert(models.ForecastDay).values(user_id=user_id, day=day, used=0).on_conflict_do_nothing())
    return db.query(models.ForecastDay).filter_by(user_id=user_id, day=day).populate_existing().with_for_update().one()


def _game(db, match_id, now=None):
    game = db.query(models.Match).filter_by(id=match_id).populate_existing().with_for_update().first()
    if not game:
        raise HTTPException(404, "Матч не найден")
    if game.status != "SCHEDULED" or utc(game.date_time) <= (now or utc_now()):
        raise HTTPException(409, "Прогнозы на этот матч закрыты")
    if not game.home_team_id or not game.away_team_id or game.tournament.type.startswith("Pending"):
        raise HTTPException(409, "Участники или расписание ещё не определены")
    for team in (game.home_team, game.away_team):
        if any(word in team.name.casefold() for word in ("tbd", "winner", "loser")):
            raise HTTPException(409, "Участники ещё не определены")
    return game


def choose(db, user_id, match_id, outcome, *, now=None, commit=True):
    if outcome not in {"HOME", "DRAW", "AWAY"}:
        raise HTTPException(422, "Выберите П1, Х или П2")
    game = _game(db, match_id, now)
    day = match_day(game)
    prediction = db.query(models.Forecast).filter_by(user_id=user_id, match_id=match_id).first()
    days = {day}
    if prediction and prediction.status in ACTIVE:
        days.add(prediction.quota_day)
    buckets = {key: _lock_day(db, user_id, key) for key in sorted(days)}
    bucket = buckets[day]
    now=now or utc_now()
    if utc(game.date_time)<=now:
        raise HTTPException(409,"Матч уже начался")
    if prediction and prediction.status in ACTIVE and prediction.quota_day != day:
        _release(db, prediction)
        prediction.status = "RECONFIRM"
    reserve = prediction is None or prediction.status not in ACTIVE
    if reserve and bucket.used >= 10:
        raise HTTPException(409, "На эту дату уже выбрано 10 матчей по МСК")
    if prediction is None:
        prediction = models.Forecast(user_id=user_id, match_id=match_id, created_at=now)
        db.add(prediction)
    if reserve:
        bucket.used += 1
    prediction.quota_day, prediction.outcome = day, outcome
    prediction.status, prediction.points, prediction.updated_at = "OPEN", 0, now
    if commit:
        db.commit()
    else:
        db.flush()
    return prediction


def observe_espn(db, game, status):
    info = status.get("type") or {}
    description = " ".join(str(info.get(key, "")) for key in ("name", "description", "detail")).casefold()
    kind = "UNKNOWN"
    if any(word in description for word in ("forfeit", "awarded", "walkover")):
        kind = "AWARDED"
    elif "pen" in description or (status.get("period") or 0) >= 5:
        kind = "PENALTIES"
    elif "extra" in description or (status.get("period") or 0) > 2:
        kind = "EXTRA_TIME"
    elif game.status == "FINISHED" and info.get("name") in {"STATUS_FULL_TIME", "STATUS_FINAL"}:
        kind = "REGULAR"
    record_result(db, game, kind=kind, source="ESPN",
        regular_home=game.score_home if kind == "REGULAR" else None,
        regular_away=game.score_away if kind == "REGULAR" else None)


def observe_goal(db, game, raw_status):
    kind = {"FINISHED":"REGULAR", "AFTER_ET":"EXTRA_TIME", "AFTER_PEN":"PENALTIES",
            "AWARDED":"AWARDED"}.get(raw_status, "UNKNOWN")
    record_result(db, game, kind=kind, source="GOAL",
        regular_home=game.score_home if kind == "REGULAR" else None,
        regular_away=game.score_away if kind == "REGULAR" else None)


def _release(db, prediction):
    if prediction.status in ACTIVE:
        db.execute(update(models.ForecastDay).where(
            models.ForecastDay.user_id == prediction.user_id,
            models.ForecastDay.day == prediction.quota_day,
            models.ForecastDay.used > 0).values(used=models.ForecastDay.used-1))


def cancel(db, user_id, match_id, *, now=None):
    now = now or utc_now()
    _game(db, match_id, now)
    prediction = db.query(models.Forecast).filter_by(user_id=user_id, match_id=match_id).with_for_update().first()
    if prediction is None:
        raise HTTPException(404, "Прогноз не найден")
    _release(db, prediction)
    prediction.status, prediction.updated_at = "CANCELLED", now
    db.commit()


def record_result(db, game, *, regular_home=None, regular_away=None, kind="UNKNOWN", source):
    db.flush()
    result = db.get(models.MatchResult, game.id)
    if result is None:
        result = models.MatchResult(match_id=game.id)
        db.add(result)
    if regular_home is None and kind in {"EXTRA_TIME","PENALTIES"}:
        evidence=db.get(models.ProviderCache,f"regular-result:{game.id}")
        if evidence and evidence.payload.get("final")==[game.score_home,game.score_away]:
            regular_home,regular_away=evidence.payload["regular"]
    result.kind, result.source, result.updated_at = kind, source, utc_now()
    result.regular_home, result.regular_away = regular_home, regular_away
    db.flush()
    settle(db, game)


def regular_from_timeline(db,game,goals,source):
    result=db.get(models.MatchResult,game.id)
    if not result or result.kind not in {"EXTRA_TIME","PENALTIES"} or game.status!="FINISHED":
        return
    counts=[0,0]
    regular=[0,0]
    for side,is_regular in goals:
        if side not in (0,1):return
        counts[side]+=1
        if is_regular:regular[side]+=1
    # A partial timeline must never decide a prediction.
    if counts != [game.score_home,game.score_away]:return
    evidence=db.get(models.ProviderCache,f"regular-result:{game.id}")
    if not evidence:
        evidence=models.ProviderCache(key=f"regular-result:{game.id}")
        db.add(evidence)
    evidence.payload={"final":counts,"regular":regular,"source":source}
    evidence.expires_at=utc_now()+timedelta(days=3650)
    record_result(db,game,kind=result.kind,regular_home=regular[0],regular_away=regular[1],source=source)


def settle(db, game):
    """Run in the same transaction as source updates; never use ET/penalty totals."""
    predictions = db.query(models.Forecast).filter_by(match_id=game.id).with_for_update().all()
    result = db.get(models.MatchResult, game.id)
    now = utc_now()
    for prediction in predictions:
        if prediction.status == "CANCELLED":
            continue
        points, status = 0, prediction.status
        if game.status in VOID_STATUSES or (result and result.kind == "AWARDED"):
            _release(db, prediction)
            status = "VOID"
        elif prediction.quota_day != match_day(game):
            _release(db, prediction)
            status = "RECONFIRM"
        elif prediction.status in {"RECONFIRM", "VOID"}:
            continue
        elif game.status == "FINISHED":
            if not result or result.regular_home is None or result.regular_away is None:
                status = "PENDING"
            else:
                outcome = "HOME" if result.regular_home > result.regular_away else (
                    "AWAY" if result.regular_home < result.regular_away else "DRAW")
                status = "WON" if prediction.outcome == outcome else "LOST"
                points = 10 if status == "WON" else 0
        elif game.status == "SCHEDULED":
            status = "OPEN"
        else:
            status = "PENDING"
        if points != prediction.points or (status in {"WON", "LOST"} and prediction.settled_at is None):
            db.add(models.ForecastLedger(forecast_id=prediction.id, delta=points-prediction.points,
                reason=status, recorded_at=now))
        prediction.points, prediction.status = points, status
        prediction.updated_at = now
        prediction.settled_at = now if status in {"WON", "LOST"} else None
        if prediction.legacy_id:
            legacy = db.get(models.Prediction, prediction.legacy_id)
            legacy.points_awarded = points
        db.flush()


def leaderboard(db, *, month=None, now=None):
    query = db.query(models.Forecast.user_id, models.User.username,
        func.sum(models.Forecast.points), func.count(models.Forecast.id),
        func.sum(case((models.Forecast.status == "WON", 1), else_=0))
    ).join(models.User, models.User.id == models.Forecast.user_id).filter(
        models.Forecast.status.in_(["WON", "LOST"]))
    if month:
        try:
            start = date.fromisoformat(month + "-01")
        except ValueError:
            raise HTTPException(422, "Месяц должен иметь формат YYYY-MM") from None
        end = (start.replace(day=28) + timedelta(days=4)).replace(day=1)
        query = query.filter(models.Forecast.quota_day >= start, models.Forecast.quota_day < end)
    records = query.group_by(models.Forecast.user_id, models.User.username).all()
    users = [{"user_id":uid, "username":name, "total_points":points, "settled":count, "correct":correct}
             for uid, name, points, count, correct in records]
    rows = sorted(users, key=lambda r: (-r["total_points"], -r["correct"]/r["settled"], r["user_id"]))
    last, rank = None, 0
    for index, row in enumerate(rows):
        key = (row["total_points"], row["correct"]/row["settled"])
        if key != last:
            rank, last = index+1, key
        row["rank"], row["accuracy"] = rank, round(100*row["correct"]/row["settled"], 1)
    return rows

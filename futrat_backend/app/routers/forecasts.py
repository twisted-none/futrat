from datetime import date
from typing import Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session, selectinload

from app import database, forecasts, models, schemas
from app.routers.auth import get_current_user

router = APIRouter(prefix="/interactive", tags=["Forecasts"])


class Choice(BaseModel):
    outcome: Literal["HOME", "DRAW", "AWAY"]


def serialize(prediction):
    return {"id": prediction.id, "match_id": prediction.match_id,
            "day": prediction.quota_day.isoformat(), "outcome": prediction.outcome,
            "status": prediction.status, "points": prediction.points,
            "match": schemas.MatchResponse.model_validate(prediction.match).model_dump(mode="json")}


@router.put("/predictions/{match_id}")
def choose(match_id: int, choice: Choice, db: Session = Depends(database.get_db), user=Depends(get_current_user)):
    return serialize(forecasts.choose(db, user.id, match_id, choice.outcome))


@router.delete("/predictions/{match_id}")
def cancel(match_id: int, db: Session = Depends(database.get_db), user=Depends(get_current_user)):
    forecasts.cancel(db, user.id, match_id)
    return {"message": "Прогноз отменён"}


@router.get("/predictions")
def mine(day: date | None = None, offset: int = Query(default=0, ge=0),
         limit: int = Query(default=100, ge=1, le=100),
         db: Session = Depends(database.get_db), user=Depends(get_current_user)):
    query = db.query(models.Forecast).filter_by(user_id=user.id)
    if day:
        query = query.filter(models.Forecast.quota_day == day)
    rows = query.options(
        selectinload(models.Forecast.match).selectinload(models.Match.home_team),
        selectinload(models.Forecast.match).selectinload(models.Match.away_team),
        selectinload(models.Forecast.match).selectinload(models.Match.tournament),
        selectinload(models.Forecast.match).selectinload(models.Match.lineups),
        selectinload(models.Forecast.match).selectinload(models.Match.events),
    ).order_by(models.Forecast.quota_day.desc(), models.Forecast.id.desc()).offset(offset).limit(limit).all()
    return [serialize(row) for row in rows]


@router.get("/prediction-quota")
def quota(day: date, db: Session = Depends(database.get_db), user=Depends(get_current_user)):
    return forecasts.quota(db, user.id, day)


@router.get("/rankings")
def rankings(month: str | None = Query(default=None, pattern=r"^\d{4}-\d{2}$"),
             offset: int = Query(default=0, ge=0), limit: int = Query(default=50, ge=1, le=100),
             db: Session = Depends(database.get_db)):
    rows = forecasts.leaderboard(db, month=month)
    return {"month": month, "total": len(rows), "rows": rows[offset:offset+limit]}


@router.get("/my-rank")
def my_rank(month: str | None = Query(default=None, pattern=r"^\d{4}-\d{2}$"),
            db: Session = Depends(database.get_db), user=Depends(get_current_user)):
    return next((row for row in forecasts.leaderboard(db, month=month) if row["user_id"] == user.id), None)

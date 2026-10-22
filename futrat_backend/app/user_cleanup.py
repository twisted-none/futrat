"""Explicit, verified deletion only; never called during ordinary startup."""
from sqlalchemy import delete, select
from app import models, security


def delete_empty_account(db, user_id):
    user = db.execute(select(models.User).where(models.User.id == user_id).with_for_update()).scalar_one_or_none()
    if user is None or user.username.strip():
        return False
    if not security.verify_password("", user.hashed_password):
        return False
    forecasts = select(models.Forecast.id).where(models.Forecast.user_id == user_id)
    db.execute(delete(models.ForecastLedger).where(models.ForecastLedger.forecast_id.in_(forecasts)))
    for entity in [models.Forecast, models.ForecastDay, models.Prediction, models.UserPlayerRating]:
        db.execute(delete(entity).where(entity.user_id == user_id))
    for table in [models.user_teams_association, models.user_players_association, models.user_tournaments_association]:
        db.execute(delete(table).where(table.c.user_id == user_id))
    db.execute(delete(models.User).where(models.User.id == user_id))
    db.commit()
    return True

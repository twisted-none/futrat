from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app import models, schemas, database, forecasts
from app.routers.auth import get_current_user

router = APIRouter(prefix="/interactive", tags=["Interactive"])

@router.post("/predict", response_model=schemas.PredictionResponse)
def make_prediction(
    prediction: schemas.PredictionCreate, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    # Legacy exact-score clients use the same quota/deadline as the 1X2 API.
    if prediction.predicted_home_score < 0 or prediction.predicted_away_score < 0:
        raise HTTPException(422,"Счёт не может быть отрицательным")
    outcome="HOME" if prediction.predicted_home_score>prediction.predicted_away_score else (
        "AWAY" if prediction.predicted_home_score<prediction.predicted_away_score else "DRAW")
    forecast=forecasts.choose(db,current_user.id,prediction.match_id,outcome,commit=False)
    existing = db.query(models.Prediction).filter(
        models.Prediction.user_id == current_user.id,
        models.Prediction.match_id == prediction.match_id
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="Prediction already made for this match")

    new_pred = models.Prediction(
        user_id=current_user.id,
        **prediction.model_dump()
    )
    db.add(new_pred)
    db.flush()
    forecast.legacy_id=new_pred.id
    db.commit()
    db.refresh(new_pred)
    return new_pred

@router.get("/my-predictions", response_model=List[schemas.PredictionResponse])
def get_my_predictions(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    return db.query(models.Prediction).filter(models.Prediction.user_id == current_user.id).all()

# Пример добавления команды в избранное
@router.post("/favorites/team/{team_id}")
def add_favorite_team(
    team_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    team = db.query(models.Team).filter(models.Team.id == team_id).first()
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
    
    current_user.favorite_teams.append(team)
    db.commit()
    return {"message": "Team added to favorites"}

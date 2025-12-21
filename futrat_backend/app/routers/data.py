from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from app import models, schemas, database

router = APIRouter(prefix="/api", tags=["Data"])

@router.get("/matches", response_model=List[schemas.MatchResponse])
def get_matches(db: Session = Depends(database.get_db)):
    # Здесь можно добавить фильтрацию по дате
    return db.query(models.Match).all()

@router.get("/tournaments", response_model=List[schemas.TournamentResponse])
def get_tournaments(db: Session = Depends(database.get_db)):
    return db.query(models.Tournament).all()

@router.get("/teams/{team_id}", response_model=schemas.TeamResponse)
def get_team(team_id: int, db: Session = Depends(database.get_db)):
    return db.query(models.Team).filter(models.Team.id == team_id).first()
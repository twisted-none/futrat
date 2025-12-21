from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app import models, schemas, database
from app.routers.auth import get_current_user

router = APIRouter(prefix="/users", tags=["Users"])

# --- Профиль ---

@router.put("/me", response_model=schemas.UserResponse)
def update_user_profile(
    user_update: schemas.UserUpdate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Обновление никнейма или email"""
    if user_update.email is not None and user_update.email != current_user.email:
        if db.query(models.User).filter(models.User.email == user_update.email).first():
            raise HTTPException(status_code=400, detail="Email already registered")
        current_user.email = user_update.email

    if user_update.username is not None:
        current_user.username = user_update.username
    
    db.commit()
    db.refresh(current_user)
    return current_user

# --- GET списки избранного ---

@router.get("/me/favorites/teams", response_model=List[schemas.TeamResponse])
def get_favorite_teams(current_user: models.User = Depends(get_current_user)):
    return current_user.favorite_teams

@router.get("/me/favorites/players", response_model=List[schemas.PlayerResponse])
def get_favorite_players(current_user: models.User = Depends(get_current_user)):
    return current_user.favorite_players

@router.get("/me/favorites/tournaments", response_model=List[schemas.TournamentResponse])
def get_favorite_tournaments(current_user: models.User = Depends(get_current_user)):
    return current_user.favorite_tournaments

# --- ИГРОКИ: Добавить/Удалить ---

@router.post("/favorites/players/{player_id}")
def add_favorite_player(player_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    player = db.query(models.Player).filter(models.Player.id == player_id).first()
    if not player: raise HTTPException(status_code=404, detail="Not found")
    
    if player not in current_user.favorite_players:
        current_user.favorite_players.append(player)
        db.commit()
    return {"message": "Added to favorites"}

@router.delete("/favorites/players/{player_id}")
def remove_favorite_player(player_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    player = db.query(models.Player).filter(models.Player.id == player_id).first()
    if player in current_user.favorite_players:
        current_user.favorite_players.remove(player)
        db.commit()
    return {"message": "Removed from favorites"}

# --- КОМАНДЫ: Добавить/Удалить ---

@router.post("/favorites/teams/{team_id}")
def add_favorite_team(team_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    team = db.query(models.Team).filter(models.Team.id == team_id).first()
    if not team: raise HTTPException(status_code=404, detail="Not found")
    
    if team not in current_user.favorite_teams:
        current_user.favorite_teams.append(team)
        db.commit()
    return {"message": "Added to favorites"}

@router.delete("/favorites/teams/{team_id}")
def remove_favorite_team(team_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    team = db.query(models.Team).filter(models.Team.id == team_id).first()
    if team in current_user.favorite_teams:
        current_user.favorite_teams.remove(team)
        db.commit()
    return {"message": "Removed from favorites"}

# --- ТУРНИРЫ: Добавить/Удалить ---

@router.post("/favorites/tournaments/{tournament_id}")
def add_favorite_tournament(tournament_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    t = db.query(models.Tournament).filter(models.Tournament.id == tournament_id).first()
    if not t: raise HTTPException(status_code=404, detail="Not found")
    
    if t not in current_user.favorite_tournaments:
        current_user.favorite_tournaments.append(t)
        db.commit()
    return {"message": "Added to favorites"}

@router.delete("/favorites/tournaments/{tournament_id}")
def remove_favorite_tournament(tournament_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    t = db.query(models.Tournament).filter(models.Tournament.id == tournament_id).first()
    if t in current_user.favorite_tournaments:
        current_user.favorite_tournaments.remove(t)
        db.commit()
    return {"message": "Removed from favorites"}
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from sqlalchemy import func, desc
from typing import List

from app import models, schemas, database
from app import lineups, forecasts
from app.routers.auth import get_current_user, nickname_taken, raise_unique_conflict

router = APIRouter(prefix="/users", tags=["Users"])

# --- ЛИДЕРБОРД (НОВОЕ) ---
@router.get("/leaderboard", response_model=List[schemas.LeaderboardEntry])
def get_leaderboard(db: Session = Depends(database.get_db)):
    """
    Возвращает список пользователей, отсортированный по сумме очков за прогнозы.
    """
    current=forecasts.leaderboard(db)
    if current:
        return [{"username":row["username"],"total_points":row["total_points"]} for row in current[:50]]
    results = db.query(
        models.User.username,
        func.sum(models.Prediction.points_awarded).label("total_points")
    ).join(models.Prediction).group_by(models.User.id).order_by(desc("total_points")).limit(50).all()

    return [{"username": r[0], "total_points": r[1] or 0} for r in results]

# --- ПРОФИЛЬ ---
@router.put("/me", response_model=schemas.UserResponse)
def update_user_profile(
    user_update: schemas.UserUpdate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user)
):
    if user_update.email is not None and user_update.email != current_user.email:
        if db.query(models.User).filter(models.User.email == user_update.email).first():
            raise HTTPException(status_code=400, detail="Email already registered")
        current_user.email = user_update.email

    if user_update.username is not None:
        if nickname_taken(db, user_update.username, exclude_id=current_user.id):
            raise HTTPException(status_code=409, detail="Этот никнейм уже занят")
        current_user.username = user_update.username

    try:
        db.commit()
    except IntegrityError as error:
        db.rollback()
        raise_unique_conflict(error)
    db.refresh(current_user)
    return current_user

# --- ИЗБРАННОЕ (GET) ---
@router.get("/me/favorites/teams", response_model=List[schemas.TeamResponse])
def get_favorite_teams(current_user: models.User = Depends(get_current_user)):
    return current_user.favorite_teams

@router.get("/me/favorites/players", response_model=List[schemas.PlayerResponse])
def get_favorite_players(db:Session=Depends(database.get_db),current_user: models.User = Depends(get_current_user)):
    players={lineups.canonical_id(db,row.id):row for row in current_user.favorite_players}
    result=[]
    for player_id in players:
        player=db.get(models.Player,player_id)
        photo=db.get(models.PlayerProfile,player_id)
        player.photo_url=photo.photo_url if photo else None
        result.append(player)
    return result

@router.get("/me/favorites/tournaments", response_model=List[schemas.TournamentResponse])
def get_favorite_tournaments(current_user: models.User = Depends(get_current_user)):
    return current_user.favorite_tournaments

# --- ИЗБРАННОЕ (TOGGLE) ---
@router.post("/favorites/players/{player_id}")
def add_favorite_player(player_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    player_id=lineups.canonical_id(db,player_id)
    item = db.query(models.Player).filter(models.Player.id == player_id).first()
    if not item: raise HTTPException(status_code=404, detail="Not found")
    if item not in current_user.favorite_players:
        current_user.favorite_players.append(item)
        db.commit()
    return {"message": "Added"}

@router.delete("/favorites/players/{player_id}")
def remove_favorite_player(player_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    player_id=lineups.canonical_id(db,player_id)
    for item in list(current_user.favorite_players):
        if lineups.canonical_id(db,item.id)==player_id:
            current_user.favorite_players.remove(item)
    db.commit()
    return {"message": "Removed"}

@router.post("/favorites/teams/{team_id}")
def add_favorite_team(team_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    item = db.query(models.Team).filter(models.Team.id == team_id).first()
    if not item: raise HTTPException(status_code=404, detail="Not found")
    if item not in current_user.favorite_teams:
        current_user.favorite_teams.append(item)
        db.commit()
    return {"message": "Added"}

@router.delete("/favorites/teams/{team_id}")
def remove_favorite_team(team_id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    item = db.query(models.Team).filter(models.Team.id == team_id).first()
    if item in current_user.favorite_teams:
        current_user.favorite_teams.remove(item)
        db.commit()
    return {"message": "Removed"}

@router.post("/favorites/tournaments/{id}")
def add_favorite_tournament(id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    item = db.query(models.Tournament).filter(models.Tournament.id == id).first()
    if not item: raise HTTPException(status_code=404, detail="Not found")
    if item not in current_user.favorite_tournaments:
        current_user.favorite_tournaments.append(item)
        db.commit()
    return {"message": "Added"}

@router.delete("/favorites/tournaments/{id}")
def remove_favorite_tournament(id: int, db: Session = Depends(database.get_db), current_user: models.User = Depends(get_current_user)):
    item = db.query(models.Tournament).filter(models.Tournament.id == id).first()
    if item in current_user.favorite_tournaments:
        current_user.favorite_tournaments.remove(item)
        db.commit()
    return {"message": "Removed"}

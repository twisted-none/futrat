from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

# --- Auth & User ---
class UserCreate(BaseModel):
    username: str
    email: str 
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None

class Token(BaseModel):
    access_token: str
    token_type: str

class UserResponse(BaseModel):
    id: int
    username: str
    email: str
    class Config:
        from_attributes = True

# --- Base Schemas ---

class TeamBase(BaseModel):
    name: str
    logo_url: Optional[str] = None
    country: Optional[str] = None

class TeamResponse(TeamBase):
    id: int
    class Config:
        from_attributes = True

class TournamentResponse(BaseModel):
    id: int
    name: str
    country: Optional[str]
    type: str
    current_season: str
    class Config:
        from_attributes = True

class PlayerResponse(BaseModel):
    id: int
    name: str
    position: Optional[str]
    nationality: Optional[str]
    goals: int
    assists: int
    class Config:
        from_attributes = True

# --- Match Events ---
class MatchEventResponse(BaseModel):
    id: int
    type: str
    minute: int
    player: PlayerResponse # Вложенный игрок
    class Config:
        from_attributes = True

class MatchResponse(BaseModel):
    id: int
    date_time: datetime
    status: str
    score_home: Optional[int]
    score_away: Optional[int]
    round: int # Тур
    home_team: TeamResponse
    away_team: TeamResponse
    tournament: TournamentResponse
    events: List[MatchEventResponse] = [] # Список голов

    class Config:
        from_attributes = True

# --- Prediction Schemas ---

class PredictionCreate(BaseModel):
    match_id: int
    predicted_home_score: int
    predicted_away_score: int

class PredictionResponse(PredictionCreate):
    id: int
    points_awarded: int
    match: MatchResponse
    
    class Config:
        from_attributes = True
from pydantic import BaseModel, ConfigDict, Field, computed_field, field_validator, AliasChoices
from typing import List, Optional
from datetime import datetime
from app.credentials import validate_nickname, validate_new_password


class UserCreate(BaseModel):
    username: str
    password: str
    # Accepted for older clients; no longer required or used by the new form.
    email: Optional[str] = None

    _nickname = field_validator("username")(validate_nickname)
    _password = field_validator("password")(validate_new_password)

    @field_validator("email")
    @classmethod
    def optional_email(cls, value):
        return value.strip() or None if value is not None else None


class UserLogin(BaseModel):
    username: str = Field(validation_alias=AliasChoices("username", "email"))
    password: str

    @field_validator("username")
    @classmethod
    def required_nickname(cls, value):
        if not value.strip():
            raise ValueError("Введите никнейм")
        return value.strip()

    @field_validator("password")
    @classmethod
    def required_password(cls, value):
        if not value:
            raise ValueError("Введите пароль")
        if "\x00" in value:
            raise ValueError("Пароль содержит недопустимый символ")
        return value


class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None

    @field_validator("username")
    @classmethod
    def valid_nickname(cls, value):
        return validate_nickname(value) if value is not None else None


class Token(BaseModel):
    access_token: str
    token_type: str


class UserResponse(BaseModel):
    id: int
    username: str
    email: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class TeamBase(BaseModel):
    name: str
    logo_url: Optional[str] = None
    country: Optional[str] = None


class TeamResponse(TeamBase):
    id: int

    model_config = ConfigDict(from_attributes=True)


class TournamentResponse(BaseModel):
    id: int
    name: str
    country: Optional[str]
    type: str
    current_season: str
    logo_url: Optional[str] = None
    api_code: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class PlayerResponse(BaseModel):
    id: int
    name: str
    position: Optional[str]
    nationality: Optional[str]
    goals: int
    assists: int
    team_id: int
    photo_url: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class MatchEventResponse(BaseModel):
    id: int
    type: str
    minute: int
    player: PlayerResponse
    secondary_player: Optional[PlayerResponse] = None

    model_config = ConfigDict(from_attributes=True)


class LineupPlayerResponse(BaseModel):
    id: int
    player_id: Optional[int] = None
    team_id: int
    player_name: str
    jersey_number: Optional[str]
    position: Optional[str]
    is_starter: bool
    rating: Optional[str] = "-"
    rating_count: int = 0
    photo_url: Optional[str] = None
    slot: Optional[int] = None
    appeared: Optional[bool] = None
    minutes: Optional[int] = None
    goals: Optional[int] = None
    assists: Optional[int] = None
    source_rating: Optional[float] = None
    rating_source: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class MatchResponse(BaseModel):
    id: int
    api_id: Optional[str] = None
    date_time: datetime
    status: str
    score_home: Optional[int]
    score_away: Optional[int]
    round: int
    possession_home: int
    possession_away: int
    shots_home: int
    shots_away: int
    corners_home: int
    corners_away: int
    fouls_home: int
    fouls_away: int
    yellow_cards_home: int
    yellow_cards_away: int
    red_cards_home: int
    red_cards_away: int
    offsides_home: int
    offsides_away: int
    passes_home: int
    passes_away: int
    pass_accuracy_home: int
    pass_accuracy_away: int
    xg_home: float = 0.0
    xg_away: float = 0.0
    shots_on_target_home: int = 0
    shots_on_target_away: int = 0
    saves_home: int = 0
    saves_away: int = 0
    home_team: TeamResponse
    away_team: TeamResponse
    tournament: TournamentResponse
    events: List[MatchEventResponse] = []
    lineups: List[LineupPlayerResponse] = []
    formations: dict[str,str] = {}
    clock: Optional[str] = None
    phase: Optional[str] = None
    live_updated_at: Optional[datetime] = None

    @computed_field
    @property
    def is_live(self) -> bool:
        from app.live_matches import is_live_match
        return is_live_match(self.status, self.date_time)

    model_config = ConfigDict(from_attributes=True)


class MatchLiveUpdate(BaseModel):
    id: int
    date_time: datetime
    status: str
    score_home: Optional[int]
    score_away: Optional[int]
    clock: Optional[str] = None
    phase: Optional[str] = None
    live_updated_at: Optional[datetime] = None

    @computed_field
    @property
    def is_live(self) -> bool:
        from app.live_matches import is_live_match
        return is_live_match(self.status, self.date_time)

    model_config = ConfigDict(from_attributes=True)


class StandingRow(BaseModel):
    rank: int
    team: TeamResponse
    played: int
    won: int
    draw: int
    lost: int
    goals_for: int
    goals_against: int
    points: int
    form: List[str] = []
    group_name: Optional[str] = None  # ДОБАВЛЕНО ПОЛЕ ДЛЯ ГРУПП (ЧМ, ЕВРО, ЛЧ)

    model_config = ConfigDict(from_attributes=True)


class PlayerRatingCreate(BaseModel):
    lineup_id: int
    rating: float = Field(..., ge=1, le=10)


class PredictionCreate(BaseModel):
    match_id: int
    predicted_home_score: int
    predicted_away_score: int


class PredictionResponse(PredictionCreate):
    id: int
    points_awarded: int
    match: MatchResponse

    model_config = ConfigDict(from_attributes=True)


class LeaderboardEntry(BaseModel):
    username: str
    total_points: int

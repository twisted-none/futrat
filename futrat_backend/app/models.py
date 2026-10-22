from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Boolean, Table, Float, JSON, Date, UniqueConstraint, event
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
from app.credentials import nickname_key

# --- ТАБЛИЦЫ СВЯЗЕЙ (Many-to-Many для избранного) ---
user_teams_association = Table(
    'user_teams', Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id'), primary_key=True),
    Column('team_id', Integer, ForeignKey('teams.id'), primary_key=True)
)

user_players_association = Table(
    'user_players', Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id'), primary_key=True),
    Column('player_id', Integer, ForeignKey('players.id'), primary_key=True)
)

user_tournaments_association = Table(
    'user_tournaments', Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id'), primary_key=True),
    Column('tournament_id', Integer, ForeignKey('tournaments.id'), primary_key=True)
)

# --- СУЩНОСТИ ---

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=True)
    username = Column(String, unique=True, index=True, nullable=False)
    username_key = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    favorite_teams = relationship("Team", secondary=user_teams_association, back_populates="favorited_by")
    favorite_players = relationship("Player", secondary=user_players_association, back_populates="favorited_by")
    favorite_tournaments = relationship("Tournament", secondary=user_tournaments_association, back_populates="favorited_by")

    predictions = relationship("Prediction", back_populates="user")
    ratings = relationship("UserPlayerRating", back_populates="user")


@event.listens_for(User, "before_insert")
@event.listens_for(User, "before_update")
def maintain_username_key(mapper, connection, user):
    user.username_key = nickname_key(user.username)

class Tournament(Base):
    __tablename__ = "tournaments"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    country = Column(String, nullable=True)
    type = Column(String, nullable=False)
    current_season = Column(String, nullable=False)
    logo_url = Column(String, nullable=True)
    api_code = Column(String, nullable=True)

    matches = relationship("Match", back_populates="tournament")
    favorited_by = relationship("User", secondary=user_tournaments_association, back_populates="favorite_tournaments")

class TournamentSyncState(Base):
    """Calendar and restart checkpoints; existing match/user tables stay intact."""

    __tablename__ = "tournament_sync_states"
    tournament_id = Column(Integer, ForeignKey("tournaments.id"), primary_key=True)
    season_start = Column(DateTime(timezone=True), nullable=False)
    season_end = Column(DateTime(timezone=True), nullable=False)
    calendar = Column(JSON, nullable=False, default=list)
    completed_dates = Column(JSON, nullable=False, default=list)
    source_rounds = Column(JSON, nullable=False, default=dict)
    calendar_updated_at = Column(DateTime(timezone=True), nullable=False)


class ProviderTeam(Base):
    __tablename__ = "provider_teams"
    provider = Column(String, primary_key=True)
    external_id = Column(String, primary_key=True)
    team_id = Column(Integer, ForeignKey("teams.id"), nullable=False, index=True)


class ProviderMatch(Base):
    __tablename__ = "provider_matches"
    __table_args__ = (UniqueConstraint("provider", "match_id"),)
    provider = Column(String, primary_key=True)
    external_id = Column(String, primary_key=True)
    match_id = Column(Integer, ForeignKey("matches.id"), nullable=False, index=True)


class ProviderCache(Base):
    __tablename__ = "provider_cache"
    key = Column(String, primary_key=True)
    payload = Column(JSON, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)


class ProviderUsage(Base):
    __tablename__ = "provider_usage"
    provider = Column(String, primary_key=True)
    day = Column(Date, primary_key=True)
    requests = Column(Integer, nullable=False, default=0)
    blocked_until = Column(DateTime(timezone=True), nullable=True)


class OfficialStandings(Base):
    __tablename__ = "official_standings"
    tournament_id = Column(Integer, ForeignKey("tournaments.id"), primary_key=True)
    season = Column(String, nullable=False)
    rows = Column(JSON, nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)


class Team(Base):
    __tablename__ = "teams"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    logo_url = Column(String, nullable=True)
    country = Column(String, nullable=True)
    coach_name = Column(String, nullable=True)

    players = relationship("Player", back_populates="team")

    # Связи с матчами
    home_matches = relationship("Match", foreign_keys="[Match.home_team_id]", back_populates="home_team")
    away_matches = relationship("Match", foreign_keys="[Match.away_team_id]", back_populates="away_team")

    favorited_by = relationship("User", secondary=user_teams_association, back_populates="favorite_teams")

class Player(Base):
    __tablename__ = "players"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    position = Column(String, nullable=True)
    nationality = Column(String, nullable=True)
    team_id = Column(Integer, ForeignKey("teams.id"))

    goals = Column(Integer, default=0)
    assists = Column(Integer, default=0)
    minutes_played = Column(Integer, default=0)

    team = relationship("Team", back_populates="players")
    favorited_by = relationship("User", secondary=user_players_association, back_populates="favorite_players")

    # Связь с событиями (голы, карточки)
    match_events = relationship("MatchEvent", foreign_keys="[MatchEvent.player_id]", back_populates="player")

class Match(Base):
    __tablename__ = "matches"
    live_state = relationship("MatchLiveState", uselist=False, lazy="selectin")

    @property
    def clock(self):
        return self.live_state.clock if self.live_state else None

    @property
    def phase(self):
        return self.live_state.phase if self.live_state else None

    @property
    def live_updated_at(self):
        return self.live_state.updated_at if self.live_state else None
    id = Column(Integer, primary_key=True, index=True)
    api_id = Column(String, nullable=True)
    is_detailed = Column(Boolean, default=False)

    date_time = Column(DateTime(timezone=True), nullable=False)
    tournament_id = Column(Integer, ForeignKey("tournaments.id"))
    home_team_id = Column(Integer, ForeignKey("teams.id"))
    away_team_id = Column(Integer, ForeignKey("teams.id"))

    score_home = Column(Integer, nullable=True)
    score_away = Column(Integer, nullable=True)
    status = Column(String, default="SCHEDULED")
    round = Column(Integer, default=1)

    # Статистика
    possession_home = Column(Integer, default=50)
    possession_away = Column(Integer, default=50)
    shots_home = Column(Integer, default=0)
    shots_away = Column(Integer, default=0)
    corners_home = Column(Integer, default=0)
    corners_away = Column(Integer, default=0)
    fouls_home = Column(Integer, default=0)
    fouls_away = Column(Integer, default=0)
    yellow_cards_home = Column(Integer, default=0)
    yellow_cards_away = Column(Integer, default=0)
    red_cards_home = Column(Integer, default=0)
    red_cards_away = Column(Integer, default=0)
    offsides_home = Column(Integer, default=0)
    offsides_away = Column(Integer, default=0)
    passes_home = Column(Integer, default=0)
    passes_away = Column(Integer, default=0)
    pass_accuracy_home = Column(Integer, default=0)
    pass_accuracy_away = Column(Integer, default=0)

    # Расширенные метрики
    xg_home = Column(Float, default=0.0)
    xg_away = Column(Float, default=0.0)
    shots_on_target_home = Column(Integer, default=0)
    shots_on_target_away = Column(Integer, default=0)
    saves_home = Column(Integer, default=0)
    saves_away = Column(Integer, default=0)

    tournament = relationship("Tournament", back_populates="matches")
    home_team = relationship("Team", foreign_keys=[home_team_id], back_populates="home_matches")
    away_team = relationship("Team", foreign_keys=[away_team_id], back_populates="away_matches")

    predictions = relationship("Prediction", back_populates="match")
    events = relationship("MatchEvent", back_populates="match")
    lineups = relationship("MatchLineup", back_populates="match")

class MatchLineup(Base):
    __tablename__ = "match_lineups"
    id = Column(Integer, primary_key=True, index=True)
    match_id = Column(Integer, ForeignKey("matches.id"))
    team_id = Column(Integer, ForeignKey("teams.id"))
    player_name = Column(String, nullable=False)
    jersey_number = Column(String, nullable=True)
    position = Column(String, nullable=True)
    is_starter = Column(Boolean, default=True)

    match = relationship("Match", back_populates="lineups")
    user_ratings = relationship("UserPlayerRating", back_populates="lineup")

class UserPlayerRating(Base):
    __tablename__ = "user_player_ratings"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    lineup_id = Column(Integer, ForeignKey("match_lineups.id"))
    rating = Column(Float, nullable=False)

    user = relationship("User", back_populates="ratings")
    lineup = relationship("MatchLineup", back_populates="user_ratings")

class MatchEvent(Base):
    __tablename__ = "match_events"
    id = Column(Integer, primary_key=True, index=True)
    match_id = Column(Integer, ForeignKey("matches.id"))
    player_id = Column(Integer, ForeignKey("players.id"))
    secondary_player_id = Column(Integer, ForeignKey("players.id"), nullable=True)
    type = Column(String, nullable=False) # "GOAL", "YELLOW_CARD", etc.
    minute = Column(Integer, nullable=False)

    match = relationship("Match", back_populates="events")
    player = relationship("Player", foreign_keys=[player_id], back_populates="match_events")
    secondary_player = relationship("Player", foreign_keys=[secondary_player_id])

class Prediction(Base):
    __tablename__ = "predictions"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    match_id = Column(Integer, ForeignKey("matches.id"))
    predicted_home_score = Column(Integer, nullable=False)
    predicted_away_score = Column(Integer, nullable=False)
    points_awarded = Column(Integer, default=0)

    user = relationship("User", back_populates="predictions")
    match = relationship("Match", back_populates="predictions")


from app.feature_models import (
    MatchLiveState,
    ForecastDay, Forecast, ForecastLedger, MatchResult, PlayerProfile,
    ProviderPlayer, PlayerAlias, LineupDetail, MatchFormation, MatchHistoryJob,
)

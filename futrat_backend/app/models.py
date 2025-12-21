from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Boolean, Table
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

# --- Таблицы связей для "Избранного" (Many-to-Many) ---

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

# --- Основные Сущности ---

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Связи для Избранного
    favorite_teams = relationship("Team", secondary=user_teams_association, back_populates="favorited_by")
    favorite_players = relationship("Player", secondary=user_players_association, back_populates="favorited_by")
    favorite_tournaments = relationship("Tournament", secondary=user_tournaments_association, back_populates="favorited_by")
    
    # Прогнозы пользователя
    predictions = relationship("Prediction", back_populates="user")

class Tournament(Base):
    __tablename__ = "tournaments"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    country = Column(String, nullable=True) # Например "International" или "England"
    type = Column(String, nullable=False)   # "League", "Cup"
    current_season = Column(String, nullable=False) # "2024/2025"

    matches = relationship("Match", back_populates="tournament")
    favorited_by = relationship("User", secondary=user_tournaments_association, back_populates="favorite_tournaments")

class Team(Base):
    __tablename__ = "teams"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    logo_url = Column(String, nullable=True)
    country = Column(String, nullable=True)
    coach_name = Column(String, nullable=True)

    players = relationship("Player", back_populates="team")
    
    # Для матчей (Home/Away)
    home_matches = relationship("Match", foreign_keys="[Match.home_team_id]", back_populates="home_team")
    away_matches = relationship("Match", foreign_keys="[Match.away_team_id]", back_populates="away_team")
    
    favorited_by = relationship("User", secondary=user_teams_association, back_populates="favorite_teams")

class Player(Base):
    __tablename__ = "players"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    position = Column(String, nullable=True) # GK, DEF, MID, FWD
    nationality = Column(String, nullable=True)
    team_id = Column(Integer, ForeignKey("teams.id"))
    
    # Статистика (упрощенно храним тут, в идеале - отдельная таблица по сезонам)
    goals = Column(Integer, default=0)
    assists = Column(Integer, default=0)
    minutes_played = Column(Integer, default=0)

    team = relationship("Team", back_populates="players")
    favorited_by = relationship("User", secondary=user_players_association, back_populates="favorite_players")

class Match(Base):
    __tablename__ = "matches"

    id = Column(Integer, primary_key=True, index=True)
    date_time = Column(DateTime(timezone=True), nullable=False)
    tournament_id = Column(Integer, ForeignKey("tournaments.id"))
    home_team_id = Column(Integer, ForeignKey("teams.id"))
    away_team_id = Column(Integer, ForeignKey("teams.id"))
    
    score_home = Column(Integer, nullable=True)
    score_away = Column(Integer, nullable=True)
    status = Column(String, default="SCHEDULED") # SCHEDULED, LIVE, FINISHED
    
    tournament = relationship("Tournament", back_populates="matches")
    home_team = relationship("Team", foreign_keys=[home_team_id], back_populates="home_matches")
    away_team = relationship("Team", foreign_keys=[away_team_id], back_populates="away_matches")
    predictions = relationship("Prediction", back_populates="match")

class Prediction(Base):
    __tablename__ = "predictions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    match_id = Column(Integer, ForeignKey("matches.id"))
    
    predicted_home_score = Column(Integer, nullable=False)
    predicted_away_score = Column(Integer, nullable=False)
    points_awarded = Column(Integer, default=0) # Очки за прогноз (начисляются после матча)

    user = relationship("User", back_populates="predictions")
    match = relationship("Match", back_populates="predictions")
"""Additive tables; legacy predictions, players and user references remain intact."""

from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Date, Boolean, Float, UniqueConstraint, CheckConstraint
from sqlalchemy.orm import relationship
from app.database import Base


class MatchLiveState(Base):
    __tablename__ = "match_live_states"
    match_id = Column(Integer, ForeignKey("matches.id"), primary_key=True)
    clock = Column(String, nullable=True)
    phase = Column(String, nullable=True)
    source = Column(String, nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)


class ForecastDay(Base):
    __tablename__ = "forecast_days"
    __table_args__ = (CheckConstraint("used >= 0 AND used <= 10"),)
    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    day = Column(Date, primary_key=True)
    used = Column(Integer, nullable=False, default=0)


class Forecast(Base):
    __tablename__ = "forecasts"
    __table_args__ = (UniqueConstraint("user_id", "match_id"),
                      CheckConstraint("outcome IN ('HOME', 'DRAW', 'AWAY')"))
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    match_id = Column(Integer, ForeignKey("matches.id"), nullable=False, index=True)
    quota_day = Column(Date, nullable=False, index=True)
    outcome = Column(String, nullable=False)
    status = Column(String, nullable=False, default="OPEN")
    points = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime(timezone=True), nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)
    settled_at = Column(DateTime(timezone=True), nullable=True)
    legacy_id = Column(Integer, ForeignKey("predictions.id"), nullable=True)
    user = relationship("User")
    match = relationship("Match")


class ForecastLedger(Base):
    __tablename__ = "forecast_ledger"
    id = Column(Integer, primary_key=True)
    forecast_id = Column(Integer, ForeignKey("forecasts.id"), nullable=False, index=True)
    delta = Column(Integer, nullable=False)
    reason = Column(String, nullable=False)
    recorded_at = Column(DateTime(timezone=True), nullable=False)


class MatchResult(Base):
    __tablename__ = "match_results"
    match_id = Column(Integer, ForeignKey("matches.id"), primary_key=True)
    regular_home = Column(Integer, nullable=True)
    regular_away = Column(Integer, nullable=True)
    kind = Column(String, nullable=False, default="UNKNOWN")
    source = Column(String, nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)


class PlayerProfile(Base):
    __tablename__ = "player_profiles"
    player_id = Column(Integer, ForeignKey("players.id"), primary_key=True)
    photo_url = Column(String, nullable=True)
    photo_source = Column(String, nullable=True)
    birth_date = Column(Date, nullable=True)
    photo_checked_at = Column(DateTime(timezone=True), nullable=True)


class ProviderPlayer(Base):
    __tablename__ = "provider_players"
    provider = Column(String, primary_key=True)
    external_id = Column(String, primary_key=True)
    player_id = Column(Integer, ForeignKey("players.id"), nullable=False, index=True)


class PlayerAlias(Base):
    __tablename__ = "player_aliases"
    alias_id = Column(Integer, ForeignKey("players.id"), primary_key=True)
    player_id = Column(Integer, ForeignKey("players.id"), nullable=False, index=True)


class LineupDetail(Base):
    __tablename__ = "lineup_details"
    lineup_id = Column(Integer, ForeignKey("match_lineups.id"), primary_key=True)
    player_id = Column(Integer, ForeignKey("players.id"), nullable=False, index=True)
    slot = Column(Integer, nullable=True)
    appeared = Column(Boolean, nullable=True)
    minutes = Column(Integer, nullable=True)
    goals = Column(Integer, nullable=True)
    assists = Column(Integer, nullable=True)
    source_rating = Column(Float, nullable=True)
    rating_source = Column(String, nullable=True)
    source = Column(String, nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)


class MatchFormation(Base):
    __tablename__ = "match_formations"
    match_id = Column(Integer, ForeignKey("matches.id"), primary_key=True)
    team_id = Column(Integer, ForeignKey("teams.id"), primary_key=True)
    formation = Column(String, nullable=False)
    source = Column(String, nullable=False)


class MatchHistoryJob(Base):
    __tablename__ = "match_history_jobs"
    match_id = Column(Integer, ForeignKey("matches.id"), primary_key=True)
    status = Column(String, nullable=False, default="QUEUED")
    attempts = Column(Integer, nullable=False, default=0)
    next_attempt = Column(DateTime(timezone=True), nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=False)

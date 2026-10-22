from datetime import datetime, timezone

from sqlalchemy import and_, or_

from app import models

ACTIVE_SEASON = 2026
NATIONAL_CODES = frozenset({
    "uefa.nations", "uefa.euro", "uefa.euroq", "caf.nations", "fifa.world", "fifa.friendly",
})


def current_matches(db, tournament_id=None):
    """Show 2026/27 clubs, calendar-year MLS and current national editions.

    Old rows remain available by ID for predictions, ratings and match details.
    Source bounds also exclude archived editions within the same date window.
    """
    state = models.TournamentSyncState
    query = db.query(models.Match).join(
        models.Tournament, models.Match.tournament_id == models.Tournament.id
    ).filter(models.Tournament.type.notin_(["PendingDraw", "PendingSchedule"])).outerjoin(
        state, models.Match.tournament_id == state.tournament_id
    ).filter(or_(
        state.tournament_id.is_(None),
        and_(models.Match.date_time >= state.season_start,
             models.Match.date_time <= state.season_end),
    ))
    season_start = datetime(ACTIVE_SEASON, 7, 1, tzinfo=timezone.utc)
    season_end = datetime(ACTIVE_SEASON + 1, 7, 1, tzinfo=timezone.utc)
    calendar_start = datetime(ACTIVE_SEASON, 1, 1, tzinfo=timezone.utc)
    calendar_end = datetime(ACTIVE_SEASON + 1, 1, 1, tzinfo=timezone.utc)
    code = models.Tournament.api_code
    query = query.filter(or_(
        code.in_(NATIONAL_CODES),
        and_(code == "usa.1", models.Match.date_time >= calendar_start,
             models.Match.date_time < calendar_end),
        and_(or_(code.is_(None), ~code.in_(NATIONAL_CODES | {"usa.1"})),
             models.Match.date_time >= season_start, models.Match.date_time < season_end),
    ))
    if tournament_id is not None:
        query = query.filter(models.Match.tournament_id == tournament_id)
    return query

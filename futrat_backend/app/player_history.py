"""Resumable, bounded lineup/photo enrichment. HTTP never runs in the profile GET."""

from datetime import timedelta
from datetime import datetime, timezone
import logging
from threading import Lock

import requests
from sqlalchemy import or_, select

from app import database, models, lineups, match_sync

logger=logging.getLogger(__name__)
_worker_lock=Lock()
NATIONAL_CODES={"uefa.nations","uefa.euro","uefa.euroq","caf.nations","fifa.world","fifa.friendly"}


def queue_player(db,player,season=None,*,requested=True):
    from app.routers.profiles import season_year,calendar_team
    calendar=calendar_team(db,player.team_id)
    season=season or (match_sync.utc_now().year if calendar else season_year())
    if not db.get(models.PlayerProfile,player.id):
        db.add(models.PlayerProfile(player_id=player.id));db.flush()
    if requested:
        marker=db.get(models.ProviderCache,f"player-request:{player.id}")
        if marker is None:
            marker=models.ProviderCache(key=f"player-request:{player.id}")
            db.add(marker)
        marker.payload={"player_id":player.id}
        marker.expires_at=match_sync.utc_now()+timedelta(days=1)
    team_ids={player.team_id}|{team_id for team_id, in db.query(models.MatchLineup.team_id).join(
        models.LineupDetail,models.LineupDetail.lineup_id==models.MatchLineup.id).filter(models.LineupDetail.player_id==player.id)}
    discovery=db.get(models.ProviderCache,f"player-teams:{player.id}")
    if discovery:
        team_ids.update(discovery.payload.get("team_ids",[]))
        team_ids.add(discovery.payload.get("current_club_id"))
    now=match_sync.utc_now()
    for team_id in sorted(value for value in team_ids if value is not None):
        for game in db.query(models.Match).filter(or_(models.Match.home_team_id==team_id,models.Match.away_team_id==team_id),
            models.Match.date_time>=datetime(season,1 if calendar else 7,1,tzinfo=timezone.utc),
            models.Match.date_time<datetime(season+1,1 if calendar else 7,1,tzinfo=timezone.utc),models.Match.status=="FINISHED"):
            job=db.get(models.MatchHistoryJob,game.id)
            if not job:
                db.add(models.MatchHistoryJob(match_id=game.id,status="QUEUED",next_attempt=now,updated_at=now))
                db.flush()
            elif job.status=="DONE" and not game.is_detailed:
                job.status,job.next_attempt="QUEUED",now


def _discover_national_teams(db,player):
    key=f"player-teams:{player.id}"
    cached=db.get(models.ProviderCache,key)
    now=match_sync.utc_now()
    if cached and match_sync.utc(cached.expires_at)>now:return
    source=db.query(models.ProviderPlayer).filter_by(provider="espn",player_id=player.id).first()
    if not source:return
    response=requests.get(f"https://site.web.api.espn.com/apis/common/v3/sports/soccer/all/athletes/{source.external_id}/gamelog",timeout=15)
    if response.status_code!=200:return
    filters=[item for item in response.json().get("filters",[]) if item.get("name")=="team"]
    options=[option for item in filters for option in item.get("options",[])]
    current_value=str(filters[0].get("value")) if filters else None
    national_ids=set()
    games=db.query(models.Match).join(models.Tournament).filter(models.Tournament.api_code.in_(NATIONAL_CODES))
    for game in games:national_ids.update((game.home_team_id,game.away_team_id))
    teams=[]
    current_club=None
    for option in options:
        if str(option.get("value"))==current_value:
            club=db.query(models.Team).filter_by(name=option.get("displayValue")).all()
            if len(club)==1 and club[0].id not in national_ids:current_club=club[0].id
        matches=db.query(models.Team).filter(models.Team.id.in_(national_ids),models.Team.name==option.get("displayValue")).all()
        if len(matches)==1:teams.append(matches[0].id)
    if cached is None:
        cached=models.ProviderCache(key=key)
        db.add(cached)
    cached.payload={"team_ids":sorted(set(teams)),"current_club_id":current_club}
    cached.expires_at=now+timedelta(days=1)


def _photo(db,profile):
    now=match_sync.utc_now()
    if profile.photo_url or (profile.photo_checked_at and now-match_sync.utc(profile.photo_checked_at)<timedelta(days=30)):
        return
    player=db.get(models.Player,profile.player_id)
    response=requests.get("https://www.thesportsdb.com/api/v1/json/123/searchplayers.php",params={"p":player.name},timeout=12)
    if response.status_code!=200:return
    profile.photo_checked_at=now
    candidates=[row for row in (response.json().get("player") or []) if str(row.get("strPlayer","")).casefold()==player.name.casefold()]
    team=db.get(models.Team,player.team_id) if player.team_id else None
    # Exact identity plus DOB or current team, rather than the first name search hit.
    verified=[row for row in candidates if (profile.birth_date and str(profile.birth_date)==row.get("dateBorn")) or
        (team and team.name.casefold()==str(row.get("strTeam","")).casefold())]
    if len(verified)!=1:return
    url=lineups.safe_photo(verified[0].get("strCutout") or verified[0].get("strThumb"))
    if url:profile.photo_url,profile.photo_source=url,"TheSportsDB"


def update_player_data():
    if not _worker_lock.acquire(blocking=False):return
    try:
        with database.SessionLocal() as db:
            # A separate lock prevents duplicate network work across API workers.
            from sqlalchemy import text
            connection=db.get_bind().connect()
            postgres=connection.dialect.name=="postgresql"
            acquired=not postgres or connection.execute(text("SELECT pg_try_advisory_lock(728613412)")).scalar()
            connection.commit()
            try:
                if not acquired:return
                requested={row.payload["player_id"] for row in db.query(models.ProviderCache).filter(
                    models.ProviderCache.key.like("player-request:%"),models.ProviderCache.expires_at>match_sync.utc_now())}
                favorite_ids=sorted(requested|set(db.scalars(select(models.user_players_association.c.player_id).distinct())))
                for player_id in favorite_ids:
                    if match_sync._stop_event.is_set():return
                    player=db.get(models.Player,lineups.canonical_id(db,player_id))
                    if not player:continue
                    try:
                        _discover_national_teams(db,player)
                        queue_player(db,player,requested=False)
                        db.commit()
                    except Exception:
                        db.rollback()
                        logger.warning("Player %s team discovery delayed",player_id)
                now=match_sync.utc_now()
                # Resolve 90-minute results for selected games that ended after ET.
                for game in db.query(models.Match).join(models.Forecast).filter(
                    models.Match.status=="FINISHED",models.Forecast.status=="PENDING").distinct():
                    if not db.get(models.MatchHistoryJob,game.id):
                        db.add(models.MatchHistoryJob(match_id=game.id,status="QUEUED",next_attempt=now,updated_at=now))
                # Recheck recently settled ET games as well as pending ones.
                recent=db.query(models.MatchHistoryJob).join(models.MatchResult,models.MatchResult.match_id==models.MatchHistoryJob.match_id).join(
                    models.Forecast,models.Forecast.match_id==models.MatchHistoryJob.match_id).filter(
                    models.MatchResult.kind.in_(["EXTRA_TIME","PENALTIES"]),models.Forecast.quota_day>=(now-timedelta(days=2)).date(),
                    models.MatchHistoryJob.status=="DONE",models.MatchHistoryJob.updated_at<now-timedelta(hours=12)).distinct()
                for job in recent:job.status,job.next_attempt="QUEUED",now
                db.commit()
                selected=db.query(models.Forecast.id).filter(models.Forecast.match_id==models.MatchHistoryJob.match_id).exists()
                ids=[row.match_id for row in db.query(models.MatchHistoryJob).filter(
                    models.MatchHistoryJob.status!="DONE",models.MatchHistoryJob.next_attempt<=now
                ).order_by(selected.desc(),models.MatchHistoryJob.next_attempt,models.MatchHistoryJob.match_id).limit(8)]
                from app.routers.data import get_match_details
                for match_id in ids:
                    if match_sync._stop_event.is_set():return
                    try:
                        game=db.get(models.Match,match_id)
                        game.is_detailed=False
                        db.commit()
                        get_match_details(match_id,db)
                        db.expire_all()
                        job=db.get(models.MatchHistoryJob,match_id)
                        has_details=db.query(models.LineupDetail).join(models.MatchLineup).filter(models.MatchLineup.match_id==match_id,
                            models.LineupDetail.updated_at>=now).first() is not None
                        job.status="DONE" if has_details else "EMPTY"
                        if db.query(models.Forecast).filter_by(match_id=match_id,status="PENDING").first():
                            job.status="PENDING_RESULT"
                        job.attempts+=1;job.updated_at=now;job.next_attempt=now+timedelta(hours=12)
                        db.commit()
                    except Exception:
                        db.rollback()
                        job=db.get(models.MatchHistoryJob,match_id)
                        job.status="FAILED";job.attempts+=1;job.updated_at=now
                        job.next_attempt=now+timedelta(minutes=min(360,5*2**min(job.attempts,6)))
                        db.commit()
                        logger.warning("Lineup enrichment deferred for match %s",match_id)
                # At most eight photo requests per minute, under the free 30/min cap.
                profiles=db.query(models.PlayerProfile).filter(models.PlayerProfile.photo_url.is_(None),or_(
                    models.PlayerProfile.photo_checked_at.is_(None),models.PlayerProfile.photo_checked_at<now-timedelta(days=30)
                )).order_by(models.PlayerProfile.player_id).limit(8).all()
                for profile in profiles:
                    if match_sync._stop_event.is_set():return
                    try:
                        _photo(db,profile);db.commit()
                    except Exception:
                        db.rollback()
                        logger.warning("Player photo enrichment delayed")
            finally:
                if postgres and acquired:
                    connection.execute(text("SELECT pg_advisory_unlock(728613412)"));connection.commit()
                connection.close()
    finally:
        _worker_lock.release()

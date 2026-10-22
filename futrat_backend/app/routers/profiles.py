"""Public season timelines; cursor pagination keeps the latest result anchored."""

from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import or_, tuple_, func
from sqlalchemy.orm import Session, selectinload

from app import database, models, schemas, lineups
from app.match_sync import utc, utc_now
from app.seasons import ACTIVE_SEASON, NATIONAL_CODES, current_matches

router=APIRouter(prefix="/api",tags=["Profiles"])


def season_year(now=None):
    now=now or utc_now()
    return now.year if now.month >= 7 else now.year-1


def calendar_team(db,team_id):
    codes={code for code, in db.query(models.Tournament.api_code).join(models.Match,models.Match.tournament_id==models.Tournament.id).filter(
        or_(models.Match.home_team_id==team_id,models.Match.away_team_id==team_id)).distinct()}
    return "usa.1" in codes


def team_query(db,team_id,season):
    if season == ACTIVE_SEASON:
        return current_matches(db).filter(or_(models.Match.home_team_id==team_id,
                                              models.Match.away_team_id==team_id))
    calendar=calendar_team(db,team_id)
    start=datetime(season,1 if calendar else 7,1,tzinfo=timezone.utc)
    end=datetime(season+1,1 if calendar else 7,1,tzinfo=timezone.utc)
    return db.query(models.Match).filter(or_(models.Match.home_team_id==team_id,models.Match.away_team_id==team_id),
        models.Match.date_time>=start,models.Match.date_time<end)


def matches_json(query):
    rows=query.options(selectinload(models.Match.home_team),selectinload(models.Match.away_team),
        selectinload(models.Match.tournament),selectinload(models.Match.events),selectinload(models.Match.lineups)).all()
    return [schemas.MatchResponse.model_validate(row).model_dump(mode="json") for row in rows]


@router.get("/teams/{team_id}/matches")
def team_matches(team_id:int,season:int|None=Query(default=None,ge=1900,le=2200),
                 cursor:int|None=None,direction:str=Query(default="past",pattern="^(past|future)$"),
                 limit:int=Query(default=20,ge=1,le=100),db:Session=Depends(database.get_db)):
    team=db.get(models.Team,team_id)
    if team is None:raise HTTPException(404,"Команда не найдена")
    calendar=calendar_team(db,team_id)
    current=ACTIVE_SEASON
    season=season or current
    query=team_query(db,team_id,season)
    if cursor is not None:
        anchor=query.filter(models.Match.id==cursor).first()
        if not anchor:raise HTTPException(422,"Матч не принадлежит выбранной команде и сезону")
        key=tuple_(models.Match.date_time,models.Match.id)
        reference=tuple_(anchor.date_time,anchor.id)
        query=query.filter(key<reference) if direction=="past" else query.filter(key>reference)
        order=(models.Match.date_time.desc(),models.Match.id.desc()) if direction=="past" else (models.Match.date_time,models.Match.id)
        rows=matches_json(query.order_by(*order).limit(limit+1))
        return {"matches":rows[:limit],"more":len(rows)>limit}
    anchor=query.filter(models.Match.status=="FINISHED").order_by(models.Match.date_time.desc(),models.Match.id.desc()).first()
    if anchor is None:
        anchor=query.order_by(models.Match.date_time,models.Match.id).first()
    past,future=[],[]
    if anchor:
        key=tuple_(models.Match.date_time,models.Match.id)
        ref=tuple_(anchor.date_time,anchor.id)
        past=matches_json(query.filter(key<ref).order_by(models.Match.date_time.desc(),models.Match.id.desc()).limit(limit+1))
        future=matches_json(query.filter(key>ref).order_by(models.Match.date_time,models.Match.id).limit(limit+1))
    return {"team":schemas.TeamResponse.model_validate(team),"season":season,"calendar_season":calendar,
        "seasons":[ACTIVE_SEASON],
        "anchor":schemas.MatchResponse.model_validate(anchor) if anchor else None,
        "past":past[:limit],"future":future[:limit],"more_past":len(past)>limit,"more_future":len(future)>limit}


def profile(db,player_id):
    player_id=lineups.canonical_id(db,player_id)
    player=db.get(models.Player,player_id)
    if player is None:raise HTTPException(404,"Игрок не найден")
    return player


@router.get("/players/{player_id}")
def player_profile(player_id:int,db:Session=Depends(database.get_db)):
    player=profile(db,player_id)
    image=db.get(models.PlayerProfile,player.id)
    data=schemas.PlayerResponse.model_validate(player).model_dump()
    data.update(photo_url=image.photo_url if image else None,photo_source=image.photo_source if image else None)
    return data


@router.get("/players/{player_id}/matches")
def player_matches(player_id:int,season:int|None=Query(default=None,ge=1900,le=2200),
                   offset:int=Query(default=0,ge=0),limit:int=Query(default=30,ge=1,le=100),
                   kind:str=Query(default="all",pattern="^(all|club|national)$"),
                   db:Session=Depends(database.get_db)):
    player=profile(db,player_id)
    calendar=calendar_team(db,player.team_id)
    season=season or ACTIVE_SEASON
    from app.player_history import queue_player
    queue_player(db,player,season)
    db.commit()
    start,end=datetime(season,1 if calendar else 7,1,tzinfo=timezone.utc),datetime(season+1,1 if calendar else 7,1,tzinfo=timezone.utc)
    season_filter = (models.Match.id.in_(current_matches(db).with_entities(models.Match.id))
                     if season == ACTIVE_SEASON else
                     (models.Match.date_time>=start) & (models.Match.date_time<end))
    query=db.query(models.LineupDetail,models.MatchLineup,models.Match).join(
        models.MatchLineup,models.MatchLineup.id==models.LineupDetail.lineup_id).join(
        models.Match,models.Match.id==models.MatchLineup.match_id).filter(
        models.LineupDetail.player_id==player.id,models.LineupDetail.appeared.is_(True),
        season_filter)
    national_codes=NATIONAL_CODES
    query=query.join(models.Tournament,models.Tournament.id==models.Match.tournament_id)
    if kind!="all":
        query=query.filter(models.Tournament.api_code.in_(national_codes) if kind=="national" else or_(models.Tournament.api_code.is_(None),~models.Tournament.api_code.in_(national_codes)))
    total=query.count()
    rows=query.order_by(models.Match.date_time.desc(),models.Match.id.desc()).offset(offset).limit(limit).all()
    image=db.get(models.PlayerProfile,player.id)
    items=[]
    for detail,entry,game in rows:
        avg,count=db.query(func.avg(models.UserPlayerRating.rating),func.count()).filter_by(lineup_id=entry.id).one()
        items.append({"match":schemas.MatchResponse.model_validate(game).model_dump(mode="json"),
            "team_id":entry.team_id,"photo_url":image.photo_url if image else None,
            "team_kind":"national" if game.tournament.api_code in national_codes else "club",
            **{key:getattr(detail,key) for key in ["minutes","goals","assists","source_rating","rating_source"]},
            "user_rating":round(avg,1) if avg is not None else None,"rating_count":count})
    # A source may have no lineup even after the match: expose this explicitly.
    team_ids={player.team_id}|{team_id for team_id, in db.query(models.MatchLineup.team_id).join(
        models.LineupDetail,models.LineupDetail.lineup_id==models.MatchLineup.id).filter(models.LineupDetail.player_id==player.id)}
    discovery=db.get(models.ProviderCache,f"player-teams:{player.id}")
    if discovery:
        team_ids.update(discovery.payload.get("team_ids",[]))
        if discovery.payload.get("current_club_id"):team_ids.add(discovery.payload["current_club_id"])
    candidates=db.query(models.Match).filter(or_(models.Match.home_team_id.in_(team_ids),models.Match.away_team_id.in_(team_ids)),
        season_filter,models.Match.status=="FINISHED").count()
    completed=db.query(models.MatchHistoryJob).join(models.Match,models.Match.id==models.MatchHistoryJob.match_id).filter(
        or_(models.Match.home_team_id.in_(team_ids),models.Match.away_team_id.in_(team_ids)),
        season_filter,models.MatchHistoryJob.status=="DONE").count()
    future_ids={player.team_id}
    if discovery:
        future_ids=set(discovery.payload.get("team_ids",[]))|{discovery.payload.get("current_club_id") or player.team_id}
    future=db.query(models.Match).filter(or_(models.Match.home_team_id.in_(future_ids),models.Match.away_team_id.in_(future_ids)),
        models.Match.status=="SCHEDULED",models.Match.date_time>=utc_now(),season_filter
    ).order_by(models.Match.date_time,models.Match.id).limit(10)
    upcoming=matches_json(future)
    return {"player_id":player.id,"season":season,"calendar_season":calendar,"matches":items,"upcoming":upcoming,"total":total,
        "more":offset+len(items)<total,"coverage":{"status":"ready" if candidates and completed>=candidates else "partial",
        "checked":completed,"candidates":candidates}}

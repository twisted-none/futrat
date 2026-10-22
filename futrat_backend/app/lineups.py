"""Stable player identity and match-specific lineup data, shared by providers."""

import re
from urllib.parse import urlparse
from sqlalchemy import func

from app import models
from app.match_sync import utc_now


def safe_photo(url):
    if not isinstance(url, str):
        return None
    parsed = urlparse(url)
    allowed = {"a.espncdn.com", "media.goal-api.com", "apiv3.apifootball.com", "r2.thesportsdb.com", "www.thesportsdb.com"}
    return url if parsed.scheme == "https" and parsed.hostname in allowed else None


def canonical_id(db, player_id):
    visited=set()
    while player_id not in visited:
        visited.add(player_id)
        alias=db.get(models.PlayerAlias,player_id)
        if alias is None:return player_id
        player_id=alias.player_id
    raise ValueError("Cyclic player identity mapping")


def bind_player(db, provider, external_id, name, team_id, photo=None):
    mapping = db.get(models.ProviderPlayer, (provider, str(external_id))) if external_id else None
    local = db.query(models.Player).filter_by(name=name, team_id=team_id).order_by(models.Player.id).first()
    if mapping:
        player = db.get(models.Player, canonical_id(db, mapping.player_id))
        if local and local.id != player.id and not db.get(models.PlayerAlias, local.id):
            db.add(models.PlayerAlias(alias_id=local.id, player_id=player.id))
    else:
        player = local or models.Player(name=name, team_id=team_id)
        db.add(player)
        db.flush()
        player = db.get(models.Player, canonical_id(db, player.id))
        if external_id:
            db.add(models.ProviderPlayer(provider=provider, external_id=str(external_id), player_id=player.id))
    profile = db.get(models.PlayerProfile, player.id)
    if not profile:
        profile = models.PlayerProfile(player_id=player.id)
        db.add(profile)
    if safe_photo(photo):
        profile.photo_url, profile.photo_source = photo, provider.upper()
    db.flush()
    return player


def formation(db, game, team_id, value, source):
    if not isinstance(value, str) or not re.fullmatch(r"\d(?:-\d){1,4}", value):
        return
    if sum(map(int, value.split("-"))) != 10:
        return
    row = db.get(models.MatchFormation, (game.id, team_id))
    if row is None:
        row = models.MatchFormation(match_id=game.id, team_id=team_id)
        db.add(row)
    row.formation, row.source = value, source


def number(value):
    try:
        return int(float(value)) if value not in (None, "", "N/A", "-") else None
    except (ValueError, TypeError):
        return None


def attach(db, game, team_id, player, name, *, starter, jersey=None, position=None,
           slot=None, appeared=None, minutes=None, goals=None, assists=None,
           rating=None, source):
    row = db.query(models.MatchLineup).filter_by(match_id=game.id, team_id=team_id, player_name=name).first()
    if row is None:
        row = db.query(models.MatchLineup).join(models.LineupDetail,
            models.LineupDetail.lineup_id == models.MatchLineup.id).filter(
                models.MatchLineup.match_id == game.id, models.MatchLineup.team_id == team_id,
                models.LineupDetail.player_id == player.id).first()
    if row is None:
        row = models.MatchLineup(match_id=game.id, team_id=team_id, player_name=name)
        db.add(row)
    row.player_name, row.is_starter = name, starter
    row.jersey_number, row.position = str(jersey) if jersey is not None else None, position
    db.flush()
    detail = db.get(models.LineupDetail, row.id)
    if not detail:
        detail = models.LineupDetail(lineup_id=row.id)
        db.add(detail)
    detail.player_id, detail.source, detail.updated_at = player.id, source, utc_now()
    parsed_slot = number(slot)
    detail.slot = parsed_slot if starter and parsed_slot and 1 <= parsed_slot <= 11 else None
    detail.appeared, detail.minutes = appeared, number(minutes)
    detail.goals, detail.assists = number(goals), number(assists)
    # Only callers working inside a fixture-statistics response may supply rating.
    try:
        parsed_rating = float(rating) if rating not in (None, "", "N/A", "-") else None
    except (ValueError, TypeError):
        parsed_rating = None
    detail.source_rating = parsed_rating if parsed_rating is not None and 0 <= parsed_rating <= 10 else None
    detail.rating_source = source if detail.source_rating is not None else None
    db.flush()
    return row


def enrich_espn(db, game, data, *, home_external_id=None):
    for roster in data.get("rosters", []):
        home = roster.get("homeAway") == "home" or str((roster.get("team") or {}).get("id")) == str(home_external_id)
        team_id = game.home_team_id if home else game.away_team_id
        formation(db, game, team_id, roster.get("formation"), "ESPN")
        for row in roster.get("roster", []):
            athlete = row.get("athlete") or {}
            name = athlete.get("displayName") or athlete.get("fullName")
            if not name:
                continue
            player = bind_player(db, "espn", athlete.get("id"), name, team_id,
                                 (athlete.get("headshot") or {}).get("href"))
            stats = {s.get("name"):s.get("value") for s in row.get("stats", [])}
            appearance = number(stats.get("appearances"))
            starter = bool(row.get("starter"))
            appeared = (appearance > 0) if appearance is not None else (
                True if game.status == "FINISHED" and starter else None)
            attach(db, game, team_id, player, name, starter=starter,
                jersey=row.get("jersey") or athlete.get("jersey"), position=(row.get("position") or {}).get("name"),
                slot=row.get("formationPlace"), appeared=appeared, minutes=stats.get("minutesPlayed"),
                goals=stats.get("totalGoals"), assists=stats.get("goalAssists"), source="ESPN")
    from app.forecasts import observe_espn,regular_from_timeline
    competition=(data.get("header") or {}).get("competitions") or [{}]
    if competition[0].get("status"):
        observe_espn(db,game,competition[0]["status"])
    goals=[]
    for event in data.get("keyEvents",[]):
        if not event.get("scoringPlay"):continue
        text=str((event.get("type") or {}).get("text","")).casefold()
        if "own" in text:return
        period=(event.get("period") or {}).get("number")
        if period is None:return
        if period>=5:continue
        external=(event.get("team") or {}).get("id")
        if not external:return
        goals.append((0 if str(external)==str(home_external_id) else 1,period<=2))
    regular_from_timeline(db,game,goals,"ESPN timeline")


def enrich_goal(db, game, data, statistics, events):
    per_player = statistics.get("players") or {}
    for side, team_id in (("home", game.home_team_id), ("away", game.away_team_id)):
        formation(db, game, team_id, data.get(side+"Formation"), "GOAL")
        stats_by_id = {str(row.get("playerId")):row for row in per_player.get(side, []) if row.get("playerId")}
        for key, starter in (("startingLineups",True), ("substitutes",False)):
            for row in (data.get(side) or {}).get(key, []):
                name = row.get("lineupPlayer")
                if not name:
                    continue
                player = bind_player(db,"goal",row.get("playerId"),name,team_id,row.get("playerImage"))
                stats = stats_by_id.get(str(row.get("playerId")), {})
                minutes = number(stats.get("minutes"))
                appeared = minutes > 0 if minutes is not None else (True if starter and game.status == "FINISHED" else None)
                attach(db,game,team_id,player,name,starter=starter,jersey=row.get("lineupNumber"),
                    position=row.get("playerPosition"),slot=row.get("lineupPosition"),appeared=appeared,
                    minutes=minutes,goals=stats.get("goals"),assists=stats.get("assists"),rating=stats.get("rating"),source="GOAL")
    goals=[]
    scoring=[]
    for event in events:
        if str(event.get("type","")).casefold()!="goal":continue
        if "own" in str(event.get("info","")).casefold():return
        minute=re.match(r"\d+",str(event.get("time") or ""))
        if not minute:return
        side=0 if event.get("homeScorer") else 1 if event.get("awayScorer") else None
        goals.append((side,int(minute.group())<=90))
        scoring.append((side,event))
    totals=[sum(side==value for side,event in scoring) for value in (0,1)]
    if game.status=="FINISHED" and totals==[game.score_home,game.score_away] and all(side in (0,1) for side,event in scoring):
        for detail,entry in db.query(models.LineupDetail,models.MatchLineup).join(
            models.MatchLineup,models.MatchLineup.id==models.LineupDetail.lineup_id).filter(models.MatchLineup.match_id==game.id):
            side=0 if entry.team_id==game.home_team_id else 1
            prefix="home" if side==0 else "away"
            if detail.goals is None:
                detail.goals=sum(s==side and event.get(prefix+"Scorer")==entry.player_name for s,event in scoring)
            assists=sum(s==side and event.get(prefix+"Assist")==entry.player_name for s,event in scoring)
            if assists and detail.assists is None:detail.assists=assists
    from app.forecasts import regular_from_timeline
    regular_from_timeline(db,game,goals,"GOAL timeline")


def decorate(db, game):
    rows = {row.lineup_id:row for row in db.query(models.LineupDetail).join(
        models.MatchLineup, models.MatchLineup.id == models.LineupDetail.lineup_id).filter(models.MatchLineup.match_id==game.id)}
    profiles = {row.player_id:row for row in db.query(models.PlayerProfile).filter(
        models.PlayerProfile.player_id.in_([row.player_id for row in rows.values()]))}
    ratings = {lineup_id:(average,count) for lineup_id,average,count in db.query(
        models.UserPlayerRating.lineup_id,func.avg(models.UserPlayerRating.rating),func.count()).join(
        models.MatchLineup,models.MatchLineup.id==models.UserPlayerRating.lineup_id).filter(
        models.MatchLineup.match_id==game.id).group_by(models.UserPlayerRating.lineup_id)}
    for entry in game.lineups:
        detail = rows.get(entry.id)
        if detail:
            entry.player_id = detail.player_id
            for key in ("slot","appeared","minutes","goals","assists","source_rating","rating_source"):
                setattr(entry,key,getattr(detail,key))
            profile=profiles.get(detail.player_id)
            entry.photo_url=profile.photo_url if profile else None
        avg,count=ratings.get(entry.id,(None,0))
        entry.rating=f"{avg:.1f}" if avg is not None else "-"
        entry.rating_count=count
    game.formations={str(row.team_id):row.formation for row in db.query(models.MatchFormation).filter_by(match_id=game.id)}
    return game

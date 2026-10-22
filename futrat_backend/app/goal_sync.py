"""GOAL adapter. Upserts bind external IDs to existing local rows, never replace them."""

from datetime import datetime, timedelta, timezone
import logging
import re
import unicodedata
from urllib.parse import quote
from sqlalchemy import text

from app import models, match_sync
from app.competitions import GOAL_COMPETITIONS
from app.goal_api import GoalClient, GoalError

logger = logging.getLogger(__name__)

# Only explicit aliases: fuzzy merging can attach ratings to a different club.
ALIASES = {
    "zenit st petersburg": "zenit", "zenit saint petersburg": "zenit",
    "dinamo moscow": "dynamo moscow", "dinamo moskva": "dynamo moscow",
    "spartak moskva": "spartak moscow", "lokomotiv moskva": "lokomotiv moscow",
    "cska moskva": "cska moscow", "rubin kazan": "rubin",
    "rostov na donu": "rostov", "akhmat grozny": "akhmat",
    "krylya sovetov samara": "krylya sovetov", "paris nn": "nizhny novgorod",
    "paris nizhny novgorod": "nizhny novgorod", "real betis balompie": "real betis",
    "atletico de madrid": "atletico madrid", "athletic club": "athletic bilbao",
}


def team_key(name):
    value = unicodedata.normalize("NFKD", name.casefold())
    value = "".join(char for char in value if not unicodedata.combining(char))
    value = re.sub(r"[^\w]+", " ", value).strip()
    value = " ".join(word for word in value.split() if word not in {"fc", "afc", "cf", "fk"})
    return ALIASES.get(value, value)


def resolve_team(db, external_id, name, badge=None):
    mapping = db.get(models.ProviderTeam, ("goal", str(external_id)))
    if mapping:
        return db.get(models.Team, mapping.team_id)
    candidates = [team for team in db.query(models.Team) if team_key(team.name) == team_key(name)]
    if len(candidates) > 1:
        raise GoalError("Ambiguous GOAL team mapping; explicit alias required")
    team = candidates[0] if candidates else models.Team(name=name, logo_url=badge, country="Global")
    db.add(team)
    db.flush()
    db.add(models.ProviderTeam(provider="goal", external_id=str(external_id), team_id=team.id))
    db.flush()
    return team


def kickoff(row):
    value = row.get("kickoffUtc")
    if not value and row.get("matchDate") and row.get("matchTime"):
        value = f"{row['matchDate']}T{row['matchTime']}Z"
    return match_sync.utc(value) if value else None


def store_fixtures(db, tournament, fixtures, start, end, *, league_id):
    saved = 0
    for row in fixtures:
        if str(row.get("leagueId")) != str(league_id):
            continue
        date = kickoff(row)
        if date is None or not start <= date < end:
            continue
        if not all(row.get(key) for key in ("id", "homeTeamId", "awayTeamId", "homeTeamName", "awayTeamName")):
            continue  # Draw placeholders are not actual teams.
        if any(re.search(r"\b(tbd|winner|loser)\b", row[key], re.I)
               for key in ("homeTeamName", "awayTeamName")):
            continue
        raw_status = row.get("matchStatus")
        status = {"LIVE": "IN_PLAY", "HALF_TIME": "IN_PLAY", "AFTER_ET": "FINISHED",
                  "AFTER_PEN": "FINISHED", "AWARDED": "FINISHED"}.get(raw_status, raw_status)
        if status not in {"IN_PLAY", "FINISHED", "SCHEDULED", "POSTPONED", "CANCELLED", "ABANDONED", "SUSPENDED"}:
            raise GoalError("Unknown GOAL match status")
        home = resolve_team(db, row["homeTeamId"], row["homeTeamName"], row.get("homeTeamBadge"))
        away = resolve_team(db, row["awayTeamId"], row["awayTeamName"], row.get("awayTeamBadge"))
        external_id = str(row["id"])
        mapping = db.get(models.ProviderMatch, ("goal", external_id))
        match = db.get(models.Match, mapping.match_id) if mapping else None
        if match and match.tournament_id != tournament.id:
            raise GoalError("GOAL fixture belongs to another tournament")
        if match is None:
            # Adopt an ESPN row from the same competition and kickoff day.
            candidates = db.query(models.Match).filter(
                models.Match.tournament_id == tournament.id, models.Match.home_team_id == home.id,
                models.Match.away_team_id == away.id,
                models.Match.date_time >= date.replace(hour=0, minute=0, second=0, microsecond=0),
                models.Match.date_time < date.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(days=1),
            ).all()
            if len(candidates) > 1:
                raise GoalError("Ambiguous GOAL fixture mapping; existing matches kept")
            match = candidates[0] if candidates else models.Match(tournament_id=tournament.id)
            db.add(match)
            # Non-null kickoff is required even before the mapping flush.
            match.date_time = date
            db.flush()
            bound = db.query(models.ProviderMatch).filter_by(provider="goal", match_id=match.id).first()
            if bound and bound.external_id != external_id:
                raise GoalError("Two GOAL fixtures resolve to one local match")
            db.add(models.ProviderMatch(provider="goal", external_id=external_id, match_id=match.id))
        scores = [None, None]
        if status in {"FINISHED", "IN_PLAY"}:
            for index, side in enumerate(("home", "away")):
                raw = row.get(f"{side}TeamScore")
                if raw not in (None, ""):
                    if not re.fullmatch(r"\d{1,2}", str(raw)):
                        raise GoalError("Invalid GOAL score")
                    scores[index] = int(raw)
        from app.live_clock import prefer_espn, goal
        keep_live = prefer_espn(db, match)
        if not keep_live and (match.status, match.score_home, match.score_away) != (status, *scores):
            match.is_detailed = False
        match.date_time = date
        match.home_team_id, match.away_team_id = home.id, away.id
        if not keep_live:
            match.status, match.score_home, match.score_away = status, *scores
        from app.lineups import formation
        formation(db,match,home.id,row.get("homeTeamSystem"),"GOAL")
        formation(db,match,away.id,row.get("awayTeamSystem"),"GOAL")
        from app.forecasts import observe_goal
        if not keep_live:
            observe_goal(db, match, raw_status)
            if status == "IN_PLAY" or match.live_state is not None:
                goal(db, match, row)
        round_text = str(row.get("matchRound") or "")
        if round_text.isdecimal():
            match.round = int(round_text)
        db.flush()
        saved += 1
    return saved


def find_league(api, code):
    expected = GOAL_COMPETITIONS[code]
    # One shared, cached discovery for all three cups; no dependence on old numeric IDs.
    leagues = api.pages("/leagues", {"search": "Cup"}, ttl=timedelta(days=7))
    matches = [row for row in leagues
               if (row.get("countryName") or (row.get("country") or {}).get("name", "")).casefold() == expected["country"].casefold()
               and row.get("name", "").casefold() in expected["names"]]
    if len(matches) != 1:
        raise GoalError(f"GOAL league discovery for {code}: expected one match, got {len(matches)}")
    return matches[0]


def sync_goal(leagues, sessions, *, full=True, force=False):
    api = GoalClient(sessions)
    if not leagues or not api.configured:
        if leagues and full:
            logger.warning("GOAL_API_KEY is absent; cup data remains unchanged")
        return
    if not match_sync._sync_lock.acquire(blocking=False):
        return
    try:
        with sessions() as db, match_sync.database_lock(db) as acquired:
            if not acquired:
                return
            for code, name in leagues.items():
                if match_sync._stop_event.is_set():
                    break
                try:
                    tournament = db.query(models.Tournament).filter_by(api_code=code).one()
                    now = match_sync.utc_now()
                    year = now.year if now.month >= 7 else now.year - 1
                    start, end = datetime(year, 7, 1, tzinfo=timezone.utc), datetime(year + 1, 7, 1, tzinfo=timezone.utc)
                    db.commit()  # Release read transaction before quota/cache writes.
                    league = find_league(api, code)
                    lower, upper = (start, end - timedelta(days=1)) if full else (
                        max(start, now - timedelta(days=1)), min(end - timedelta(days=1), now + timedelta(days=1)))
                    fixtures = api.pages("/fixtures", {"leagueId": league["id"],
                        "from": lower.date().isoformat(), "to": upper.date().isoformat()},
                        ttl=timedelta(hours=6) if full else timedelta(minutes=10), force=force)
                    saved = store_fixtures(db, tournament, fixtures, start, end, league_id=league["id"])
                    if saved:
                        state = db.get(models.TournamentSyncState, tournament.id)
                        if not state:
                            state = models.TournamentSyncState(tournament_id=tournament.id)
                            db.add(state)
                        if full or state.season_start is None:
                            state.season_start, state.season_end = start, end - timedelta(microseconds=1)
                            state.calendar, state.completed_dates, state.source_rounds = [], [], {}
                            state.calendar_updated_at = now
                        tournament.current_season = f"{year}/{year + 1}"
                        tournament.logo_url = league.get("logo") or tournament.logo_url
                    db.commit()
                    logger.info("%s: GOAL %s fixtures saved (%s)", code, saved, "season" if full else "recent")
                except GoalError as error:
                    db.rollback()
                    logger.warning("%s: %s", code, error)
                except Exception:
                    db.rollback()
                    logger.warning("%s: GOAL import failed; existing data kept", code)
    finally:
        match_sync._sync_lock.release()


STAT_FIELDS = {
    "ball possession": "possession", "shots total": "shots", "total shots": "shots",
    "shots on goal": "shots_on_target", "shots on target": "shots_on_target", "on target": "shots_on_target",
    "corner kicks": "corners", "corners": "corners", "fouls": "fouls", "offsides": "offsides",
    "yellow cards": "yellow_cards", "red cards": "red_cards", "total passes": "passes",
    "passes %": "pass_accuracy", "pass accuracy": "pass_accuracy", "goalkeeper saves": "saves",
    "saves": "saves", "expected goals": "xg",
}


def store_details(db, match, lineups, statistics, events):
    if not isinstance(lineups, dict) or not isinstance(statistics, dict) or not isinstance(events, list):
        raise GoalError("Invalid GOAL match details")
    from app.lineups import enrich_goal
    enrich_goal(db,match,lineups,statistics,events)
    for side, team_id in (("home", match.home_team_id), ("away", match.away_team_id)):
        for key, starter in (("startingLineups", True), ("substitutes", False)):
            for row in (lineups.get(side) or {}).get(key, []):
                name = row.get("lineupPlayer")
                if not name:
                    continue
                entry = db.query(models.MatchLineup).filter_by(match_id=match.id, team_id=team_id, player_name=name).first()
                if not entry:
                    entry = models.MatchLineup(match_id=match.id, team_id=team_id, player_name=name)
                    db.add(entry)
                entry.jersey_number = row.get("lineupNumber")
                entry.position = row.get("playerPosition") or row.get("lineupPosition")
                entry.is_starter = starter
                db.flush()  # Duplicate source entries must reuse the same lineup ID.
    for row in (statistics.get("match") or {}).get("fullTime", []):
        field = STAT_FIELDS.get(str(row.get("type", "")).casefold())
        if not field:
            continue
        for side in ("home", "away"):
            raw = str(row.get(side, "")).strip().rstrip("%")
            if re.fullmatch(r"\d+(\.\d+)?", raw):
                setattr(match, f"{field}_{side}", float(raw) if field == "xg" else int(float(raw)))
    # Timeline IDs have no user references; lineup IDs do, so they are never deleted.
    db.query(models.MatchEvent).filter_by(match_id=match.id).delete(synchronize_session=False)
    for row in events:
        side = "home" if row.get("homeScorer") else "away"
        name = row.get(f"{side}Scorer")
        kind = str(row.get("type") or "").casefold()
        event_type = {"goal": "GOAL", "yellow card": "YELLOW_CARD", "red card": "RED_CARD",
                      "yellow_card": "YELLOW_CARD", "red_card": "RED_CARD"}.get(kind)
        if not name or not event_type:
            continue
        team_id = match.home_team_id if side == "home" else match.away_team_id
        player = db.query(models.Player).filter_by(team_id=team_id, name=name).first()
        if not player:
            player = models.Player(team_id=team_id, name=name)
            db.add(player)
            db.flush()

        minute = re.match(r"\d+", str(row.get("time") or "0"))
        minute = int(minute.group()) if minute else 0
        if not db.query(models.MatchEvent).filter_by(match_id=match.id, player_id=player.id, type=event_type, minute=minute).first():
            db.add(models.MatchEvent(match_id=match.id, player_id=player.id, type=event_type, minute=minute))
            db.flush()


    match.is_detailed=bool((lineups.get("home") or {}).get("startingLineups") or (lineups.get("away") or {}).get("startingLineups"))


def refresh_details(db, match, sessions):
    mapping = db.query(models.ProviderMatch).filter_by(provider="goal", match_id=match.id).first()
    if mapping is None:
        return False
    if db.get_bind().dialect.name == "postgresql" and not db.execute(
        text("SELECT pg_try_advisory_xact_lock(728613411, :match_id)"), {"match_id": match.id}
    ).scalar():
        return True
    api = GoalClient(sessions)
    if not api.configured:
        return True
    try:
        ttl = timedelta(hours=24) if match.status == "FINISHED" else timedelta(minutes=10)
        prefix = "/fixtures/" + quote(mapping.external_id, safe="")
        data = [api.get(prefix + "/" + endpoint, ttl=ttl)["data"]
                for endpoint in ("lineups", "statistics", "events")]
        store_details(db, match, *data)
        db.commit()
        db.expire(match, ["lineups", "events"])
    except GoalError as error:
        db.rollback()
        logger.warning("GOAL details unavailable for match %s: %s", match.id, error)
    except Exception:
        db.rollback()
        logger.warning("GOAL details invalid for match %s; existing data kept", match.id)
    return True

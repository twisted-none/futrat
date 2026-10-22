"""ESPN day calendars, resumable season imports, and small live refreshes."""

from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
import logging
from threading import Event, Lock

import requests
from sqlalchemy import text

from app import models
from app.seasons import current_matches


logger = logging.getLogger(__name__)
FETCH_WORKERS = 4
CALENDAR_TTL = timedelta(hours=6)
_sync_lock = Lock()
_stop_event = Event()


def utc_now():
    return datetime.now(timezone.utc)


def start_sync():
    _stop_event.clear()


def stop_sync():
    _stop_event.set()


def utc(value):
    if isinstance(value, str):
        value = datetime.fromisoformat(value.replace("Z", "+00:00"))
    return value.replace(tzinfo=timezone.utc) if value.tzinfo is None else value.astimezone(timezone.utc)


def fetch_day(code, day):
    # A range produces HTTP 400 for soccer. Never fall back to an undated feed.
    url = f"https://site.api.espn.com/apis/site/v2/sports/soccer/{code}/scoreboard?limit=1000&dates={day}"
    for attempt in range(3):
        if _stop_event.is_set():
            raise InterruptedError("Synchronization is stopping")
        try:
            response = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=20)
            if response.status_code in (429, 500, 502, 503, 504):
                raise requests.RequestException(f"HTTP {response.status_code}")
            if response.status_code != 200:
                raise ValueError(f"{code}/{day}: HTTP {response.status_code}")
            data = response.json()
            if not isinstance(data, dict) or not isinstance(data.get("events"), list):
                raise ValueError(f"{code}/{day}: invalid scoreboard")
            if len(data["events"]) >= 1000:
                raise ValueError(f"{code}/{day}: feed hit the event limit")
            return data
        except requests.RequestException:
            if attempt == 2:
                raise
            _stop_event.wait(0.5 * (2 ** attempt))


@contextmanager
def database_lock(db):
    # Also serialize separate maintenance processes / multiple API workers.
    engine = db.get_bind()
    if engine.dialect.name != "postgresql":
        yield True
        return
    with engine.connect() as connection:
        acquired = connection.execute(text("SELECT pg_try_advisory_lock(728613410)")).scalar()
        connection.commit()
        try:
            yield acquired
        finally:
            if acquired:
                connection.execute(text("SELECT pg_advisory_unlock(728613410)"))
                connection.commit()


def calendar_days(code, league, start, end):
    items = league.get("calendar") or []
    if items and all(isinstance(item, str) for item in items):
        return {utc(item).strftime("%Y%m%d") for item in items}
    # Cup/UEFA calendars contain stage objects, not fixture dates. Calendar-year
    # feeds are supported by ESPN (unlike date ranges); use them to discover
    # actual published days, then reuse the same resumable daily importer.
    days = set()
    try:
        for year in range(start.year, end.year + 1):
            data = fetch_day(code, str(year))
            days.update(utc(item["date"]).strftime("%Y%m%d") for item in data["events"])
    except ValueError as error:
        logger.warning("%s: yearly discovery unavailable, probing season days: %s", code, error)
        days = {(start + timedelta(days=offset)).strftime("%Y%m%d")
                for offset in range((end.date() - start.date()).days + 1)}
    return days


def discover_calendar(db, code, name, now, *, force=False):
    tournament = db.query(models.Tournament).filter_by(api_code=code).first()
    if tournament is None:
        tournament = db.query(models.Tournament).filter_by(name=name).first()
    state = db.get(models.TournamentSyncState, tournament.id) if tournament else None
    if state and not force and now - utc(state.calendar_updated_at) < CALENDAR_TTL:
        return tournament, state

    data = fetch_day(code, now.strftime("%Y%m%d"))
    league = data.get("leagues", [{}])[0]
    season = league.get("season", {})
    start = utc(season.get("startDate") or league["calendarStartDate"])
    end = utc(season.get("endDate") or league["calendarEndDate"])
    if code == "uefa.euroq" and end.year < 2028:
        # ESPN returns 2024 when the 2028 qualifying draw is not published yet.
        raise ValueError("Euro 2028 qualifying schedule has not been published")
    if end <= start:
        raise ValueError(f"{code}: invalid season boundaries")
    calendar = calendar_days(code, league, start, end)
    calendar.update(utc(event["date"]).strftime("%Y%m%d") for event in data["events"])
    calendar = sorted(day for day in calendar
                      if start.date() <= datetime.strptime(day, "%Y%m%d").date() <= end.date())
    if tournament is None:
        tournament = models.Tournament(name=name, country="Global", type="League")
        db.add(tournament)
    tournament.api_code = code
    if code == "uefa.euroq":
        tournament.type = "National"
    tournament.current_season = season.get("displayName") or str(season.get("year", start.year))
    logos = league.get("logos") or []
    if logos:
        tournament.logo_url = logos[0].get("href")
    db.flush()
    if state is None:
        state = models.TournamentSyncState(tournament_id=tournament.id)
        db.add(state)
    if state.season_start is None or utc(state.season_start) != start or utc(state.season_end) != end:
        state.completed_dates = []
        state.source_rounds = {}
    elif force:
        state.completed_dates = []
    else:
        # Recheck announced fixtures on calendar refresh, while keeping old
        # completed history across crashes/restarts of a long initial import.
        cutoff = (now - timedelta(days=2)).strftime("%Y%m%d")
        state.completed_dates = [day for day in state.completed_dates if day < cutoff]
    state.season_start, state.season_end = start, end
    state.calendar, state.calendar_updated_at = calendar, now
    db.commit()
    return tournament, state


def _score(competitor):
    value = competitor.get("score")
    if isinstance(value, dict):
        value = value.get("value", value.get("displayValue"))
    return int(float(value)) if value not in (None, "") else None


def store_day(db, tournament, state, day, data):
    teams = {team.name: team for team in db.query(models.Team).all()}
    source_rounds = dict(state.source_rounds or {})
    saved = 0
    seen = {}
    for event in data["events"]:
        date = utc(event["date"])
        if not utc(state.season_start) <= date <= utc(state.season_end):
            continue
        comp = event["competitions"][0]
        home = next(item for item in comp["competitors"] if item["homeAway"] == "home")
        away = next(item for item in comp["competitors"] if item["homeAway"] == "away")
        pair = []
        for competitor in (home, away):
            item = competitor["team"]
            name = item.get("displayName") or item["name"]
            if any(word in name for word in ("All-Star", "LIGA MX")):
                break
            if name not in teams:
                teams[name] = models.Team(name=name, country="Global", logo_url=item.get("logo"))
                db.add(teams[name])
                db.flush()
            pair.append(teams[name])
        if len(pair) != 2:
            continue
        status_info = event["status"]["type"]
        status = {
            "STATUS_POSTPONED": "POSTPONED", "STATUS_DELAYED": "DELAYED",
            "STATUS_CANCELED": "CANCELLED",
        }.get(status_info.get("name")) or {
            "post": "FINISHED", "in": "IN_PLAY", "pre": "SCHEDULED",
        }[status_info["state"]]
        scores = (_score(home), _score(away)) if status in ("FINISHED", "IN_PLAY") else (None, None)
        api_id = str(event["id"])
        match = seen.get(api_id)
        if match is None:
            match = db.query(models.Match).filter_by(tournament_id=tournament.id, api_id=api_id).one_or_none()
        if match is None:
            match = models.Match(tournament_id=tournament.id, api_id=api_id)
            db.add(match)
        elif (match.status, match.score_home, match.score_away) != (status, *scores):
            match.is_detailed = False
        match.date_time = date
        match.home_team_id, match.away_team_id = pair[0].id, pair[1].id
        match.status, match.score_home, match.score_away = status, *scores
        from app.forecasts import observe_espn
        observe_espn(db, match, event["status"])
        if status == "IN_PLAY" or match.live_state is not None:
            from app.live_clock import espn
            espn(db, match, event["status"])
        seen[api_id] = match
        week = event.get("week") or comp.get("week") or {}
        if isinstance(week, dict) and week.get("number"):
            source_rounds[api_id] = int(week["number"])
        saved += 1
    state.source_rounds = source_rounds
    state.completed_dates = sorted(set(state.completed_dates or []) | {day})
    # Match rows and checkpoint commit together. A failed day remains retryable.
    db.commit()
    return saved


def assign_rounds(db, tournament_id, state):
    counts = {}
    # ESPN's soccer scoreboard often omits the official week. In that case
    # retain the app's per-team ordinal, calculated over the whole season.
    for match in current_matches(db, tournament_id).order_by(models.Match.date_time, models.Match.api_id):
        for team in (match.home_team_id, match.away_team_id):
            counts[team] = counts.get(team, 0) + 1
        match.round = (state.source_rounds or {}).get(match.api_id) or max(
            counts[match.home_team_id], counts[match.away_team_id])
    db.commit()


def sync_leagues(leagues, session_factory, *, full=True, force=False):
    """One writer, up to four HTTP requests, checkpoints after every date."""
    if not _sync_lock.acquire(blocking=False):
        logger.info("Sync skipped: another synchronization is running")
        return
    try:
        with session_factory() as db, database_lock(db) as acquired, ThreadPoolExecutor(max_workers=FETCH_WORKERS) as pool:
            if not acquired:
                logger.info("Sync skipped: another process is synchronizing this database")
                return
            for code, name in leagues.items():
                if _stop_event.is_set():
                    break
                try:
                    now = utc_now()
                    tournament, state = discover_calendar(db, code, name, now, force=force)
                    completed = set(state.completed_dates or [])
                    cutoff = (now - timedelta(days=2)).strftime("%Y%m%d")
                    near_end = (now + timedelta(days=2)).strftime("%Y%m%d")
                    days = [day for day in state.calendar if (
                        (force or day not in completed) if full
                        else cutoff <= day <= near_end
                    )]
                    logger.info("%s: %s season dates, %s to fetch (%s)", code, len(state.calendar),
                                len(days), "season" if full else "live")
                    failures, saved = 0, 0
                    for offset in range(0, len(days), FETCH_WORKERS):
                        if _stop_event.is_set():
                            break
                        batch = [(day, pool.submit(fetch_day, code, day))
                                 for day in days[offset:offset + FETCH_WORKERS]]
                        for day, future in batch:
                            try:
                                saved += store_day(db, tournament, state, day, future.result())
                            except Exception as error:
                                db.rollback()
                                failures += 1
                                logger.warning("%s/%s failed; checkpoint not advanced: %s", code, day, error)
                        logger.info("%s: processed %s/%s dates, saved %s events, %s failed", code,
                                    min(offset + FETCH_WORKERS, len(days)), len(days), saved, failures)
                    if saved or full:
                        assign_rounds(db, tournament.id, state)
                    from app.national_standings import sync_standings
                    sync_standings(db, tournament, state, now)
                except Exception as error:
                    db.rollback()
                    logger.warning("%s sync failed; continuing with other leagues: %s", code, error)
    finally:
        _sync_lock.release()

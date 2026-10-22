import requests
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, selectinload
from sqlalchemy import func, or_
from sqlalchemy import text
from typing import List
from datetime import datetime, timedelta, timezone
from app import models, schemas, database
from app.seasons import current_matches
from app.live_matches import LIVE_WINDOW, is_live_match
from app.competitions import NATIONAL_COMPETITIONS
from app import national_standings, goal_sync, lineups
from app.routers.auth import get_current_user

router = APIRouter(prefix="/api", tags=["Data"])


def get_or_create_player(db, player_name, team_id):
    if not player_name:
        return None
    player = db.query(models.Player).filter_by(
        name=player_name, team_id=team_id).first()
    if not player:
        player = models.Player(
            name=player_name, team_id=team_id, position="FWD")
        db.add(player)
        db.commit()
        db.refresh(player)
    return player


@router.get("/tournaments", response_model=List[schemas.TournamentResponse])
def get_tournaments(db: Session = Depends(database.get_db)):
    return db.query(models.Tournament).all()


@router.get("/matches", response_model=List[schemas.MatchResponse])
def get_matches(live: bool = False, db: Session = Depends(database.get_db)):
    now = datetime.now(timezone.utc)
    query = current_matches(db)
    if live:
        query = query.filter(models.Match.date_time >= now - LIVE_WINDOW,
                             models.Match.date_time <= now)
    raw_matches = query.options(
        selectinload(models.Match.home_team), selectinload(models.Match.away_team),
        selectinload(models.Match.tournament), selectinload(models.Match.lineups),
        selectinload(models.Match.events).selectinload(models.MatchEvent.player),
        selectinload(models.Match.events).selectinload(models.MatchEvent.secondary_player),
    ).order_by(models.Match.date_time).all()
    matches = []

    bad_words = ["winner", "tbd", "loser", "quarterfinal",
                 "quaterfinal", "semifinal", "final "]
    for m in raw_matches:
        if live and not is_live_match(m.status, m.date_time, now=now):
            continue
        hn = m.home_team.name.lower() if m.home_team else ""
        an = m.away_team.name.lower() if m.away_team else ""
        if any(w in hn for w in bad_words) or any(w in an for w in bad_words):
            continue

        if m.tournament and m.tournament.name == "Champions League":
            m_dt = m.date_time.replace(
                tzinfo=timezone.utc) if m.date_time.tzinfo is None else m.date_time
            month = m_dt.month
            day = m_dt.day
            if month == 2:
                m.round = 9 if day < 15 else 10
            elif month == 3:
                m.round = 11 if day < 15 else 12
            elif month == 4:
                m.round = 13 if day < 15 else 14
            elif month == 5 and day < 20:
                m.round = 15 if day < 10 else 16
            elif month == 5 and day >= 20:
                m.round = 17
            elif month == 6:
                m.round = 17

        matches.append(m)

    return matches


@router.get("/tournaments/{tournament_id}/standings", response_model=List[schemas.StandingRow])
def get_standings(tournament_id: int, db: Session = Depends(database.get_db)):
    tournament = db.query(models.Tournament).filter(
        models.Tournament.id == tournament_id).first()

    if tournament and tournament.type in {"PendingDraw", "PendingSchedule"}:
        return []
    if tournament and tournament.api_code in NATIONAL_COMPETITIONS:
        return national_standings.get_standings(db, tournament)

    # ХАРДКОД ДЛЯ ЧМ (ИЩЕМ ИКОНКИ В БАЗЕ ДАННЫХ!)
    if tournament and tournament.api_code == "fifa.world":
        wc_groups = {
            "Группа A": ["Mexico", "South Africa", "South Korea", "TBD"],
            "Группа B": ["Canada", "TBD", "Qatar", "Switzerland"],
            "Группа C": ["Brazil", "Morocco", "Haiti", "Scotland"],
            "Группа D": ["United States", "Paraguay", "Australia", "TBD"],
            "Группа E": ["Germany", "Curaçao", "Ivory Coast", "Ecuador"],
            "Группа F": ["Netherlands", "Japan", "TBD", "Tunisia"],
            "Группа G": ["Belgium", "Egypt", "Iran", "New Zealand"],
            "Группа H": ["Spain", "Cape Verde", "Saudi Arabia", "Uruguay"],
            "Группа I": ["France", "Senegal", "TBD", "Norway"],
            "Группа J": ["Argentina", "Algeria", "Austria", "Jordan"],
            "Группа K": ["Portugal", "TBD", "Uzbekistan", "Colombia"],
            "Группа L": ["England", "Croatia", "Ghana", "Panama"],
        }
        wc_stats = []
        mock_id = -100
        for g_name, teams_list in wc_groups.items():
            for i, t_name in enumerate(teams_list):
                # Ищем сборную в базе, чтобы подтянуть её логотип (из товарищеских матчей)
                team_db = db.query(models.Team).filter(
                    models.Team.name == t_name).first()
                if not team_db:
                    team_db = db.query(models.Team).filter(
                        models.Team.name.ilike(f"%{t_name}%")).first()

                logo_url = team_db.logo_url if team_db and team_db.logo_url else ""
                team_id = team_db.id if team_db else mock_id

                t_resp = schemas.TeamResponse(
                    id=team_id, name=t_name, logo_url=logo_url, country="World")
                wc_stats.append({
                    "rank": i + 1, "team": t_resp, "played": 0, "won": 0, "draw": 0, "lost": 0,
                    "goals_for": 0, "goals_against": 0, "points": 0, "form": [], "group_name": g_name
                })
                mock_id -= 1
        return wc_stats

    query = current_matches(db, tournament_id).filter(models.Match.status == "FINISHED")
    if tournament:
        code = tournament.api_code
        if code in ["uefa.champions", "uefa.europa", "uefa.europa.conf"]:
            query = query.filter(models.Match.round <= 8)

    matches = query.all()
    season_teams = current_matches(db, tournament_id).with_entities(
        models.Match.home_team_id, models.Match.away_team_id).all()
    team_ids = {team_id for pair in season_teams for team_id in pair}
    teams = db.query(models.Team).filter(models.Team.id.in_(team_ids)).all()

    stats = {}
    bad_words = ["winner", "tbd", "loser", "quarterfinal",
                 "quaterfinal", "semifinal", "final "]

    for t in teams:
        n = t.name.lower()
        if any(w in n for w in bad_words):
            continue
        stats[t.id] = {"team": schemas.TeamResponse.model_validate(
            t), "played": 0, "won": 0, "draw": 0, "lost": 0, "goals_for": 0, "goals_against": 0, "points": 0, "form": [], "group_name": "Таблица"}

    for m in matches:
        if m.score_home is None or m.score_away is None:
            continue
        h, a = m.home_team_id, m.away_team_id
        if h not in stats or a not in stats:
            continue

        stats[h]["played"] += 1
        stats[a]["played"] += 1
        stats[h]["goals_for"] += m.score_home
        stats[h]["goals_against"] += m.score_away
        stats[a]["goals_for"] += m.score_away
        stats[a]["goals_against"] += m.score_home

        if m.score_home > m.score_away:
            stats[h]["won"] += 1
            stats[h]["points"] += 3
            stats[a]["lost"] += 1
        elif m.score_home < m.score_away:
            stats[a]["won"] += 1
            stats[a]["points"] += 3
            stats[h]["lost"] += 1
        else:
            stats[h]["draw"] += 1
            stats[a]["draw"] += 1
            stats[h]["points"] += 1
            stats[a]["points"] += 1

    for t_id, data in stats.items():
        t_matches = [m for m in matches if m.home_team_id ==
                     t_id or m.away_team_id == t_id]
        t_matches.sort(key=lambda x: x.date_time, reverse=True)
        form = []
        for m in t_matches[:5]:
            if m.score_home == m.score_away:
                form.append("D")
            elif m.home_team_id == t_id and m.score_home > m.score_away:
                form.append("W")
            elif m.away_team_id == t_id and m.score_away > m.score_home:
                form.append("W")
            else:
                form.append("L")
        data["form"] = form[::-1]

    if tournament and tournament.api_code in ["uefa.champions", "uefa.europa", "uefa.europa.conf", "usa.1"]:
        try:
            url = f"https://site.api.espn.com/apis/site/v2/sports/soccer/{tournament.api_code}/standings"
            resp = requests.get(url, timeout=5)
            if resp.status_code == 200:
                s_data = resp.json()
                children = s_data.get('children', [])
                for child in children:
                    g_name = child.get('name', 'Group')

                    if len(g_name) == 1:
                        g_name = f"Группа {g_name}"
                    elif "Group" in g_name:
                        g_name = g_name.replace("Group", "Группа")
                    elif "Eastern Conference" in g_name:
                        g_name = "Восточная конференция"
                    elif "Western Conference" in g_name:
                        g_name = "Западная конференция"

                    for standing in child.get('standings', {}).get('entries', []):
                        team_name = standing.get('team', {}).get('name')
                        if not team_name:
                            continue
                        for t_id, s_row in stats.items():
                            db_name = s_row['team'].name
                            if db_name == team_name or db_name in team_name or team_name in db_name:
                                s_row['group_name'] = g_name
        except Exception:
            pass

    sorted_stats = sorted(stats.values(), key=lambda x: (
        x["group_name"], x["points"], x["goals_for"] - x["goals_against"], x["goals_for"]), reverse=True)

    current_group = None
    rank = 1
    for s in sorted_stats:
        if s["group_name"] != current_group:
            current_group = s["group_name"]
            rank = 1
        s["rank"] = rank
        rank += 1

    return sorted_stats


@router.get("/matches/updates", response_model=List[schemas.MatchLiveUpdate])
def get_match_updates(ids: List[int] = Query(default=[], max_length=500),
                      db: Session = Depends(database.get_db)):
    now = datetime.now(timezone.utc)
    # Include ended games and requested IDs: live-only would lose the final score
    # or leave an old kickoff behind when a match is rescheduled.
    return current_matches(db).filter(or_(
        (models.Match.date_time >= now - LIVE_WINDOW) &
        (models.Match.date_time <= now + timedelta(minutes=15)),
        models.Match.id.in_(ids),
    )).order_by(models.Match.date_time, models.Match.id).all()


@router.get("/matches/{match_id}", response_model=schemas.MatchResponse)
def get_match_details(match_id: int, db: Session = Depends(database.get_db)):
    match = db.query(models.Match).filter(models.Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    if db.get_bind().dialect.name=="postgresql" and not db.execute(
        text("SELECT pg_try_advisory_xact_lock(728613411,:match_id)"),{"match_id":match.id}).scalar():
        return lineups.decorate(db,match)

    needs_update = not match.is_detailed or match.status not in [
        "FINISHED", "SCHEDULED", "CANCELLED", "POSTPONED", "DELAYED"]
    if match.lineups and not db.query(models.LineupDetail).join(models.MatchLineup,
        models.MatchLineup.id==models.LineupDetail.lineup_id).filter(models.MatchLineup.match_id==match.id).first():
        needs_update = True

    goal_details = goal_sync.refresh_details(db, match, database.SessionLocal)
    if not goal_details and needs_update and match.api_id and match.tournament.api_code:
        try:
            url = f"https://site.api.espn.com/apis/site/v2/sports/soccer/{match.tournament.api_code}/summary?event={match.api_id}"
            resp = requests.get(
                url, headers={'User-Agent': 'Mozilla/5.0'}, timeout=12)
            if resp.status_code == 200:
                data = resp.json()
                header_comps = data.get('header', {}).get(
                    'competitions', [{}])[0].get('competitors', [])
                home_api_id = next((c.get('team', {}).get(
                    'id') for c in header_comps if c.get('homeAway') == 'home'), None)

                m_status = data.get('header', {}).get(
                    'competitions', [{}])[0].get('status', {})
                state = m_status.get('type', {}).get('state')
                status_name = m_status.get('type', {}).get('name')

                if status_name in ["STATUS_POSTPONED", "STATUS_DELAYED", "STATUS_CANCELED"]:
                    match.status = "DELAYED"
                    match.score_home = None
                    match.score_away = None
                    match.is_detailed = True
                elif state == 'post':
                    match.status = "FINISHED"
                    match.is_detailed = True
                elif state == 'in':
                    clock = m_status.get('displayClock', "0'")
                    match.status = f"{clock}'" if "'" not in clock else clock
                    match.is_detailed = False

                if match.status not in {"DELAYED","SCHEDULED"}:
                    for c in header_comps:
                        if c.get('homeAway') == 'home':
                            match.score_home = int(c.get('score', 0))
                        else:
                            match.score_away = int(c.get('score', 0))

                boxscore = data.get('boxscore', {})
                stat_map = {'possessionPct': 'possession', 'totalShots': 'shots', 'shotsOnTarget': 'shots_on_target', 'wonCorners': 'corners',
                            'foulsCommitted': 'fouls', 'yellowCards': 'yellow_cards', 'redCards': 'red_cards', 'offsides': 'offsides', 'saves': 'saves'}

                for t_stat in boxscore.get('teams', []):
                    is_h = t_stat.get('team', {}).get('id') == home_api_id
                    suffix = "_home" if is_h else "_away"

                    raw_stats = {s['name']: s.get('displayValue', '0').replace(
                        '%', '') for s in t_stat.get('statistics', [])}

                    for k, v in stat_map.items():
                        if k in raw_stats:
                            try:
                                setattr(match, v + suffix,
                                        int(float(raw_stats[k])))
                            except:
                                pass

                    tot_passes = 0
                    acc_passes = 0

                    if 'accuratePasses' in raw_stats and 'totalPasses' in raw_stats:
                        try:
                            acc_passes = float(raw_stats['accuratePasses'])
                            tot_passes = float(raw_stats['totalPasses'])
                        except:
                            pass
                    elif 'passes' in raw_stats and ('/' in raw_stats['passes'] or '-' in raw_stats['passes']):
                        pval = raw_stats['passes']
                        sep = '/' if '/' in pval else '-'
                        try:
                            acc, tot = map(float, pval.split(sep))
                            acc_passes = acc
                            tot_passes = tot
                        except:
                            pass
                    elif 'passes' in raw_stats:
                        try:
                            tot_passes = float(raw_stats['passes'])
                            pct = float(raw_stats.get('passPct')
                                        or raw_stats.get('passCompletionPct', 0))
                            acc_passes = (pct / 100.0) * tot_passes
                        except:
                            pass

                    if tot_passes > 0:
                        setattr(match, f"passes{suffix}", int(tot_passes))
                        setattr(match, f"pass_accuracy{suffix}", int(
                            (acc_passes / tot_passes) * 100))

                rosters = data.get('rosters', [])
                lineups.enrich_espn(db,match,data,home_external_id=home_api_id)
                for roster in rosters:
                    r_team_id = match.home_team_id if roster.get('team', {}).get(
                        'id') == home_api_id else match.away_team_id
                    for r_p in roster.get('roster', []):
                        athlete = r_p.get('athlete', {})
                        p_name = athlete.get('displayName') or athlete.get(
                            'fullName') or athlete.get('shortName') or 'Unknown'
                        if not db.query(models.MatchLineup).filter_by(match_id=match.id, team_id=r_team_id, player_name=p_name).first():
                            db.add(models.MatchLineup(match_id=match.id, team_id=r_team_id, player_name=p_name, jersey_number=athlete.get(
                                'jersey', ''), position=r_p.get('position', {}).get('name', ''), is_starter=r_p.get('starter', False)))

                for ev in data.get('keyEvents', []):
                    clock = ev.get('clock', {}).get('displayValue', '0')
                    minute = int(
                        ''.join(filter(str.isdigit, clock.split('+')[0])) or 0)
                    act_team_id = match.home_team_id if ev.get('team', {}).get(
                        'id') == home_api_id else match.away_team_id
                    participants = ev.get('participants', [])
                    if not participants:
                        continue
                    p1_data = participants[0].get('athlete', {})
                    p1 = get_or_create_player(db, p1_data.get('displayName') or p1_data.get(
                        'fullName') or p1_data.get('shortName') or 'Unknown', act_team_id)
                    p2 = None
                    if len(participants) > 1:
                        p2_data = participants[1].get('athlete', {})
                        p2 = get_or_create_player(db, p2_data.get('displayName') or p2_data.get(
                            'fullName') or p2_data.get('shortName') or 'Unknown', act_team_id)

                    txt = ev.get('type', {}).get('text', '').lower()
                    ev_type = "GOAL" if 'goal' in txt or 'penalty' in txt else ("YELLOW_CARD" if 'yellow' in txt else (
                        "RED_CARD" if 'red' in txt else ("SUBSTITUTION" if 'substitution' in txt else None)))
                    if ev_type and not db.query(models.MatchEvent).filter_by(match_id=match.id, player_id=p1.id, type=ev_type, minute=minute).first():
                        db.add(models.MatchEvent(match_id=match.id, player_id=p1.id,
                               secondary_player_id=p2.id if p2 else None, type=ev_type, minute=minute))

                db.commit()
        except Exception as e:
            db.rollback()
            print(f"Lazy Load Error: {e}")

    team_ids = {lp.team_id for lp in match.lineups}
    players = {
        (player.name, player.team_id): player
        for player in db.query(models.Player).filter(models.Player.team_id.in_(team_ids)).all()
    } if team_ids else {}
    added_players = False
    for lp in match.lineups:
        if db.get(models.LineupDetail,lp.id):
            continue
        key = (lp.player_name, lp.team_id)
        if key not in players:
            players[key] = models.Player(name=lp.player_name, team_id=lp.team_id)
            db.add(players[key])
            added_players = True
    if added_players:
        db.flush()
    player_ids = {key: player.id for key, player in players.items()}
    if added_players:
        db.commit()

    for lp in match.lineups:
        detail=db.get(models.LineupDetail,lp.id)
        lp.player_id = detail.player_id if detail else player_ids[(lp.player_name, lp.team_id)]
        avg = db.query(func.avg(models.UserPlayerRating.rating)).filter(
            models.UserPlayerRating.lineup_id == lp.id).scalar()
        lp.rating = f"{avg:.1f}" if avg else "-"
    return lineups.decorate(db,match)


@router.post("/rate-player")
def rate_player(data: schemas.PlayerRatingCreate, db: Session = Depends(database.get_db), user: models.User = Depends(get_current_user)):
    lineup=db.query(models.MatchLineup).filter_by(id=data.lineup_id).with_for_update().first()
    if not lineup:
        raise HTTPException(404,"Игрок в составе не найден")
    detail=db.get(models.LineupDetail,lineup.id)
    if lineup.match.status!="FINISHED" or (detail and detail.appeared is not True) or (not detail and not lineup.is_starter):
        raise HTTPException(409,"Оценивать можно после матча и только участвовавших игроков")
    existing = db.query(models.UserPlayerRating).filter_by(
        user_id=user.id, lineup_id=data.lineup_id).first()
    if existing:
        existing.rating = data.rating
    else:
        db.add(models.UserPlayerRating(user_id=user.id,
               lineup_id=data.lineup_id, rating=data.rating))
    db.commit()
    return {"message": "Saved"}

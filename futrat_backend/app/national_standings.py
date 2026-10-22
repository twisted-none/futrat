"""Cache official group tables, including deductions and federation tiebreaks."""

from datetime import timedelta
import requests

from app import models
from app.competitions import NATIONAL_COMPETITIONS
from app.match_sync import utc


def sync_standings(db, tournament, state, now):
    if tournament.api_code not in NATIONAL_COMPETITIONS:
        return
    cached = db.get(models.OfficialStandings, tournament.id)
    if cached and cached.season == tournament.current_season and now - utc(cached.updated_at) < timedelta(hours=1):
        return
    year = utc(state.season_start).year
    response = requests.get(
        f"https://site.web.api.espn.com/apis/v2/sports/soccer/{tournament.api_code}/standings",
        params={"region": "us", "lang": "en", "season": year}, timeout=20)
    if response.status_code != 200:
        raise ValueError(f"Standings HTTP {response.status_code}")
    data = response.json()
    rows = []

    def visit(node):
        group = node.get("name", "").replace("Group", "Группа")
        for entry in (node.get("standings") or {}).get("entries", []):
            source_team = entry.get("team") or {}
            name = source_team.get("displayName") or source_team.get("name")
            if not name:
                continue
            team = db.query(models.Team).filter_by(name=name).first()
            if not team:
                logos = source_team.get("logos") or []
                team = models.Team(name=name, country="National", logo_url=logos[0].get("href") if logos else None)
                db.add(team)
                db.flush()
            values = {stat["name"]: stat.get("value") for stat in entry.get("stats", [])}
            fields = {"rank": "rank", "played": "gamesPlayed", "won": "wins", "draw": "ties",
                      "lost": "losses", "goals_for": "pointsFor", "goals_against": "pointsAgainst", "points": "points"}
            if any(values.get(key) is None for key in fields.values()):
                raise ValueError("Incomplete national standings")
            rows.append({"team_id": team.id, "group_name": group, "form": [],
                         **{field: int(values[key]) for field, key in fields.items()}})
        for child in node.get("children", []):
            visit(child)

    visit(data)
    if rows:
        if cached is None:
            cached = models.OfficialStandings(tournament_id=tournament.id)
            db.add(cached)
        cached.season, cached.rows, cached.updated_at = tournament.current_season, rows, now
        db.commit()


def get_standings(db, tournament):
    cached = db.get(models.OfficialStandings, tournament.id)
    if not cached or cached.season != tournament.current_season:
        return []
    teams = {team.id: team for team in db.query(models.Team).filter(
        models.Team.id.in_([row["team_id"] for row in cached.rows]))}
    return [{**row, "team": teams[row["team_id"]]} for row in cached.rows if row["team_id"] in teams]

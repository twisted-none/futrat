from datetime import datetime, timezone

from app import models, lineups
from app.seasons import current_matches
from tests.test_profiles import roster


def instant(year, month, day=1):
    return datetime(year, month, day, tzinfo=timezone.utc)


def add_game(db, template, code, date, *, source_bounds=None):
    tournament = models.Tournament(
        name=code, api_code=code, type="Cup", current_season="Test edition",
    )
    game = models.Match(
        tournament=tournament, date_time=date, status="FINISHED",
        home_team_id=template.home_team_id, away_team_id=template.away_team_id,
        score_home=1, score_away=0,
    )
    db.add(game)
    db.flush()
    if source_bounds:
        db.add(models.TournamentSyncState(
            tournament_id=tournament.id, season_start=source_bounds[0],
            season_end=source_bounds[1], calendar_updated_at=instant(2026, 10),
        ))
    return game


def test_public_lists_keep_only_2627_clubs_calendar_mls_and_current_national(db, match):
    old = add_game(db, match, "eng.1", instant(2026, 5))
    next_season = add_game(db, match, "esp.1", instant(2027, 8))
    old_french_cup = add_game(db, match, "fra.coupe_de_france", instant(2026, 5),
                              source_bounds=(instant(2025, 7), instant(2026, 6)))
    mls = add_game(db, match, "usa.1", instant(2026, 3))
    old_mls = add_game(db, match, "usa.1", instant(2025, 10))
    national = add_game(db, match, "caf.nations", instant(2025, 12),
                        source_bounds=(instant(2025, 12), instant(2026, 2)))
    archived_national = models.Match(
        tournament_id=national.tournament_id, date_time=instant(2024, 1),
        status="FINISHED", home_team_id=match.home_team_id,
        away_team_id=match.away_team_id,
    )
    db.add(archived_national)
    db.commit()
    ids = {game.id for game in current_matches(db)}
    assert ids == {match.id, mls.id, national.id}
    assert all(db.get(models.Match, game.id) for game in
               [old, next_season, old_french_cup, old_mls, archived_national])


def test_profile_defaults_and_cursor_share_public_season_filter(client, db, match):
    old = add_game(db, match, "eng.1", instant(2026, 5))
    national = add_game(db, match, "fifa.world", instant(2026, 6),
                        source_bounds=(instant(2026, 6), instant(2026, 8)))
    db.commit()
    for game in [old, match, national]:
        lineups.enrich_espn(db, game, {"rosters": [roster(10)]}, home_external_id="10")
    db.commit()
    result = client.get(f"/api/teams/{match.home_team_id}/matches").json()
    assert result["season"] == 2026 and result["seasons"] == [2026]
    assert result["anchor"]["id"] == match.id
    assert [item["id"] for item in result["past"]] == [national.id]
    assert client.get(f"/api/teams/{match.home_team_id}/matches?cursor={old.id}").status_code == 422
    player_id = db.query(models.LineupDetail).first().player_id
    player = client.get(f"/api/players/{player_id}/matches").json()
    assert player["season"] == 2026
    assert {item["match"]["id"] for item in player["matches"]} == {match.id, national.id}

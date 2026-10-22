from datetime import datetime, timezone, timedelta

from app import models, lineups


def roster(team_id, name="Player One", external_id="source-player", starter=True):
    return {"team":{"id":str(team_id)}, "homeAway":"home", "formation":"4-2-3-1", "roster":[{
        "athlete":{"id":external_id,"displayName":name,"headshot":{"href":"https://a.espncdn.com/i/headshots/soccer/players/full/1.png"}},
        "starter":starter,"formationPlace":1 if starter else 0,"jersey":"1",
        "stats":[{"name":"appearances","value":1 if starter else 0},{"name":"totalGoals","value":0},{"name":"goalAssists","value":1}],
    }]}


def test_source_player_id_unifies_club_and_national_appearances_without_deleting_legacy(db, match):
    old = models.Player(name="Player One", team_id=match.home_team_id)
    db.add(old);db.commit()
    lineups.enrich_espn(db, match, {"rosters":[roster(10)]}, home_external_id="10")
    db.commit()
    first = db.query(models.LineupDetail).one().player_id
    assert first == old.id
    national = models.Team(name="National",country="National")
    other = models.Match(date_time=match.date_time, status="FINISHED", tournament_id=match.tournament_id,
        home_team=national, away_team_id=match.away_team_id, score_home=1,score_away=0)
    db.add(other);db.commit()
    lineups.enrich_espn(db, other, {"rosters":[roster(20)]}, home_external_id="20")
    db.commit()
    assert {row.player_id for row in db.query(models.LineupDetail)} == {first}
    assert db.get(models.Player,old.id) is not None
    assert db.get(models.PlayerProfile,first).photo_url.startswith('https://a.espncdn.com/')


def test_unused_substitute_is_not_recorded_as_played_and_ratings_are_not_invented(db, match):
    lineups.enrich_espn(db, match, {"rosters":[roster(10,starter=False)]}, home_external_id="10")
    db.commit()
    detail = db.query(models.LineupDetail).one()
    assert detail.appeared is False
    assert detail.source_rating is None
    assert detail.slot is None


def test_lineup_refresh_keeps_user_rating_ids(db, match):
    data={"rosters":[roster(10)]}
    lineups.enrich_espn(db, match, data, home_external_id="10");db.commit()
    entry=db.query(models.MatchLineup).one()
    user=models.User(username="lineup",email="lineup@example.test",hashed_password="fake")
    db.add(models.UserPlayerRating(user=user,lineup=entry,rating=8));db.commit()
    old_id=entry.id
    lineups.enrich_espn(db, match, data, home_external_id="10");db.commit()
    assert db.query(models.MatchLineup).one().id == old_id
    assert db.query(models.UserPlayerRating).one().rating == 8


def test_team_timeline_has_last_finished_anchor_all_competitions_and_history_above(client,db,match):
    match.date_time=datetime(2026,10,10,tzinfo=timezone.utc)
    cup=models.Tournament(name="Cup",type="Cup",country="Global",current_season="2026/27")
    newer=models.Match(date_time=datetime(2026,10,15,tzinfo=timezone.utc),status="FINISHED",tournament=cup,
        home_team_id=match.home_team_id,away_team_id=match.away_team_id,score_home=0,score_away=0)
    future=models.Match(date_time=datetime(2026,11,1,tzinfo=timezone.utc),status="SCHEDULED",tournament=cup,
        home_team_id=match.home_team_id,away_team_id=match.away_team_id)
    db.add_all([newer,future]);db.commit()
    data=client.get(f"/api/teams/{match.home_team_id}/matches?season=2026").json()
    assert data["anchor"]["id"] == newer.id
    assert [m["id"] for m in data["past"]] == [match.id]
    assert [m["id"] for m in data["future"]] == [future.id]
    assert client.get('/api/teams/99999/matches').status_code == 404


def test_player_history_only_contains_confirmed_appearances(client,db,match):
    lineups.enrich_espn(db,match,{"rosters":[roster(10)]},home_external_id="10");db.commit()
    player_id=db.query(models.LineupDetail).one().player_id
    data=client.get(f'/api/players/{player_id}/matches?season=2026').json()
    assert len(data['matches']) == 1
    assert data['matches'][0]['goals'] == 0
    assert data['matches'][0]['source_rating'] is None
    assert data['matches'][0]['assists'] == 1


def test_goal_photo_and_position_are_kept_without_season_rating_fallback(db,match):
    from app.goal_sync import store_details
    data={"home":{"startingLineups":[{"lineupPlayer":"Goal Player","playerId":"goal-player",
        "playerImage":"https://media.goal-api.com/badges/players/1.jpg","lineupPosition":"1"}]},"away":{},"homeFormation":"4-3-3"}
    store_details(db,match,data,{},[]);db.commit()
    detail=db.query(models.LineupDetail).one()
    assert detail.slot == 1 and detail.source_rating is None
    assert db.get(models.PlayerProfile,detail.player_id).photo_source == 'GOAL'


def test_goal_match_rating_comes_only_from_the_fixture_player_block(db,match):
    from app.goal_sync import store_details
    data={'home':{'startingLineups':[{'lineupPlayer':'Player','playerId':'p'}]},'away':{}}
    store_details(db,match,data,{'players':{'home':[{'playerId':'p','rating':'8.3','goals':1,'assists':0,'minutes':90}]}},[])
    db.commit()
    detail=db.query(models.LineupDetail).one()
    assert detail.source_rating==8.3 and detail.rating_source=='GOAL'
    assert detail.minutes==90 and detail.goals==1


def test_wrong_person_photo_is_not_used_on_name_alone(db,match,monkeypatch):
    from app.player_history import _photo
    from types import SimpleNamespace
    player=models.Player(name='Common Name',team_id=match.home_team_id)
    db.add(player);db.flush()
    photo=models.PlayerProfile(player_id=player.id);db.add(photo);db.commit()
    monkeypatch.setattr('app.player_history.requests.get',lambda *a,**kw:SimpleNamespace(status_code=200,json=lambda:{
        'player':[{'strPlayer':'Common Name','strTeam':'Another Club','strCutout':'https://r2.thesportsdb.com/example.png'}]}))
    _photo(db,photo)
    assert photo.photo_url is None


def test_rating_unused_substitute_is_rejected(client,db,match):
    lineups.enrich_espn(db,match,{'rosters':[roster(10,starter=False)]},home_external_id='10');db.commit()
    response=client.post('/auth/register',json={'username':'rater','email':'rater@example.test','password':'test-pass'})
    headers={'Authorization':'Bearer '+response.json()['access_token']}
    entry=db.query(models.MatchLineup).one()
    assert client.post('/api/rate-player',headers=headers,json={'lineup_id':entry.id,'rating':8}).status_code==409

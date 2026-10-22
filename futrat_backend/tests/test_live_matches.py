from datetime import datetime, timedelta, timezone

import pytest

from app import models


def test_live_api_excludes_august_fixture_but_keeps_it_in_history(client, db, match):
    now = datetime.now(timezone.utc)
    match.status = "IN_PLAY"
    match.date_time = datetime(2026, 8, 12, 15, tzinfo=timezone.utc)
    recent = models.Match(
        tournament_id=match.tournament_id, home_team_id=match.home_team_id,
        away_team_id=match.away_team_id, status="IN_PLAY",
        date_time=now - timedelta(minutes=70), score_home=1, score_away=0,
    )
    db.add(recent)
    db.commit()
    live = client.get('/api/matches?live=true').json()
    assert [game['id'] for game in live] == [recent.id]
    assert live[0]['is_live'] is True
    history = {game['id']: game for game in client.get('/api/matches').json()}
    assert history[match.id]['status'] == 'IN_PLAY'
    assert history[match.id]['is_live'] is False
    assert (history[match.id]['score_home'], history[match.id]['score_away']) == (2, 1)
    assert db.get(models.Match, match.id).status == 'IN_PLAY'


@pytest.mark.parametrize('status', [
    'SCHEDULED', 'FINISHED', 'POSTPONED', 'DELAYED', 'CANCELLED',
    'ABANDONED', 'SUSPENDED', 'UNKNOWN', '',
])
def test_live_api_rejects_non_live_statuses(client, db, match, status):
    match.date_time = datetime.now(timezone.utc) - timedelta(minutes=20)
    match.status = status
    db.commit()
    assert client.get('/api/matches?live=true').json() == []


def test_live_window_crosses_midnight_and_accepts_espn_clock(client, db, match):
    from app.live_matches import is_live_match

    now = datetime(2026, 10, 18, 0, 20, tzinfo=timezone.utc)
    kickoff = now - timedelta(minutes=100)
    assert is_live_match("90'+3'", kickoff, now=now)
    assert is_live_match('HALF_TIME', kickoff.replace(tzinfo=None), now=now)
    assert is_live_match('IN_PLAY', now - timedelta(hours=6), now=now)
    assert not is_live_match('IN_PLAY', now - timedelta(hours=6, seconds=1), now=now)
    assert not is_live_match('IN_PLAY', now + timedelta(minutes=1), now=now)
    assert not is_live_match('season 2026', kickoff, now=now)

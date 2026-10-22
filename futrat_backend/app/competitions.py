"""Provider assignments do not change the application's tournament IDs/codes."""

GOAL_COMPETITIONS = {
    "rus.cup": {"country": "Russia", "names": {"cup", "russian cup", "russia cup"}},
    "eng.fa": {"country": "England", "names": {"fa cup", "england fa cup"}},
    "esp.super_cup": {"country": "Spain", "names": {"super cup", "supercopa", "spain super cup", "supercopa de españa"}},
}

NATIONAL_COMPETITIONS = {"uefa.nations", "caf.nations", "uefa.euroq"}


def seed_tournaments(db, leagues):
    from app import models
    for code, name in leagues.items():
        tournament = db.query(models.Tournament).filter_by(api_code=code).first()
        if tournament is None:
            tournament = db.query(models.Tournament).filter_by(name=name).first()
        if tournament is None:
            tournament = models.Tournament(name=name, api_code=code, country="Global",
                                           type="League", current_season="Ожидание данных")
            db.add(tournament)
        tournament.api_code = code
        if code == "uefa.euro":
            # Enable import deliberately once the complete draw is published.
            tournament.type, tournament.current_season = "PendingDraw", "2028"
        elif code == "uefa.euroq" and tournament.type in (None, "League"):
            tournament.type, tournament.current_season = "PendingSchedule", "2028"
    db.commit()

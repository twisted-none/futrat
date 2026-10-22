from app.security import get_password_hash, verify_password
from app.config import settings
from app import models, match_sync
from app.database import SessionLocal, engine, Base
from app.competitions import GOAL_COMPETITIONS, seed_tournaments as seed_registry
import requests  # Kept as the HTTP seam used by regression tests.

# --- ПЕРЕВЕДЕННЫЕ ЛИГИ С ТЕГАМИ ---
TARGET_LEAGUES = {
    "eng.1": "Английская Премьер-лига (ENG-1)",
    "esp.1": "Ла Лига (ESP-1)",
    "ger.1": "Бундеслига (GER-1)",
    "ita.1": "Серия А (ITA-1)",
    "fra.1": "Лига 1 (FRA-1)",
    "rus.1": "РПЛ (RUS-1)",
    "ned.1": "Эредивизи (NED-1)",
    "por.1": "Примейра-лига (POR-1)",
    "tur.1": "Турецкая Суперлига (TUR-1)",  # ИЗМЕНЕНО НАЗВАНИЕ
    "ksa.1": "Саудовская Про-лига (KSA-1)",

    "eng.2": "Чемпионшип (ENG-2)",

    "uefa.champions": "Лига Чемпионов (UEFA)",
    "uefa.europa": "Лига Европы (UEFA)",
    "uefa.europa.conf": "Лига Конференций (UEFA)",

    "fifa.world": "Чемпионат Мира (FIFA)",
    "fifa.friendly": "Товарищеские матчи (INT)",
    "uefa.nations": "Лига наций (UEFA-NL)",
    "caf.nations": "Кубок африканских наций (CAF)",
    "uefa.euroq": "Отбор Евро (UEFA-Q)",
    "uefa.euro": "Евро (EURO)",

    "eng.fa": "Кубок Англии (ENG-CUP)",
    "eng.league_cup": "Кубок Лиги (ENG-LC)",
    "esp.copa_del_rey": "Кубок Короля (ESP-CUP)",
    "ger.dfb_pokal": "Кубок Германии (GER-CUP)",
    "ita.coppa_italia": "Кубок Италии (ITA-CUP)",
    "fra.coupe_de_france": "Кубок Франции (FRA-CUP)",
    "rus.cup": "Кубок России (RUS-CUP)",

    "eng.charity": "Суперкубок Англии (ENG-SC)",
    "esp.super_cup": "Суперкубок Испании (ESP-SC)",
    "uefa.super_cup": "Суперкубок УЕФА (UEFA-SC)",

    "usa.1": "МЛС (USA-1)"
}


def update_all_data(*, force=False):
    return sync_sources(full=True, force=force)


def update_live_data():
    return sync_sources(full=False)


def update_live_feed():
    from app.live_sync import refresh
    return refresh(SessionLocal)


def seed_tournaments(db):
    seed_registry(db, TARGET_LEAGUES)


def sync_sources(*, full, force=False):
    from app.goal_sync import sync_goal
    # GOAL's cache keeps minute scheduler calls inside the free daily budget.
    if full:
        sync_goal({code: TARGET_LEAGUES[code] for code in GOAL_COMPETITIONS if code in TARGET_LEAGUES},
                  SessionLocal, full=full, force=force)
    espn = {code: name for code, name in TARGET_LEAGUES.items()
            if code not in GOAL_COMPETITIONS and code != "uefa.euro"}
    return match_sync.sync_leagues(espn, SessionLocal, full=full, force=force)


def init_db():
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        if settings.APP_ENV == "production":
            legacy_admin = db.query(models.User).filter(
                (models.User.email == "admin@futrat.com")
                | (models.User.username_key == "admin")
            ).all()
            if any(verify_password("admin", user.hashed_password) for user in legacy_admin):
                raise RuntimeError(
                    "Unsafe development account: change its password before production startup"
                )
        seed_tournaments(db)
        if (settings.APP_ENV != "production"
                and not db.query(models.User).filter_by(email="admin@futrat.com").first()):
            db.add(models.User(email="admin@futrat.com", username="Admin",
                               hashed_password=get_password_hash("admin")))
            db.commit()


if __name__ == "__main__":
    init_db()
    update_all_data()

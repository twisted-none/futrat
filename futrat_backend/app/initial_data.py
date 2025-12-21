import sys
import os
import requests
import time
from datetime import datetime

# Настройка путей
sys.path.append(os.getcwd())

from sqlalchemy.orm import Session
from app.database import SessionLocal, engine, Base
from app import models
from app.security import get_password_hash

# ==========================================
# ВСТАВЬ СЮДА СВОЙ КЛЮЧ ИЗ СКРИНШОТА
API_KEY = "008fa4d126b84c99aa88b8a0f8719e14"  # <-- ВСТАВЬ ПОЛНЫЙ КЛЮЧ СЮДА
# ==========================================

API_URL = "https://api.football-data.org/v4"

# Коды лиг
TARGET_LEAGUES = {
    "PL": "Premier League",
    "PD": "La Liga",
    "BL1": "Bundesliga",
    "SA": "Serie A",
    "FL1": "Ligue 1",
    "CL": "Champions League"
}

def make_api_request(url, headers, retries=3):
    """Функция с повторными попытками при ошибке"""
    for attempt in range(retries):
        try:
            print(f"   Requesting... (Attempt {attempt + 1})")
            resp = requests.get(url, headers=headers)
            
            if resp.status_code == 200:
                return resp.json()
            elif resp.status_code == 429:
                print("   Rate limited! Waiting 30 seconds...")
                time.sleep(30)
            else:
                print(f"   Error {resp.status_code}: {resp.text}")
                print("   Waiting 15 seconds before retry...")
                time.sleep(15)
                
        except Exception as e:
            print(f"   Connection error: {e}")
            time.sleep(10)
            
    print("   FAILED after all retries.")
    return None

def get_or_create_team(db, team_data):
    if not team_data.get('name'): return None
    
    t_name = team_data.get('shortName') or team_data.get('name')
    # Обрезаем слишком длинные названия
    if len(t_name) > 30: t_name = t_name[:30]

    team = db.query(models.Team).filter_by(name=t_name).first()
    
    if not team:
        team = models.Team(
            name=t_name,
            logo_url=team_data.get('crest'),
            country="Europe"
        )
        db.add(team)
        db.commit()
        db.refresh(team)
        
        # Создаем фейковых игроков для красоты
        db.add(models.Player(name=f"Star of {t_name}", team_id=team.id, position="FWD"))
        db.add(models.Player(name=f"Captain of {t_name}", team_id=team.id, position="MID"))
        db.commit()
        
    return team

def generate_fake_scorers(db, match):
    # Если матч сыгран и есть голы, назначаем их случайным игрокам
    home_score = match.score_home or 0
    away_score = match.score_away or 0
    
    # Чтобы не дублировать, проверяем, есть ли уже события
    if db.query(models.MatchEvent).filter_by(match_id=match.id).count() > 0:
        return

    import random
    
    # Хозяева
    if home_score > 0:
        players = db.query(models.Player).filter_by(team_id=match.home_team_id).all()
        if players:
            for _ in range(home_score):
                db.add(models.MatchEvent(
                    match_id=match.id,
                    player_id=random.choice(players).id,
                    type="GOAL",
                    minute=random.randint(5, 90)
                ))
    
    # Гости
    if away_score > 0:
        players = db.query(models.Player).filter_by(team_id=match.away_team_id).all()
        if players:
            for _ in range(away_score):
                db.add(models.MatchEvent(
                    match_id=match.id,
                    player_id=random.choice(players).id,
                    type="GOAL",
                    minute=random.randint(5, 90)
                ))
    db.commit()

def fetch_data_from_api(db: Session):
    headers = {'X-Auth-Token': API_KEY}
    
    if "ВСТАВЬ" in API_KEY or len(API_KEY) < 10:
        print("!!! API KEY IS MISSING. Please edit app/initial_data.py !!!")
        return

    for code, name in TARGET_LEAGUES.items():
        print(f"--- Fetching {name} ({code}) ---")
        
        # 1. Создаем Турнир
        tournament = db.query(models.Tournament).filter_by(name=name).first()
        if not tournament:
            tournament = models.Tournament(
                name=name,
                country="Europe" if code == "CL" else "National",
                type="Cup" if code == "CL" else "League",
                current_season="2024/2025"
            )
            db.add(tournament)
            db.commit()
            db.refresh(tournament)

        # 2. Скачиваем Матчи
        # Делаем паузу перед запросом, чтобы не получить бан (Free tier: 10 req/min)
        time.sleep(10) 
        
        matches_json = make_api_request(f"{API_URL}/competitions/{code}/matches", headers)
        
        if matches_json:
            matches_data = matches_json.get('matches', [])
            print(f"   Found {len(matches_data)} matches. Saving to DB...")

            count = 0
            for m_json in matches_data:
                # Берем только сыгранные или запланированные
                status = m_json['status'] # SCHEDULED, TIMED, FINISHED, IN_PLAY
                
                # Создаем команды
                home_team = get_or_create_team(db, m_json['homeTeam'])
                away_team = get_or_create_team(db, m_json['awayTeam'])
                
                if home_team and away_team:
                    dt_str = m_json['utcDate'] 
                    dt = datetime.strptime(dt_str, "%Y-%m-%dT%H:%M:%SZ")
                    
                    # Проверяем дубликаты
                    exists = db.query(models.Match).filter_by(
                        tournament_id=tournament.id,
                        home_team_id=home_team.id, 
                        away_team_id=away_team.id
                    ).first()

                    if not exists:
                        match = models.Match(
                            date_time=dt,
                            tournament_id=tournament.id,
                            home_team_id=home_team.id,
                            away_team_id=away_team.id,
                            status=status,
                            round=m_json.get('matchday', 1),
                            score_home=m_json['score']['fullTime']['home'],
                            score_away=m_json['score']['fullTime']['away']
                        )
                        db.add(match)
                        db.commit()
                        db.refresh(match)
                        
                        if status == "FINISHED":
                            generate_fake_scorers(db, match)
                        
                        count += 1
            print(f"   Saved {count} new matches.")
        else:
            print(f"   Skipping {name} due to API error.")

def init_db():
    print("--- INITIALIZING DATABASE ---")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    try:
        # Admin
        if not db.query(models.User).filter_by(email="admin@futrat.com").first():
            user = models.User(
                email="admin@futrat.com", 
                username="Admin", 
                hashed_password=get_password_hash("admin")
            )
            db.add(user)
            db.commit()

        # ЗАПУСК
        fetch_data_from_api(db)
        
        print("--- DONE ---")

    except Exception as e:
        print(f"Global Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    init_db()
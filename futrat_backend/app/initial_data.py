import sys
import os
import requests
from datetime import datetime, timedelta
import random

sys.path.append(os.getcwd())

from sqlalchemy.orm import Session
from app.database import SessionLocal, engine, Base
from app import models
from app.security import get_password_hash

# --- НАСТРОЙКИ ---
USE_REAL_API = True  # Поставь True, если есть ключ
API_KEY = "008fa4d126b84c99aa88b8a0f8719e14" 
API_URL = "https://api.football-data.org/v4"

# Данные для симуляции (если API выключен)
SIMULATION_DATA = {
    "Premier League": ["Man City", "Arsenal", "Liverpool", "Aston Villa", "Tottenham", "Chelsea", "Man Utd", "West Ham", "Newcastle", "Brighton"],
    "La Liga": ["Real Madrid", "Barcelona", "Girona", "Atlético Madrid", "Athletic Club", "Real Sociedad", "Betis", "Valencia", "Sevilla", "Villarreal"],
    "Bundesliga": ["Bayer 04", "Bayern", "Stuttgart", "RB Leipzig", "Dortmund", "Frankfurt", "Hoffenheim", "Werder"],
    "Serie A": ["Inter", "Milan", "Juventus", "Bologna", "Atalanta", "Roma", "Lazio", "Napoli"],
    "Ligue 1": ["PSG", "Monaco", "Lille", "Brest", "Nice", "Lyon", "Lens", "Marseille"],
    "RPL": ["Zenit", "Krasnodar", "Dynamo", "Lokomotiv", "Spartak", "CSKA", "Rostov", "Rubin"]
}

def generate_matches_for_league(db, tournament, teams):
    """Генерация расписания (Round Robin)"""
    if len(teams) < 2: return
    
    # 1. Создаем даты туров (каждые выходные)
    start_date = datetime(2025, 8, 10, 15, 0)
    
    # Простая генерация: каждый с каждым 1 раз (для демо)
    for i in range(len(teams)):
        for j in range(i + 1, len(teams)):
            home = teams[i]
            away = teams[j]
            
            # Случайная дата в сезоне
            random_weeks = random.randint(0, 30)
            match_date = start_date + timedelta(weeks=random_weeks)
            
            # Статус
            status = "FINISHED" if match_date < datetime.now() else "SCHEDULED"
            score_h = random.randint(0, 4) if status == "FINISHED" else None
            score_a = random.randint(0, 4) if status == "FINISHED" else None
            
            m = models.Match(
                date_time=match_date,
                tournament_id=tournament.id,
                home_team_id=home.id,
                away_team_id=away.id,
                status=status,
                score_home=score_h,
                score_away=score_a
            )
            db.add(m)

def fetch_from_api(db):
    """Парсинг с реального API"""
    headers = {'X-Auth-Token': API_KEY}
    
    # Коды лиг в API football-data.org: PL, PD, BL1, SA, FL1, PPL, DED, CL
    competitions = {
        "PL": "Premier League",
        "PD": "La Liga",
        "BL1": "Bundesliga",
        "SA": "Serie A",
        "FL1": "Ligue 1",
        "CL": "Champions League"
    }
    
    for code, name in competitions.items():
        print(f"Fetching {name}...")
        # 1. Создаем турнир
        t = db.query(models.Tournament).filter_by(name=name).first()
        if not t:
            t = models.Tournament(name=name, type="League", current_season="2025", country="Europe")
            db.add(t)
            db.commit()
            db.refresh(t)
            
        # 2. Грузим команды
        try:
            resp = requests.get(f"{API_URL}/competitions/{code}/teams", headers=headers)
            if resp.status_code == 200:
                teams_data = resp.json().get('teams', [])
                for team_json in teams_data:
                    t_name = team_json.get('shortName') or team_json.get('name')
                    team = db.query(models.Team).filter_by(name=t_name).first()
                    if not team:
                        team = models.Team(name=t_name, logo_url=team_json.get('crest'), country="Europe")
                        db.add(team)
                db.commit()
            
            # 3. Грузим матчи
            resp_m = requests.get(f"{API_URL}/competitions/{code}/matches", headers=headers)
            if resp_m.status_code == 200:
                matches_data = resp_m.json().get('matches', [])
                for m_json in matches_data:
                    home_name = m_json['homeTeam']['shortName'] or m_json['homeTeam']['name']
                    away_name = m_json['awayTeam']['shortName'] or m_json['awayTeam']['name']
                    
                    h_team = db.query(models.Team).filter_by(name=home_name).first()
                    a_team = db.query(models.Team).filter_by(name=away_name).first()
                    
                    if h_team and a_team:
                        dt = datetime.strptime(m_json['utcDate'], "%Y-%m-%dT%H:%M:%SZ")
                        status = m_json['status'] # SCHEDULED, FINISHED
                        
                        m = models.Match(
                            date_time=dt,
                            tournament_id=t.id,
                            home_team_id=h_team.id,
                            away_team_id=a_team.id,
                            status=status,
                            score_home=m_json['score']['fullTime']['home'],
                            score_away=m_json['score']['fullTime']['away']
                        )
                        db.add(m)
                db.commit()
        except Exception as e:
            print(f"API Error for {name}: {e}")

def init_db():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    try:
        # Admin User
        if not db.query(models.User).filter_by(email="admin@futrat.com").first():
            user = models.User(
                email="admin@futrat.com",
                username="Admin",
                hashed_password=get_password_hash("admin")
            )
            db.add(user)

        if USE_REAL_API:
            fetch_from_api(db)
        else:
            # СИМУЛЯЦИЯ
            for league, teams in SIMULATION_DATA.items():
                t = db.query(models.Tournament).filter_by(name=league).first()
                if not t:
                    t = models.Tournament(name=league, type="League", current_season="2025/2026", country="Europe")
                    db.add(t)
                    db.flush()
                    
                    team_objs = []
                    for t_name in teams:
                        team = db.query(models.Team).filter_by(name=t_name).first()
                        if not team:
                            team = models.Team(name=t_name, country="Europe")
                            db.add(team)
                            db.flush()
                        team_objs.append(team)
                    
                    generate_matches_for_league(db, t, team_objs)
            db.commit()

        print("Database initialized!")

    except Exception as e:
        print(f"Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    init_db()
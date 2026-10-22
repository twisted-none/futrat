from fastapi import FastAPI
from contextlib import asynccontextmanager
from datetime import datetime, timezone
import logging
from apscheduler.schedulers.background import BackgroundScheduler

from app.database import engine, Base
from app import models
from app.routers import auth, data, predictions, users
from app.routers import forecasts as forecast_routes
from app.routers import profiles
from app.initial_data import init_db, update_all_data, update_live_data, update_live_feed
from app.match_sync import start_sync, stop_sync
from app.player_history import update_player_data
from app.user_migration import ensure_user_schema
from app.auth_errors import validation_error
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

logging.basicConfig(level=logging.INFO)
scheduler = BackgroundScheduler()

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Startup: Initializing database...")
    Base.metadata.create_all(bind=engine)
    ensure_user_schema(engine)

    init_db()

    # The API starts immediately; season backfill runs in a background worker.
    start_sync()
    scheduler.add_job(update_live_data, 'interval', minutes=15,
                      id='live-sync', coalesce=True, max_instances=1)
    scheduler.add_job(update_live_feed, 'interval', seconds=60,
                      id='live-feed', next_run_time=datetime.now(timezone.utc),
                      coalesce=True, max_instances=1)
    scheduler.add_job(update_all_data, 'interval', hours=6,
                      id='season-sync', next_run_time=datetime.now(timezone.utc),
                      coalesce=True, max_instances=1)
    scheduler.add_job(update_player_data,'interval',minutes=1,
                      id='player-sync',coalesce=True,max_instances=1)
    scheduler.start()

    yield

    print("Shutdown: App stopping...")
    stop_sync()
    scheduler.shutdown()

app = FastAPI(
    title="Futrat API",
    description="Backend for Futrat football application",
    version="1.0.0",
    lifespan=lifespan
)
app.add_exception_handler(RequestValidationError, validation_error)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(data.router)
app.include_router(predictions.router)
app.include_router(forecast_routes.router)
app.include_router(profiles.router)

@app.get("/")
def root():
    return {"message": "Futrat LIVE API Running"}


@app.get("/health/ready", include_in_schema=False)
def readiness():
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))
    except SQLAlchemyError:
        return JSONResponse(status_code=503, content={"status": "unavailable"})
    return {"status": "ready"}

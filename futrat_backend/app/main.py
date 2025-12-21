from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.database import engine, Base
# Импортируем новый роутер users
from app.routers import auth, data, predictions, users 
from app.initial_data import init_db

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Startup: Initializing database...")
    Base.metadata.create_all(bind=engine)
    init_db()
    yield
    print("Shutdown: App stopping...")

app = FastAPI(
    title="Futrat API",
    description="Backend for Futrat football application",
    version="1.0.0",
    lifespan=lifespan
)

app.include_router(auth.router)
app.include_router(users.router) # <-- ДОБАВИЛ ЗДЕСЬ
app.include_router(data.router)
app.include_router(predictions.router)

@app.get("/")
def root():
    return {"message": "Welcome to Futrat API. Check /docs for Swagger UI."}
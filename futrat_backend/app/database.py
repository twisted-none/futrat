from sqlalchemy import create_engine
from sqlalchemy.engine import make_url
from sqlalchemy.orm import sessionmaker, declarative_base
from app.config import settings

# Создаем движок
database_url = make_url(settings.DATABASE_URL)
# Keep existing postgresql:// configurations on the installed psycopg2 driver.
if database_url.drivername == "postgresql":
    database_url = database_url.set(drivername="postgresql+psycopg2")
options = {"pool_pre_ping": True}
if settings.APP_ENV == "production":
    # Bound one API process + scheduler to ten connections on the shared server.
    options.update(pool_size=5, max_overflow=5, pool_timeout=5,
                   connect_args={"connect_timeout": 5})
engine = create_engine(database_url, **options)

# Фабрика сессий
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# Dependency (функция, которая выдает сессию базы данных)
def get_db():
    db = SessionLocal()
    try:
        yield db
    except Exception:
        # Если произошла ошибка, откатываем транзакцию, чтобы БД не зависла
        db.rollback()
        raise
    finally:
        # Всегда закрываем соединение
        db.close()

from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import SecretStr, Field, model_validator
from sqlalchemy.engine import make_url
from typing import Literal

class Settings(BaseSettings):
    APP_ENV: Literal["development", "test", "production"] = "development"
    DATABASE_URL: str
    SECRET_KEY: str
    ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(gt=0)
    GOAL_API_KEY: SecretStr | None = None
    # Reserve 100 of the free plan's 1,000 calls for manual diagnostics.
    GOAL_API_DAILY_LIMIT: int = Field(default=900, ge=1, le=1000)

    model_config = SettingsConfigDict(env_file=".env", hide_input_in_errors=True)

    @model_validator(mode="after")
    def validate_production(self):
        if self.APP_ENV != "production":
            return self
        if (len(self.SECRET_KEY) < 32
                or any(marker in self.SECRET_KEY.lower()
                       for marker in ("replace", "change", "example", "fake"))):
            raise ValueError("Production SECRET_KEY must be generated and at least 32 characters")
        if self.ALGORITHM != "HS256":
            raise ValueError("Production ALGORITHM must be HS256")
        try:
            url = make_url(self.DATABASE_URL)
        except Exception:
            raise ValueError("Invalid production DATABASE_URL") from None
        if (url.get_backend_name() != "postgresql"
                or url.database != "futrat" or url.username != "futrat"):
            raise ValueError("Production requires PostgreSQL database futrat and role futrat")
        if (not url.password or any(marker in url.password.lower()
                                    for marker in ("replace", "change_me", "example"))):
            raise ValueError("Production database password must be configured")
        return self

settings = Settings()

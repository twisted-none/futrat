"""Idempotent user migration, run before serving traffic or starting workers."""
from sqlalchemy import inspect, text
from app.credentials import nickname_key


def ensure_user_schema(engine):
    with engine.begin() as connection:
        if connection.dialect.name == "postgresql":
            connection.execute(text("SELECT pg_advisory_xact_lock(728613416)"))
        columns = {column["name"]: column for column in inspect(connection).get_columns("users")}
        rows = connection.execute(text("SELECT id, username FROM users ORDER BY id")).all()
        keys = {}
        for user_id, username in rows:
            key = nickname_key(username)
            if key in keys:
                # Refuse rather than rename/merge existing accounts automatically.
                raise RuntimeError(f"Existing nickname collision: user IDs {keys[key]}, {user_id}")
            keys[key] = user_id
        if "username_key" not in columns:
            connection.execute(text("ALTER TABLE users ADD COLUMN username_key VARCHAR"))
        if connection.dialect.name == "postgresql" and not columns["email"]["nullable"]:
            connection.execute(text("ALTER TABLE users ALTER COLUMN email DROP NOT NULL"))
        elif connection.dialect.name != "postgresql" and not columns["email"]["nullable"]:
            raise RuntimeError("Legacy email nullability migration requires PostgreSQL")
        for key, user_id in keys.items():
            connection.execute(text("UPDATE users SET username_key=:key WHERE id=:id AND (username_key IS NULL OR username_key<>:key)"),
                               {"key": key, "id": user_id})
        connection.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS ix_users_username_key ON users (username_key)"))
        if connection.dialect.name == "postgresql":
            connection.execute(text("ALTER TABLE users ALTER COLUMN username_key SET NOT NULL"))

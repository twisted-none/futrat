"""Preserve the provider clock; never estimate it from kickoff time."""
from datetime import timedelta
import re
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert

from app import models
from app.match_sync import utc, utc_now


def minute(value):
    value = str(value or "").strip().replace("'", "").replace("′", "")
    return value if re.fullmatch(r"\d{1,3}(?:\+\d{0,2})?", value) else None


def write(db, game, clock, phase, source, observed=None, *, fill_missing=False):
    observed = utc(observed) if observed else utc_now()
    if game.id is None:
        db.flush()
    insert = pg_insert if db.get_bind().dialect.name == "postgresql" else sqlite_insert
    values = dict(clock=clock, phase=phase, source=source, updated_at=observed)
    db.execute(insert(models.MatchLiveState).values(match_id=game.id, **values).on_conflict_do_update(
        index_elements=["match_id"], set_=values,
        where=None if fill_missing else models.MatchLiveState.updated_at <= observed,
    ))
    db.expire(game, ["live_state"])


def espn(db, game, status):
    info = status.get("type") or {}
    name, state = info.get("name"), info.get("state")
    if name in {"STATUS_HALFTIME", "STATUS_HALF_TIME"} or info.get("shortDetail") == "HT":
        phase = "HALF_TIME"
    elif state == "post":
        phase = "FINISHED"
    elif state == "pre":
        phase = "NOT_STARTED"
    elif "PENALT" in (name or "") or "SHOOTOUT" in (name or ""):
        phase = "PENALTIES"
    else:
        phase = {1: "FIRST_HALF", 2: "SECOND_HALF", 3: "EXTRA_TIME", 4: "EXTRA_TIME"}.get(status.get("period"))
    clock = minute(status.get("displayClock")) if state == "in" and phase != "HALF_TIME" else None
    write(db, game, clock, phase, "ESPN")
    return phase == "HALF_TIME" or clock is not None or state in {"post", "pre"}


def goal(db, game, row, *, fill_missing=False):
    phase = row.get("matchPeriod")
    if row.get("matchStatus") == "HALF_TIME":
        phase = "HALF_TIME"
    observed = row.get("clockUpdatedAt")
    clock = minute(row.get("matchMinute")) or minute(row.get("matchElapsed"))
    write(db, game, clock, phase, "GOAL", observed, fill_missing=fill_missing)


def prefer_espn(db, game):
    row = db.get(models.MatchLiveState, game.id)
    return bool(row and (row.source == "ESPN" or row.clock or row.phase == "HALF_TIME")
                and utc_now() - utc(row.updated_at) < timedelta(seconds=90))

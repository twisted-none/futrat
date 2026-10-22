"""Live is a display classification, never an inferred final result."""

from datetime import datetime, timedelta, timezone
import re

LIVE_WINDOW = timedelta(hours=6)
LIVE_STATUSES = frozenset({
    "IN_PLAY", "LIVE", "HALF_TIME", "HALFTIME", "HT", "EXTRA_TIME", "ET",
    "PENALTIES", "PENALTY_SHOOTOUT",
})
_CLOCK = re.compile(r"(?:\d{1,3}(?:\+\d{1,2})?'|\d{1,3}'\+\d{1,2}'?)")


def is_live_status(status):
    return status in LIVE_STATUSES or _CLOCK.fullmatch(status) is not None


def is_live_match(status, kickoff, *, now=None):
    now = now or datetime.now(timezone.utc)
    # SQLite and legacy rows can omit the timezone; persisted kickoff is UTC.
    if kickoff.tzinfo is None:
        kickoff = kickoff.replace(tzinfo=timezone.utc)
    return is_live_status(status) and timedelta(0) <= now - kickoff <= LIVE_WINDOW

# Minute live updates

## Provider priority

ESPN is the primary live source for every supported tournament, including tournaments whose season calendar came from GOAL. Fixtures match by an existing ESPN ID; otherwise a unique normalized home/away pair in the same competition and within five minutes of kickoff is required. Ambiguous matches are rejected.

GOAL is called only when ESPN has no matching fixture or lacks clock/score information, and only for the three GOAL cup integrations. Missing fields are filled without replacing known ESPN scores. Requests are batched per league/day, cached for 55 seconds and use the existing shared daily budget/cooldown. The free-plan cap remains enforced. A cached bulk GOAL season response cannot replace a fresh live observation.

## Storage and API

`match_live_states` is an additive table: match ID, clock, phase, source, observation timestamp. It is created through the existing Base.metadata startup path; existing match IDs, ratings, predictions and history remain intact. Atomic clock upserts protect concurrent calendar/live imports.

`clock`, `phase` and `live_updated_at` are optional additions to MatchResponse. `GET /api/matches/updates?ids=1&ids=2` returns compact patches for matches in the last six hours / next fifteen minutes and up to 500 explicitly requested current-season IDs. Ended games are included so the client receives final scores; requested IDs cover rescheduling outside the time window. No lineups, events or team objects are transferred by this endpoint.

## Refresh

A dedicated 60-second job uses a separate process/database lock from season import, with four bounded ESPN HTTP workers. Only tournaments/dates with playing or soon-starting games are fetched. Confirmed finals with missing scores remain retryable; old live scores must not settle a prediction. Calendar maintenance runs every fifteen minutes and full season import every six hours. The short HTTP endpoint reads the database; multiple phones do not multiply provider requests.

The app polls patches every 60 seconds, pauses the timer in background, and refreshes immediately on resume. It preserves the selected round and collapsed leagues. Known live and nearby scheduled IDs remain tracked across reschedules. Full season data is reloaded only if an unfamiliar fixture appears in patches.

## Display

Cards in leagues, Today and Live show `47′ · LIVE`, stoppage time such as `90+3′ · LIVE`, or `Перерыв`. Kickoff remains for unstarted games. ESPN halftime type overrides its last first-half clock. GOAL matchMinute/matchPeriod/clockUpdatedAt are used; matchLive is a legacy boolean, not a minute. Unknown/stale clocks are not advanced from kickoff: after three minutes without a clock observation the label falls back to LIVE. The existing six-hour stale-live protection remains.

Official source contract: https://goal-api.com/openapi.json. ESPN scoreboard status fields were verified against its public current feed.

## Verification

101 tests passed in Docker/Python 3.15/PostgreSQL, including provider priority, fallback, halftime, stoppage time, independent calendar/live locks, compact final patches, score completeness and cache ordering. 43 Flutter tests passed, including the 60-second timer, pause/resume, round/group retention and all three list types. Actual live API snapshots showed minute advancement. Visuals in `.tools/accent-live-previews/` use bundled IBM Plex Sans in both themes.

On 18 October 2026 the installed APK was checked on MT2111 over Wi-Fi with no ADB reverse: nine inline colors, immediate selection, Today advancing from 65′ to 67′ without navigation, and a real halftime label in Live. The independent server and client polls can add almost two minutes of display latency, in addition to upstream delay.

# Daily public cache and permanent badges

## Approved behavior

Approved 25 November 2026: keep the current fixture/tournament list on the device
for one Moscow calendar day. Expire at 00:00 MSK, immediately while active or on
the next launch/resume. Continue fetching live scores, clocks and phases every
60 seconds. Keep downloaded team/tournament badges across days and logout.

## Implementation

- APK 2.3.0+11, API `https://176.108.255.248`; no backend migration required.
- Public JSON snapshot in application support, isolated by backend origin.
  Encoding/decoding runs outside the UI isolate. Writes are serialized and use a
  temporary file followed by rename; responses from yesterday cannot populate
  today's cache. Invalid/missing/unwritable storage falls back to network data.
- A valid snapshot skips full fixture/tournament requests for the same day.
  Immediate and subsequent minute score patches also update the saved snapshot.
  Discovery of an unknown fixture may refresh the full list to include it.
- Midnight timer and resume checks expire old files and reload today's data.
  Background timers stop while inactive. A failed load is retried on the next
  foreground minute or resume. Selection and chosen round survive live patches.
- Badge prefetch covers all tournament and fixture-team artwork in the loaded
  season plus favorite teams/tournaments. Other artwork uses the same cache when
  encountered. URLs are deduplicated; three prefetch workers share a four-download
  limit with visible badges. Files use SHA-256 URL names and do not expire.
- Badges use an unauthenticated transport to the original image first and the
  existing image proxy only as fallback, bounded downloads, PNG validation and
  actual decoding before permanent storage. Decodable original JPEG/WebP images
  are normalized to PNG; invalid/oversized original responses also use fallback.
  Failed downloads retry after a minute on a later prefetch/request; invalid
  local images are invalidated. Already downloaded files work without network.
- Network profile validation no longer blocks startup. Only the saved account
  is restored before rendering; normal server verification continues in the
  background and protected endpoints still enforce session validity.
- No credentials, personal favorites or leaderboard data are written to the
  public snapshot. OS app-data clearing/uninstallation removes these files;
  ordinary logout and day changes do not delete badges.

## Verification

- Full Flutter suite: 129 tests passed, including offline cold start, concurrent
  badge requests, permanent badge reuse, actual offline badge rendering and dark
  contrast, invalid/truncated images, disk failure, live patch persistence,
  active midnight rollover and resume after midnight.
- Analyzer: 60 existing informational diagnostics; no errors or warnings.
- Code graph refreshed: 1876 nodes, 3386 edges; semantic documents not indexed.
- Existing SQL-parser and Linux-header extraction limitations remain unchanged.
- APK installed with `adb install -r` on the connected device; package reports
  2.3.0 / versionCode 11. The app created today's public snapshot and 151 permanent
  badge files during the post-install check. No unhandled Flutter/plugin errors
  were found in the process log summary. The phone was locked, so final manual
  screen inspection was unavailable.
- Readiness, tournaments and matches on the production API returned HTTP 200.

## Badge-loading correction (2.3.1+12)

- Both original Russian tournament badge URLs responded HTTP 200, while the
  proxy requests returned HTTP 403. The previous proxy-only loader had no direct
  fallback. Prefer original images to remove that dependency.
- Regression checks cover both tournament URLs, original success without proxy
  requests, HTTP 403, invalid image content, oversized responses and failure of
  both sources without retaining an invalid cache entry.
- Full Flutter suite after correction: 135 tests passed. Code graph refreshed.

## Russian club correction (2.3.2+13)

The user clarified that the missing badges belong to clubs, not the two
tournaments. Production data lacked URLs for 9/16 RPL and 102/102 Russian Cup
teams. Existing importers did not fill artwork on existing club rows.

The backend now backfills from the free ESPN Russian team catalog before GOAL,
uses the paginated GOAL team catalog for remaining missing Cup artwork, and
fills missing badges on repeated fixture imports. IDs and user links remain
unchanged. See `futrat_backend/deploy/CLUB_BADGES.md` for deployment.

The app refreshes only missing badge metadata and saves it into today's local
snapshot; a backend deployment does not require deleting cached fixtures.

Verification: 137 Flutter tests passed; analyzer reports 60 existing info items
and no errors/warnings. The full isolated backend run passed 149 tests with two
PostgreSQL-only skips; the final 11 targeted badge tests, including two added
GOAL catalog-failure cases, also passed. Windows denied pytest's default temp
folder, so the full run used a fresh temporary directory under `.tools`.

APK 2.3.2+13 was installed and launched on the connected phone. The backend
changes are prepared locally and require Deploy Desk deployment; no server
database was modified. Code graph refreshed to 1924 nodes and 3512 edges.

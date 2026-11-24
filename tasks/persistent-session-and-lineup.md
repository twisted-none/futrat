# Persistent session and confirmed lineup layout

## Scope

- Approved 24 November 2026: remove forced sign-out by time. Keep finite access
  JWTs with a revocable device session that can renew them without a password.
- Separately approved: fix player placement, preserve goalkeeper-at-bottom
  orientation, and show a list when exact roles cannot be confirmed.
- Installation is explicitly deferred by the user; prepare the APK only.
- Proposed but awaiting approval: one daily public fixture/tournament snapshot
  expiring at Moscow midnight and permanent background-prefetched team/league
  badge files. No daily/disk-badge cache implementation has been changed yet.

## Implemented

- Backend: additive `auth_sessions` table, hashed random device keys, refresh
  and logout routes, immediate rejection of revoked session-bound JWTs,
  configured access lifetime, validation that never echoes session keys.
- Flutter: secure persistent device key, one shared in-flight refresh, one retry
  per rejected request, cache binding updated after token renewal, generation
  guards and ordered credential writes. Network/5xx failures retain the session.
- Lineups: ESPN `formationPlace` was incorrectly interpreted as row-major order.
  Confirmed this against the actual public ESPN summary and Futrat match 604:
  Solanke=9 is a forward, Williams-Barnett=11 is an attacking midfielder on the
  left, Senesi=6 is a center-left defender. Layout now uses detailed match roles
  and left/right information; equal-role ambiguities never pick arbitrary names.
- GOAL's public schema only exposes broad position groups. Where those do not
  establish a reliable full layout, the list fallback remains available.
- The first APK is 2.2.0+10, API https://176.108.255.248. Permanent sign-in requires
  uploading/rebuilding the Backend through Deploy Desk, then signing in once.
  The public server was checked and does not yet have `/auth/refresh`.

## Sources

- https://site.api.espn.com/apis/site/v2/sports/soccer/eng.1/summary?event=401878754
- https://176.108.255.248/api/matches/604
- https://goal-api.com/openapi.json (`LineupEntry`, `PlayerPosition`)

## Verification and deployment

- Flutter: 109 tests passed; analyzer returns 60 existing info diagnostics and no
  errors or warnings. Tests verify actual rendered player coordinates and player
  action/rating flows in both list and field modes.
- Backend: the old exact two-field token schema tests were updated for the
  approved additional fields. The newly added validation-leak test first failed,
  then passed after refresh/logout were added to credential sanitization.
- Full backend suite: 140 passed, 2 PostgreSQL-specific checks skipped in the
  isolated SQLite run. The API contract, session validation and new logout/refresh
  behavior passed. No production database was modified.
- Final review added a readable session-revocation message; all 30 affected
  Flutter auth/refresh tests passed after that change. APK was rebuilt afterward.
- `deploy/PERSISTENT_SESSIONS.md` includes rollout steps and the security review.
  Reachable certifi TLS trust advisory fixed at 2026.10.19; both hashed locks were
  regenerated with uv without source builds. Other advisory matches were assessed
  for reachability and documented with a follow-up review date.
- Native Dart pub metadata audit: 53 packages checked, zero current versions
  affected by known advisories. No Dart dependencies were changed for this stage.
- Final APK build completed successfully. Code graph refreshed after the review
  fixes: 1766 nodes, 3228 edges. Semantic document indexing was not run.

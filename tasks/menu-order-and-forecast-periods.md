# Tournament menu and forecast update

## Approved scope

- Group the left menu by country; national-team tournaments share «Сборные», UEFA club tournaments share «Еврокубки».
- Split favorite and other tournaments into independent sections, each grouped by country. Mixed countries appear once per section, with different leagues.
- Hold for 1500 ms to drag a country group within its section or a league within its country and section. Preserve preferences on this device separately for each account and guest.
- Choosing/changing/cancelling a forecast preserves list position and filters; keep quota authoritative on the server.
- Ranking periods begin October 2026, retain all-time and previous months, automatically add/select the new Moscow month while open or on resume. Historical forecasts remain in the database.

## Implementation

- `core/tournament_menu.dart`: classification uses stable provider codes before country labels (several leagues still arrive with country Global); national UEFA competitions are separated from club cups.
- `providers/tournament_menu_preferences.dart`: saved group/league orders and collapsed groups, queued secure-storage writes, separate account/guest keys.
- `widgets/tournament_menu.dart`: grouped drawer, authenticated favorite actions, drag boundaries, 1.5-second gesture, edge scrolling during drag and accessibility move actions.
- `screens/home_screen.dart`: delegates drawer to the new component.
- `screens/forecasts_screen.dart`: background refresh after mutations retains the existing ListView; server still supplies predictions and quota. Moscow month timer and resume check update the period; the selector no longer invents months before launch or drops months older than twelve months.
- Version 2.1.0+5. Backend and API contract require no update for this feature.

## Verification

- Menu grouping, country/league dragging, favorite boundaries, saved preferences and account separation.
- Choice/change/cancel retain a scroll offset over 500 px during a delayed request and after completion.
- October-to-November transition at 21:00 UTC, period update after resume and preservation of a manual past-period selection within the same month.
- Narrow 320 px layout with 1.4 text scale in both themes.
- All 64 Flutter tests passed with API_BASE_URL=https://176.108.255.248. Static analysis: no errors/warnings, 61 existing info messages; no new diagnostics in the new components.
- APK 2.1.0+5 built successfully and package/version checked with aapt. Server readiness and 31 tournaments with provider codes verified over HTTPS.
- Review fixed a boundary race by using a single timestamp when scheduling the next Moscow month.
- Code graph refreshed: 1649 nodes, 3015 edges; semantic document refresh was not run. Existing unsupported SQL/header extraction warnings remain unrelated to these Dart changes.
- APK 2.1.0 (versionCode 5) installed with adb install -r on f03f9967 and launched. Actual drawer screenshot inspected: grouped national tournaments and country cards render correctly with server data.

## Drag handle correction (2026-10-23)

- Removed the group-header drag tooltip: its long-press recognizer won the gesture before the 1500 ms draggable delay, preventing dragging when the user held the icon.
- Regression tests reproduced this failure on the actual icon in both favorite and other country groups before the fix. They now verify dragging, the delay, favorite boundaries, collapse state and absence of the header tooltip.
- All 65 Flutter tests pass. Static analysis retains the same 61 existing info diagnostics, with no errors or warnings.
- Version 2.1.1+6; public API address retained. Code graph refreshed; existing unrelated SQL/header extraction warnings remain.
- APK installed successfully on f03f9967 with user data preserved; package inspection confirms version 2.1.1 / versionCode 6, and the application was launched. Drag behavior was verified in widget tests; no physical touch gesture is claimed.

## Full-width country header interaction (2026-10-23)

- The country header now has an explicit full-width touch surface: an opaque draggable receives holds throughout the row, and the outer InkWell handles short taps across the same area. ListTile no longer owns the country toggle separately.
- Retained the 1500 ms delay, favorite boundaries, saved ordering and collapse state. Dropping a country does not trigger its tap action.
- Added seven position-based tests for text, empty space, padding and all four edges. They exercise opening/closing, the delay and a complete drag/drop. The prior implementation also passed these synthetic position tests; this change makes the intended touch surface explicit rather than claiming a reproduced additional gesture failure.
- All 72 Flutter tests pass; static analysis retains 61 existing info diagnostics and no errors/warnings. Version 2.1.2+7; code graph refreshed (1650 nodes, 3016 edges).
- Debug APK built successfully with the public API URL and installed on f03f9967 after the phone was connected; package inspection confirms 2.1.2 / versionCode 7 and the application was launched.
- Verified on the actual phone: a short tap in the empty middle of Spain's header opens/closes its leagues; a 1.7-second hold at that same horizontal position followed by dragging moves Spain above England. UI hierarchy confirmed the changed order and collapsed state after dropping. Restored the user's initial order using the reverse drag and removed the temporary device XML.

## One-second hold and player actions (2026-10-27)

- Approved: country/league dragging after one second, prevent accidental Drawer dismissal while holding/moving a row, show statistics/rating choices for player taps on both field and list layouts.
- Reproduced the Drawer conflict in a real Scaffold/Drawer widget test: horizontal movement before the delayed drag closed the menu. Movable rows now consume that horizontal gesture; vertical scrolling remains functional. After the one-second delay, the draggable owns the gesture. Outside taps still dismiss the menu.
- Player action sheet routes to the existing player profile or rating picker. Missing profiles, unfinished matches and non-participating players have explanatory disabled choices. Ratings still require authentication and use lineup IDs.
- All 82 Flutter tests pass, including actual match-screen rating submission/authentication flows and one-second timing across the header. Static analysis retains the baseline 61 info diagnostics, no errors/warnings. Version 2.1.3+8. Code graph refreshed (1667 nodes, 3055 edges).
- Additional reported issue: startup `AuthProvider.checkAuth` calls logout on every profile-check failure, including network/server errors. Proposed fix (retain secure token/profile on transient failures, clear only for logout/invalid token) is awaiting separate approval; authentication code is unchanged in this build.
- APK installed on f03f9967 and launched; installed package confirms version 2.1.3 / versionCode 8. On-device input checks verified that a horizontal move after a 0.4-second hold leaves the Drawer open and a 1.1-second hold permits moving Spain above England. The reverse drag restored the initial order. Player action/rating flows were verified with isolated widget tests; no production rating was submitted.

## Session restoration correction (2026-10-27)

- User separately approved preserving token/profile between launches and temporary network failures, clearing only on explicit logout or a profile-check 401.
- Reproduced offline cold-start logout in a failing test. AuthProvider now uses the same secure storage as ApiClient, saves a token-bound minimal profile (ID/nickname), restores it before the server check and retains it on network, 5xx, 403 and throttling failures. No password is persisted; server token expiry/verification remain unchanged.
- Storage writes are ordered and asynchronous work is revision-guarded. Corrupt/mismatched caches cannot authenticate; old tokens gain a profile cache after an online check. Explicit logout removes both keys, including when profile requests are pending.
- Review reproduced and fixed a further race: a failed new login could otherwise cancel queued logout cleanup. Cleanup now always executes before later login writes.
- All 97 Flutter tests pass (15 session tests added). Static analysis: 60 existing info diagnostics, no errors/warnings. Native Dart pub metadata check covered 53 packages with zero current versions affected by known advisories. No dependency versions changed.
- Version 2.1.4+9; code graph refreshed (1685 nodes, 3084 edges). Previously deleted tokens cannot be recovered; an already logged-out user needs to sign in once to establish the saved session.
- APK installed successfully on f03f9967 with data preserved; installed package confirms 2.1.4 / versionCode 9 and the app was launched. The device exposed only System UI during the attempted profile inspection, so an authenticated cold restart was verified in isolated tests rather than claimed on-device. No device token or password was read, and the temporary device XML was removed.

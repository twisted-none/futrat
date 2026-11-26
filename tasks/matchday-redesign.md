# Matchday direction A

## Approved scope

Approved 26 November 2026: implement direction A from the UI audit, including
the mandatory screen/component plan and horizontal scrolling for detailed
standings and the nine-color palette on narrow devices. The user explicitly
requested loading skeletons. No optional sticky headers, haptics or separate
tablet layout were approved. Preserve prediction rules, provider data, guest
access, ratings, identities, favorite ordering and one-second menu dragging.

## Implementation

- Theme: IBM Plex Sans retained, two neutral themes and all nine accents,
  centralized layout tokens, text hierarchy, tabular figures and meaningful
  live/error colors. Thin borders remain on major panels.
- Common static skeletons for fixtures, standings and profiles. They contain
  no fake data or continuous animation and expose one accessible loading label.
- Separate retryable errors and empty states. Cached fixture, standings and
  profile content remains visible on refresh. Late standings responses cannot
  replace a newer selected tournament.
- Shared match summary for today/live feeds, tournament rounds, club/player
  history and prediction history. Match taps, independent stars and explicit
  club-profile links keep their original purposes. Existing club translations
  remain in use.
- Tables: readable row heights and numbers, fixed club column, horizontally
  scrollable complete statistics and non-color-only form indicators.
- Main navigation retains branch state, list scroll and tournament tabs.
  Existing URLs remain unchanged. Drawer grouping/drag rules are retained;
  only the header, colors and spacing changed.
- Match: compact outlined team blocks, large score, localized status/date,
  adaptive tabs, clearer lineup labels, original field orientation and user
  rating flow. Missing details have skeleton/retry states; existing details
  remain available on refresh failure.
- Forecasts: adaptive date/quota/filter controls, readable club rows, unchanged
  selection and cancellation, retained scrolling and month behavior. Larger
  text uses scrollable long tabs; ordinary league tabs remain equal-width.
  Ranking names and points no longer compete in one narrow row.
- Favorites: shared cards, neutral starred removal buttons, readable empty and
  error states, guest sign-in action and existing profile/league navigation.
- Club/player: compact identity header, same season/timeline/filters, one card
  per match instead of nested cards, user ratings without source labels.
- Profile/auth: compact account section, 48x48 color targets in one scrollable
  row, two-field form, autofill hints, keyboard submission, stable pending button
  and the original validation/session flow.
- Russian Material/Cupertino SDK localizations and platform-aware back button.
  No backend API, database or scoring rules changed for this redesign.

## Verification

Regression coverage includes skeleton-to-error-to-retry, keeping saved games
visible during refresh, pinned standings during a real horizontal gesture,
320-wide layouts with 200% text, late standings responses, keyboard submission,
and branch scroll/tab retention. Existing functional regressions remain enabled.

Visual comparison uses the actual Flutter widgets in an external rendering
workspace with fixtures, both themes, narrow layouts, keyboard insets, long
names, error and empty states. These are not physical-device checks. The user
asked to proceed without a phone; iOS compilation/device verification requires
macOS and Apple tooling and is not claimed here.

The previously staged removal of `futrat_backend/.env` from Git is preserved.
Its contents were not inspected. No commit or remote deployment is performed.

## Final checks

- Full Flutter regression run: 146 passed. After final navigation/lifecycle
  refinements, all 26 affected navigation/layout/loading tests passed again.
- Analyzer: no errors or warnings, 53 informational diagnostics remaining
  (existing deprecations/style items). No diagnostic suppression was added.
- 58 actual-widget snapshots produced in the external audit workspace: both
  themes, all nine accents, 320/390 widths, enlarged text, keyboard insets,
  loading/empty/error states and long names. No Flutter layout exceptions were
  captured. Main screens and difficult states were visually inspected.
- Review fixed large-text tab/nav wrapping, preserved the club column during
  horizontal table gestures, kept already-loaded match details visible while
  offline, and added retry states and mounted/generation guards.
- APK built successfully for `https://176.108.255.248`: `ru.dema.futrat`,
  versionName `2.4.0`, versionCode `14`. Installation was not performed.
- Code graph refreshed: 2016 nodes, 3663 edges, 125 communities. Existing SQL
  parser/Linux header extraction limitations remain; semantic documents were
  not reindexed. `git diff --check` passed.

## Changed files

Paths below are relative to `futrat_mobile/` unless noted.

- Theme/navigation/state: `lib/core/app_theme.dart`, `lib/main.dart`,
  `lib/providers/data_provider.dart`.
- Screens: `lib/screens/home_screen.dart`, `main_scaffold.dart`,
  `match_detail_screen.dart`, `forecasts_screen.dart`, `favorites_screen.dart`,
  `team_screen.dart`, `player_screen.dart`, `profile_screen.dart`,
  `auth_screen.dart` (all under `lib/screens/`).
- Common widgets: `lib/widgets/app_states.dart` (new), `match_summary.dart`
  (new), `standings_table.dart` (new), `grouped_matches_list.dart`,
  `match_tile.dart`, `lineup_view.dart`, `tournament_menu.dart` (all under
  `lib/widgets/`).
- SDK Russian localization/version: `pubspec.yaml`, `pubspec.lock`.
- Tests: `test/matchday_design_test.dart` (new), `widget_test.dart`,
  `auth_validation_test.dart`, `profiles_test.dart` (all under `test/`).
- Project record: `tasks/matchday-redesign.md` at repository root; generated
  graph report/JSON/HTML, manifest and extraction caches under `graphify-out/`.

APK: `futrat_mobile/build/app/outputs/flutter-apk/app-debug.apk` at repository
root. Visual comparison artifacts live outside the project in the dedicated
`futrat-design-audit/matchday-after/` rendering workspace.

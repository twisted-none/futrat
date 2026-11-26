# Graph Report - futrat  (2026-11-26)

## Corpus Check
- 173 files · ~101,619 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 67 file(s) not represented in the graph (top: (none) 14, .xml 9, .xcconfig 8)

## Summary
- 2016 nodes · 3663 edges · 125 communities (96 shown, 29 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 62 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `05cd69eb`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- all_models.dart
- FlutterWindow
- home_screen.dart
- data_provider.dart
- .application
- auth.py
- my_application.cc
- utils.cpp
- Match navigation and typography
- match_detail_screen.dart
- app/forecasts.py
- player_actions_test.dart
- app_theme.dart
- football_logo.dart
- match_sync.py
- lineups.py
- theme_provider.dart
- main.dart
- Анализ Предметной Области (ПО) Futrat
- badge_cache.dart
- test_team_badges.py
- manifest.json
- Predictions, favorites and player profiles
- futrat_mobile
- widget_test.dart
- LaunchImage.imageset/README.md
- test_runtime.py
- Phone connection over LAN
- constants.dart
- Implementation checklist
- FlutterActivity
- widgets/tournament_menu.dart
- test_live_feed.py
- match_navigation_test.dart
- accent-live-feed.md
- forecasts_screen.dart
- lineup_view.dart
- data.py
- team_screen.dart
- Deployment: Ubuntu, existing Caddy and PostgreSQL
- api_client.dart
- data_cache_provider_test.dart
- forecasts_test.dart
- auth_provider.dart
- auth_session_test.dart
- models.py
- package:flutter/material.dart
- match_status.dart
- match_summary.dart
- test_production.py
- profiles_test.dart
- conftest.py
- package:flutter_secure_storage/flutter_secure_storage.dart
- branding/README.md
- core/tournament_menu.dart
- grouped_matches_list.dart
- test_api.py
- app_states.dart
- Appearance
- appearance-plan.md
- football_logo_test.dart
- build
- auth_screen.dart
- tournament_menu_preferences.dart
- Season and match interface
- test_season_sync.py
- fonts/README.md
- match-navigation-plan.md
- public_data_cache.dart
- test_registration.py
- Stale live status correction
- lineup-selector.md
- active_season.dart
- Backend over the phone hotspot
- security.py
- Player photos outside sports APIs
- DataProvider
- Match
- logo-contrast-and-photos.md
- token_refresh_test.dart
- dart:async
- test_goal_fallback_uses_one_short_cached_batch_per_league
- registration-fix.md
- persistent_session.dart
- goal_sync.py
- package:dio/dio.dart
- main.py
- test_sessions.py
- backup.sh
- utc_now
- predictions.py
- Production deployment preparation
- Base
- Tournament menu and forecast update
- Persistent session and confirmed lineup layout
- Map
- Player
- player_screen.dart
- Win32Window
- win32_window.cpp
- _SavedTournamentMenu
- .MessageHandler
- matchday_design_test.dart
- Club badge repair
- Daily public cache and permanent badges
- Point
- store_day
- lineup_layout.dart
- goal_api.py
- is_live_match
- initial_data.py
- Minute live updates
- Matchday direction A
- TournamentMenu

## God Nodes (most connected - your core abstractions)
1. `DataProvider` - 55 edges
2. `AuthProvider` - 30 edges
3. `ThemeProvider` - 27 edges
4. `utc()` - 26 edges
5. `utc_now()` - 25 edges
6. `GoalError` - 22 edges
7. `Win32Window` - 21 edges
8. `choose()` - 18 edges
9. `store_fixtures()` - 17 edges
10. `sync_goal()` - 17 edges

## Surprising Connections (you probably didn't know these)
- `Проверка` --references--> `db()`  [INFERRED]
  futrat_backend/README.md → futrat_backend/tests/conftest.py
- `Identity and compatibility` --references--> `Player`  [INFERRED]
  futrat_backend/docs/registration.md → futrat_backend/app/models.py
- `Active season 2026/27` --references--> `current_matches()`  [INFERRED]
  futrat_backend/docs/active-season.md → futrat_backend/app/seasons.py
- `sync_goal()` --indirect_call--> `db()`  [INFERRED]
  futrat_backend/app/goal_sync.py → futrat_backend/tests/conftest.py
- `lifespan()` --indirect_call--> `update_all_data()`  [INFERRED]
  futrat_backend/app/main.py → futrat_backend/app/initial_data.py

## Import Cycles
- None detected.

## Communities (125 total, 29 thin omitted)

### Community 0 - "all_models.dart"
Cohesion: 0.02
Nodes (87): apiCode, appeared, assists, awayTeam, cornersAway, cornersHome, country, currentSeason (+79 more)

### Community 1 - "FlutterWindow"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 2 - "home_screen.dart"
Cohesion: 0.04
Nodes (45): _activeStageFilter, addMatch, awayToken, _bracketRow, _buildBracketColumn, _buildLogo, _buildMatchCard, _buildMatchesList (+37 more)

### Community 3 - "data_provider.dart"
Cohesion: 0.03
Nodes (68): _allMatches, _badgeMetadataBusy, _badgeMetadataCheckedAt, _badges, _cache, clearFavorites, _client, _collapsedLeagues (+60 more)

### Community 4 - ".application"
Cohesion: 0.09
Nodes (10): Cocoa, Flutter, FlutterMacOS, AppDelegate, RunnerTests, AppDelegate, MainFlutterWindow, RunnerTests (+2 more)

### Community 5 - "auth.py"
Cohesion: 0.05
Nodes (47): get_current_user(), login(), nickname_taken(), raise_unique_conflict(), read_users_me(), refresh_session(), register(), revoke_session() (+39 more)

### Community 6 - "my_application.cc"
Cohesion: 0.10
Nodes (13): main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 7 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 8 - "Match navigation and typography"
Cohesion: 0.20
Nodes (9): Font and files, League tabs and rounds, Lineup team selector, Live status correction, Match feeds, Match navigation and typography, Season and ratings, Team profiles (+1 more)

### Community 9 - "match_detail_screen.dart"
Cohesion: 0.09
Nodes (19): _buildStats, _buildTimeline, createState, _currentMatch, _detailsBusy, _detailsError, dispose, _evContent (+11 more)

### Community 10 - "app/forecasts.py"
Cohesion: 0.10
Nodes (31): cancel(), choose(), _game(), leaderboard(), _lock_day(), match_day(), quota(), record_result() (+23 more)

### Community 11 - "player_actions_test.dart"
Cohesion: 0.15
Nodes (12): game, getMatchDetails, host, isAuthenticated, main, match, original, ratePlayer (+4 more)

### Community 12 - "app_theme.dart"
Cohesion: 0.05
Nodes (32): accentColor, accentFill, AppLayout, AppTheme, background, blockGap, cardBg, cardBorder (+24 more)

### Community 13 - "football_logo.dart"
Cohesion: 0.05
Nodes (33): _analyze, background, _badgeReady, _broken, build, cache, _configuration, _contrast (+25 more)

### Community 14 - "match_sync.py"
Cohesion: 0.19
Nodes (4): sync_standings(), _discover_national_teams(), _photo(), update_player_data()

### Community 15 - "lineups.py"
Cohesion: 0.24
Nodes (16): regular_from_timeline(), attach(), bind_player(), canonical_id(), decorate(), enrich_espn(), enrich_goal(), formation() (+8 more)

### Community 16 - "theme_provider.dart"
Cohesion: 0.08
Nodes (20): AppAccent, AppCustomTheme, AppThemeType, _accent, currentAccent, currentTheme, currentType, dispose (+12 more)

### Community 17 - "main.dart"
Cohesion: 0.11
Nodes (12): authProvider, createState, dataProvider, didChangeAppLifecycleState, dispose, FutratApp, _FutratAppState, initState (+4 more)

### Community 18 - "Анализ Предметной Области (ПО) Futrat"
Cohesion: 0.14
Nodes (13): 1.  Ключевые Сущности и Их Атрибуты, 1. Прогнозы Пользователей (Prediction Game), 1. Статистика Игроков и Команд, 1. Управление Пользователями, 2. Голосования, 2. Модуль Авторизации и Персонализации, 2. Персонализация (Модуль "Избранное"), 2. Турнирные Таблицы и Сетки (+5 more)

### Community 19 - "badge_cache.dart"
Cohesion: 0.08
Nodes (20): _acquire, _active, BadgeDownloader, _directory, download, _downloadPng, _failed, instance (+12 more)

### Community 20 - "test_team_badges.py"
Cohesion: 0.18
Nodes (19): resolve_team(), team_key(), ProviderTeam, apply_espn_catalog(), apply_goal_catalog(), fill_badge(), goal_catalog_needed(), goal_team_catalog() (+11 more)

### Community 21 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 22 - "Predictions, favorites and player profiles"
Cohesion: 0.33
Nodes (5): Approved brief, Constraints, Implementation order, Predictions, favorites and player profiles, Verification

### Community 24 - "widget_test.dart"
Cohesion: 0.12
Nodes (14): AppearanceDataProvider, currentStandings, FakeAuthProvider, FakeDataProvider, fetchFavorites, initData, isAuthenticated, league (+6 more)

### Community 26 - "test_runtime.py"
Cohesion: 0.20
Nodes (4): test_existing_postgresql_url_keeps_psycopg2_driver(), test_uvicorn_serves_http(), test_expired_token_is_rejected(), test_password_with_null_byte_is_rejected()

### Community 27 - "Phone connection over LAN"
Cohesion: 0.50
Nodes (3): Delivery, Phone connection over LAN, Resolved network issue

### Community 32 - "widgets/tournament_menu.dart"
Cohesion: 0.08
Nodes (21): _autoScroll, createState, data, dispose, favoriteIds, _group, id, _league (+13 more)

### Community 34 - "test_live_feed.py"
Cohesion: 0.20
Nodes (19): observe_espn(), apply_espn(), apply_goal(), find_event(), refresh(), scoreboard(), writer_lock(), db() (+11 more)

### Community 39 - "match_navigation_test.dart"
Cohesion: 0.10
Nodes (16): currentStandings, fake, favoriteTournaments, fixture, games, getMatchDetails, host, initData (+8 more)

### Community 41 - "forecasts_screen.dart"
Cohesion: 0.05
Nodes (36): api, _cancel, _checkMonth, _choices, _choose, createState, _currentMonth, _day (+28 more)

### Community 42 - "lineup_view.dart"
Cohesion: 0.09
Nodes (18): build, _canRate, createState, _field, _fieldPlayer, LineupView, _LineupViewState, match (+10 more)

### Community 43 - "data.py"
Cohesion: 0.21
Nodes (11): get_standings(), get_match_details(), get_match_updates(), get_matches(), get_or_create_player(), get_standings(), get_team_badges(), get_tournaments() (+3 more)

### Community 44 - "team_screen.dart"
Cohesion: 0.06
Nodes (23): createState, dispose, initState, _tabs, _anchor, api, build, _calendar (+15 more)

### Community 45 - "Deployment: Ubuntu, existing Caddy and PostgreSQL"
Cohesion: 0.06
Nodes (31): Contract and lifetime, Deploy, Persistent sign-in — 24 November 2026, Security review, Android, Backups and restore, Caddy and IP HTTPS, Configuration (+23 more)

### Community 46 - "api_client.dart"
Cohesion: 0.12
Nodes (10): ApiClient, configured, _credentialEndpoint, dio, _instance, session, storage, BadgeCache (+2 more)

### Community 47 - "data_cache_provider_test.dart"
Cohesion: 0.09
Nodes (22): PublicDataCache, artwork, badges, cache, client, counts, create, dio (+14 more)

### Community 48 - "forecasts_test.dart"
Cohesion: 0.09
Nodes (20): allMatches, cancel, choose, count, ForecastAuth, ForecastData, game, games (+12 more)

### Community 49 - "auth_provider.dart"
Cohesion: 0.07
Nodes (24): _authenticate, _cachedUser, checkAuth, clearError, _client, _currentUser, dispose, _errorMessage (+16 more)

### Community 50 - "auth_session_test.dart"
Cohesion: 0.08
Nodes (19): main, auth, fake, main, nickname, offline, restart, started (+11 more)

### Community 51 - "models.py"
Cohesion: 0.21
Nodes (12): Forecast, ForecastDay, ForecastLedger, LineupDetail, MatchFormation, MatchHistoryJob, MatchLiveState, MatchResult (+4 more)

### Community 52 - "package:flutter/material.dart"
Cohesion: 0.14
Nodes (9): main, player, spurs, lineupFixture, main, game, main, liveGame (+1 more)

### Community 53 - "match_status.dart"
Cohesion: 0.29
Nodes (6): _clock, elapsed, isLiveMatch, isLiveStatus, _liveStatuses, liveWindow

### Community 54 - "match_summary.dart"
Cohesion: 0.08
Nodes (14): caption, match, matchStatusLabel, onTap, showTournament, build, form, rows (+6 more)

### Community 55 - "test_production.py"
Cohesion: 0.14
Nodes (6): Settings, production_settings(), test_production_accepts_dedicated_database(), test_production_rejects_unsafe_settings_without_echoing_secrets(), test_production_seeds_tournaments_without_a_test_user(), test_readiness_checks_database()

### Community 56 - "profiles_test.dart"
Cohesion: 0.12
Nodes (11): ProfileApi, calendar, FakeProfiles, game, host, main, player, playerMatches (+3 more)

### Community 57 - "conftest.py"
Cohesion: 0.22
Nodes (3): block_external_http(), client(), match()

### Community 58 - "package:flutter_secure_storage/flutter_secure_storage.dart"
Cohesion: 0.12
Nodes (7): contrast, main, x, league, leagues, main, menu

### Community 61 - "core/tournament_menu.dart"
Cohesion: 0.10
Nodes (18): code, _countries, country, _countryCodes, _european, favorite, _group, key (+10 more)

### Community 62 - "grouped_matches_list.dart"
Cohesion: 0.07
Nodes (27): MatchModel, ProfileScreen, AppEmptyState, AppSkeleton, SkeletonBox, UpdateNotice, build, byLeague (+19 more)

### Community 63 - "test_api.py"
Cohesion: 0.31
Nodes (6): register(), test_duplicate_registration_is_rejected(), test_existing_password_hash_can_log_in(), test_lineup_player_can_be_favorited(), test_prediction_and_favorite_persist(), test_register_login_and_current_user()

### Community 64 - "app_states.dart"
Cohesion: 0.05
Nodes (31): actionLabel, appTabs, build, controller, fixedEqualWidth, icon, label, layout (+23 more)

### Community 65 - "Appearance"
Cohesion: 0.40
Nodes (4): Appearance, Files and verification, Logo contrast — 20 October 2026, Visual rules

### Community 67 - "football_logo_test.dart"
Cohesion: 0.15
Nodes (9): badge, bytes, canvas, image, main, picture, pixels, recorder (+1 more)

### Community 68 - "build"
Cohesion: 0.18
Nodes (6): build, _games, _buildPairCard, _onItemTapped, _profile, build

### Community 69 - "auth_screen.dart"
Cohesion: 0.09
Nodes (21): AuthScreen, _AuthScreenState, createState, dispose, _field, _formKey, _isRegister, _obscurePassword (+13 more)

### Community 70 - "tournament_menu_preferences.dart"
Cohesion: 0.11
Nodes (15): _changed, _collapsed, dispose, _disposed, isCollapsed, _key, _load, move (+7 more)

### Community 71 - "Season and match interface"
Cohesion: 0.40
Nodes (4): Delivery, Limits, Scope, Season and match interface

### Community 72 - "test_season_sync.py"
Cohesion: 0.15
Nodes (24): update_all_data(), event(), mock_source(), get(), scoreboard(), test_distinct_events_with_same_teams_keep_their_ids_and_results(), test_failed_day_is_retried_without_reimporting_completed_history(), test_grouped_cup_calendar_discovers_fixture_days_from_year_feeds() (+16 more)

### Community 75 - "public_data_cache.dart"
Cohesion: 0.10
Nodes (16): CacheDirectory, DailySnapshot, day, _directory, expire, _folder, moscow, moscowDay (+8 more)

### Community 76 - "test_registration.py"
Cohesion: 0.19
Nodes (11): ensure_user_schema(), signup(), test_database_guards_nickname_races(), test_invalid_registration_is_rejected_without_echoing_password(), test_legacy_nickname_migration_is_idempotent_and_refuses_collisions(), test_login_errors_are_readable_and_do_not_disclose_account_existence(), test_nickname_is_unique_after_normalization(), test_postgres_upgrade_retains_users_and_allows_new_accounts_without_email() (+3 more)

### Community 77 - "Stale live status correction"
Cohesion: 0.40
Nodes (4): Delivery, Files, Scope, Stale live status correction

### Community 80 - "Backend over the phone hotspot"
Cohesion: 0.29
Nodes (6): Address and build, Backend over the phone hotspot, Latest build — 20 October 2026, Verification without USB forwarding, Verified on 18 October 2026, Windows setup

### Community 81 - "security.py"
Cohesion: 0.17
Nodes (14): init_db(), User, _bcrypt_password(), get_password_hash(), verify_password(), delete_empty_account(), test_production_accepts_admin_with_changed_password(), test_production_refuses_imported_development_account() (+6 more)

### Community 84 - "Player photos outside sports APIs"
Cohesion: 0.33
Nodes (5): Alternatives considered, Limits, Ordered implementation, Player photos outside sports APIs, Selected approach

### Community 85 - "DataProvider"
Cohesion: 0.08
Nodes (27): onAuthenticated, openAuthScreen, resumedAfterLogin, runAuthenticatedAction, signedIn, build, AuthProvider, DataProvider (+19 more)

### Community 86 - "Match"
Cohesion: 0.30
Nodes (8): Match, Tournament, Storage and API, add_game(), instant(), test_profile_defaults_and_cursor_share_public_season_filter(), test_public_lists_keep_only_2627_clubs_calendar_mls_and_current_national(), test_team_timeline_has_last_finished_anchor_all_competitions_and_history_above()

### Community 88 - "token_refresh_test.dart"
Cohesion: 0.14
Nodes (10): adapter, auth, client, close, expired, fetch, main, refreshes (+2 more)

### Community 89 - "dart:async"
Cohesion: 0.12
Nodes (8): main, png, root, cache, main, now, root, snapshot

### Community 90 - "test_goal_fallback_uses_one_short_cached_batch_per_league"
Cohesion: 0.33
Nodes (3): ProviderMatch, test_goal_mapped_match_never_sends_goal_id_to_espn(), test_goal_fallback_uses_one_short_cached_batch_per_league()

### Community 92 - "persistent_session.dart"
Cohesion: 0.15
Nodes (8): clear, _generation, refresh, _refreshing, saveTokens, storage, _wasRejected, _writes

### Community 93 - "goal_sync.py"
Cohesion: 0.13
Nodes (21): observe_goal(), GoalClient, GoalError, find_league(), kickoff(), refresh_details(), store_fixtures(), sync_goal() (+13 more)

### Community 94 - "package:dio/dio.dart"
Cohesion: 0.12
Nodes (13): cancel, choose, dio, ForecastApi, mine, myRank, rankings, used (+5 more)

### Community 95 - "main.py"
Cohesion: 0.16
Nodes (8): validation_error(), update_live_data(), update_live_feed(), lifespan(), readiness(), root(), start_sync(), stop_sync()

### Community 96 - "test_sessions.py"
Cohesion: 0.26
Nodes (11): create_access_token(), test_invalid_expired_and_missing_tokens_are_rejected(), test_token_keeps_subject_without_mutating_input(), bearer(), register(), test_access_cannot_use_another_users_session(), test_configured_access_lifetime_is_used(), test_expired_access_refreshes_without_password_even_after_long_absence() (+3 more)

### Community 98 - "utc_now"
Cohesion: 0.34
Nodes (10): utc_now(), queue_player(), calendar_team(), matches_json(), player_matches(), player_profile(), profile(), season_year() (+2 more)

### Community 99 - "predictions.py"
Cohesion: 0.43
Nodes (3): add_favorite_team(), get_my_predictions(), make_prediction()

### Community 100 - "Production deployment preparation"
Cohesion: 0.33
Nodes (5): Approved brief, Implementation, Production deployment preparation, Remaining server checks, Verification — 2026-10-22

### Community 101 - "Base"
Cohesion: 0.17
Nodes (14): store_details(), AuthSession, MatchEvent, MatchLineup, OfficialStandings, Prediction, ProviderCache, ProviderUsage (+6 more)

### Community 102 - "Tournament menu and forecast update"
Cohesion: 0.22
Nodes (8): Approved scope, Drag handle correction (2026-10-23), Full-width country header interaction (2026-10-23), Implementation, One-second hold and player actions (2026-10-27), Session restoration correction (2026-10-27), Tournament menu and forecast update, Verification

### Community 103 - "Persistent session and confirmed lineup layout"
Cohesion: 0.33
Nodes (5): Implemented, Persistent session and confirmed lineup layout, Scope, Sources, Verification and deployment

### Community 104 - "Map"
Cohesion: 0.40
Nodes (3): cleanName, _countryTranslations, tr

### Community 105 - "Player"
Cohesion: 0.25
Nodes (7): Player, API and errors, Identity and compatibility, Nickname registration, Requested cleanup, Verification, test_wrong_person_photo_is_not_used_on_name_alone()

### Community 106 - "player_screen.dart"
Cohesion: 0.10
Nodes (16): api, build, _calendar, _coverage, createState, _error, _generation, initState (+8 more)

### Community 107 - "Win32Window"
Cohesion: 0.14
Nodes (7): Size, height, width, Win32Window, child_content_, quit_on_close_, window_handle_

### Community 108 - "win32_window.cpp"
Cohesion: 0.20
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 111 - "matchday_design_test.dart"
Cohesion: 0.12
Nodes (12): NavigationData, allMatches, error, getMatchDetails, isLoading, loadError, loading, LoadingData (+4 more)

### Community 112 - "Club badge repair"
Cohesion: 0.40
Nodes (4): Club badge repair, Deploy, Diagnosed production data, Verify

### Community 113 - "Daily public cache and permanent badges"
Cohesion: 0.29
Nodes (6): Approved behavior, Badge-loading correction (2.3.1+12), Daily public cache and permanent badges, Implementation, Russian club correction (2.3.2+13), Verification

### Community 114 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 115 - "store_day"
Cohesion: 0.16
Nodes (13): sync_sources(), assign_rounds(), calendar_days(), database_lock(), discover_calendar(), fetch_day(), _score(), store_day() (+5 more)

### Community 116 - "lineup_layout.dart"
Cohesion: 0.13
Nodes (13): center, confirmedLineupRows, counts, left, line, offset, ordered, right (+5 more)

### Community 117 - "goal_api.py"
Cohesion: 0.26
Nodes (4): espn(), goal(), minute(), write()

### Community 119 - "is_live_match"
Cohesion: 0.28
Nodes (5): is_live_match(), is_live_status(), test_live_api_excludes_august_fixture_but_keeps_it_in_history(), test_live_api_rejects_non_live_statuses(), test_live_window_crosses_midnight_and_accepts_espn_clock()

### Community 120 - "initial_data.py"
Cohesion: 0.38
Nodes (4): seed_tournaments(), seed_tournaments(), test_pending_euro_api_has_no_fictional_standings(), test_registry_seeds_31_tournaments_and_preserves_ids()

### Community 121 - "Minute live updates"
Cohesion: 0.33
Nodes (5): Display, Minute live updates, Provider priority, Refresh, Verification

### Community 122 - "Matchday direction A"
Cohesion: 0.40
Nodes (4): Approved scope, Implementation, Matchday direction A, Verification

## Knowledge Gaps
- **791 isolated node(s):** `activeSeason`, `seasonLabel`, `_instance`, `dio`, `storage` (+786 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1185 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **29 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `DataProvider` connect `DataProvider` to `home_screen.dart`, `data_provider.dart`, `match_detail_screen.dart`, `player_actions_test.dart`, `main.dart`, `widget_test.dart`, `widgets/tournament_menu.dart`, `forecasts_screen.dart`, `lineup_view.dart`, `team_screen.dart`, `api_client.dart`, `forecasts_test.dart`, `match_summary.dart`, `profiles_test.dart`, `grouped_matches_list.dart`, `build`, `auth_screen.dart`, `player_screen.dart`, `matchday_design_test.dart`?**
  _High betweenness centrality (0.055) - this node is a cross-community bridge._
- **What connects `activeSeason`, `seasonLabel`, `_instance` to the rest of the system?**
  _791 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `all_models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.022222222222222223 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `Win32Window` to `FlutterWindow`, `win32_window.cpp`, `.MessageHandler`, `Point`, `string`?**
  _High betweenness centrality (0.033) - this node is a cross-community bridge._
- **Should `FlutterWindow` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._
- **Why does `db()` connect `test_live_feed.py` to `Deployment: Ubuntu, existing Caddy and PostgreSQL`, `match_sync.py`, `security.py`, `store_day`, `test_team_badges.py`, `conftest.py`, `goal_sync.py`?**
  _High betweenness centrality (0.025) - this node is a cross-community bridge._
- **Should `home_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._
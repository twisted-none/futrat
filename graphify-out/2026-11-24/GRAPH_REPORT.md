# Graph Report - futrat  (2026-11-24)

## Corpus Check
- 159 files · ~93,205 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 67 file(s) not represented in the graph (top: (none) 14, .xml 9, .xcconfig 8)

## Summary
- 1765 nodes · 3226 edges · 106 communities (80 shown, 26 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 58 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `069ba992`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- all_models.dart
- win32_window.cpp
- home_screen.dart
- data_provider.dart
- .application
- schemas.py
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
- conftest.py
- test_season_sync.py
- manifest.json
- Predictions, favorites and player profiles
- futrat_mobile
- widget_test.dart
- LaunchImage.imageset/README.md
- auth_gate.dart
- Phone connection over LAN
- constants.dart
- Implementation checklist
- FlutterActivity
- widgets/tournament_menu.dart
- live_sync.py
- match_navigation_test.dart
- accent-live-feed.md
- forecasts_screen.dart
- lineup_view.dart
- app/__init__.py
- team_screen.dart
- Deployment: Ubuntu, existing Caddy and PostgreSQL
- api_client.dart
- users.py
- forecasts_test.dart
- auth_provider.dart
- auth_session_test.dart
- models.py
- package:flutter/material.dart
- match_status.dart
- goal_sync.py
- test_production.py
- profiles_test.dart
- State
- tournament_menu_test.dart
- branding/README.md
- core/tournament_menu.dart
- grouped_matches_list.dart
- test_api.py
- round_selector.dart
- Appearance
- appearance-plan.md
- football_logo_test.dart
- favorites_screen.dart
- auth_screen.dart
- tournament_menu_preferences.dart
- Season and match interface
- main.py
- fonts/README.md
- match-navigation-plan.md
- goal_api.py
- test_registration.py
- Stale live status correction
- lineup-selector.md
- active_season.dart
- Backend over the phone hotspot
- security.py
- Player photos outside sports APIs
- DataProvider
- auth.py
- logo-contrast-and-photos.md
- token_refresh_test.dart
- Match
- registration-fix.md
- persistent_session.dart
- lineup_layout_test.dart
- package:dio/dio.dart
- auth_validation_test.dart
- test_sessions.py
- backup.sh
- utc_now
- make_prediction
- Production deployment preparation
- Nickname registration
- Tournament menu and forecast update
- Persistent session and confirmed lineup layout
- Map
- ForecastApi

## God Nodes (most connected - your core abstractions)
1. `DataProvider` - 54 edges
2. `ThemeProvider` - 30 edges
3. `utc()` - 26 edges
4. `AuthProvider` - 26 edges
5. `utc_now()` - 25 edges
6. `Win32Window` - 21 edges
7. `GoalError` - 19 edges
8. `choose()` - 18 edges
9. `store_fixtures()` - 17 edges
10. `update_all_data()` - 16 edges

## Surprising Connections (you probably didn't know these)
- `Identity and compatibility` --references--> `Player`  [INFERRED]
  futrat_backend/docs/registration.md → futrat_backend/app/models.py
- `Проверка` --references--> `db()`  [INFERRED]
  futrat_backend/README.md → futrat_backend/tests/conftest.py
- `Active season 2026/27` --references--> `current_matches()`  [INFERRED]
  futrat_backend/docs/active-season.md → futrat_backend/app/seasons.py
- `goal_fallback()` --uses--> `GoalError`  [INFERRED]
  futrat_backend/app/live_sync.py → futrat_backend/app/goal_api.py
- `sync_goal()` --indirect_call--> `db()`  [INFERRED]
  futrat_backend/app/goal_sync.py → futrat_backend/tests/conftest.py

## Import Cycles
- None detected.

## Communities (106 total, 26 thin omitted)

### Community 0 - "all_models.dart"
Cohesion: 0.02
Nodes (87): apiCode, appeared, assists, awayTeam, cornersAway, cornersHome, country, currentSeason (+79 more)

### Community 1 - "win32_window.cpp"
Cohesion: 0.05
Nodes (20): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_, EnableFullDpiSupportIfAvailable(), Point, x, y (+12 more)

### Community 2 - "home_screen.dart"
Cohesion: 0.04
Nodes (50): _activeStageFilter, addMatch, awayToken, _bracketRow, _buildBracketColumn, _buildDynamicTable, _buildLogo, _buildMatchCard (+42 more)

### Community 3 - "data_provider.dart"
Cohesion: 0.05
Nodes (42): _allMatches, clearFavorites, _client, _collapsedLeagues, _currentStandings, dispose, _favoritePlayers, _favoriteTeams (+34 more)

### Community 4 - ".application"
Cohesion: 0.09
Nodes (10): Cocoa, Flutter, FlutterMacOS, AppDelegate, RunnerTests, AppDelegate, MainFlutterWindow, RunnerTests (+2 more)

### Community 5 - "schemas.py"
Cohesion: 0.09
Nodes (24): LeaderboardEntry, LineupPlayerResponse, MatchEventResponse, MatchLiveUpdate, MatchResponse, PlayerRatingCreate, PlayerResponse, PredictionCreate (+16 more)

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
Cohesion: 0.11
Nodes (16): _buildStats, _buildTimeline, createState, _currentMatch, dispose, _evContent, _getRatingColor, initState (+8 more)

### Community 10 - "app/forecasts.py"
Cohesion: 0.10
Nodes (31): cancel(), choose(), _game(), leaderboard(), _lock_day(), match_day(), quota(), record_result() (+23 more)

### Community 11 - "player_actions_test.dart"
Cohesion: 0.15
Nodes (11): game, getMatchDetails, host, isAuthenticated, main, match, original, ratePlayer (+3 more)

### Community 12 - "app_theme.dart"
Cohesion: 0.07
Nodes (22): accentColor, accentFill, AppTheme, background, cardBg, cardBorder, color, _contrast (+14 more)

### Community 13 - "football_logo.dart"
Cohesion: 0.07
Nodes (23): _analyze, background, build, _contrast, createState, didChangeDependencies, didUpdateWidget, _disconnect (+15 more)

### Community 14 - "match_sync.py"
Cohesion: 0.20
Nodes (10): sync_sources(), assign_rounds(), calendar_days(), discover_calendar(), fetch_day(), _score(), store_day(), sync_leagues() (+2 more)

### Community 15 - "lineups.py"
Cohesion: 0.16
Nodes (25): observe_espn(), regular_from_timeline(), store_details(), attach(), bind_player(), canonical_id(), decorate(), enrich_espn() (+17 more)

### Community 16 - "theme_provider.dart"
Cohesion: 0.08
Nodes (20): AppAccent, AppCustomTheme, AppThemeType, _accent, currentAccent, currentTheme, currentType, dispose (+12 more)

### Community 17 - "main.dart"
Cohesion: 0.09
Nodes (13): authProvider, createState, dataProvider, didChangeAppLifecycleState, dispose, initState, main, _router (+5 more)

### Community 18 - "Анализ Предметной Области (ПО) Futrat"
Cohesion: 0.14
Nodes (13): 1.  Ключевые Сущности и Их Атрибуты, 1. Прогнозы Пользователей (Prediction Game), 1. Статистика Игроков и Команд, 1. Управление Пользователями, 2. Голосования, 2. Модуль Авторизации и Персонализации, 2. Персонализация (Модуль "Избранное"), 2. Турнирные Таблицы и Сетки (+5 more)

### Community 19 - "conftest.py"
Cohesion: 0.13
Nodes (9): block_external_http(), client(), db(), fake_scoreboard(), test_api_starts_while_season_source_is_still_waiting(), get(), test_match_sync_inserts_and_updates_without_duplicates(), test_scheduler_executes_match_sync_in_background() (+1 more)

### Community 20 - "test_season_sync.py"
Cohesion: 0.22
Nodes (19): update_all_data(), database_lock(), event(), mock_source(), get(), scoreboard(), test_distinct_events_with_same_teams_keep_their_ids_and_results(), test_failed_day_is_retried_without_reimporting_completed_history() (+11 more)

### Community 21 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 22 - "Predictions, favorites and player profiles"
Cohesion: 0.33
Nodes (5): Approved brief, Constraints, Implementation order, Predictions, favorites and player profiles, Verification

### Community 24 - "widget_test.dart"
Cohesion: 0.12
Nodes (13): AppearanceDataProvider, currentStandings, FakeDataProvider, fetchFavorites, initData, isAuthenticated, league, main (+5 more)

### Community 26 - "auth_gate.dart"
Cohesion: 0.25
Nodes (4): onAuthenticated, resumedAfterLogin, runAuthenticatedAction, signedIn

### Community 27 - "Phone connection over LAN"
Cohesion: 0.50
Nodes (3): Delivery, Phone connection over LAN, Resolved network issue

### Community 32 - "widgets/tournament_menu.dart"
Cohesion: 0.08
Nodes (21): _autoScroll, createState, data, dispose, favoriteIds, _group, id, _league (+13 more)

### Community 34 - "live_sync.py"
Cohesion: 0.16
Nodes (23): observe_goal(), find_league(), team_key(), apply_espn(), apply_goal(), find_event(), goal_fallback(), refresh() (+15 more)

### Community 39 - "match_navigation_test.dart"
Cohesion: 0.09
Nodes (17): currentStandings, fake, favoriteTournaments, fixture, games, getMatchDetails, host, initData (+9 more)

### Community 41 - "forecasts_screen.dart"
Cohesion: 0.05
Nodes (34): api, _cancel, _checkMonth, _choices, _choose, createState, _currentMonth, _day (+26 more)

### Community 42 - "lineup_view.dart"
Cohesion: 0.09
Nodes (18): build, _canRate, createState, _field, _fieldPlayer, LineupView, _LineupViewState, match (+10 more)

### Community 43 - "app/__init__.py"
Cohesion: 0.12
Nodes (16): is_live_match(), is_live_status(), get_standings(), get_match_updates(), get_matches(), get_standings(), get_tournaments(), rate_player() (+8 more)

### Community 44 - "team_screen.dart"
Cohesion: 0.05
Nodes (40): ProfileApi, api, build, _calendar, _coverage, createState, _error, _generation (+32 more)

### Community 45 - "Deployment: Ubuntu, existing Caddy and PostgreSQL"
Cohesion: 0.06
Nodes (31): Contract and lifetime, Deploy, Persistent sign-in — 24 November 2026, Security review, Android, Backups and restore, Caddy and IP HTTPS, Configuration (+23 more)

### Community 46 - "api_client.dart"
Cohesion: 0.17
Nodes (7): ApiClient, configured, _credentialEndpoint, dio, _instance, session, storage

### Community 47 - "users.py"
Cohesion: 0.22
Nodes (13): nickname_taken(), raise_unique_conflict(), add_favorite_player(), add_favorite_team(), add_favorite_tournament(), get_favorite_players(), get_favorite_teams(), get_favorite_tournaments() (+5 more)

### Community 48 - "forecasts_test.dart"
Cohesion: 0.09
Nodes (19): allMatches, cancel, choose, count, ForecastData, game, games, isAuthenticated (+11 more)

### Community 49 - "auth_provider.dart"
Cohesion: 0.07
Nodes (23): _authenticate, _cachedUser, checkAuth, clearError, _client, _currentUser, dispose, _errorMessage (+15 more)

### Community 50 - "auth_session_test.dart"
Cohesion: 0.14
Nodes (11): auth, fake, main, nickname, offline, restart, started, status (+3 more)

### Community 51 - "models.py"
Cohesion: 0.10
Nodes (27): Forecast, ForecastDay, ForecastLedger, LineupDetail, MatchFormation, MatchHistoryJob, MatchLiveState, MatchResult (+19 more)

### Community 52 - "package:flutter/material.dart"
Cohesion: 0.14
Nodes (8): main, game, main, liveGame, main, contrast, main, x

### Community 53 - "match_status.dart"
Cohesion: 0.29
Nodes (6): _clock, elapsed, isLiveMatch, isLiveStatus, _liveStatuses, liveWindow

### Community 54 - "goal_sync.py"
Cohesion: 0.12
Nodes (17): GoalClient, GoalError, kickoff(), refresh_details(), store_fixtures(), sync_goal(), prefer_espn(), ProviderMatch (+9 more)

### Community 55 - "test_production.py"
Cohesion: 0.14
Nodes (11): Settings, init_db(), User, production_settings(), test_production_accepts_admin_with_changed_password(), test_production_accepts_dedicated_database(), test_production_refuses_imported_development_account(), test_production_rejects_unsafe_settings_without_echoing_secrets() (+3 more)

### Community 56 - "profiles_test.dart"
Cohesion: 0.14
Nodes (9): calendar, game, host, main, player, playerMatches, requestedSeasons, team (+1 more)

### Community 57 - "State"
Cohesion: 0.18
Nodes (12): FutratApp, _FutratAppState, FavoritesScreen, _FavoritesScreenState, ForecastsScreen, _ForecastsScreenState, FootballLogo, _FootballLogoState (+4 more)

### Community 58 - "tournament_menu_test.dart"
Cohesion: 0.20
Nodes (4): league, leagues, main, menu

### Community 61 - "core/tournament_menu.dart"
Cohesion: 0.05
Nodes (31): center, confirmedLineupRows, counts, left, line, offset, ordered, right (+23 more)

### Community 62 - "grouped_matches_list.dart"
Cohesion: 0.07
Nodes (20): MatchModel, byLeague, feedId, groupMatchesByLeague, groups, LeagueMatches, match, matches (+12 more)

### Community 63 - "test_api.py"
Cohesion: 0.15
Nodes (8): register(), test_duplicate_registration_is_rejected(), test_existing_password_hash_can_log_in(), test_lineup_player_can_be_favorited(), test_prediction_and_favorite_persist(), test_register_login_and_current_user(), test_existing_postgresql_url_keeps_psycopg2_driver(), test_uvicorn_serves_http()

### Community 64 - "round_selector.dart"
Cohesion: 0.15
Nodes (12): build, _choose, createState, current, dispose, onChanged, _positioned, _RoundPicker (+4 more)

### Community 65 - "Appearance"
Cohesion: 0.40
Nodes (4): Appearance, Files and verification, Logo contrast — 20 October 2026, Visual rules

### Community 67 - "football_logo_test.dart"
Cohesion: 0.14
Nodes (9): badge, bytes, canvas, image, main, picture, pixels, recorder (+1 more)

### Community 68 - "favorites_screen.dart"
Cohesion: 0.08
Nodes (14): _buildEmptyState, _buildPlayersList, _buildTeamsList, _buildThemedLogo, _buildTournamentsList, createState, dispose, initState (+6 more)

### Community 69 - "auth_screen.dart"
Cohesion: 0.14
Nodes (12): AuthScreen, _AuthScreenState, build, createState, dispose, _field, _formKey, _isRegister (+4 more)

### Community 70 - "tournament_menu_preferences.dart"
Cohesion: 0.11
Nodes (15): _changed, _collapsed, dispose, _disposed, isCollapsed, _key, _load, move (+7 more)

### Community 71 - "Season and match interface"
Cohesion: 0.40
Nodes (4): Delivery, Limits, Scope, Season and match interface

### Community 72 - "main.py"
Cohesion: 0.11
Nodes (12): validation_error(), seed_tournaments(), seed_tournaments(), update_live_data(), update_live_feed(), lifespan(), readiness(), root() (+4 more)

### Community 75 - "goal_api.py"
Cohesion: 0.26
Nodes (4): espn(), goal(), minute(), write()

### Community 76 - "test_registration.py"
Cohesion: 0.17
Nodes (12): delete_empty_account(), ensure_user_schema(), signup(), test_empty_account_cleanup_only_removes_verified_target_and_its_favorites(), test_invalid_registration_is_rejected_without_echoing_password(), test_legacy_nickname_migration_is_idempotent_and_refuses_collisions(), test_login_errors_are_readable_and_do_not_disclose_account_existence(), test_nickname_is_unique_after_normalization() (+4 more)

### Community 77 - "Stale live status correction"
Cohesion: 0.40
Nodes (4): Delivery, Files, Scope, Stale live status correction

### Community 80 - "Backend over the phone hotspot"
Cohesion: 0.29
Nodes (6): Address and build, Backend over the phone hotspot, Latest build — 20 October 2026, Verification without USB forwarding, Verified on 18 October 2026, Windows setup

### Community 81 - "security.py"
Cohesion: 0.15
Nodes (14): _bcrypt_password(), create_access_token(), get_password_hash(), verify_password(), test_invalid_expired_and_missing_tokens_are_rejected(), test_existing_short_password_and_legacy_email_session_still_work(), test_expired_token_is_rejected(), test_legacy_long_password_truncation() (+6 more)

### Community 84 - "Player photos outside sports APIs"
Cohesion: 0.33
Nodes (5): Alternatives considered, Limits, Ordered implementation, Player photos outside sports APIs, Selected approach

### Community 85 - "DataProvider"
Cohesion: 0.11
Nodes (28): openAuthScreen, PersistentSession, build, AuthProvider, DataProvider, ThemeProvider, TournamentMenuPreferences, build (+20 more)

### Community 86 - "auth.py"
Cohesion: 0.24
Nodes (9): get_current_user(), login(), read_users_me(), refresh_session(), register(), revoke_session(), session_for_key(), token_pair() (+1 more)

### Community 88 - "token_refresh_test.dart"
Cohesion: 0.14
Nodes (10): adapter, auth, client, close, expired, fetch, main, refreshes (+2 more)

### Community 89 - "Match"
Cohesion: 0.18
Nodes (9): Match, Display, Minute live updates, Provider priority, Refresh, Storage and API, Verification, test_live_api_excludes_august_fixture_but_keeps_it_in_history() (+1 more)

### Community 92 - "persistent_session.dart"
Cohesion: 0.17
Nodes (7): clear, _generation, refresh, _refreshing, saveTokens, storage, _writes

### Community 93 - "lineup_layout_test.dart"
Cohesion: 0.20
Nodes (5): main, player, spurs, lineupFixture, main

### Community 94 - "package:dio/dio.dart"
Cohesion: 0.14
Nodes (11): cancel, choose, dio, mine, myRank, rankings, used, dio (+3 more)

### Community 95 - "auth_validation_test.dart"
Cohesion: 0.18
Nodes (7): auth, fail, fake, host, main, press, requests

### Community 96 - "test_sessions.py"
Cohesion: 0.47
Nodes (7): bearer(), register(), test_access_cannot_use_another_users_session(), test_expired_access_refreshes_without_password_even_after_long_absence(), test_login_creates_hashed_revocable_session(), test_logout_revokes_only_this_device_and_its_access_token(), test_unknown_refresh_key_is_rejected_and_cannot_be_used_as_access()

### Community 98 - "utc_now"
Cohesion: 0.23
Nodes (14): utc_now(), ProviderCache, _discover_national_teams(), _photo(), queue_player(), update_player_data(), calendar_team(), matches_json() (+6 more)

### Community 99 - "make_prediction"
Cohesion: 0.43
Nodes (3): add_favorite_team(), get_my_predictions(), make_prediction()

### Community 100 - "Production deployment preparation"
Cohesion: 0.33
Nodes (5): Approved brief, Implementation, Production deployment preparation, Remaining server checks, Verification — 2026-10-22

### Community 101 - "Nickname registration"
Cohesion: 0.33
Nodes (5): API and errors, Identity and compatibility, Nickname registration, Requested cleanup, Verification

### Community 102 - "Tournament menu and forecast update"
Cohesion: 0.22
Nodes (8): Approved scope, Drag handle correction (2026-10-23), Full-width country header interaction (2026-10-23), Implementation, One-second hold and player actions (2026-10-27), Session restoration correction (2026-10-27), Tournament menu and forecast update, Verification

### Community 103 - "Persistent session and confirmed lineup layout"
Cohesion: 0.33
Nodes (5): Implemented, Persistent session and confirmed lineup layout, Scope, Sources, Verification and deployment

### Community 104 - "Map"
Cohesion: 0.40
Nodes (3): cleanName, _countryTranslations, tr

## Knowledge Gaps
- **643 isolated node(s):** `activeSeason`, `seasonLabel`, `_instance`, `dio`, `storage` (+638 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 994 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **26 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MatchModel` connect `grouped_matches_list.dart` to `all_models.dart`, `home_screen.dart`, `match_detail_screen.dart`, `lineup_view.dart`, `player_actions_test.dart`, `team_screen.dart`, `forecasts_test.dart`?**
  _High betweenness centrality (0.061) - this node is a cross-community bridge._
- **What connects `activeSeason`, `seasonLabel`, `_instance` to the rest of the system?**
  _643 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `all_models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02197802197802198 - nodes in this community are weakly interconnected._
- **Why does `db()` connect `conftest.py` to `live_sync.py`, `utc_now`, `Deployment: Ubuntu, existing Caddy and PostgreSQL`, `match_sync.py`, `goal_sync.py`, `test_production.py`?**
  _High betweenness centrality (0.045) - this node is a cross-community bridge._
- **Should `win32_window.cpp` be split into smaller, more focused modules?**
  _Cohesion score 0.05268065268065268 - nodes in this community are weakly interconnected._
- **Why does `Проверка` connect `Deployment: Ubuntu, existing Caddy and PostgreSQL` to `conftest.py`?**
  _High betweenness centrality (0.044) - this node is a cross-community bridge._
- **Should `home_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.037037037037037035 - nodes in this community are weakly interconnected._
# Graph Report - futrat  (2026-10-23)

## Corpus Check
- 150 files · ~80,121 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 67 file(s) not represented in the graph (top: (none) 14, .xml 9, .xcconfig 8)

## Summary
- 1649 nodes · 3015 edges · 105 communities (76 shown, 29 thin omitted)
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
- routers/forecasts.py
- auth_provider.dart
- app_theme.dart
- football_logo.dart
- match_sync.py
- lineups.py
- theme_provider.dart
- main.dart
- Анализ Предметной Области (ПО) Futrat
- test_runtime.py
- test_season_sync.py
- manifest.json
- Predictions, favorites and player profiles
- futrat_mobile
- widget_test.dart
- LaunchImage.imageset/README.md
- profiles.py
- Phone connection over LAN
- constants.dart
- Implementation checklist
- FlutterActivity
- widgets/tournament_menu.dart
- goal_sync.py
- match_navigation_test.dart
- accent-live-feed.md
- forecasts_screen.dart
- lineup_view.dart
- data.py
- team_screen.dart
- Deployment: Ubuntu, existing Caddy and PostgreSQL
- package:dio/dio.dart
- users.py
- forecasts_test.dart
- player_screen.dart
- auth_validation_test.dart
- models.py
- live_matches_test.dart
- match_status.dart
- conftest.py
- national_standings.py
- profiles_test.dart
- State
- tournament_menu_test.dart
- branding/README.md
- core/tournament_menu.dart
- grouped_matches_list.dart
- test_production.py
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
- make_prediction
- Stale live status correction
- lineup-selector.md
- active_season.dart
- Backend over the phone hotspot
- test_security.py
- Player photos outside sports APIs
- DataProvider
- auth.py
- logo-contrast-and-photos.md
- utc_now
- test_api.py
- registration-fix.md
- test_registration.py
- match_tile.dart
- forecast_api.dart
- Live match classification
- MaterialPageRoute
- backup.sh
- package:flutter/material.dart
- UserLogin
- Production deployment preparation
- User
- Tournament menu and forecast update
- rate_player
- ProfileApi

## God Nodes (most connected - your core abstractions)
1. `DataProvider` - 52 edges
2. `ThemeProvider` - 29 edges
3. `utc()` - 26 edges
4. `utc_now()` - 25 edges
5. `AuthProvider` - 22 edges
6. `Win32Window` - 21 edges
7. `GoalError` - 19 edges
8. `choose()` - 18 edges
9. `store_fixtures()` - 17 edges
10. `update_all_data()` - 16 edges

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

## Communities (105 total, 29 thin omitted)

### Community 0 - "all_models.dart"
Cohesion: 0.02
Nodes (87): apiCode, appeared, assists, awayTeam, cornersAway, cornersHome, country, currentSeason (+79 more)

### Community 1 - "win32_window.cpp"
Cohesion: 0.05
Nodes (20): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_, EnableFullDpiSupportIfAvailable(), Point, x, y (+12 more)

### Community 2 - "home_screen.dart"
Cohesion: 0.04
Nodes (48): _activeStageFilter, addMatch, awayToken, _bracketRow, _buildBracketColumn, _buildDynamicTable, _buildLogo, _buildMatchCard (+40 more)

### Community 3 - "data_provider.dart"
Cohesion: 0.05
Nodes (42): _allMatches, clearFavorites, _client, _collapsedLeagues, _currentStandings, dispose, _favoritePlayers, _favoriteTeams (+34 more)

### Community 4 - ".application"
Cohesion: 0.09
Nodes (10): Cocoa, Flutter, FlutterMacOS, AppDelegate, RunnerTests, AppDelegate, MainFlutterWindow, RunnerTests (+2 more)

### Community 5 - "schemas.py"
Cohesion: 0.20
Nodes (17): LeaderboardEntry, LineupPlayerResponse, MatchEventResponse, MatchLiveUpdate, MatchResponse, PlayerRatingCreate, PlayerResponse, PredictionCreate (+9 more)

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

### Community 10 - "routers/forecasts.py"
Cohesion: 0.11
Nodes (26): choose(), leaderboard(), _lock_day(), quota(), record_result(), cancel(), Choice, choose() (+18 more)

### Community 11 - "auth_provider.dart"
Cohesion: 0.10
Nodes (17): _authenticate, checkAuth, clearError, _client, _currentUser, _errorMessage, fetchProfile, isAuthenticated (+9 more)

### Community 12 - "app_theme.dart"
Cohesion: 0.07
Nodes (22): accentColor, accentFill, AppTheme, background, cardBg, cardBorder, color, _contrast (+14 more)

### Community 13 - "football_logo.dart"
Cohesion: 0.07
Nodes (25): _analyze, background, build, _contrast, createState, didChangeDependencies, didUpdateWidget, _disconnect (+17 more)

### Community 14 - "match_sync.py"
Cohesion: 0.15
Nodes (17): observe_espn(), espn(), minute(), prefer_espn(), write(), find_event(), refresh(), scoreboard() (+9 more)

### Community 15 - "lineups.py"
Cohesion: 0.07
Nodes (44): regular_from_timeline(), store_details(), attach(), bind_player(), decorate(), enrich_espn(), enrich_goal(), formation() (+36 more)

### Community 16 - "theme_provider.dart"
Cohesion: 0.08
Nodes (20): AppAccent, AppCustomTheme, AppThemeType, _accent, currentAccent, currentTheme, currentType, dispose (+12 more)

### Community 17 - "main.dart"
Cohesion: 0.08
Nodes (14): onAuthenticated, resumedAfterLogin, runAuthenticatedAction, signedIn, authProvider, createState, dataProvider, didChangeAppLifecycleState (+6 more)

### Community 18 - "Анализ Предметной Области (ПО) Futrat"
Cohesion: 0.14
Nodes (13): 1.  Ключевые Сущности и Их Атрибуты, 1. Прогнозы Пользователей (Prediction Game), 1. Статистика Игроков и Команд, 1. Управление Пользователями, 2. Голосования, 2. Модуль Авторизации и Персонализации, 2. Персонализация (Модуль "Избранное"), 2. Турнирные Таблицы и Сетки (+5 more)

### Community 19 - "test_runtime.py"
Cohesion: 0.19
Nodes (4): test_existing_password_hash_can_log_in(), test_existing_postgresql_url_keeps_psycopg2_driver(), test_uvicorn_serves_http(), test_expired_token_is_rejected()

### Community 20 - "test_season_sync.py"
Cohesion: 0.14
Nodes (25): update_all_data(), database_lock(), event(), mock_source(), get(), scoreboard(), test_distinct_events_with_same_teams_keep_their_ids_and_results(), test_failed_day_is_retried_without_reimporting_completed_history() (+17 more)

### Community 21 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 22 - "Predictions, favorites and player profiles"
Cohesion: 0.33
Nodes (5): Approved brief, Constraints, Implementation order, Predictions, favorites and player profiles, Verification

### Community 24 - "widget_test.dart"
Cohesion: 0.12
Nodes (13): AppearanceDataProvider, currentStandings, FakeDataProvider, fetchFavorites, initData, isAuthenticated, league, main (+5 more)

### Community 26 - "profiles.py"
Cohesion: 0.40
Nodes (7): calendar_team(), matches_json(), player_matches(), player_profile(), profile(), team_matches(), team_query()

### Community 27 - "Phone connection over LAN"
Cohesion: 0.50
Nodes (3): Delivery, Phone connection over LAN, Resolved network issue

### Community 32 - "widgets/tournament_menu.dart"
Cohesion: 0.07
Nodes (23): _autoScroll, createState, data, dispose, favoriteIds, _group, id, _league (+15 more)

### Community 34 - "goal_sync.py"
Cohesion: 0.08
Nodes (41): observe_goal(), GoalClient, GoalError, find_league(), kickoff(), refresh_details(), resolve_team(), store_fixtures() (+33 more)

### Community 39 - "match_navigation_test.dart"
Cohesion: 0.09
Nodes (17): currentStandings, fake, favoriteTournaments, fixture, games, getMatchDetails, host, initData (+9 more)

### Community 41 - "forecasts_screen.dart"
Cohesion: 0.05
Nodes (37): cleanName, _countryTranslations, tr, api, _cancel, _checkMonth, _choices, _choose (+29 more)

### Community 42 - "lineup_view.dart"
Cohesion: 0.11
Nodes (14): build, _canRate, createState, _field, _fieldPlayer, match, onRate, paint (+6 more)

### Community 43 - "data.py"
Cohesion: 0.16
Nodes (13): is_live_match(), is_live_status(), get_match_details(), get_match_updates(), get_matches(), get_or_create_player(), get_standings(), get_tournaments() (+5 more)

### Community 44 - "team_screen.dart"
Cohesion: 0.09
Nodes (20): _anchor, api, build, _calendar, _center, createState, dispose, _generation (+12 more)

### Community 45 - "Deployment: Ubuntu, existing Caddy and PostgreSQL"
Cohesion: 0.06
Nodes (27): Android, Backups and restore, Caddy and IP HTTPS, Configuration, Database, Deployment: Ubuntu, existing Caddy and PostgreSQL, Existing local data, Networks (+19 more)

### Community 46 - "package:dio/dio.dart"
Cohesion: 0.14
Nodes (8): ApiClient, dio, _instance, storage, dio, player, playerMatches, team

### Community 47 - "users.py"
Cohesion: 0.27
Nodes (11): canonical_id(), add_favorite_player(), add_favorite_team(), add_favorite_tournament(), get_favorite_players(), get_favorite_teams(), get_favorite_tournaments(), get_leaderboard() (+3 more)

### Community 48 - "forecasts_test.dart"
Cohesion: 0.08
Nodes (19): allMatches, cancel, choose, count, ForecastData, game, games, isAuthenticated (+11 more)

### Community 49 - "player_screen.dart"
Cohesion: 0.10
Nodes (18): api, build, _calendar, _coverage, createState, _error, _generation, initState (+10 more)

### Community 50 - "auth_validation_test.dart"
Cohesion: 0.17
Nodes (7): auth, fail, fake, host, main, press, requests

### Community 51 - "models.py"
Cohesion: 0.25
Nodes (12): Forecast, ForecastDay, ForecastLedger, LineupDetail, MatchFormation, MatchHistoryJob, MatchLiveState, MatchResult (+4 more)

### Community 52 - "live_matches_test.dart"
Cohesion: 0.19
Nodes (5): main, game, main, liveGame, main

### Community 53 - "match_status.dart"
Cohesion: 0.29
Nodes (6): _clock, elapsed, isLiveMatch, isLiveStatus, _liveStatuses, liveWindow

### Community 54 - "conftest.py"
Cohesion: 0.18
Nodes (5): Team, block_external_http(), client(), db(), match()

### Community 55 - "national_standings.py"
Cohesion: 0.18
Nodes (6): seed_tournaments(), OfficialStandings, Tournament, get_standings(), sync_standings(), test_national_groups_use_official_points_instead_of_knockout_results()

### Community 56 - "profiles_test.dart"
Cohesion: 0.10
Nodes (11): lineupFixture, main, calendar, game, host, main, player, playerMatches (+3 more)

### Community 57 - "State"
Cohesion: 0.18
Nodes (12): FutratApp, _FutratAppState, FavoritesScreen, _FavoritesScreenState, ForecastsScreen, _ForecastsScreenState, HomeScreen, _HomeScreenState (+4 more)

### Community 58 - "tournament_menu_test.dart"
Cohesion: 0.14
Nodes (7): contrast, main, x, league, leagues, main, menu

### Community 61 - "core/tournament_menu.dart"
Cohesion: 0.09
Nodes (18): code, _countries, country, _countryCodes, _european, favorite, _group, key (+10 more)

### Community 62 - "grouped_matches_list.dart"
Cohesion: 0.13
Nodes (10): byLeague, feedId, groupMatchesByLeague, groups, LeagueMatches, match, matches, order (+2 more)

### Community 63 - "test_production.py"
Cohesion: 0.14
Nodes (6): Settings, production_settings(), test_production_accepts_dedicated_database(), test_production_rejects_unsafe_settings_without_echoing_secrets(), test_production_seeds_tournaments_without_a_test_user(), test_readiness_checks_database()

### Community 64 - "round_selector.dart"
Cohesion: 0.15
Nodes (12): build, _choose, createState, current, dispose, onChanged, _positioned, _RoundPicker (+4 more)

### Community 65 - "Appearance"
Cohesion: 0.40
Nodes (4): Appearance, Files and verification, Logo contrast — 20 October 2026, Visual rules

### Community 67 - "football_logo_test.dart"
Cohesion: 0.13
Nodes (9): badge, bytes, canvas, image, main, picture, pixels, recorder (+1 more)

### Community 68 - "favorites_screen.dart"
Cohesion: 0.08
Nodes (12): _buildEmptyState, _buildThemedLogo, _buildTournamentsList, createState, dispose, initState, _tabController, build (+4 more)

### Community 69 - "auth_screen.dart"
Cohesion: 0.15
Nodes (11): AuthScreen, _AuthScreenState, createState, dispose, _field, _formKey, _isRegister, _obscurePassword (+3 more)

### Community 70 - "tournament_menu_preferences.dart"
Cohesion: 0.10
Nodes (15): _changed, _collapsed, dispose, _disposed, isCollapsed, _key, _load, move (+7 more)

### Community 71 - "Season and match interface"
Cohesion: 0.40
Nodes (4): Delivery, Limits, Scope, Season and match interface

### Community 72 - "main.py"
Cohesion: 0.13
Nodes (9): validation_error(), sync_sources(), update_live_data(), update_live_feed(), lifespan(), readiness(), root(), start_sync() (+1 more)

### Community 76 - "make_prediction"
Cohesion: 0.36
Nodes (4): Prediction, add_favorite_team(), get_my_predictions(), make_prediction()

### Community 77 - "Stale live status correction"
Cohesion: 0.40
Nodes (4): Delivery, Files, Scope, Stale live status correction

### Community 80 - "Backend over the phone hotspot"
Cohesion: 0.29
Nodes (6): Address and build, Backend over the phone hotspot, Latest build — 20 October 2026, Verification without USB forwarding, Verified on 18 October 2026, Windows setup

### Community 81 - "test_security.py"
Cohesion: 0.26
Nodes (8): _bcrypt_password(), get_password_hash(), verify_password(), test_legacy_long_password_truncation(), test_passlib_hashes_remain_verifiable(), test_password_hashes_are_salted(), test_password_round_trip(), test_password_with_null_byte_is_rejected()

### Community 84 - "Player photos outside sports APIs"
Cohesion: 0.33
Nodes (5): Alternatives considered, Limits, Ordered implementation, Player photos outside sports APIs, Selected approach

### Community 85 - "DataProvider"
Cohesion: 0.11
Nodes (27): openAuthScreen, build, AuthProvider, DataProvider, ThemeProvider, TournamentMenuPreferences, build, build (+19 more)

### Community 86 - "auth.py"
Cohesion: 0.21
Nodes (8): get_current_user(), login(), nickname_taken(), raise_unique_conflict(), read_users_me(), register(), user_token(), update_user_profile()

### Community 88 - "utc_now"
Cohesion: 0.23
Nodes (12): cancel(), _game(), match_day(), _release(), settle(), utc_now(), ProviderCache, _discover_national_teams() (+4 more)

### Community 89 - "test_api.py"
Cohesion: 0.22
Nodes (9): create_access_token(), register(), test_duplicate_registration_is_rejected(), test_invalid_expired_and_missing_tokens_are_rejected(), test_lineup_player_can_be_favorited(), test_prediction_and_favorite_persist(), test_register_login_and_current_user(), test_existing_short_password_and_legacy_email_session_still_work() (+1 more)

### Community 92 - "test_registration.py"
Cohesion: 0.24
Nodes (12): delete_empty_account(), ensure_user_schema(), signup(), test_empty_account_cleanup_only_removes_verified_target_and_its_favorites(), test_invalid_registration_is_rejected_without_echoing_password(), test_legacy_nickname_migration_is_idempotent_and_refuses_collisions(), test_login_errors_are_readable_and_do_not_disclose_account_existence(), test_nickname_is_unique_after_normalization() (+4 more)

### Community 93 - "match_tile.dart"
Cohesion: 0.18
Nodes (6): MatchModel, build, caption, match, size, url

### Community 94 - "forecast_api.dart"
Cohesion: 0.20
Nodes (9): cancel, choose, dio, ForecastApi, mine, myRank, rankings, used (+1 more)

### Community 95 - "Live match classification"
Cohesion: 0.22
Nodes (5): API and app, Incident, Live match classification, Minute feed, Rule

### Community 96 - "MaterialPageRoute"
Cohesion: 0.29
Nodes (6): _buildPlayersList, _buildTeamsList, _games, _buildPairCard, build, _profile

### Community 98 - "package:flutter/material.dart"
Cohesion: 0.29
Nodes (3): build, child, team

### Community 100 - "Production deployment preparation"
Cohesion: 0.33
Nodes (5): Approved brief, Implementation, Production deployment preparation, Remaining server checks, Verification — 2026-10-22

### Community 101 - "User"
Cohesion: 0.60
Nodes (5): init_db(), User, test_production_accepts_admin_with_changed_password(), test_production_refuses_imported_development_account(), test_database_guards_nickname_races()

### Community 102 - "Tournament menu and forecast update"
Cohesion: 0.40
Nodes (4): Approved scope, Implementation, Tournament menu and forecast update, Verification

## Knowledge Gaps
- **579 isolated node(s):** `activeSeason`, `seasonLabel`, `_instance`, `dio`, `storage` (+574 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 913 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **29 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MatchModel` connect `match_tile.dart` to `all_models.dart`, `home_screen.dart`, `match_detail_screen.dart`, `lineup_view.dart`, `team_screen.dart`, `forecasts_test.dart`, `grouped_matches_list.dart`?**
  _High betweenness centrality (0.048) - this node is a cross-community bridge._
- **What connects `activeSeason`, `seasonLabel`, `_instance` to the rest of the system?**
  _579 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `all_models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02197802197802198 - nodes in this community are weakly interconnected._
- **Why does `DataProvider` connect `DataProvider` to `MaterialPageRoute`, `widgets/tournament_menu.dart`, `home_screen.dart`, `data_provider.dart`, `favorites_screen.dart`, `match_navigation_test.dart`, `forecasts_screen.dart`, `match_detail_screen.dart`, `lineup_view.dart`, `team_screen.dart`, `forecasts_test.dart`, `main.dart`, `player_screen.dart`, `widget_test.dart`, `profiles_test.dart`, `State`, `grouped_matches_list.dart`?**
  _High betweenness centrality (0.036) - this node is a cross-community bridge._
- **Should `win32_window.cpp` be split into smaller, more focused modules?**
  _Cohesion score 0.05268065268065268 - nodes in this community are weakly interconnected._
- **Why does `db()` connect `conftest.py` to `goal_sync.py`, `User`, `Deployment: Ubuntu, existing Caddy and PostgreSQL`, `match_sync.py`, `utc_now`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Should `home_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03773584905660377 - nodes in this community are weakly interconnected._
# Graph Report - futrat  (2026-10-22)

## Corpus Check
- 144 files · ~76,391 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 65 file(s) not represented in the graph (top: (none) 12, .xml 9, .xcconfig 8)

## Summary
- 1543 nodes · 2861 edges · 98 communities (72 shown, 26 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 58 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- all_models.dart
- FlutterWindow
- home_screen.dart
- data_provider.dart
- .application
- schemas.py
- my_application.cc
- string
- Match navigation and typography
- match_detail_screen.dart
- app/forecasts.py
- auth_provider.dart
- app_theme.dart
- football_logo.dart
- match_sync.py
- Match
- theme_provider.dart
- main.dart
- Анализ Предметной Области (ПО) Futrat
- test_api.py
- test_season_sync.py
- manifest.json
- Predictions, favorites and player profiles
- futrat_mobile
- widget_test.dart
- LaunchImage.imageset/README.md
- utc_now
- Phone connection over LAN
- constants.dart
- Implementation checklist
- FlutterActivity
- test_profiles.py
- goal_sync.py
- match_navigation_test.dart
- accent-live-feed.md
- forecasts_screen.dart
- lineup_view.dart
- app/__init__.py
- team_screen.dart
- Deployment: Ubuntu, existing Caddy and PostgreSQL
- forecast_api.dart
- users.py
- forecasts_test.dart
- player_screen.dart
- auth_validation_test.dart
- models.py
- live_matches_test.dart
- match_status.dart
- conftest.py
- Base
- profiles_test.dart
- DataProvider
- package:flutter_secure_storage/flutter_secure_storage.dart
- branding/README.md
- _onItemTapped
- grouped_matches_list.dart
- test_production.py
- round_selector.dart
- Appearance
- appearance-plan.md
- football_logo_test.dart
- favorites_screen.dart
- auth_screen.dart
- lineups.py
- Season and match interface
- main.py
- fonts/README.md
- match-navigation-plan.md
- live_sync.py
- predictions.py
- Stale live status correction
- lineup-selector.md
- active_season.dart
- Backend over the phone hotspot
- test_security.py
- Player photos outside sports APIs
- package:flutter/material.dart
- auth.py
- logo-contrast-and-photos.md
- Minute live updates
- get_match_details
- win32_window.cpp
- registration-fix.md
- test_registration.py
- Win32Window
- .MessageHandler
- Point
- Size
- backup.sh

## God Nodes (most connected - your core abstractions)
1. `DataProvider` - 49 edges
2. `utc()` - 26 edges
3. `ThemeProvider` - 26 edges
4. `utc_now()` - 25 edges
5. `Win32Window` - 21 edges
6. `AuthProvider` - 20 edges
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

## Communities (98 total, 26 thin omitted)

### Community 0 - "all_models.dart"
Cohesion: 0.02
Nodes (87): apiCode, appeared, assists, awayTeam, cornersAway, cornersHome, country, currentSeason (+79 more)

### Community 1 - "FlutterWindow"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 2 - "home_screen.dart"
Cohesion: 0.04
Nodes (49): _activeStageFilter, addMatch, awayToken, _bracketRow, _buildBracketColumn, _buildDrawer, _buildDynamicTable, _buildLogo (+41 more)

### Community 3 - "data_provider.dart"
Cohesion: 0.04
Nodes (45): cleanName, _countryTranslations, tr, _allMatches, clearFavorites, _client, _collapsedLeagues, _currentStandings (+37 more)

### Community 4 - ".application"
Cohesion: 0.09
Nodes (10): Cocoa, Flutter, FlutterMacOS, AppDelegate, RunnerTests, AppDelegate, MainFlutterWindow, RunnerTests (+2 more)

### Community 5 - "schemas.py"
Cohesion: 0.07
Nodes (29): is_live_match(), is_live_status(), rate_player(), LeaderboardEntry, LineupPlayerResponse, MatchEventResponse, MatchLiveUpdate, MatchResponse (+21 more)

### Community 6 - "my_application.cc"
Cohesion: 0.10
Nodes (13): main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 7 - "string"
Cohesion: 0.12
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 8 - "Match navigation and typography"
Cohesion: 0.20
Nodes (9): Font and files, League tabs and rounds, Lineup team selector, Live status correction, Match feeds, Match navigation and typography, Season and ratings, Team profiles (+1 more)

### Community 9 - "match_detail_screen.dart"
Cohesion: 0.11
Nodes (15): _buildStats, _buildTimeline, createState, _currentMatch, dispose, _evContent, _getRatingColor, initState (+7 more)

### Community 10 - "app/forecasts.py"
Cohesion: 0.10
Nodes (32): cancel(), choose(), _game(), leaderboard(), _lock_day(), match_day(), quota(), record_result() (+24 more)

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
Nodes (13): espn(), goal(), minute(), write(), assign_rounds(), calendar_days(), discover_calendar(), fetch_day() (+5 more)

### Community 15 - "Match"
Cohesion: 0.33
Nodes (7): Match, Storage and API, add_game(), instant(), test_profile_defaults_and_cursor_share_public_season_filter(), test_public_lists_keep_only_2627_clubs_calendar_mls_and_current_national(), test_team_timeline_has_last_finished_anchor_all_competitions_and_history_above()

### Community 16 - "theme_provider.dart"
Cohesion: 0.07
Nodes (20): AppAccent, AppCustomTheme, AppThemeType, _accent, currentAccent, currentTheme, currentType, dispose (+12 more)

### Community 17 - "main.dart"
Cohesion: 0.10
Nodes (12): authProvider, createState, dataProvider, didChangeAppLifecycleState, dispose, FutratApp, _FutratAppState, initState (+4 more)

### Community 18 - "Анализ Предметной Области (ПО) Futrat"
Cohesion: 0.14
Nodes (13): 1.  Ключевые Сущности и Их Атрибуты, 1. Прогнозы Пользователей (Prediction Game), 1. Статистика Игроков и Команд, 1. Управление Пользователями, 2. Голосования, 2. Модуль Авторизации и Персонализации, 2. Персонализация (Модуль "Избранное"), 2. Турнирные Таблицы и Сетки (+5 more)

### Community 19 - "test_api.py"
Cohesion: 0.15
Nodes (8): register(), test_duplicate_registration_is_rejected(), test_existing_password_hash_can_log_in(), test_lineup_player_can_be_favorited(), test_prediction_and_favorite_persist(), test_register_login_and_current_user(), test_existing_postgresql_url_keeps_psycopg2_driver(), test_uvicorn_serves_http()

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

### Community 26 - "utc_now"
Cohesion: 0.19
Nodes (15): utc_now(), _discover_national_teams(), _photo(), queue_player(), update_player_data(), calendar_team(), matches_json(), player_matches() (+7 more)

### Community 27 - "Phone connection over LAN"
Cohesion: 0.50
Nodes (3): Delivery, Phone connection over LAN, Resolved network issue

### Community 32 - "test_profiles.py"
Cohesion: 0.38
Nodes (10): store_details(), enrich_espn(), roster(), test_goal_match_rating_comes_only_from_the_fixture_player_block(), test_goal_photo_and_position_are_kept_without_season_rating_fallback(), test_lineup_refresh_keeps_user_rating_ids(), test_player_history_only_contains_confirmed_appearances(), test_rating_unused_substitute_is_rejected() (+2 more)

### Community 34 - "goal_sync.py"
Cohesion: 0.12
Nodes (24): observe_goal(), GoalClient, GoalError, find_league(), kickoff(), refresh_details(), resolve_team(), store_fixtures() (+16 more)

### Community 39 - "match_navigation_test.dart"
Cohesion: 0.09
Nodes (17): currentStandings, fake, favoriteTournaments, fixture, games, getMatchDetails, host, initData (+9 more)

### Community 41 - "forecasts_screen.dart"
Cohesion: 0.07
Nodes (26): api, _cancel, _choices, _choose, createState, _day, dispose, _empty (+18 more)

### Community 42 - "lineup_view.dart"
Cohesion: 0.11
Nodes (14): build, _canRate, createState, _field, _fieldPlayer, match, onRate, paint (+6 more)

### Community 43 - "app/__init__.py"
Cohesion: 0.23
Nodes (5): get_standings(), get_match_updates(), get_matches(), get_standings(), get_tournaments()

### Community 44 - "team_screen.dart"
Cohesion: 0.09
Nodes (18): _anchor, api, build, _calendar, _center, createState, dispose, _generation (+10 more)

### Community 45 - "Deployment: Ubuntu, existing Caddy and PostgreSQL"
Cohesion: 0.06
Nodes (27): Android, Backups and restore, Caddy and IP HTTPS, Configuration, Database, Deployment: Ubuntu, existing Caddy and PostgreSQL, Existing local data, Networks (+19 more)

### Community 46 - "forecast_api.dart"
Cohesion: 0.10
Nodes (15): ApiClient, dio, _instance, storage, cancel, choose, dio, mine (+7 more)

### Community 47 - "users.py"
Cohesion: 0.20
Nodes (14): canonical_id(), nickname_taken(), raise_unique_conflict(), add_favorite_player(), add_favorite_team(), add_favorite_tournament(), get_favorite_players(), get_favorite_teams() (+6 more)

### Community 48 - "forecasts_test.dart"
Cohesion: 0.10
Nodes (16): ForecastApi, allMatches, choose, count, FakeForecastApi, ForecastData, game, isAuthenticated (+8 more)

### Community 49 - "player_screen.dart"
Cohesion: 0.10
Nodes (18): ProfileApi, api, build, _calendar, _coverage, createState, _error, _generation (+10 more)

### Community 50 - "auth_validation_test.dart"
Cohesion: 0.17
Nodes (7): auth, fail, fake, host, main, press, requests

### Community 51 - "models.py"
Cohesion: 0.23
Nodes (12): Forecast, ForecastDay, ForecastLedger, LineupDetail, MatchFormation, MatchHistoryJob, MatchLiveState, MatchResult (+4 more)

### Community 52 - "live_matches_test.dart"
Cohesion: 0.19
Nodes (5): main, game, main, liveGame, main

### Community 53 - "match_status.dart"
Cohesion: 0.29
Nodes (6): _clock, elapsed, isLiveMatch, isLiveStatus, _liveStatuses, liveWindow

### Community 54 - "conftest.py"
Cohesion: 0.14
Nodes (7): seed_tournaments(), Team, Tournament, block_external_http(), client(), db(), match()

### Community 55 - "Base"
Cohesion: 0.14
Nodes (13): MatchLineup, OfficialStandings, Prediction, ProviderCache, ProviderMatch, ProviderTeam, ProviderUsage, TournamentSyncState (+5 more)

### Community 56 - "profiles_test.dart"
Cohesion: 0.13
Nodes (9): calendar, game, host, main, player, playerMatches, requestedSeasons, team (+1 more)

### Community 57 - "DataProvider"
Cohesion: 0.12
Nodes (25): openAuthScreen, AuthProvider, DataProvider, AuthScreen, _AuthScreenState, FavoritesScreen, _FavoritesScreenState, build (+17 more)

### Community 58 - "package:flutter_secure_storage/flutter_secure_storage.dart"
Cohesion: 0.29
Nodes (3): contrast, main, x

### Community 62 - "grouped_matches_list.dart"
Cohesion: 0.06
Nodes (25): MatchModel, LeaderboardScreen, byLeague, feedId, GroupedMatchesList, groupMatchesByLeague, groups, LeagueMatches (+17 more)

### Community 63 - "test_production.py"
Cohesion: 0.13
Nodes (11): Settings, init_db(), User, production_settings(), test_production_accepts_admin_with_changed_password(), test_production_accepts_dedicated_database(), test_production_refuses_imported_development_account(), test_production_rejects_unsafe_settings_without_echoing_secrets() (+3 more)

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
Cohesion: 0.10
Nodes (13): build, _buildEmptyState, _buildPlayersList, _buildTeamsList, _buildThemedLogo, createState, dispose, initState (+5 more)

### Community 69 - "auth_screen.dart"
Cohesion: 0.15
Nodes (10): build, createState, dispose, _field, _formKey, _isRegister, _obscurePassword, _passwordController (+2 more)

### Community 70 - "lineups.py"
Cohesion: 0.39
Nodes (6): attach(), bind_player(), enrich_goal(), formation(), number(), safe_photo()

### Community 71 - "Season and match interface"
Cohesion: 0.40
Nodes (4): Delivery, Limits, Scope, Season and match interface

### Community 72 - "main.py"
Cohesion: 0.16
Nodes (9): validation_error(), sync_sources(), update_live_data(), update_live_feed(), lifespan(), readiness(), root(), start_sync() (+1 more)

### Community 75 - "live_sync.py"
Cohesion: 0.15
Nodes (19): observe_espn(), apply_espn(), apply_goal(), find_event(), refresh(), scoreboard(), writer_lock(), event() (+11 more)

### Community 76 - "predictions.py"
Cohesion: 0.43
Nodes (3): add_favorite_team(), get_my_predictions(), make_prediction()

### Community 77 - "Stale live status correction"
Cohesion: 0.40
Nodes (4): Delivery, Files, Scope, Stale live status correction

### Community 80 - "Backend over the phone hotspot"
Cohesion: 0.29
Nodes (6): Address and build, Backend over the phone hotspot, Latest build — 20 October 2026, Verification without USB forwarding, Verified on 18 October 2026, Windows setup

### Community 81 - "test_security.py"
Cohesion: 0.17
Nodes (13): _bcrypt_password(), create_access_token(), get_password_hash(), verify_password(), test_invalid_expired_and_missing_tokens_are_rejected(), test_existing_short_password_and_legacy_email_session_still_work(), test_expired_token_is_rejected(), test_legacy_long_password_truncation() (+5 more)

### Community 84 - "Player photos outside sports APIs"
Cohesion: 0.33
Nodes (5): Alternatives considered, Limits, Ordered implementation, Player photos outside sports APIs, Selected approach

### Community 85 - "package:flutter/material.dart"
Cohesion: 0.10
Nodes (16): onAuthenticated, resumedAfterLogin, runAuthenticatedAction, signedIn, build, ThemeProvider, build, build (+8 more)

### Community 86 - "auth.py"
Cohesion: 0.20
Nodes (5): get_current_user(), login(), read_users_me(), register(), user_token()

### Community 88 - "Minute live updates"
Cohesion: 0.33
Nodes (5): Display, Minute live updates, Provider priority, Refresh, Verification

### Community 89 - "get_match_details"
Cohesion: 0.18
Nodes (11): decorate(), MatchEvent, Player, get_match_details(), get_or_create_player(), API and errors, Identity and compatibility, Nickname registration (+3 more)

### Community 90 - "win32_window.cpp"
Cohesion: 0.19
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 92 - "test_registration.py"
Cohesion: 0.20
Nodes (12): delete_empty_account(), ensure_user_schema(), signup(), test_empty_account_cleanup_only_removes_verified_target_and_its_favorites(), test_invalid_registration_is_rejected_without_echoing_password(), test_legacy_nickname_migration_is_idempotent_and_refuses_collisions(), test_login_errors_are_readable_and_do_not_disclose_account_existence(), test_nickname_is_unique_after_normalization() (+4 more)

### Community 93 - "Win32Window"
Cohesion: 0.21
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 95 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 96 - "Size"
Cohesion: 0.50
Nodes (3): Size, height, width

## Knowledge Gaps
- **508 isolated node(s):** `activeSeason`, `seasonLabel`, `_instance`, `dio`, `storage` (+503 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 829 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **26 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MatchModel` connect `grouped_matches_list.dart` to `all_models.dart`, `home_screen.dart`, `match_detail_screen.dart`, `lineup_view.dart`, `team_screen.dart`, `forecasts_test.dart`?**
  _High betweenness centrality (0.058) - this node is a cross-community bridge._
- **What connects `activeSeason`, `seasonLabel`, `_instance` to the rest of the system?**
  _508 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `all_models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.021739130434782608 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `Win32Window` to `Size`, `FlutterWindow`, `string`, `win32_window.cpp`, `.MessageHandler`, `Point`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **Should `FlutterWindow` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._
- **Why does `db()` connect `conftest.py` to `goal_sync.py`, `live_sync.py`, `Deployment: Ubuntu, existing Caddy and PostgreSQL`, `match_sync.py`, `utc_now`, `test_production.py`?**
  _High betweenness centrality (0.034) - this node is a cross-community bridge._
- **Should `home_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03773584905660377 - nodes in this community are weakly interconnected._
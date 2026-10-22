# Graph Report - futrat  (2026-10-18)

## Corpus Check
- 122 files · ~65,080 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 64 file(s) not represented in the graph (top: (none) 12, .xml 9, .xcconfig 8)

## Summary
- 1335 nodes · 2423 edges · 84 communities (59 shown, 25 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 48 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `228fc984`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- all_models.dart
- FlutterWindow
- home_screen.dart
- data_provider.dart
- .application
- schemas.py
- my_application.cc
- utils.cpp
- DataProvider
- match_detail_screen.dart
- match_sync.py
- auth_provider.dart
- app_theme.dart
- _onItemTapped
- conftest.py
- api_client.dart
- theme_provider.dart
- main.dart
- Анализ Предметной Области (ПО) Futrat
- test_security.py
- test_season_sync.py
- manifest.json
- Predictions, favorites and player profiles
- futrat_mobile
- widget_test.dart
- LaunchImage.imageset/README.md
- player_screen.dart
- Win32Window
- constants.dart
- Implementation checklist
- FlutterActivity
- lineups.py
- goal_sync.py
- match_navigation_test.dart
- win32_window.cpp
- forecasts_screen.dart
- lineup_view.dart
- data.py
- team_screen.dart
- Прогнозы, избранное и профили
- forecast_api.dart
- forecasts_test.dart
- State
- .MessageHandler
- models.py
- live_matches_test.dart
- match_status.dart
- main.py
- Point
- profiles_test.dart
- AuthProvider
- current_matches
- branding/README.md
- users.py
- grouped_matches_list.dart
- get_match_details
- round_selector.dart
- Appearance
- appearance-plan.md
- test_goal_api.py
- favorites_screen.dart
- profiles.py
- Base
- Season and match interface
- is_live_match
- fonts/README.md
- match-navigation-plan.md
- player_history.py
- package:flutter/material.dart
- Stale live status correction
- lineup-selector.md
- active_season.dart
- Backend over the phone hotspot
- read_users_me

## God Nodes (most connected - your core abstractions)
1. `DataProvider` - 46 edges
2. `ThemeProvider` - 27 edges
3. `Win32Window` - 21 edges
4. `utc_now()` - 20 edges
5. `AuthProvider` - 19 edges
6. `choose()` - 18 edges
7. `utc()` - 18 edges
8. `GoalError` - 17 edges
9. `update_all_data()` - 16 edges
10. `enrich_espn()` - 14 edges

## Surprising Connections (you probably didn't know these)
- `Проверка` --references--> `db()`  [INFERRED]
  futrat_backend/README.md → futrat_backend/tests/conftest.py
- `Active season 2026/27` --references--> `current_matches()`  [INFERRED]
  futrat_backend/docs/active-season.md → futrat_backend/app/seasons.py
- `test_failed_or_invalid_goal_payload_is_not_cached()` --uses--> `GoalError`  [INFERRED]
  futrat_backend/tests/test_goal_api.py → futrat_backend/app/goal_api.py
- `test_goal_429_honors_persistent_cooldown()` --uses--> `GoalError`  [INFERRED]
  futrat_backend/tests/test_goal_api.py → futrat_backend/app/goal_api.py
- `test_goal_cache_and_persistent_budget()` --uses--> `GoalError`  [INFERRED]
  futrat_backend/tests/test_goal_api.py → futrat_backend/app/goal_api.py

## Import Cycles
- None detected.

## Communities (84 total, 25 thin omitted)

### Community 0 - "all_models.dart"
Cohesion: 0.02
Nodes (84): apiCode, appeared, assists, awayTeam, cornersAway, cornersHome, country, currentSeason (+76 more)

### Community 1 - "FlutterWindow"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 2 - "home_screen.dart"
Cohesion: 0.04
Nodes (50): _activeStageFilter, addMatch, awayToken, _bracketRow, _buildBracketColumn, _buildDrawer, _buildDynamicTable, _buildLogo (+42 more)

### Community 3 - "data_provider.dart"
Cohesion: 0.04
Nodes (42): cleanName, _countryTranslations, tr, _allMatches, clearFavorites, _client, _collapsedLeagues, _currentStandings (+34 more)

### Community 4 - ".application"
Cohesion: 0.09
Nodes (10): Cocoa, Flutter, FlutterMacOS, AppDelegate, RunnerTests, AppDelegate, MainFlutterWindow, RunnerTests (+2 more)

### Community 5 - "schemas.py"
Cohesion: 0.06
Nodes (35): login(), register(), add_favorite_team(), get_my_predictions(), make_prediction(), LeaderboardEntry, LineupPlayerResponse, MatchEventResponse (+27 more)

### Community 6 - "my_application.cc"
Cohesion: 0.10
Nodes (13): main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 7 - "utils.cpp"
Cohesion: 0.18
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 8 - "DataProvider"
Cohesion: 0.14
Nodes (18): DataProvider, ThemeProvider, build, initState, build, LeaderboardScreen, build, _calculateSelectedIndex (+10 more)

### Community 9 - "match_detail_screen.dart"
Cohesion: 0.10
Nodes (16): _buildStats, _buildTimeline, createState, _currentMatch, dispose, _evContent, _getProxyUrl, _getRatingColor (+8 more)

### Community 10 - "match_sync.py"
Cohesion: 0.07
Nodes (44): cancel(), choose(), _game(), leaderboard(), _lock_day(), match_day(), observe_espn(), observe_goal() (+36 more)

### Community 11 - "auth_provider.dart"
Cohesion: 0.10
Nodes (15): checkAuth, clearError, _client, _currentUser, _errorMessage, fetchProfile, isAuthenticated, _isLoading (+7 more)

### Community 12 - "app_theme.dart"
Cohesion: 0.07
Nodes (22): accentColor, accentFill, AppTheme, background, cardBg, cardBorder, color, _contrast (+14 more)

### Community 14 - "conftest.py"
Cohesion: 0.13
Nodes (9): block_external_http(), client(), db(), fake_scoreboard(), test_api_starts_while_season_source_is_still_waiting(), get(), test_match_sync_inserts_and_updates_without_duplicates(), test_scheduler_executes_match_sync_in_background() (+1 more)

### Community 15 - "api_client.dart"
Cohesion: 0.25
Nodes (4): ApiClient, dio, _instance, storage

### Community 16 - "theme_provider.dart"
Cohesion: 0.07
Nodes (20): AppAccent, AppCustomTheme, AppThemeType, _accent, currentAccent, currentTheme, currentType, dispose (+12 more)

### Community 17 - "main.dart"
Cohesion: 0.11
Nodes (11): authProvider, build, createState, dataProvider, dispose, FutratApp, _FutratAppState, main (+3 more)

### Community 18 - "Анализ Предметной Области (ПО) Futrat"
Cohesion: 0.14
Nodes (13): 1.  Ключевые Сущности и Их Атрибуты, 1. Прогнозы Пользователей (Prediction Game), 1. Статистика Игроков и Команд, 1. Управление Пользователями, 2. Голосования, 2. Модуль Авторизации и Персонализации, 2. Персонализация (Модуль "Избранное"), 2. Турнирные Таблицы и Сетки (+5 more)

### Community 19 - "test_security.py"
Cohesion: 0.08
Nodes (21): Settings, _bcrypt_password(), create_access_token(), get_password_hash(), verify_password(), register(), test_duplicate_registration_is_rejected(), test_existing_password_hash_can_log_in() (+13 more)

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

### Community 26 - "player_screen.dart"
Cohesion: 0.10
Nodes (18): ProfileApi, api, build, _calendar, _coverage, createState, _error, _generation (+10 more)

### Community 27 - "Win32Window"
Cohesion: 0.24
Nodes (4): Win32Window, child_content_, quit_on_close_, window_handle_

### Community 32 - "lineups.py"
Cohesion: 0.19
Nodes (19): store_details(), attach(), bind_player(), enrich_espn(), enrich_goal(), formation(), number(), safe_photo() (+11 more)

### Community 34 - "goal_sync.py"
Cohesion: 0.22
Nodes (9): GoalClient, GoalError, find_league(), kickoff(), refresh_details(), resolve_team(), store_fixtures(), sync_goal() (+1 more)

### Community 39 - "match_navigation_test.dart"
Cohesion: 0.09
Nodes (17): currentStandings, fake, favoriteTournaments, fixture, games, getMatchDetails, host, initData (+9 more)

### Community 40 - "win32_window.cpp"
Cohesion: 0.18
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 41 - "forecasts_screen.dart"
Cohesion: 0.07
Nodes (25): api, _cancel, _choices, _choose, createState, _day, dispose, _empty (+17 more)

### Community 42 - "lineup_view.dart"
Cohesion: 0.10
Nodes (16): build, _canRate, createState, _field, _fieldPlayer, LineupView, _LineupViewState, match (+8 more)

### Community 44 - "team_screen.dart"
Cohesion: 0.10
Nodes (17): _anchor, api, _calendar, _center, createState, dispose, _generation, initState (+9 more)

### Community 45 - "Прогнозы, избранное и профили"
Cohesion: 0.11
Nodes (16): Источники футбольных данных, Настройка GOAL, Проверка и откат, Список турниров — 31, API, Избранное и история, Основные файлы, Правила прогнозов (+8 more)

### Community 46 - "forecast_api.dart"
Cohesion: 0.12
Nodes (13): cancel, choose, dio, ForecastApi, mine, myRank, rankings, used (+5 more)

### Community 48 - "forecasts_test.dart"
Cohesion: 0.11
Nodes (14): allMatches, choose, count, ForecastData, game, isAuthenticated, main, mine (+6 more)

### Community 49 - "State"
Cohesion: 0.22
Nodes (10): FavoritesScreen, _FavoritesScreenState, ForecastsScreen, _ForecastsScreenState, HomeScreen, _HomeScreenState, PlayerScreen, _PlayerScreenState (+2 more)

### Community 51 - "models.py"
Cohesion: 0.31
Nodes (10): Forecast, ForecastDay, ForecastLedger, LineupDetail, MatchFormation, MatchHistoryJob, MatchResult, PlayerAlias (+2 more)

### Community 52 - "live_matches_test.dart"
Cohesion: 0.20
Nodes (3): main, game, main

### Community 53 - "match_status.dart"
Cohesion: 0.29
Nodes (6): _clock, elapsed, isLiveMatch, isLiveStatus, _liveStatuses, liveWindow

### Community 54 - "main.py"
Cohesion: 0.19
Nodes (11): seed_tournaments(), init_db(), seed_tournaments(), sync_sources(), update_live_data(), lifespan(), root(), start_sync() (+3 more)

### Community 55 - "Point"
Cohesion: 0.21
Nodes (6): Point, x, y, Size, height, width

### Community 56 - "profiles_test.dart"
Cohesion: 0.10
Nodes (11): lineupFixture, main, calendar, game, host, main, player, playerMatches (+3 more)

### Community 57 - "AuthProvider"
Cohesion: 0.09
Nodes (21): onAuthenticated, openAuthScreen, resumedAfterLogin, runAuthenticatedAction, signedIn, AuthProvider, AuthScreen, _AuthScreenState (+13 more)

### Community 58 - "current_matches"
Cohesion: 0.24
Nodes (11): Match, Team, Tournament, current_matches(), Active season 2026/27, match(), add_game(), instant() (+3 more)

### Community 61 - "users.py"
Cohesion: 0.24
Nodes (12): canonical_id(), add_favorite_player(), add_favorite_team(), add_favorite_tournament(), get_favorite_players(), get_favorite_teams(), get_favorite_tournaments(), get_leaderboard() (+4 more)

### Community 62 - "grouped_matches_list.dart"
Cohesion: 0.06
Nodes (27): MatchModel, byLeague, feedId, GroupedMatchesList, groupMatchesByLeague, groups, LeagueMatches, _Logo (+19 more)

### Community 63 - "get_match_details"
Cohesion: 0.21
Nodes (8): decorate(), MatchEvent, get_standings(), get_match_details(), get_matches(), get_standings(), get_tournaments(), rate_player()

### Community 64 - "round_selector.dart"
Cohesion: 0.15
Nodes (12): build, _choose, createState, current, dispose, onChanged, _positioned, _RoundPicker (+4 more)

### Community 65 - "Appearance"
Cohesion: 0.50
Nodes (3): Appearance, Files and verification, Visual rules

### Community 67 - "test_goal_api.py"
Cohesion: 0.21
Nodes (10): OfficialStandings, client(), fixture(), test_failed_or_invalid_goal_payload_is_not_cached(), test_goal_429_honors_persistent_cooldown(), test_goal_cache_and_persistent_budget(), test_goal_pagination_reads_every_page_and_rejects_stuck_offsets(), test_goal_rejects_other_league_and_history_without_hiding_existing_season() (+2 more)

### Community 68 - "favorites_screen.dart"
Cohesion: 0.10
Nodes (14): build, _buildEmptyState, _buildPlayersList, _buildTeamsList, _buildThemedLogo, createState, dispose, _getProxyUrl (+6 more)

### Community 69 - "profiles.py"
Cohesion: 0.40
Nodes (7): calendar_team(), matches_json(), player_matches(), player_profile(), profile(), team_matches(), team_query()

### Community 70 - "Base"
Cohesion: 0.16
Nodes (12): MatchLineup, Prediction, ProviderMatch, ProviderTeam, ProviderUsage, TournamentSyncState, User, UserPlayerRating (+4 more)

### Community 71 - "Season and match interface"
Cohesion: 0.40
Nodes (4): Delivery, Limits, Scope, Season and match interface

### Community 72 - "is_live_match"
Cohesion: 0.24
Nodes (5): is_live_match(), is_live_status(), test_live_api_excludes_august_fixture_but_keeps_it_in_history(), test_live_api_rejects_non_live_statuses(), test_live_window_crosses_midnight_and_accepts_espn_clock()

### Community 75 - "player_history.py"
Cohesion: 0.42
Nodes (6): ProviderCache, _discover_national_teams(), _photo(), queue_player(), update_player_data(), season_year()

### Community 76 - "package:flutter/material.dart"
Cohesion: 0.29
Nodes (3): contrast, main, x

### Community 77 - "Stale live status correction"
Cohesion: 0.40
Nodes (4): Delivery, Files, Scope, Stale live status correction

### Community 80 - "Backend over the phone hotspot"
Cohesion: 0.40
Nodes (4): Address and build, Backend over the phone hotspot, Verification without USB forwarding, Windows setup

## Knowledge Gaps
- **462 isolated node(s):** `activeSeason`, `seasonLabel`, `_instance`, `dio`, `storage` (+457 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 722 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **25 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MatchModel` connect `grouped_matches_list.dart` to `all_models.dart`, `home_screen.dart`, `match_detail_screen.dart`, `lineup_view.dart`, `team_screen.dart`, `forecasts_test.dart`?**
  _High betweenness centrality (0.077) - this node is a cross-community bridge._
- **What connects `activeSeason`, `seasonLabel`, `_instance` to the rest of the system?**
  _462 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `all_models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02247191011235955 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `Win32Window` to `FlutterWindow`, `win32_window.cpp`, `flutter_window.h`, `.MessageHandler`, `Point`?**
  _High betweenness centrality (0.044) - this node is a cross-community bridge._
- **Should `FlutterWindow` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._
- **Why does `DataProvider` connect `DataProvider` to `home_screen.dart`, `data_provider.dart`, `favorites_screen.dart`, `match_navigation_test.dart`, `forecasts_screen.dart`, `match_detail_screen.dart`, `lineup_view.dart`, `team_screen.dart`, `forecasts_test.dart`, `State`, `widget_test.dart`, `profiles_test.dart`, `AuthProvider`, `player_screen.dart`, `grouped_matches_list.dart`?**
  _High betweenness centrality (0.038) - this node is a cross-community bridge._
- **Should `home_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03636363636363636 - nodes in this community are weakly interconnected._
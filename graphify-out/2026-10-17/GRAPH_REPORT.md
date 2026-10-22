# Graph Report - futrat  (2026-10-17)

## Corpus Check
- 96 files · ~56,303 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 60 file(s) not represented in the graph (top: (none) 12, .xml 9, .xcconfig 8)

## Summary
- 1140 nodes · 2135 edges · 61 communities (44 shown, 17 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 45 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- all_models.dart
- FlutterWindow
- home_screen.dart
- data_provider.dart
- .application
- schemas.py
- my_application.cc
- utils.cpp
- favorites_screen.dart
- match_detail_screen.dart
- app/forecasts.py
- auth_provider.dart
- app_theme.dart
- _onItemTapped
- users.py
- DataProvider
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
- models.py
- test_goal_api.py
- profiles.py
- win32_window.cpp
- forecasts_screen.dart
- lineup_view.dart
- Base
- team_screen.dart
- Прогнозы, избранное и профили
- forecast_api.dart
- forecasts_test.dart
- State
- .MessageHandler
- api_client.dart
- lineups.py
- match_tile.dart
- goal_sync.py
- Point
- profiles_test.dart
- discover_calendar
- branding/README.md

## God Nodes (most connected - your core abstractions)
1. `DataProvider` - 40 edges
2. `ThemeProvider` - 25 edges
3. `utc_now()` - 21 edges
4. `Win32Window` - 21 edges
5. `choose()` - 18 edges
6. `utc()` - 18 edges
7. `AuthProvider` - 18 edges
8. `GoalError` - 17 edges
9. `update_all_data()` - 16 edges
10. `store_fixtures()` - 13 edges

## Surprising Connections (you probably didn't know these)
- `Проверка` --references--> `db()`  [INFERRED]
  futrat_backend/README.md → futrat_backend/tests/conftest.py
- `test_failed_or_invalid_goal_payload_is_not_cached()` --uses--> `GoalError`  [INFERRED]
  futrat_backend/tests/test_goal_api.py → futrat_backend/app/goal_api.py
- `test_goal_429_honors_persistent_cooldown()` --uses--> `GoalError`  [INFERRED]
  futrat_backend/tests/test_goal_api.py → futrat_backend/app/goal_api.py
- `test_goal_cache_and_persistent_budget()` --uses--> `GoalError`  [INFERRED]
  futrat_backend/tests/test_goal_api.py → futrat_backend/app/goal_api.py
- `test_goal_pagination_reads_every_page_and_rejects_stuck_offsets()` --uses--> `GoalError`  [INFERRED]
  futrat_backend/tests/test_goal_api.py → futrat_backend/app/goal_api.py

## Import Cycles
- None detected.

## Communities (61 total, 17 thin omitted)

### Community 0 - "all_models.dart"
Cohesion: 0.02
Nodes (80): apiCode, appeared, assists, awayTeam, cornersAway, cornersHome, country, currentSeason (+72 more)

### Community 1 - "FlutterWindow"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 2 - "home_screen.dart"
Cohesion: 0.04
Nodes (49): _activeStageFilter, addMatch, awayToken, _bracketRow, _buildBracketColumn, _buildDrawer, _buildDynamicTable, _buildLogo (+41 more)

### Community 3 - "data_provider.dart"
Cohesion: 0.05
Nodes (36): _allMatches, clearFavorites, _client, _currentStandings, dispose, _favoritePlayers, _favoriteTeams, _favoriteTournaments (+28 more)

### Community 4 - ".application"
Cohesion: 0.09
Nodes (10): Cocoa, Flutter, FlutterMacOS, AppDelegate, RunnerTests, AppDelegate, MainFlutterWindow, RunnerTests (+2 more)

### Community 5 - "schemas.py"
Cohesion: 0.11
Nodes (22): login(), register(), add_favorite_team(), get_my_predictions(), make_prediction(), LeaderboardEntry, LineupPlayerResponse, MatchEventResponse (+14 more)

### Community 6 - "my_application.cc"
Cohesion: 0.10
Nodes (13): main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 7 - "utils.cpp"
Cohesion: 0.19
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 8 - "favorites_screen.dart"
Cohesion: 0.12
Nodes (13): _buildEmptyState, _buildPlayersList, _buildTeamsList, _buildThemedLogo, createState, dispose, FavoritesScreen, _FavoritesScreenState (+5 more)

### Community 9 - "match_detail_screen.dart"
Cohesion: 0.10
Nodes (16): _buildStats, _buildTimeline, createState, _currentMatch, dispose, _evContent, _getProxyUrl, _getRatingColor (+8 more)

### Community 10 - "app/forecasts.py"
Cohesion: 0.10
Nodes (32): cancel(), choose(), _game(), leaderboard(), _lock_day(), match_day(), observe_espn(), quota() (+24 more)

### Community 11 - "auth_provider.dart"
Cohesion: 0.11
Nodes (15): checkAuth, clearError, _client, _currentUser, _errorMessage, fetchProfile, isAuthenticated, _isLoading (+7 more)

### Community 12 - "app_theme.dart"
Cohesion: 0.06
Nodes (28): accentColor, AppCustomTheme, AppTheme, cardBg, cardBorder, _createTheme, dimTextColor, dividerColor (+20 more)

### Community 14 - "users.py"
Cohesion: 0.25
Nodes (11): add_favorite_player(), add_favorite_team(), add_favorite_tournament(), get_favorite_players(), get_favorite_teams(), get_favorite_tournaments(), get_leaderboard(), remove_favorite_player() (+3 more)

### Community 15 - "DataProvider"
Cohesion: 0.09
Nodes (28): openAuthScreen, AuthProvider, DataProvider, ThemeProvider, build, initState, build, _load (+20 more)

### Community 16 - "theme_provider.dart"
Cohesion: 0.20
Nodes (6): AppThemeType, currentTheme, _currentType, _loadTheme, setTheme, _storage

### Community 17 - "main.dart"
Cohesion: 0.08
Nodes (13): onAuthenticated, resumedAfterLogin, runAuthenticatedAction, signedIn, authProvider, build, checkAuth, createState (+5 more)

### Community 18 - "Анализ Предметной Области (ПО) Futrat"
Cohesion: 0.14
Nodes (13): 1.  Ключевые Сущности и Их Атрибуты, 1. Прогнозы Пользователей (Prediction Game), 1. Статистика Игроков и Команд, 1. Управление Пользователями, 2. Голосования, 2. Модуль Авторизации и Персонализации, 2. Персонализация (Модуль "Избранное"), 2. Турнирные Таблицы и Сетки (+5 more)

### Community 19 - "test_security.py"
Cohesion: 0.09
Nodes (20): _bcrypt_password(), create_access_token(), get_password_hash(), verify_password(), register(), test_duplicate_registration_is_rejected(), test_existing_password_hash_can_log_in(), test_invalid_expired_and_missing_tokens_are_rejected() (+12 more)

### Community 20 - "test_season_sync.py"
Cohesion: 0.13
Nodes (23): update_all_data(), event(), mock_source(), get(), scoreboard(), test_distinct_events_with_same_teams_keep_their_ids_and_results(), test_failed_day_is_retried_without_reimporting_completed_history(), test_grouped_cup_calendar_discovers_fixture_days_from_year_feeds() (+15 more)

### Community 21 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 22 - "Predictions, favorites and player profiles"
Cohesion: 0.33
Nodes (5): Approved brief, Constraints, Implementation order, Predictions, favorites and player profiles, Verification

### Community 24 - "widget_test.dart"
Cohesion: 0.12
Nodes (10): FakeDataProvider, fetchFavorites, initData, isAuthenticated, league, main, register, selectedLeague (+2 more)

### Community 26 - "player_screen.dart"
Cohesion: 0.09
Nodes (18): cleanName, _countryTranslations, tr, api, _calendar, _coverage, createState, _error (+10 more)

### Community 27 - "Win32Window"
Cohesion: 0.14
Nodes (7): Size, height, width, Win32Window, child_content_, quit_on_close_, window_handle_

### Community 32 - "models.py"
Cohesion: 0.06
Nodes (36): seed_tournaments(), Settings, Forecast, ForecastDay, ForecastLedger, LineupDetail, MatchFormation, MatchHistoryJob (+28 more)

### Community 34 - "test_goal_api.py"
Cohesion: 0.12
Nodes (16): OfficialStandings, ProviderMatch, block_external_http(), client(), user(), client(), fixture(), test_failed_or_invalid_goal_payload_is_not_cached() (+8 more)

### Community 39 - "profiles.py"
Cohesion: 0.25
Nodes (14): utc_now(), ProviderCache, _discover_national_teams(), _photo(), queue_player(), update_player_data(), calendar_team(), matches_json() (+6 more)

### Community 40 - "win32_window.cpp"
Cohesion: 0.20
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 41 - "forecasts_screen.dart"
Cohesion: 0.07
Nodes (25): api, _cancel, _choices, _choose, createState, _day, dispose, _empty (+17 more)

### Community 42 - "lineup_view.dart"
Cohesion: 0.11
Nodes (15): build, _canRate, createState, _fieldPlayer, LineupView, _LineupViewState, match, onRate (+7 more)

### Community 43 - "Base"
Cohesion: 0.19
Nodes (16): store_details(), decorate(), MatchEvent, MatchLineup, Player, Prediction, ProviderUsage, User (+8 more)

### Community 44 - "team_screen.dart"
Cohesion: 0.09
Nodes (18): _anchor, api, _calendar, _center, createState, dispose, _generation, initState (+10 more)

### Community 45 - "Прогнозы, избранное и профили"
Cohesion: 0.11
Nodes (15): Источники футбольных данных, Настройка GOAL, Проверка и откат, Список турниров — 31, API, Избранное и история, Основные файлы, Правила прогнозов (+7 more)

### Community 46 - "forecast_api.dart"
Cohesion: 0.12
Nodes (13): cancel, choose, dio, ForecastApi, mine, myRank, rankings, used (+5 more)

### Community 48 - "forecasts_test.dart"
Cohesion: 0.11
Nodes (13): allMatches, choose, count, game, isAuthenticated, main, mine, myRank (+5 more)

### Community 49 - "State"
Cohesion: 0.21
Nodes (10): FutratApp, _FutratAppState, ForecastsScreen, _ForecastsScreenState, HomeScreen, _HomeScreenState, PlayerScreen, _PlayerScreenState (+2 more)

### Community 51 - "api_client.dart"
Cohesion: 0.29
Nodes (4): ApiClient, dio, _instance, storage

### Community 52 - "lineups.py"
Cohesion: 0.28
Nodes (13): attach(), bind_player(), canonical_id(), enrich_espn(), enrich_goal(), number(), safe_photo(), roster() (+5 more)

### Community 53 - "match_tile.dart"
Cohesion: 0.17
Nodes (8): MatchModel, build, caption, match, MatchTile, PlayerPhoto, size, url

### Community 54 - "goal_sync.py"
Cohesion: 0.18
Nodes (13): observe_goal(), GoalClient, GoalError, find_league(), kickoff(), refresh_details(), resolve_team(), store_fixtures() (+5 more)

### Community 55 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 56 - "profiles_test.dart"
Cohesion: 0.12
Nodes (8): ProfileApi, FakeProfiles, game, host, main, player, playerMatches, team

### Community 58 - "discover_calendar"
Cohesion: 0.19
Nodes (12): calendar_days(), discover_calendar(), fetch_day(), _score(), store_day(), Match, Team, Tournament (+4 more)

## Knowledge Gaps
- **378 isolated node(s):** `_instance`, `dio`, `storage`, `AppCustomTheme`, `AppTheme` (+373 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 585 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **17 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MatchModel` connect `match_tile.dart` to `all_models.dart`, `home_screen.dart`, `match_detail_screen.dart`, `lineup_view.dart`, `team_screen.dart`, `forecasts_test.dart`?**
  _High betweenness centrality (0.078) - this node is a cross-community bridge._
- **What connects `_instance`, `dio`, `storage` to the rest of the system?**
  _378 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `all_models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.024096385542168676 - nodes in this community are weakly interconnected._
- **Why does `DataProvider` connect `DataProvider` to `home_screen.dart`, `data_provider.dart`, `favorites_screen.dart`, `forecasts_screen.dart`, `match_detail_screen.dart`, `lineup_view.dart`, `team_screen.dart`, `forecasts_test.dart`, `main.dart`, `State`, `profiles_test.dart`, `widget_test.dart`, `player_screen.dart`?**
  _High betweenness centrality (0.046) - this node is a cross-community bridge._
- **Should `FlutterWindow` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `Win32Window` to `FlutterWindow`, `win32_window.cpp`, `flutter_window.h`, `.MessageHandler`, `Point`?**
  _High betweenness centrality (0.039) - this node is a cross-community bridge._
- **Should `home_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.038461538461538464 - nodes in this community are weakly interconnected._
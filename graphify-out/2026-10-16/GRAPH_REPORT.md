# Graph Report - futrat  (2026-10-16)

## Corpus Check
- 68 files · ~81,859 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 58 file(s) not represented in the graph (top: (none) 12, .xcconfig 8, .xml 7)

## Summary
- 742 nodes · 1150 edges · 41 communities (29 shown, 12 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- all_models.dart
- win32_window.cpp
- home_screen.dart
- data_provider.dart
- .application
- schemas.py
- my_application.cc
- utils.cpp
- favorites_screen.dart
- match_detail_screen.dart
- models.py
- auth_provider.dart
- app_theme.dart
- auth_screen.dart
- User
- DataProvider
- profile_screen.dart
- main.dart
- Анализ Предметной Области (ПО) Futrat
- test_security.py
- main_scaffold.dart
- manifest.json
- Python upgrade
- futrat_mobile
- api_client.dart
- LaunchImage.imageset/README.md
- translator.dart
- widget_test.dart
- constants.dart
- todo.md
- FlutterActivity
- _FavoritesScreenState
- _buildPairCard
- auth_gate.dart
- Backend на Python 3.15.0

## God Nodes (most connected - your core abstractions)
1. `DataProvider` - 26 edges
2. `ThemeProvider` - 25 edges
3. `Win32Window` - 21 edges
4. `AuthProvider` - 12 edges
5. `update_all_data()` - 10 edges
6. `get_password_hash()` - 10 edges
7. `FlutterWindow` - 10 edges
8. `create_access_token()` - 9 edges
9. `register()` - 7 edges
10. `get_match_details()` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Проверка` --references--> `db()`  [INFERRED]
  futrat_backend/README.md → futrat_backend/tests/conftest.py
- `FakeDataProvider` --inherits--> `DataProvider`  [EXTRACTED]
  futrat_mobile/test/widget_test.dart → futrat_mobile/lib/providers/data_provider.dart
- `build` --references--> `ThemeProvider`  [EXTRACTED]
  futrat_mobile/lib/screens/main_scaffold.dart → futrat_mobile/lib/providers/theme_provider.dart
- `_showThemePicker` --references--> `ThemeProvider`  [EXTRACTED]
  futrat_mobile/lib/screens/profile_screen.dart → futrat_mobile/lib/providers/theme_provider.dart
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  futrat_mobile/windows/runner/main.cpp → futrat_mobile/windows/runner/utils.cpp

## Import Cycles
- None detected.

## Communities (41 total, 12 thin omitted)

### Community 0 - "all_models.dart"
Cohesion: 0.03
Nodes (70): assists, awayTeam, cornersAway, cornersHome, country, dateTime, draw, email (+62 more)

### Community 1 - "win32_window.cpp"
Cohesion: 0.05
Nodes (20): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_, EnableFullDpiSupportIfAvailable(), Point, x, y (+12 more)

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
Cohesion: 0.18
Nodes (17): LeaderboardEntry, LineupPlayerResponse, MatchEventResponse, MatchResponse, PlayerRatingCreate, PlayerResponse, PredictionCreate, PredictionResponse (+9 more)

### Community 6 - "my_application.cc"
Cohesion: 0.10
Nodes (13): main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 7 - "utils.cpp"
Cohesion: 0.12
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 8 - "favorites_screen.dart"
Cohesion: 0.17
Nodes (9): _buildEmptyState, _buildPlayersList, _buildTeamsList, _buildThemedLogo, _buildTournamentsList, createState, dispose, _getProxyUrl (+1 more)

### Community 9 - "match_detail_screen.dart"
Cohesion: 0.10
Nodes (16): MatchModel, _buildLineups, _buildStats, _buildTimeline, createState, _currentMatch, dispose, _evContent (+8 more)

### Community 10 - "models.py"
Cohesion: 0.05
Nodes (36): Settings, get_or_create_team(), get_season_dates(), init_db(), update_all_data(), lifespan(), root(), Match (+28 more)

### Community 11 - "auth_provider.dart"
Cohesion: 0.11
Nodes (15): checkAuth, clearError, _client, _currentUser, _errorMessage, fetchProfile, isAuthenticated, _isLoading (+7 more)

### Community 12 - "app_theme.dart"
Cohesion: 0.10
Nodes (16): accentColor, AppCustomTheme, AppTheme, cardBg, cardBorder, _createTheme, dimTextColor, dividerColor (+8 more)

### Community 13 - "auth_screen.dart"
Cohesion: 0.17
Nodes (11): AuthScreen, _AuthScreenState, _buildNeonTextField, createState, _deepPurple, _emailController, _isRegister, _neonPurple (+3 more)

### Community 14 - "User"
Cohesion: 0.20
Nodes (11): add_favorite_player(), add_favorite_team(), add_favorite_tournament(), get_favorite_players(), get_favorite_teams(), get_favorite_tournaments(), get_leaderboard(), remove_favorite_player() (+3 more)

### Community 15 - "DataProvider"
Cohesion: 0.15
Nodes (19): openAuthScreen, build, AuthProvider, DataProvider, ThemeProvider, build, build, initState (+11 more)

### Community 16 - "profile_screen.dart"
Cohesion: 0.13
Nodes (9): AppThemeType, currentTheme, _currentType, _loadTheme, setTheme, _storage, build, _showThemePicker (+1 more)

### Community 17 - "main.dart"
Cohesion: 0.12
Nodes (8): authProvider, checkAuth, createState, dataProvider, dispose, main, _router, themeProvider

### Community 18 - "Анализ Предметной Области (ПО) Futrat"
Cohesion: 0.14
Nodes (13): 1.  Ключевые Сущности и Их Атрибуты, 1. Прогнозы Пользователей (Prediction Game), 1. Статистика Игроков и Команд, 1. Управление Пользователями, 2. Голосования, 2. Модуль Авторизации и Персонализации, 2. Персонализация (Модуль "Избранное"), 2. Турнирные Таблицы и Сетки (+5 more)

### Community 19 - "test_security.py"
Cohesion: 0.09
Nodes (22): login(), register(), _bcrypt_password(), create_access_token(), get_password_hash(), verify_password(), register(), test_duplicate_registration_is_rejected() (+14 more)

### Community 20 - "main_scaffold.dart"
Cohesion: 0.17
Nodes (4): build, _calculateSelectedIndex, child, _onItemTapped

### Community 21 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 22 - "Python upgrade"
Cohesion: 0.33
Nodes (5): Acceptance criteria, Approved scope, Implementation order, Python upgrade, Risks

### Community 24 - "api_client.dart"
Cohesion: 0.22
Nodes (4): ApiClient, dio, _instance, storage

### Community 26 - "translator.dart"
Cohesion: 0.40
Nodes (3): cleanName, _countryTranslations, tr

### Community 27 - "widget_test.dart"
Cohesion: 0.13
Nodes (7): FakeDataProvider, fetchFavorites, initData, isAuthenticated, main, register, signedIn

### Community 32 - "_FavoritesScreenState"
Cohesion: 0.24
Nodes (8): FutratApp, _FutratAppState, FavoritesScreen, _FavoritesScreenState, HomeScreen, _HomeScreenState, MatchDetailScreen, _MatchDetailScreenState

### Community 39 - "auth_gate.dart"
Cohesion: 0.25
Nodes (4): onAuthenticated, resumedAfterLogin, runAuthenticatedAction, signedIn

### Community 45 - "Backend на Python 3.15.0"
Cohesion: 0.50
Nodes (3): Backend на Python 3.15.0, Совместимость и откат, Установка

## Knowledge Gaps
- **266 isolated node(s):** `_instance`, `dio`, `storage`, `AppCustomTheme`, `AppTheme` (+261 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 422 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MatchModel` connect `match_detail_screen.dart` to `all_models.dart`, `home_screen.dart`?**
  _High betweenness centrality (0.092) - this node is a cross-community bridge._
- **What connects `_instance`, `dio`, `storage` to the rest of the system?**
  _266 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `all_models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0273972602739726 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `win32_window.cpp` to `utils.cpp`?**
  _High betweenness centrality (0.062) - this node is a cross-community bridge._
- **Should `win32_window.cpp` be split into smaller, more focused modules?**
  _Cohesion score 0.05268065268065268 - nodes in this community are weakly interconnected._
- **Why does `ThemeProvider` connect `DataProvider` to `_FavoritesScreenState`, `home_screen.dart`, `favorites_screen.dart`, `match_detail_screen.dart`, `profile_screen.dart`, `main.dart`, `main_scaffold.dart`, `widget_test.dart`?**
  _High betweenness centrality (0.032) - this node is a cross-community bridge._
- **Should `home_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.037037037037037035 - nodes in this community are weakly interconnected._
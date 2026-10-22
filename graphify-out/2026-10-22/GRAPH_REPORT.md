# Graph Report - futrat  (2026-10-20)

## Corpus Check
- 140 files · ~73,544 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 64 file(s) not represented in the graph (top: (none) 12, .xml 9, .xcconfig 8)

## Summary
- 1514 nodes · 2803 edges · 92 communities (64 shown, 28 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 58 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- all_models.dart
- win32_window.cpp
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
- test_registration.py
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
- Прогнозы, избранное и профили
- forecast_api.dart
- forecasts_test.dart
- player_screen.dart
- auth_validation_test.dart
- models.py
- package:flutter/material.dart
- match_status.dart
- main.py
- Base
- profiles_test.dart
- DataProvider
- api_client.dart
- branding/README.md
- package:provider/provider.dart
- grouped_matches_list.dart
- UserPlayerRating
- round_selector.dart
- Appearance
- appearance-plan.md
- football_logo_test.dart
- favorites_screen.dart
- auth_screen.dart
- lineups.py
- Season and match interface
- auth_errors.py
- fonts/README.md
- match-navigation-plan.md
- live_sync.py
- make_prediction
- Stale live status correction
- lineup-selector.md
- active_season.dart
- Backend over the phone hotspot
- live_clock.py
- Player photos outside sports APIs
- auth_gate.dart
- read_users_me
- logo-contrast-and-photos.md
- Minute live updates
- Nickname registration
- wWinMain
- registration-fix.md

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
- `Identity and compatibility` --references--> `Player`  [INFERRED]
  futrat_backend/docs/registration.md → futrat_backend/app/models.py
- `Проверка` --references--> `db()`  [INFERRED]
  futrat_backend/README.md → futrat_backend/tests/conftest.py
- `Active season 2026/27` --references--> `current_matches()`  [INFERRED]
  futrat_backend/docs/active-season.md → futrat_backend/app/seasons.py
- `sync_goal()` --indirect_call--> `db()`  [INFERRED]
  futrat_backend/app/goal_sync.py → futrat_backend/tests/conftest.py
- `lifespan()` --indirect_call--> `update_all_data()`  [INFERRED]
  futrat_backend/app/main.py → futrat_backend/app/initial_data.py

## Import Cycles
- None detected.

## Communities (92 total, 28 thin omitted)

### Community 0 - "all_models.dart"
Cohesion: 0.02
Nodes (87): apiCode, appeared, assists, awayTeam, cornersAway, cornersHome, country, currentSeason (+79 more)

### Community 1 - "win32_window.cpp"
Cohesion: 0.05
Nodes (20): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_, EnableFullDpiSupportIfAvailable(), Point, x, y (+12 more)

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
Cohesion: 0.05
Nodes (45): canonical_id(), is_live_match(), is_live_status(), login(), nickname_taken(), raise_unique_conflict(), register(), user_token() (+37 more)

### Community 6 - "my_application.cc"
Cohesion: 0.10
Nodes (13): main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line(), my_application_new() (+5 more)

### Community 8 - "Match navigation and typography"
Cohesion: 0.20
Nodes (9): Font and files, League tabs and rounds, Lineup team selector, Live status correction, Match feeds, Match navigation and typography, Season and ratings, Team profiles (+1 more)

### Community 9 - "match_detail_screen.dart"
Cohesion: 0.11
Nodes (15): _buildStats, _buildTimeline, createState, _currentMatch, dispose, _evContent, _getRatingColor, initState (+7 more)

### Community 10 - "app/forecasts.py"
Cohesion: 0.10
Nodes (30): cancel(), choose(), _game(), leaderboard(), _lock_day(), match_day(), quota(), record_result() (+22 more)

### Community 11 - "auth_provider.dart"
Cohesion: 0.10
Nodes (17): _authenticate, checkAuth, clearError, _client, _currentUser, _errorMessage, fetchProfile, isAuthenticated (+9 more)

### Community 12 - "app_theme.dart"
Cohesion: 0.07
Nodes (22): accentColor, accentFill, AppTheme, background, cardBg, cardBorder, color, _contrast (+14 more)

### Community 13 - "football_logo.dart"
Cohesion: 0.07
Nodes (23): _analyze, background, build, _contrast, createState, didChangeDependencies, didUpdateWidget, _disconnect (+15 more)

### Community 14 - "match_sync.py"
Cohesion: 0.20
Nodes (10): assign_rounds(), calendar_days(), discover_calendar(), fetch_day(), _score(), store_day(), sync_leagues(), utc() (+2 more)

### Community 15 - "Match"
Cohesion: 0.33
Nodes (7): Match, Storage and API, add_game(), instant(), test_profile_defaults_and_cursor_share_public_season_filter(), test_public_lists_keep_only_2627_clubs_calendar_mls_and_current_national(), test_team_timeline_has_last_finished_anchor_all_competitions_and_history_above()

### Community 16 - "theme_provider.dart"
Cohesion: 0.07
Nodes (20): AppAccent, AppCustomTheme, AppThemeType, _accent, currentAccent, currentTheme, currentType, dispose (+12 more)

### Community 17 - "main.dart"
Cohesion: 0.09
Nodes (13): authProvider, build, createState, dataProvider, didChangeAppLifecycleState, dispose, FutratApp, _FutratAppState (+5 more)

### Community 18 - "Анализ Предметной Области (ПО) Futrat"
Cohesion: 0.14
Nodes (13): 1.  Ключевые Сущности и Их Атрибуты, 1. Прогнозы Пользователей (Prediction Game), 1. Статистика Игроков и Команд, 1. Управление Пользователями, 2. Голосования, 2. Модуль Авторизации и Персонализации, 2. Персонализация (Модуль "Избранное"), 2. Турнирные Таблицы и Сетки (+5 more)

### Community 19 - "test_registration.py"
Cohesion: 0.06
Nodes (36): User, _bcrypt_password(), create_access_token(), get_password_hash(), verify_password(), delete_empty_account(), ensure_user_schema(), register() (+28 more)

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
Cohesion: 0.28
Nodes (12): utc_now(), ProviderCache, _discover_national_teams(), queue_player(), calendar_team(), matches_json(), player_matches(), player_profile() (+4 more)

### Community 27 - "Phone connection over LAN"
Cohesion: 0.50
Nodes (3): Delivery, Phone connection over LAN, Resolved network issue

### Community 32 - "test_profiles.py"
Cohesion: 0.21
Nodes (16): store_details(), decorate(), MatchEvent, MatchLineup, Player, get_match_details(), get_or_create_player(), roster() (+8 more)

### Community 34 - "goal_sync.py"
Cohesion: 0.12
Nodes (20): observe_goal(), GoalClient, GoalError, find_league(), kickoff(), refresh_details(), resolve_team(), store_fixtures() (+12 more)

### Community 39 - "match_navigation_test.dart"
Cohesion: 0.09
Nodes (17): currentStandings, fake, favoriteTournaments, fixture, games, getMatchDetails, host, initData (+9 more)

### Community 41 - "forecasts_screen.dart"
Cohesion: 0.07
Nodes (27): api, _cancel, _choices, _choose, createState, _day, dispose, _empty (+19 more)

### Community 42 - "lineup_view.dart"
Cohesion: 0.11
Nodes (16): build, _canRate, createState, _field, _fieldPlayer, LineupView, _LineupViewState, match (+8 more)

### Community 43 - "app/__init__.py"
Cohesion: 0.12
Nodes (9): Settings, get_standings(), get_current_user(), get_match_updates(), get_matches(), get_standings(), get_tournaments(), current_matches() (+1 more)

### Community 44 - "team_screen.dart"
Cohesion: 0.09
Nodes (20): _anchor, api, build, _calendar, _center, createState, dispose, _generation (+12 more)

### Community 45 - "Прогнозы, избранное и профили"
Cohesion: 0.11
Nodes (16): Источники футбольных данных, Настройка GOAL, Проверка и откат, Список турниров — 31, API, Избранное и история, Основные файлы, Правила прогнозов (+8 more)

### Community 46 - "forecast_api.dart"
Cohesion: 0.12
Nodes (13): cancel, choose, dio, ForecastApi, mine, myRank, rankings, used (+5 more)

### Community 48 - "forecasts_test.dart"
Cohesion: 0.11
Nodes (14): allMatches, choose, count, ForecastData, game, isAuthenticated, main, mine (+6 more)

### Community 49 - "player_screen.dart"
Cohesion: 0.09
Nodes (20): ProfileApi, api, build, _calendar, _coverage, createState, _error, _generation (+12 more)

### Community 50 - "auth_validation_test.dart"
Cohesion: 0.17
Nodes (7): auth, fail, fake, host, main, press, requests

### Community 51 - "models.py"
Cohesion: 0.25
Nodes (12): Forecast, ForecastDay, ForecastLedger, LineupDetail, MatchFormation, MatchHistoryJob, MatchLiveState, MatchResult (+4 more)

### Community 52 - "package:flutter/material.dart"
Cohesion: 0.15
Nodes (7): main, lineupFixture, main, game, main, liveGame, main

### Community 53 - "match_status.dart"
Cohesion: 0.29
Nodes (6): _clock, elapsed, isLiveMatch, isLiveStatus, _liveStatuses, liveWindow

### Community 54 - "main.py"
Cohesion: 0.10
Nodes (19): seed_tournaments(), init_db(), seed_tournaments(), sync_sources(), update_live_data(), update_live_feed(), lifespan(), root() (+11 more)

### Community 55 - "Base"
Cohesion: 0.18
Nodes (8): OfficialStandings, Prediction, ProviderMatch, ProviderTeam, ProviderUsage, TournamentSyncState, test_goal_mapped_match_never_sends_goal_id_to_espn(), test_national_groups_use_official_points_instead_of_knockout_results()

### Community 56 - "profiles_test.dart"
Cohesion: 0.13
Nodes (9): calendar, game, host, main, player, playerMatches, requestedSeasons, team (+1 more)

### Community 57 - "DataProvider"
Cohesion: 0.14
Nodes (20): openAuthScreen, AuthProvider, DataProvider, ThemeProvider, build, build, build, _load (+12 more)

### Community 58 - "api_client.dart"
Cohesion: 0.15
Nodes (7): ApiClient, dio, _instance, storage, contrast, main, x

### Community 61 - "package:provider/provider.dart"
Cohesion: 0.17
Nodes (5): _buildTournamentsList, build, _calculateSelectedIndex, child, _onItemTapped

### Community 62 - "grouped_matches_list.dart"
Cohesion: 0.06
Nodes (25): MatchModel, MainScaffold, byLeague, feedId, GroupedMatchesList, groupMatchesByLeague, groups, LeagueMatches (+17 more)

### Community 63 - "UserPlayerRating"
Cohesion: 0.40
Nodes (3): UserPlayerRating, rate_player(), test_goal_details_upsert_lineup_without_losing_rating()

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
Nodes (14): _buildEmptyState, _buildPlayersList, _buildTeamsList, _buildThemedLogo, createState, dispose, FavoritesScreen, _FavoritesScreenState (+6 more)

### Community 69 - "auth_screen.dart"
Cohesion: 0.10
Nodes (15): AuthScreen, _AuthScreenState, createState, dispose, _field, _formKey, _isRegister, _obscurePassword (+7 more)

### Community 70 - "lineups.py"
Cohesion: 0.40
Nodes (8): regular_from_timeline(), attach(), bind_player(), enrich_espn(), enrich_goal(), formation(), number(), safe_photo()

### Community 71 - "Season and match interface"
Cohesion: 0.40
Nodes (4): Delivery, Limits, Scope, Season and match interface

### Community 75 - "live_sync.py"
Cohesion: 0.16
Nodes (20): observe_espn(), team_key(), apply_espn(), apply_goal(), find_event(), refresh(), scoreboard(), writer_lock() (+12 more)

### Community 76 - "make_prediction"
Cohesion: 0.43
Nodes (3): add_favorite_team(), get_my_predictions(), make_prediction()

### Community 77 - "Stale live status correction"
Cohesion: 0.40
Nodes (4): Delivery, Files, Scope, Stale live status correction

### Community 80 - "Backend over the phone hotspot"
Cohesion: 0.33
Nodes (5): Address and build, Backend over the phone hotspot, Verification without USB forwarding, Verified on 18 October 2026, Windows setup

### Community 81 - "live_clock.py"
Cohesion: 0.43
Nodes (5): espn(), goal(), minute(), prefer_espn(), write()

### Community 84 - "Player photos outside sports APIs"
Cohesion: 0.33
Nodes (5): Alternatives considered, Limits, Ordered implementation, Player photos outside sports APIs, Selected approach

### Community 85 - "auth_gate.dart"
Cohesion: 0.25
Nodes (4): onAuthenticated, resumedAfterLogin, runAuthenticatedAction, signedIn

### Community 88 - "Minute live updates"
Cohesion: 0.33
Nodes (5): Display, Minute live updates, Provider priority, Refresh, Verification

### Community 89 - "Nickname registration"
Cohesion: 0.33
Nodes (5): API and errors, Identity and compatibility, Nickname registration, Requested cleanup, Verification

## Knowledge Gaps
- **508 isolated node(s):** `activeSeason`, `seasonLabel`, `_instance`, `dio`, `storage` (+503 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 814 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **28 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MatchModel` connect `grouped_matches_list.dart` to `all_models.dart`, `home_screen.dart`, `match_detail_screen.dart`, `lineup_view.dart`, `team_screen.dart`, `forecasts_test.dart`?**
  _High betweenness centrality (0.062) - this node is a cross-community bridge._
- **What connects `activeSeason`, `seasonLabel`, `_instance` to the rest of the system?**
  _508 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `all_models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.021739130434782608 - nodes in this community are weakly interconnected._
- **Why does `Win32Window` connect `win32_window.cpp` to `flutter_window.h`?**
  _High betweenness centrality (0.041) - this node is a cross-community bridge._
- **Should `win32_window.cpp` be split into smaller, more focused modules?**
  _Cohesion score 0.05268065268065268 - nodes in this community are weakly interconnected._
- **Why does `DataProvider` connect `DataProvider` to `home_screen.dart`, `data_provider.dart`, `favorites_screen.dart`, `match_navigation_test.dart`, `forecasts_screen.dart`, `match_detail_screen.dart`, `lineup_view.dart`, `team_screen.dart`, `forecasts_test.dart`, `main.dart`, `player_screen.dart`, `auth_gate.dart`, `profiles_test.dart`, `widget_test.dart`, `grouped_matches_list.dart`?**
  _High betweenness centrality (0.038) - this node is a cross-community bridge._
- **Should `home_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03773584905660377 - nodes in this community are weakly interconnected._
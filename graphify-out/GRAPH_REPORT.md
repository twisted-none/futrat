# Graph Report - futrat  (2026-11-25)

## Corpus Check
- 168 files · ~99,113 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 67 file(s) not represented in the graph (top: (none) 14, .xml 9, .xcconfig 8)

## Summary
- 1924 nodes · 3512 edges · 116 communities (89 shown, 27 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 62 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `008436e4`
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
- string
- Match navigation and typography
- match_detail_screen.dart
- app/forecasts.py
- package:flutter/material.dart
- app_theme.dart
- football_logo.dart
- match_sync.py
- test_profiles.py
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
- app/__init__.py
- team_screen.dart
- Deployment: Ubuntu, existing Caddy and PostgreSQL
- api_client.dart
- data_cache_provider_test.dart
- forecasts_test.dart
- auth_provider.dart
- auth_session_test.dart
- models.py
- package:flutter_test/flutter_test.dart
- match_status.dart
- goal_sync.py
- test_production.py
- profiles_test.dart
- conftest.py
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
- AuthProvider
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
- public_data_cache_test.dart
- test_goal_fallback_uses_one_short_cached_batch_per_league
- registration-fix.md
- persistent_session.dart
- test_goal_api.py
- package:dio/dio.dart
- main.py
- test_sessions.py
- backup.sh
- lineups.py
- routers/forecasts.py
- Production deployment preparation
- auth.py
- Tournament menu and forecast update
- Persistent session and confirmed lineup layout
- Map
- Nickname registration
- dart:async
- Win32Window
- win32_window.cpp
- State
- .MessageHandler
- _onItemTapped
- Club badge repair
- Daily public cache and permanent badges
- Point
- ChangeNotifier

## God Nodes (most connected - your core abstractions)
1. `DataProvider` - 54 edges
2. `ThemeProvider` - 30 edges
3. `utc()` - 26 edges
4. `AuthProvider` - 26 edges
5. `utc_now()` - 25 edges
6. `GoalError` - 22 edges
7. `Win32Window` - 21 edges
8. `choose()` - 18 edges
9. `store_fixtures()` - 17 edges
10. `sync_goal()` - 17 edges

## Surprising Connections (you probably didn't know these)
- `Identity and compatibility` --references--> `Player`  [INFERRED]
  futrat_backend/docs/registration.md → futrat_backend/app/models.py
- `Проверка` --references--> `db()`  [INFERRED]
  futrat_backend/README.md → futrat_backend/tests/conftest.py
- `Active season 2026/27` --references--> `current_matches()`  [INFERRED]
  futrat_backend/docs/active-season.md → futrat_backend/app/seasons.py
- `refresh_details()` --uses--> `GoalError`  [INFERRED]
  futrat_backend/app/goal_sync.py → futrat_backend/app/goal_api.py
- `sync_goal()` --uses--> `GoalError`  [INFERRED]
  futrat_backend/app/goal_sync.py → futrat_backend/app/goal_api.py

## Import Cycles
- None detected.

## Communities (116 total, 27 thin omitted)

### Community 0 - "all_models.dart"
Cohesion: 0.02
Nodes (87): apiCode, appeared, assists, awayTeam, cornersAway, cornersHome, country, currentSeason (+79 more)

### Community 1 - "FlutterWindow"
Cohesion: 0.11
Nodes (4): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), project_

### Community 2 - "home_screen.dart"
Cohesion: 0.04
Nodes (50): _activeStageFilter, addMatch, awayToken, _bracketRow, _buildBracketColumn, _buildDynamicTable, _buildLogo, _buildMatchCard (+42 more)

### Community 3 - "data_provider.dart"
Cohesion: 0.03
Nodes (60): _allMatches, _badgeMetadataBusy, _badgeMetadataCheckedAt, _badges, _cache, clearFavorites, _client, _collapsedLeagues (+52 more)

### Community 4 - ".application"
Cohesion: 0.09
Nodes (10): Cocoa, Flutter, FlutterMacOS, AppDelegate, RunnerTests, AppDelegate, MainFlutterWindow, RunnerTests (+2 more)

### Community 5 - "schemas.py"
Cohesion: 0.06
Nodes (37): rate_player(), add_favorite_player(), add_favorite_team(), add_favorite_tournament(), get_favorite_players(), get_favorite_teams(), get_favorite_tournaments(), get_leaderboard() (+29 more)

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
Cohesion: 0.10
Nodes (17): _buildStats, _buildTimeline, createState, _currentMatch, dispose, _evContent, _getRatingColor, initState (+9 more)

### Community 10 - "app/forecasts.py"
Cohesion: 0.16
Nodes (24): cancel(), choose(), _game(), _lock_day(), match_day(), observe_espn(), quota(), record_result() (+16 more)

### Community 11 - "package:flutter/material.dart"
Cohesion: 0.09
Nodes (19): main, player, spurs, lineupFixture, main, game, getMatchDetails, host (+11 more)

### Community 12 - "app_theme.dart"
Cohesion: 0.07
Nodes (22): accentColor, accentFill, AppTheme, background, cardBg, cardBorder, color, _contrast (+14 more)

### Community 13 - "football_logo.dart"
Cohesion: 0.05
Nodes (31): _analyze, background, _badgeReady, _broken, build, cache, _configuration, _contrast (+23 more)

### Community 14 - "match_sync.py"
Cohesion: 0.13
Nodes (13): prefer_espn(), write(), find_event(), refresh(), scoreboard(), writer_lock(), assign_rounds(), calendar_days() (+5 more)

### Community 15 - "test_profiles.py"
Cohesion: 0.15
Nodes (26): store_details(), attach(), decorate(), enrich_espn(), enrich_goal(), formation(), number(), MatchEvent (+18 more)

### Community 16 - "theme_provider.dart"
Cohesion: 0.08
Nodes (20): AppAccent, AppCustomTheme, AppThemeType, _accent, currentAccent, currentTheme, currentType, dispose (+12 more)

### Community 17 - "main.dart"
Cohesion: 0.10
Nodes (13): authProvider, build, createState, dataProvider, didChangeAppLifecycleState, dispose, FutratApp, _FutratAppState (+5 more)

### Community 18 - "Анализ Предметной Области (ПО) Futrat"
Cohesion: 0.14
Nodes (13): 1.  Ключевые Сущности и Их Атрибуты, 1. Прогнозы Пользователей (Prediction Game), 1. Статистика Игроков и Команд, 1. Управление Пользователями, 2. Голосования, 2. Модуль Авторизации и Персонализации, 2. Персонализация (Модуль "Избранное"), 2. Турнирные Таблицы и Сетки (+5 more)

### Community 19 - "badge_cache.dart"
Cohesion: 0.08
Nodes (20): _acquire, _active, BadgeDownloader, _directory, download, _downloadPng, _failed, instance (+12 more)

### Community 20 - "test_team_badges.py"
Cohesion: 0.20
Nodes (17): resolve_team(), team_key(), ProviderTeam, apply_espn_catalog(), apply_goal_catalog(), fill_badge(), goal_catalog_needed(), repair_russian_badges() (+9 more)

### Community 21 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 22 - "Predictions, favorites and player profiles"
Cohesion: 0.33
Nodes (5): Approved brief, Constraints, Implementation order, Predictions, favorites and player profiles, Verification

### Community 24 - "widget_test.dart"
Cohesion: 0.12
Nodes (13): AppearanceDataProvider, currentStandings, FakeDataProvider, fetchFavorites, initData, isAuthenticated, league, main (+5 more)

### Community 27 - "Phone connection over LAN"
Cohesion: 0.50
Nodes (3): Delivery, Phone connection over LAN, Resolved network issue

### Community 32 - "widgets/tournament_menu.dart"
Cohesion: 0.08
Nodes (21): _autoScroll, createState, data, dispose, favoriteIds, _group, id, _league (+13 more)

### Community 34 - "test_live_feed.py"
Cohesion: 0.25
Nodes (16): espn(), goal(), minute(), apply_espn(), apply_goal(), event(), prepare(), test_bulk_goal_cache_does_not_override_a_recent_espn_live_result() (+8 more)

### Community 39 - "match_navigation_test.dart"
Cohesion: 0.09
Nodes (17): currentStandings, fake, favoriteTournaments, fixture, games, getMatchDetails, host, initData (+9 more)

### Community 41 - "forecasts_screen.dart"
Cohesion: 0.05
Nodes (36): api, _cancel, _checkMonth, _choices, _choose, createState, _currentMonth, _day (+28 more)

### Community 42 - "lineup_view.dart"
Cohesion: 0.10
Nodes (16): build, _canRate, createState, _field, _fieldPlayer, match, onRate, paint (+8 more)

### Community 43 - "app/__init__.py"
Cohesion: 0.15
Nodes (12): is_live_match(), is_live_status(), get_standings(), get_match_updates(), get_matches(), get_standings(), get_team_badges(), get_tournaments() (+4 more)

### Community 44 - "team_screen.dart"
Cohesion: 0.05
Nodes (40): ProfileApi, api, build, _calendar, _coverage, createState, _error, _generation (+32 more)

### Community 45 - "Deployment: Ubuntu, existing Caddy and PostgreSQL"
Cohesion: 0.06
Nodes (31): Contract and lifetime, Deploy, Persistent sign-in — 24 November 2026, Security review, Android, Backups and restore, Caddy and IP HTTPS, Configuration (+23 more)

### Community 46 - "api_client.dart"
Cohesion: 0.17
Nodes (7): ApiClient, configured, _credentialEndpoint, dio, _instance, session, storage

### Community 47 - "data_cache_provider_test.dart"
Cohesion: 0.09
Nodes (22): PublicDataCache, artwork, badges, cache, client, counts, create, dio (+14 more)

### Community 48 - "forecasts_test.dart"
Cohesion: 0.09
Nodes (19): allMatches, cancel, choose, count, ForecastData, game, games, isAuthenticated (+11 more)

### Community 49 - "auth_provider.dart"
Cohesion: 0.07
Nodes (24): _authenticate, _cachedUser, checkAuth, clearError, _client, _currentUser, dispose, _errorMessage (+16 more)

### Community 50 - "auth_session_test.dart"
Cohesion: 0.09
Nodes (18): auth, fake, main, nickname, offline, restart, started, status (+10 more)

### Community 51 - "models.py"
Cohesion: 0.19
Nodes (13): Forecast, ForecastDay, ForecastLedger, LineupDetail, MatchFormation, MatchHistoryJob, MatchLiveState, MatchResult (+5 more)

### Community 52 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.18
Nodes (5): main, game, main, liveGame, main

### Community 53 - "match_status.dart"
Cohesion: 0.29
Nodes (6): _clock, elapsed, isLiveMatch, isLiveStatus, _liveStatuses, liveWindow

### Community 54 - "goal_sync.py"
Cohesion: 0.23
Nodes (7): GoalClient, find_league(), refresh_details(), sync_goal(), goal_fallback(), goal_team_catalog(), test_goal_catalog_fetch_is_batched_cached_and_bounded_by_existing_client()

### Community 55 - "test_production.py"
Cohesion: 0.14
Nodes (12): Settings, init_db(), User, test_existing_password_hash_can_log_in(), production_settings(), test_production_accepts_admin_with_changed_password(), test_production_accepts_dedicated_database(), test_production_refuses_imported_development_account() (+4 more)

### Community 56 - "profiles_test.dart"
Cohesion: 0.14
Nodes (9): calendar, game, host, main, player, playerMatches, requestedSeasons, team (+1 more)

### Community 57 - "conftest.py"
Cohesion: 0.15
Nodes (6): seed_tournaments(), Tournament, block_external_http(), client(), db(), match()

### Community 58 - "tournament_menu_test.dart"
Cohesion: 0.20
Nodes (4): league, leagues, main, menu

### Community 61 - "core/tournament_menu.dart"
Cohesion: 0.05
Nodes (31): center, confirmedLineupRows, counts, left, line, offset, ordered, right (+23 more)

### Community 62 - "grouped_matches_list.dart"
Cohesion: 0.06
Nodes (22): MatchModel, byLeague, feedId, groupMatchesByLeague, groups, LeagueMatches, match, matches (+14 more)

### Community 63 - "test_api.py"
Cohesion: 0.33
Nodes (5): register(), test_duplicate_registration_is_rejected(), test_lineup_player_can_be_favorited(), test_prediction_and_favorite_persist(), test_register_login_and_current_user()

### Community 64 - "round_selector.dart"
Cohesion: 0.15
Nodes (12): build, _choose, createState, current, dispose, onChanged, _positioned, _RoundPicker (+4 more)

### Community 65 - "Appearance"
Cohesion: 0.40
Nodes (4): Appearance, Files and verification, Logo contrast — 20 October 2026, Visual rules

### Community 67 - "football_logo_test.dart"
Cohesion: 0.15
Nodes (9): badge, bytes, canvas, image, main, picture, pixels, recorder (+1 more)

### Community 68 - "favorites_screen.dart"
Cohesion: 0.09
Nodes (15): build, _buildEmptyState, _buildPlayersList, _buildTeamsList, _buildThemedLogo, createState, dispose, FavoritesScreen (+7 more)

### Community 69 - "AuthProvider"
Cohesion: 0.08
Nodes (23): onAuthenticated, openAuthScreen, resumedAfterLogin, runAuthenticatedAction, signedIn, AuthProvider, AuthScreen, _AuthScreenState (+15 more)

### Community 70 - "tournament_menu_preferences.dart"
Cohesion: 0.12
Nodes (15): _changed, _collapsed, dispose, _disposed, isCollapsed, _key, _load, move (+7 more)

### Community 71 - "Season and match interface"
Cohesion: 0.40
Nodes (4): Delivery, Limits, Scope, Season and match interface

### Community 72 - "test_season_sync.py"
Cohesion: 0.14
Nodes (25): update_all_data(), database_lock(), event(), mock_source(), get(), scoreboard(), test_distinct_events_with_same_teams_keep_their_ids_and_results(), test_failed_day_is_retried_without_reimporting_completed_history() (+17 more)

### Community 75 - "public_data_cache.dart"
Cohesion: 0.10
Nodes (16): CacheDirectory, DailySnapshot, day, _directory, expire, _folder, moscow, moscowDay (+8 more)

### Community 76 - "test_registration.py"
Cohesion: 0.18
Nodes (12): delete_empty_account(), ensure_user_schema(), signup(), test_empty_account_cleanup_only_removes_verified_target_and_its_favorites(), test_invalid_registration_is_rejected_without_echoing_password(), test_legacy_nickname_migration_is_idempotent_and_refuses_collisions(), test_login_errors_are_readable_and_do_not_disclose_account_existence(), test_nickname_is_unique_after_normalization() (+4 more)

### Community 77 - "Stale live status correction"
Cohesion: 0.40
Nodes (4): Delivery, Files, Scope, Stale live status correction

### Community 80 - "Backend over the phone hotspot"
Cohesion: 0.29
Nodes (6): Address and build, Backend over the phone hotspot, Latest build — 20 October 2026, Verification without USB forwarding, Verified on 18 October 2026, Windows setup

### Community 81 - "security.py"
Cohesion: 0.23
Nodes (9): _bcrypt_password(), get_password_hash(), verify_password(), test_expired_token_is_rejected(), test_legacy_long_password_truncation(), test_passlib_hashes_remain_verifiable(), test_password_hashes_are_salted(), test_password_round_trip() (+1 more)

### Community 84 - "Player photos outside sports APIs"
Cohesion: 0.33
Nodes (5): Alternatives considered, Limits, Ordered implementation, Player photos outside sports APIs, Selected approach

### Community 85 - "DataProvider"
Cohesion: 0.16
Nodes (17): DataProvider, ThemeProvider, build, initState, build, LeaderboardScreen, build, _calculateSelectedIndex (+9 more)

### Community 86 - "Match"
Cohesion: 0.11
Nodes (18): _score(), store_day(), Match, Team, TournamentSyncState, Display, Minute live updates, Provider priority (+10 more)

### Community 88 - "token_refresh_test.dart"
Cohesion: 0.13
Nodes (10): adapter, auth, client, close, expired, fetch, main, refreshes (+2 more)

### Community 89 - "public_data_cache_test.dart"
Cohesion: 0.22
Nodes (5): cache, main, now, root, snapshot

### Community 90 - "test_goal_fallback_uses_one_short_cached_batch_per_league"
Cohesion: 0.33
Nodes (3): ProviderMatch, test_goal_mapped_match_never_sends_goal_id_to_espn(), test_goal_fallback_uses_one_short_cached_batch_per_league()

### Community 92 - "persistent_session.dart"
Cohesion: 0.14
Nodes (8): clear, _generation, refresh, _refreshing, saveTokens, storage, _wasRejected, _writes

### Community 93 - "test_goal_api.py"
Cohesion: 0.13
Nodes (19): observe_goal(), GoalError, kickoff(), store_fixtures(), seed_tournaments(), client(), fixture(), test_euro_qualifying_rejects_old_2024_feed() (+11 more)

### Community 94 - "package:dio/dio.dart"
Cohesion: 0.12
Nodes (13): cancel, choose, dio, ForecastApi, mine, myRank, rankings, used (+5 more)

### Community 95 - "main.py"
Cohesion: 0.16
Nodes (9): validation_error(), sync_sources(), update_live_data(), update_live_feed(), lifespan(), readiness(), root(), start_sync() (+1 more)

### Community 96 - "test_sessions.py"
Cohesion: 0.23
Nodes (12): create_access_token(), test_invalid_expired_and_missing_tokens_are_rejected(), test_existing_short_password_and_legacy_email_session_still_work(), test_token_keeps_subject_without_mutating_input(), bearer(), register(), test_access_cannot_use_another_users_session(), test_configured_access_lifetime_is_used() (+4 more)

### Community 98 - "lineups.py"
Cohesion: 0.19
Nodes (17): bind_player(), canonical_id(), safe_photo(), utc_now(), ProviderCache, _discover_national_teams(), _photo(), queue_player() (+9 more)

### Community 99 - "routers/forecasts.py"
Cohesion: 0.11
Nodes (13): leaderboard(), get_current_user(), cancel(), Choice, choose(), mine(), my_rank(), quota() (+5 more)

### Community 100 - "Production deployment preparation"
Cohesion: 0.33
Nodes (5): Approved brief, Implementation, Production deployment preparation, Remaining server checks, Verification — 2026-10-22

### Community 101 - "auth.py"
Cohesion: 0.21
Nodes (11): AuthSession, login(), nickname_taken(), raise_unique_conflict(), read_users_me(), refresh_session(), register(), revoke_session() (+3 more)

### Community 102 - "Tournament menu and forecast update"
Cohesion: 0.22
Nodes (8): Approved scope, Drag handle correction (2026-10-23), Full-width country header interaction (2026-10-23), Implementation, One-second hold and player actions (2026-10-27), Session restoration correction (2026-10-27), Tournament menu and forecast update, Verification

### Community 103 - "Persistent session and confirmed lineup layout"
Cohesion: 0.33
Nodes (5): Implemented, Persistent session and confirmed lineup layout, Scope, Sources, Verification and deployment

### Community 104 - "Map"
Cohesion: 0.40
Nodes (3): cleanName, _countryTranslations, tr

### Community 105 - "Nickname registration"
Cohesion: 0.33
Nodes (5): API and errors, Identity and compatibility, Nickname registration, Requested cleanup, Verification

### Community 106 - "dart:async"
Cohesion: 0.22
Nodes (3): main, png, root

### Community 107 - "Win32Window"
Cohesion: 0.14
Nodes (7): Size, height, width, Win32Window, child_content_, quit_on_close_, window_handle_

### Community 108 - "win32_window.cpp"
Cohesion: 0.20
Nodes (5): Scale(), Win32Window::Win32Window(), WindowClassRegistrar, class_registered_, instance_

### Community 109 - "State"
Cohesion: 0.27
Nodes (8): FootballLogo, _FootballLogoState, LineupView, _LineupViewState, _SavedTournamentMenu, _SavedTournamentMenuState, TournamentMenu, _TournamentMenuState

### Community 112 - "Club badge repair"
Cohesion: 0.40
Nodes (4): Club badge repair, Deploy, Diagnosed production data, Verify

### Community 113 - "Daily public cache and permanent badges"
Cohesion: 0.29
Nodes (6): Approved behavior, Badge-loading correction (2.3.1+12), Daily public cache and permanent badges, Implementation, Russian club correction (2.3.2+13), Verification

### Community 114 - "Point"
Cohesion: 0.50
Nodes (3): Point, x, y

### Community 115 - "ChangeNotifier"
Cohesion: 0.50
Nodes (3): BadgeCache, PersistentSession, TournamentMenuPreferences

## Knowledge Gaps
- **733 isolated node(s):** `activeSeason`, `seasonLabel`, `_instance`, `dio`, `storage` (+728 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1111 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **27 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `DataProvider` connect `DataProvider` to `widgets/tournament_menu.dart`, `home_screen.dart`, `data_provider.dart`, `favorites_screen.dart`, `AuthProvider`, `match_navigation_test.dart`, `forecasts_screen.dart`, `match_detail_screen.dart`, `lineup_view.dart`, `team_screen.dart`, `State`, `package:flutter/material.dart`, `forecasts_test.dart`, `main.dart`, `ChangeNotifier`, `profiles_test.dart`, `widget_test.dart`, `grouped_matches_list.dart`?**
  _High betweenness centrality (0.063) - this node is a cross-community bridge._
- **What connects `activeSeason`, `seasonLabel`, `_instance` to the rest of the system?**
  _733 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `all_models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.02197802197802198 - nodes in this community are weakly interconnected._
- **Why does `db()` connect `conftest.py` to `lineups.py`, `Deployment: Ubuntu, existing Caddy and PostgreSQL`, `match_sync.py`, `test_team_badges.py`, `goal_sync.py`, `test_production.py`?**
  _High betweenness centrality (0.044) - this node is a cross-community bridge._
- **Should `FlutterWindow` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._
- **Why does `Проверка` connect `Deployment: Ubuntu, existing Caddy and PostgreSQL` to `conftest.py`?**
  _High betweenness centrality (0.043) - this node is a cross-community bridge._
- **Should `home_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.037037037037037035 - nodes in this community are weakly interconnected._
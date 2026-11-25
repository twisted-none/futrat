import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/all_models.dart';
import '../core/match_status.dart';
import '../core/public_data_cache.dart';
import '../core/badge_cache.dart';

class DataProvider extends ChangeNotifier {
  DataProvider({
    ApiClient? client,
    PublicDataCache? cache,
    BadgeCache? badges,
    DateTime Function()? now,
  }) : _client = client ?? ApiClient(),
       _now = now ?? DateTime.now,
       _cache =
           cache ??
           PublicDataCache(origin: (client ?? ApiClient()).dio.options.baseUrl),
       _badges = badges ?? BadgeCache.instance;

  final ApiClient _client;
  final PublicDataCache _cache;
  final BadgeCache _badges;
  final DateTime Function() _now;
  List<Map<String, dynamic>>? _rawMatches, _rawTournaments;
  String? _matchesDay, _tournamentsDay, _loadedDay;
  Future<void>? _initializing;
  Future<void>? _rollingDay;
  Future<void>? _liveRequest;
  Timer? _midnightTimer;
  bool _hasInitialized = false;
  bool _badgeMetadataBusy = false;
  DateTime? _badgeMetadataCheckedAt;

  List<MatchModel> _allMatches = [];
  List<MatchModel> _filteredMatches = [];
  List<Tournament> _tournaments = [];
  Tournament? _selectedLeague;

  List<Team> _favoriteTeams = [];
  List<Tournament> _favoriteTournaments = [];
  List<Player> _favoritePlayers = [];
  List<LeaderboardEntry> _leaderboard = [];
  List<StandingRow> _currentStandings = [];

  bool _isLoading = false;
  int _selectedRound = 1;
  Timer? _liveUpdateTimer;
  bool _liveBusy = false, _disposed = false, _updatesEnabled = true;
  final Map<int, Set<int>> _collapsedLeagues = {};

  bool isLeagueCollapsed(int feedId, int leagueId) =>
      _collapsedLeagues[feedId]?.contains(leagueId) ?? false;

  void toggleLeagueCollapsed(int feedId, int leagueId) {
    final leagues = _collapsedLeagues.putIfAbsent(feedId, () => <int>{});
    if (!leagues.remove(leagueId)) leagues.add(leagueId);
    notifyListeners();
  }

  final Tournament todayVirtual = Tournament(
    id: -1,
    name: "Матчи сегодня",
    type: "Virtual",
  );
  final Tournament liveVirtual = Tournament(
    id: -2,
    name: "Матчи сейчас",
    type: "Virtual",
  );

  List<MatchModel> get matches => _filteredMatches;
  List<MatchModel> get allMatches => List.unmodifiable(_allMatches);
  List<Tournament> get tournaments {
    final favorites = _favoriteTournaments.map((item) => item.id).toSet();
    return [
      ..._tournaments.where((item) => favorites.contains(item.id)),
      ..._tournaments.where((item) => !favorites.contains(item.id)),
    ];
  }

  Tournament? get selectedLeague => _selectedLeague;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  List<Team> get favoriteTeams => _favoriteTeams;
  List<Tournament> get favoriteTournaments => _favoriteTournaments;
  List<Player> get favoritePlayers => _favoritePlayers;
  List<StandingRow> get currentStandings => _currentStandings;
  bool get isLoading => _isLoading;
  int get selectedRound => _selectedRound;

  Future<void> initData() {
    return _initializing ??= _initialize().whenComplete(
      () => _initializing = null,
    );
  }

  Future<void> _initialize() async {
    if (_disposed) return;
    _hasInitialized = true;
    _isLoading = _allMatches.isEmpty && _loadedDay != moscowDay(_now());
    notifyListeners();
    try {
      var day = moscowDay(_now());
      if (_loadedDay != day) {
        final snapshot = await _cache.read();
        if (_disposed) return;
        day = moscowDay(_now());
        if (snapshot != null && snapshot.day == day) {
          try {
            final matches = snapshot.matches.map(MatchModel.fromJson).toList();
            final tournaments = snapshot.tournaments
                .map(Tournament.fromJson)
                .toList();
            _allMatches = matches;
            _tournaments = tournaments;
            _rawMatches = snapshot.matches;
            _rawTournaments = snapshot.tournaments;
            _matchesDay = _tournamentsDay = _loadedDay = day;
          } catch (_) {
            // A valid JSON file may still have obsolete/invalid model fields.
          }
        }
        if (_loadedDay != day) {
          await Future.wait([
            fetchTournaments(),
            fetchMatches(preserveRound: true),
          ]);
          if (_disposed) return;
          if (_matchesDay == day && _tournamentsDay == day) {
            _loadedDay = day;
            unawaited(_savePublicData());
          }
        }
      }
      if (_disposed) return;
      _selectedLeague ??= todayVirtual;
      _filterMatches(preserveRound: true);
      _startLiveUpdates();
      _scheduleMidnight();
      unawaited(_prefetchBadges());
      unawaited(fetchMissingTeamBadges());
      unawaited(fetchFavorites());
      unawaited(fetchLeaderboard());
      unawaited(fetchLiveUpdates());
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _savePublicData() async {
    if (_rawMatches == null ||
        _rawTournaments == null ||
        _matchesDay != _tournamentsDay ||
        _matchesDay != moscowDay(_now())) {
      return;
    }
    await _cache.save(
      DailySnapshot(
        day: _matchesDay!,
        matches: _rawMatches!,
        tournaments: _rawTournaments!,
      ),
    );
  }

  Future<void> _prefetchBadges() => _badges.prefetch([
    ..._tournaments.map((t) => t.logoUrl),
    ..._allMatches.expand((m) => [m.homeTeam.logoUrl, m.awayTeam.logoUrl]),
  ]);

  /// Refresh just missing artwork, even when today's fixtures came from disk.
  Future<void> fetchMissingTeamBadges({bool force = false}) async {
    if (_disposed || _badgeMetadataBusy || _rawMatches == null) return;
    final now = _now();
    if (!force &&
        _badgeMetadataCheckedAt != null &&
        now.difference(_badgeMetadataCheckedAt!) < const Duration(minutes: 5)) {
      return;
    }
    final missing = <int>{};
    for (final match in _allMatches) {
      for (final team in [match.homeTeam, match.awayTeam]) {
        if (team.logoUrl == null || team.logoUrl!.trim().isEmpty) {
          missing.add(team.id);
        }
      }
    }
    if (missing.isEmpty) return;
    _badgeMetadataBusy = true;
    _badgeMetadataCheckedAt = now;
    final day = moscowDay(now);
    try {
      final ids = missing.toList();
      final artwork = <int, String>{};
      for (var offset = 0; offset < ids.length; offset += 100) {
        final response = await _client.dio.get(
          '/api/team-badges',
          queryParameters: {
            'ids': ids.sublist(offset, (offset + 100).clamp(0, ids.length)),
          },
          options: Options(listFormat: ListFormat.multi),
        );
        if (_disposed || day != moscowDay(_now())) return;
        for (final row in response.data as List) {
          final id = row['id'];
          final url = row['logo_url'];
          final uri = url is String ? Uri.tryParse(url) : null;
          if (id is int &&
              missing.contains(id) &&
              uri != null &&
              {'https', 'http'}.contains(uri.scheme) &&
              uri.hasAuthority &&
              uri.userInfo.isEmpty) {
            artwork[id] = url;
          }
        }
      }
      if (artwork.isEmpty || _rawMatches == null) return;
      Map<String, dynamic> patchedTeam(dynamic raw) {
        final team = Map<String, dynamic>.from(raw);
        if (artwork.containsKey(team['id']) &&
            (team['logo_url'] == null ||
                (team['logo_url'] as String).trim().isEmpty)) {
          team['logo_url'] = artwork[team['id']];
        }
        return team;
      }

      _rawMatches = _rawMatches!
          .map(
            (row) => <String, dynamic>{
              ...row,
              'home_team': patchedTeam(row['home_team']),
              'away_team': patchedTeam(row['away_team']),
            },
          )
          .toList();
      _allMatches = _rawMatches!.map(MatchModel.fromJson).toList();
      _filterMatches(preserveRound: true);
      unawaited(_savePublicData());
      unawaited(_prefetchBadges());
    } catch (error) {
      debugPrint('Team artwork unavailable: ${error.runtimeType}');
    } finally {
      _badgeMetadataBusy = false;
    }
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    if (_disposed || !_updatesEnabled) return;
    _midnightTimer = Timer(nextMoscowMidnight(_now()).difference(_now()), () {
      unawaited(_newDay());
    });
  }

  Future<void> _newDay() =>
      _rollingDay ??= _rollDay().whenComplete(() => _rollingDay = null);

  Future<void> _rollDay() async {
    await _cache.expire();
    if (_disposed) return;
    if (_loadedDay != moscowDay(_now())) {
      // Yesterday's list must not remain a current-day offline snapshot.
      _allMatches = [];
      _filteredMatches = [];
      _rawMatches = null;
      _matchesDay = null;
      notifyListeners();
      await initData();
    }
    _scheduleMidnight();
  }

  void _startLiveUpdates() {
    _liveUpdateTimer?.cancel();
    if (!_updatesEnabled || _disposed) return;
    _liveUpdateTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_hasInitialized && _loadedDay != moscowDay(_now())) {
        unawaited(_newDay());
      } else {
        unawaited(fetchLiveUpdates());
        unawaited(fetchMissingTeamBadges());
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _liveUpdateTimer?.cancel();
    _midnightTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchTournaments() async {
    final day = moscowDay(_now());
    try {
      final res = await _client.dio.get('/api/tournaments');
      if (_disposed || day != moscowDay(_now())) return;
      final rows = (res.data as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _tournaments = rows.map(Tournament.fromJson).toList();
      _rawTournaments = rows;
      _tournamentsDay = day;
    } catch (e) {
      print("Error fetching tournaments: $e");
    }
  }

  Future<void> fetchMatches({bool preserveRound = false}) async {
    final day = moscowDay(_now());
    try {
      final res = await _client.dio.get('/api/matches');
      if (_disposed || day != moscowDay(_now())) return;
      final rows = (res.data as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _allMatches = rows.map(MatchModel.fromJson).toList();
      _rawMatches = rows;
      _matchesDay = day;
      if (!_disposed) _filterMatches(preserveRound: preserveRound);
    } catch (e) {
      print("Error fetching matches: $e");
    }
  }

  void setLiveUpdatesActive(bool active) {
    _updatesEnabled = active;
    if (active) {
      _startLiveUpdates();
      _scheduleMidnight();
      if (_hasInitialized && _loadedDay != moscowDay(_now())) {
        unawaited(_newDay());
      } else {
        unawaited(fetchLiveUpdates());
        unawaited(fetchMissingTeamBadges());
        unawaited(_prefetchBadges());
      }
    } else {
      _liveUpdateTimer?.cancel();
      _midnightTimer?.cancel();
    }
  }

  Future<void> fetchLiveUpdates() => _liveRequest ??= _fetchLiveUpdates()
      .whenComplete(() => _liveRequest = null);

  Future<void> _fetchLiveUpdates() async {
    if (_liveBusy || _disposed || !_updatesEnabled) return;
    _liveBusy = true;
    try {
      final day = moscowDay(_now());
      final now = _now();
      final ids = _allMatches
          .where(
            (m) =>
                isLiveStatus(m.status) ||
                (m.dateTime.isAfter(now.subtract(const Duration(hours: 6))) &&
                    m.dateTime.isBefore(now.add(const Duration(minutes: 15)))),
          )
          .map((m) => m.id)
          .take(500)
          .toList();
      final response = await _client.dio.get(
        '/api/matches/updates',
        queryParameters: {'ids': ids},
        options: Options(listFormat: ListFormat.multi),
      );
      if (_disposed || day != moscowDay(_now())) return;
      final updates = {
        for (final row in response.data as List)
          row['id'] as int: Map<String, dynamic>.from(row),
      };
      final known = _allMatches.map((m) => m.id).toSet();
      if (updates.keys.any((id) => !known.contains(id))) {
        await fetchMatches(preserveRound: true);
      } else {
        _allMatches = _allMatches
            .map(
              (m) => updates.containsKey(m.id)
                  ? m.withLiveUpdate(updates[m.id]!)
                  : m,
            )
            .toList();
        _filterMatches(preserveRound: true);
      }
      _rawMatches = _rawMatches
          ?.map(
            (row) => updates.containsKey(row['id'])
                ? {...row, ...updates[row['id']]!}
                : row,
          )
          .toList();
      unawaited(_savePublicData());
    } catch (error) {
      debugPrint('Live update unavailable: ${error.runtimeType}');
    } finally {
      _liveBusy = false;
    }
  }

  Future<void> fetchStandings(int tournamentId) async {
    try {
      final res = await _client.dio.get(
        '/api/tournaments/$tournamentId/standings',
      );
      _currentStandings = (res.data as List)
          .map((e) => StandingRow.fromJson(e))
          .toList();
      notifyListeners();
    } catch (e) {
      _currentStandings = [];
      notifyListeners();
    }
  }

  Future<void> fetchFavorites() async {
    try {
      if (await _client.storage.read(key: 'auth_token') == null) {
        if (!_disposed) clearFavorites();
        return;
      }
      final t = await _client.dio.get('/users/me/favorites/teams');
      if (_disposed) return;
      _favoriteTeams = (t.data as List).map((e) => Team.fromJson(e)).toList();

      final tr = await _client.dio.get('/users/me/favorites/tournaments');
      if (_disposed) return;
      _favoriteTournaments = (tr.data as List)
          .map((e) => Tournament.fromJson(e))
          .toList();

      final p = await _client.dio.get('/users/me/favorites/players');
      if (_disposed) return;
      _favoritePlayers = (p.data as List)
          .map((e) => Player.fromJson(e))
          .toList();
      notifyListeners();
      unawaited(
        _badges.prefetch([
          ..._favoriteTeams.map((team) => team.logoUrl),
          ..._favoriteTournaments.map((tournament) => tournament.logoUrl),
        ]),
      );
    } catch (e) {
      print("Error fetching favorites: $e");
    }
  }

  Future<void> fetchLeaderboard() async {
    try {
      final res = await _client.dio.get('/users/leaderboard');
      if (_disposed) return;
      _leaderboard = (res.data as List)
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList();
      notifyListeners();
    } catch (e) {
      print("Error fetching leaderboard: $e");
    }
  }

  Future<MatchModel?> getMatchDetails(int matchId) async {
    try {
      final response = await _client.dio.get('/api/matches/$matchId');
      return MatchModel.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> ratePlayer(int lineupId, double rating) async {
    try {
      await _client.dio.post(
        '/api/rate-player',
        data: {"lineup_id": lineupId, "rating": rating},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleTeamFavorite(int id, [bool? f]) async {
    final isFav = isTeamFavorite(id);
    if (f != null && f != isFav) return;
    try {
      if (isFav) {
        _favoriteTeams.removeWhere((t) => t.id == id);
        await _client.dio.delete('/users/favorites/teams/$id');
      } else {
        await _client.dio.post('/users/favorites/teams/$id');
        final res = await _client.dio.get('/users/me/favorites/teams');
        _favoriteTeams = (res.data as List)
            .map((e) => Team.fromJson(e))
            .toList();
      }
      notifyListeners();
    } catch (e) {
      print("Error toggling team fav: $e");
    }
  }

  Future<void> toggleTournamentFavorite(int id) async {
    final isFav = isLeagueFavorite(id);
    try {
      if (isFav) {
        _favoriteTournaments.removeWhere((t) => t.id == id);
        await _client.dio.delete('/users/favorites/tournaments/$id');
      } else {
        await _client.dio.post('/users/favorites/tournaments/$id');
        final res = await _client.dio.get('/users/me/favorites/tournaments');
        _favoriteTournaments = (res.data as List)
            .map((e) => Tournament.fromJson(e))
            .toList();
      }
      notifyListeners();
    } catch (e) {
      print("Error toggling tourn fav: $e");
    }
  }

  Future<void> togglePlayerFavorite(int id) async {
    try {
      if (isPlayerFavorite(id)) {
        await _client.dio.delete('/users/favorites/players/$id');
      } else {
        await _client.dio.post('/users/favorites/players/$id');
      }
      final response = await _client.dio.get('/users/me/favorites/players');
      _favoritePlayers = (response.data as List)
          .map((item) => Player.fromJson(item))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling player favorite: $e');
    }
  }

  void clearFavorites() {
    _favoriteTeams = [];
    _favoriteTournaments = [];
    _favoritePlayers = [];
    notifyListeners();
  }

  bool isTeamFavorite(int id) => _favoriteTeams.any((t) => t.id == id);
  bool isLeagueFavorite(int id) => _favoriteTournaments.any((t) => t.id == id);
  bool isPlayerFavorite(int id) => _favoritePlayers.any((p) => p.id == id);

  void setSelectedRound(int round) {
    _selectedRound = round;
    notifyListeners();
  }

  void selectLeague(Tournament l) {
    _selectedLeague = l;
    _filterMatches();
    if (l.id > 0) fetchStandings(l.id);
    notifyListeners();
  }

  void _filterMatches({bool preserveRound = false}) {
    final previousRound = _selectedRound;
    if (_selectedLeague == null) return;

    if (_selectedLeague!.id == -1) {
      final today = moscowDay(_now());
      // Убираем DELAYED из раздела "Матчи сегодня"
      _filteredMatches = _allMatches
          .where((m) => moscowDay(m.dateTime) == today && m.status != "DELAYED")
          .toList();
    } else if (_selectedLeague!.id == -2) {
      final now = _now();
      _filteredMatches = _allMatches.where((m) => m.isLiveAt(now)).toList();
    } else {
      // Обычный турнир — тут отложенные матчи ОСТАЮТСЯ в своих турах
      _filteredMatches = _allMatches
          .where((m) => m.tournament.id == _selectedLeague!.id)
          .toList();

      // Но при поиске ТЕКУЩЕГО тура (чтобы авто-скролл сработал) мы их игнорируем
      final validMatches = _filteredMatches
          .where(
            (m) =>
                m.status != "CANCELLED" &&
                m.status != "POSTPONED" &&
                m.status != "DELAYED",
          )
          .toList();

      if (validMatches.isNotEmpty) {
        int cur = 1;
        for (var m in validMatches) {
          if (m.status != "SCHEDULED" && m.round > cur) cur = m.round;
        }
        if (_selectedLeague?.name == "Champions League" && cur > 8) {
          _selectedRound = 8;
        } else {
          _selectedRound = cur;
        }
      } else {
        _selectedRound = 1;
      }
    }
    if (preserveRound) _selectedRound = previousRound;
    _filteredMatches.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    notifyListeners();
  }
}

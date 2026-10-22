import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/all_models.dart';
import '../core/match_status.dart';

class DataProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();

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

  Future<void> initData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        fetchTournaments(),
        fetchMatches(),
        fetchFavorites(),
        fetchLeaderboard(),
      ]);

      if (_tournaments.isNotEmpty && _selectedLeague == null) {
        _selectedLeague = todayVirtual;
        _filterMatches();
      }
      _startLiveUpdates();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startLiveUpdates() {
    _liveUpdateTimer?.cancel();
    if (!_updatesEnabled || _disposed) return;
    _liveUpdateTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => fetchLiveUpdates(),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _liveUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchTournaments() async {
    try {
      final res = await _client.dio.get('/api/tournaments');
      _tournaments = (res.data as List)
          .map((e) => Tournament.fromJson(e))
          .toList();
    } catch (e) {
      print("Error fetching tournaments: $e");
    }
  }

  Future<void> fetchMatches({bool preserveRound = false}) async {
    try {
      final res = await _client.dio.get('/api/matches');
      _allMatches = (res.data as List)
          .map((e) => MatchModel.fromJson(e))
          .toList();
      if (!_disposed) _filterMatches(preserveRound: preserveRound);
    } catch (e) {
      print("Error fetching matches: $e");
    }
  }

  void setLiveUpdatesActive(bool active) {
    _updatesEnabled = active;
    if (active) {
      _startLiveUpdates();
      fetchLiveUpdates();
    } else {
      _liveUpdateTimer?.cancel();
    }
  }

  Future<void> fetchLiveUpdates() async {
    if (_liveBusy || _disposed || !_updatesEnabled) return;
    _liveBusy = true;
    try {
      final now = DateTime.now();
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
      if (_disposed) return;
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
    if (await _client.storage.read(key: 'auth_token') == null) {
      clearFavorites();
      return;
    }
    try {
      final t = await _client.dio.get('/users/me/favorites/teams');
      _favoriteTeams = (t.data as List).map((e) => Team.fromJson(e)).toList();

      final tr = await _client.dio.get('/users/me/favorites/tournaments');
      _favoriteTournaments = (tr.data as List)
          .map((e) => Tournament.fromJson(e))
          .toList();

      final p = await _client.dio.get('/users/me/favorites/players');
      _favoritePlayers = (p.data as List)
          .map((e) => Player.fromJson(e))
          .toList();
      notifyListeners();
    } catch (e) {
      print("Error fetching favorites: $e");
    }
  }

  Future<void> fetchLeaderboard() async {
    try {
      final res = await _client.dio.get('/users/leaderboard');
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
      final now = DateTime.now();
      // Убираем DELAYED из раздела "Матчи сегодня"
      _filteredMatches = _allMatches
          .where(
            (m) =>
                m.dateTime.year == now.year &&
                m.dateTime.month == now.month &&
                m.dateTime.day == now.day &&
                m.status != "DELAYED",
          )
          .toList();
    } else if (_selectedLeague!.id == -2) {
      final now = DateTime.now();
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

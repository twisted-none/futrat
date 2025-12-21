import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/all_models.dart';

class DataProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();

  // --- ДАННЫЕ ---
  List<MatchModel> _allMatches = [];
  List<MatchModel> _filteredMatches = [];
  List<Tournament> _tournaments = [];
  Tournament? _selectedLeague;

  // --- ИЗБРАННОЕ ---
  List<Team> _favoriteTeams = [];
  List<Tournament> _favoriteTournaments = [];
  List<Player> _favoritePlayers = [];

  // --- ЛИДЕРБОРД ---
  final List<Map<String, dynamic>> _leaderboard = [
    {"username": "Striker99", "points": 150},
    {"username": "Admin", "points": 120},
    {"username": "FutMaster", "points": 99},
  ];

  bool _isLoading = false;

  // --- ГЕТТЕРЫ ---
  List<MatchModel> get matches => _filteredMatches;
  List<Tournament> get tournaments => _tournaments;
  Tournament? get selectedLeague => _selectedLeague;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  
  List<Team> get favoriteTeams => _favoriteTeams;
  List<Tournament> get favoriteTournaments => _favoriteTournaments;
  List<Player> get favoritePlayers => _favoritePlayers;
  
  bool get isLoading => _isLoading;

  // --- ИНИЦИАЛИЗАЦИЯ ---
  Future<void> initData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        fetchTournaments(),
        fetchMatches(),
        fetchFavorites(),
      ]);
      
      // Выбор лиги по умолчанию (сначала любимые, потом АПЛ, потом первая попавшаяся)
      if (_tournaments.isNotEmpty && _selectedLeague == null) {
        if (_favoriteTournaments.isNotEmpty) {
           // Ищем объект турнира в общем списке, который соответствует любимому
           try {
             _selectedLeague = _tournaments.firstWhere((t) => t.id == _favoriteTournaments.first.id);
           } catch (e) {
             _selectedLeague = _tournaments.first;
           }
        } else {
           try {
             _selectedLeague = _tournaments.firstWhere((t) => t.name == "Premier League");
           } catch (e) {
             _selectedLeague = _tournaments.first;
           }
        }
        _filterMatches();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ЗАГРУЗКА ДАННЫХ ---

  Future<void> fetchTournaments() async {
    try {
      final response = await _client.dio.get('/api/tournaments');
      _tournaments = (response.data as List).map((e) => Tournament.fromJson(e)).toList();
    } catch (e) {
      print("Error fetching tournaments: $e");
    }
  }

  Future<void> fetchMatches() async {
    try {
      final response = await _client.dio.get('/api/matches');
      _allMatches = (response.data as List).map((e) => MatchModel.fromJson(e)).toList();
      _filterMatches();
    } catch (e) {
      print("Error fetching matches: $e");
    }
  }

  Future<void> fetchFavorites() async {
    try {
      final teamRes = await _client.dio.get('/users/me/favorites/teams');
      _favoriteTeams = (teamRes.data as List).map((e) => Team.fromJson(e)).toList();

      final tournRes = await _client.dio.get('/users/me/favorites/tournaments');
      _favoriteTournaments = (tournRes.data as List).map((e) => Tournament.fromJson(e)).toList();

      final playerRes = await _client.dio.get('/users/me/favorites/players');
      _favoritePlayers = (playerRes.data as List).map((e) => Player.fromJson(e)).toList();
      
      notifyListeners();
    } catch (e) {
      print("Error fetching favorites: $e");
    }
  }

  // --- УПРАВЛЕНИЕ ИЗБРАННЫМ ---

  Future<void> toggleTeamFavorite(int teamId, [bool? forceState]) async {
    final isFav = isTeamFavorite(teamId);
    // Если передан forceState (например true = удалить), проверяем совпадение
    if (forceState != null && forceState != isFav) return; 

    try {
      if (isFav) {
        // Удаляем локально сразу для отзывчивости
        _favoriteTeams.removeWhere((t) => t.id == teamId);
        notifyListeners();
        await _client.dio.delete('/users/favorites/teams/$teamId');
      } else {
        await _client.dio.post('/users/favorites/teams/$teamId');
        // Подгружаем актуальный список, чтобы получить данные команды (имя, лого)
        final res = await _client.dio.get('/users/me/favorites/teams');
        _favoriteTeams = (res.data as List).map((e) => Team.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      print("Error toggling team fav: $e");
      await fetchFavorites(); // Откат при ошибке
    }
  }

  Future<void> toggleTournamentFavorite(int tournamentId) async {
    final isFav = isLeagueFavorite(tournamentId);
    try {
      if (isFav) {
        _favoriteTournaments.removeWhere((t) => t.id == tournamentId);
        notifyListeners();
        await _client.dio.delete('/users/favorites/tournaments/$tournamentId');
      } else {
        await _client.dio.post('/users/favorites/tournaments/$tournamentId');
        final res = await _client.dio.get('/users/me/favorites/tournaments');
        _favoriteTournaments = (res.data as List).map((e) => Tournament.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      print("Error toggling tourn fav: $e");
    }
  }

  // --- ЛОГИКА UI ---

  bool isTeamFavorite(int id) => _favoriteTeams.any((t) => t.id == id);
  bool isLeagueFavorite(int id) => _favoriteTournaments.any((t) => t.id == id);

  void selectLeague(Tournament league) {
    _selectedLeague = league;
    _filterMatches();
    notifyListeners();
  }

  void _filterMatches() {
    if (_selectedLeague == null) {
      _filteredMatches = _allMatches;
    } else {
      _filteredMatches = _allMatches
          .where((m) => m.tournament.id == _selectedLeague!.id)
          .toList();
    }
    // Сортировка по дате
    _filteredMatches.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }
}
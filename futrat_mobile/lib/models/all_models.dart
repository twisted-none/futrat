class User {
  final int id; final String email; final String username;
  User({required this.id, required this.email, required this.username});
  factory User.fromJson(Map<String, dynamic> json) => User(id: json['id'], email: json['email'], username: json['username']);
}

class Tournament {
  final int id; final String name; final String? country; final String type;
  Tournament({required this.id, required this.name, this.country, required this.type});
  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(id: json['id'], name: json['name'], country: json['country'], type: json['type']);
}

class Team {
  final int id; final String name; final String? logoUrl; final String? country;
  Team({required this.id, required this.name, this.logoUrl, this.country});
  factory Team.fromJson(Map<String, dynamic> json) => Team(id: json['id'], name: json['name'], logoUrl: json['logo_url'], country: json['country']);
}

class Player {
  final int id; final String name; final int goals; final int assists;
  Player({required this.id, required this.name, required this.goals, required this.assists});
  factory Player.fromJson(Map<String, dynamic> json) => Player(id: json['id'], name: json['name'], goals: json['goals'] ?? 0, assists: json['assists'] ?? 0);
}

class MatchEvent {
  final int id;
  final String type;
  final int minute;
  final Player player;

  MatchEvent({required this.id, required this.type, required this.minute, required this.player});
  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      id: json['id'],
      type: json['type'],
      minute: json['minute'],
      player: Player.fromJson(json['player']),
    );
  }
}

class MatchModel {
  final int id;
  final DateTime dateTime;
  final String status;
  final int? scoreHome;
  final int? scoreAway;
  final int round; // ТУР
  final Team homeTeam;
  final Team awayTeam;
  final Tournament tournament;
  final List<MatchEvent> events; // ГОЛЫ

  MatchModel({
    required this.id,
    required this.dateTime,
    required this.status,
    this.scoreHome,
    this.scoreAway,
    required this.round,
    required this.homeTeam,
    required this.awayTeam,
    required this.tournament,
    required this.events,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'],
      dateTime: DateTime.parse(json['date_time']),
      status: json['status'],
      scoreHome: json['score_home'],
      scoreAway: json['score_away'],
      round: json['round'] ?? 1,
      homeTeam: Team.fromJson(json['home_team']),
      awayTeam: Team.fromJson(json['away_team']),
      tournament: Tournament.fromJson(json['tournament']),
      events: (json['events'] as List).map((e) => MatchEvent.fromJson(e)).toList(),
    );
  }
}
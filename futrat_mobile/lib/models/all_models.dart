// Пользователь
class User {
  final int id;
  final String email;
  final String username;

  User({required this.id, required this.email, required this.username});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
    );
  }
}

// Турнир
class Tournament {
  final int id;
  final String name;
  final String? country;
  final String type;

  Tournament({required this.id, required this.name, this.country, required this.type});

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'],
      name: json['name'],
      country: json['country'],
      type: json['type'],
    );
  }
}

// Команда
class Team {
  final int id;
  final String name;
  final String? logoUrl;
  final String? country;

  Team({required this.id, required this.name, this.logoUrl, this.country});

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      logoUrl: json['logo_url'],
      country: json['country'],
    );
  }
}

// Игрок
class Player {
  final int id;
  final String name;
  final String? position;
  final int goals;
  final int assists;

  Player({
    required this.id, 
    required this.name, 
    this.position, 
    required this.goals, 
    required this.assists
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      position: json['position'],
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
    );
  }
}

// Матч
class MatchModel {
  final int id;
  final DateTime dateTime;
  final String status;
  final int? scoreHome;
  final int? scoreAway;
  final Team homeTeam;
  final Team awayTeam;
  final Tournament tournament;

  MatchModel({
    required this.id,
    required this.dateTime,
    required this.status,
    this.scoreHome,
    this.scoreAway,
    required this.homeTeam,
    required this.awayTeam,
    required this.tournament,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'],
      dateTime: DateTime.parse(json['date_time']),
      status: json['status'],
      scoreHome: json['score_home'],
      scoreAway: json['score_away'],
      homeTeam: Team.fromJson(json['home_team']),
      awayTeam: Team.fromJson(json['away_team']),
      tournament: Tournament.fromJson(json['tournament']),
    );
  }
}

// Прогноз
class Prediction {
  final int id;
  final int predictedHome;
  final int predictedAway;
  final int points;

  Prediction({required this.id, required this.predictedHome, required this.predictedAway, required this.points});

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      id: json['id'],
      predictedHome: json['predicted_home_score'],
      predictedAway: json['predicted_away_score'],
      points: json['points_awarded'],
    );
  }
}
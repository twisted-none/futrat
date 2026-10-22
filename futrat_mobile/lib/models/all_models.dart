import '../core/match_status.dart';

class User {
  final int id;
  final String? email;
  final String username;
  User({required this.id, required this.email, required this.username});
  factory User.fromJson(Map<String, dynamic> json) =>
      User(id: json['id'], email: json['email'], username: json['username']);
}

class Tournament {
  final int id;
  final String name;
  final String? country;
  final String type;
  final String? logoUrl;
  final String? apiCode;
  final String? currentSeason;
  Tournament({
    required this.id,
    required this.name,
    this.country,
    required this.type,
    this.logoUrl,
    this.apiCode,
    this.currentSeason,
  });
  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
    id: json['id'],
    name: json['name'],
    country: json['country'],
    type: json['type'],
    logoUrl: json['logo_url'],
    apiCode: json['api_code'],
    currentSeason: json['current_season'],
  );
}

class Team {
  final int id;
  final String name;
  final String? logoUrl;
  final String? country;
  Team({required this.id, required this.name, this.logoUrl, this.country});
  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'],
    name: json['name'],
    logoUrl: json['logo_url'],
    country: json['country'],
  );
}

class Player {
  final int id;
  final String name;
  final int goals;
  final int assists;
  final int teamId;
  final String? photoUrl;
  Player({
    required this.id,
    required this.name,
    required this.goals,
    required this.assists,
    required this.teamId,
    this.photoUrl,
  });
  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'],
    name: json['name'],
    goals: json['goals'] ?? 0,
    assists: json['assists'] ?? 0,
    teamId: json['team_id'] ?? 0,
    photoUrl: json['photo_url'],
  );
}

class MatchEvent {
  final int id;
  final String type;
  final int minute;
  final Player player;
  final Player? secondaryPlayer;
  MatchEvent({
    required this.id,
    required this.type,
    required this.minute,
    required this.player,
    this.secondaryPlayer,
  });
  factory MatchEvent.fromJson(Map<String, dynamic> json) => MatchEvent(
    id: json['id'],
    type: json['type'],
    minute: json['minute'],
    player: Player.fromJson(json['player']),
    secondaryPlayer: json['secondary_player'] != null
        ? Player.fromJson(json['secondary_player'])
        : null,
  );
}

class LineupPlayer {
  final int id;
  final int? playerId;
  final int teamId;
  final String playerName;
  final String jersey;
  final String position;
  final bool isStarter;
  final String rating;
  final String? photoUrl;
  final int? slot;
  final bool? appeared;
  final int? minutes;
  final int? goals;
  final int? assists;
  final double? sourceRating;
  final String? ratingSource;
  final int ratingCount;
  LineupPlayer({
    required this.id,
    this.playerId,
    required this.teamId,
    required this.playerName,
    required this.jersey,
    required this.position,
    required this.isStarter,
    required this.rating,
    this.photoUrl,
    this.slot,
    this.appeared,
    this.minutes,
    this.goals,
    this.assists,
    this.sourceRating,
    this.ratingSource,
    this.ratingCount = 0,
  });
  factory LineupPlayer.fromJson(Map<String, dynamic> json) => LineupPlayer(
    id: json['id'],
    playerId: json['player_id'],
    teamId: json['team_id'],
    playerName: json['player_name'],
    jersey: json['jersey_number'] ?? '',
    position: json['position'] ?? '',
    isStarter: json['is_starter'] ?? true,
    rating: json['rating'] ?? '-',
    photoUrl: json['photo_url'],
    slot: json['slot'],
    appeared: json['appeared'],
    minutes: json['minutes'],
    goals: json['goals'],
    assists: json['assists'],
    sourceRating: (json['source_rating'] as num?)?.toDouble(),
    ratingSource: json['rating_source'],
    ratingCount: json['rating_count'] ?? 0,
  );
}

// Найди класс StandingRow и замени его:
class StandingRow {
  final int rank;
  final Team team;
  final int played;
  final int won;
  final int draw;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int points;
  final List<String> form;
  final String? groupName; // НОВОЕ ПОЛЕ

  StandingRow({
    required this.rank,
    required this.team,
    required this.played,
    required this.won,
    required this.draw,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
    required this.form,
    this.groupName,
  });

  factory StandingRow.fromJson(Map<String, dynamic> json) => StandingRow(
    rank: json['rank'],
    team: Team.fromJson(json['team']),
    played: json['played'],
    won: json['won'],
    draw: json['draw'],
    lost: json['lost'],
    goalsFor: json['goals_for'],
    goalsAgainst: json['goals_against'],
    points: json['points'],
    form: List<String>.from(json['form'] ?? []),
    groupName: json['group_name'], // ПАРСИНГ ГРУППЫ
  );
}

class MatchModel {
  final int id;
  final DateTime dateTime;
  final String status;
  final int? scoreHome;
  final int? scoreAway;
  final int round;
  final int possessionHome;
  final int possessionAway;
  final int shotsHome;
  final int shotsAway;
  final int cornersHome;
  final int cornersAway;
  final int foulsHome;
  final int foulsAway;
  final int yellowCardsHome;
  final int yellowCardsAway;
  final int redCardsHome;
  final int redCardsAway;
  final int offsidesHome;
  final int offsidesAway;
  final int passesHome;
  final int passesAway;
  final int passAccuracyHome;
  final int passAccuracyAway;
  final double xgHome;
  final double xgAway;
  final int shotsOnTargetHome;
  final int shotsOnTargetAway;
  final int savesHome;
  final int savesAway;
  final Team homeTeam;
  final Team awayTeam;
  final Tournament tournament;
  final List<MatchEvent> events;
  final List<LineupPlayer> lineups;
  final Map<String, String> formations;
  final String? clock, phase;
  final DateTime? liveUpdatedAt;

  String get liveLabel {
    final fresh =
        liveUpdatedAt == null ||
        DateTime.now().difference(liveUpdatedAt!).inSeconds <= 180;
    if (!isLive) return needsStatusCheck ? 'Уточняется' : status;
    if (fresh && phase == 'HALF_TIME') return 'Перерыв';
    if (fresh && phase == 'PENALTIES') return 'Пенальти · LIVE';
    return fresh && clock != null && clock!.isNotEmpty
        ? '$clock′ · LIVE'
        : 'LIVE';
  }

  final bool? serverLive;

  bool isLiveAt(DateTime now) =>
      serverLive != false && isLiveMatch(status, dateTime, now);
  bool get isLive => isLiveAt(DateTime.now());
  bool get needsStatusCheck => isLiveStatus(status) && !isLive;

  MatchModel({
    required this.id,
    required this.dateTime,
    required this.status,
    this.scoreHome,
    this.scoreAway,
    required this.round,
    required this.possessionHome,
    required this.possessionAway,
    required this.shotsHome,
    required this.shotsAway,
    required this.cornersHome,
    required this.cornersAway,
    required this.foulsHome,
    required this.foulsAway,
    required this.yellowCardsHome,
    required this.yellowCardsAway,
    required this.redCardsHome,
    required this.redCardsAway,
    required this.offsidesHome,
    required this.offsidesAway,
    required this.passesHome,
    required this.passesAway,
    required this.passAccuracyHome,
    required this.passAccuracyAway,
    required this.xgHome,
    required this.xgAway,
    required this.shotsOnTargetHome,
    required this.shotsOnTargetAway,
    required this.savesHome,
    required this.savesAway,
    required this.homeTeam,
    required this.awayTeam,
    required this.tournament,
    required this.events,
    required this.lineups,
    this.formations = const {},
    this.serverLive,
    this.clock,
    this.phase,
    this.liveUpdatedAt,
  });

  MatchModel withLiveUpdate(Map<String, dynamic> patch) => MatchModel(
    id: id,
    dateTime: DateTime.parse(patch['date_time']).toLocal(),
    status: patch['status'],
    scoreHome: patch['score_home'],
    scoreAway: patch['score_away'],
    round: round,
    possessionHome: possessionHome,
    possessionAway: possessionAway,
    shotsHome: shotsHome,
    shotsAway: shotsAway,
    cornersHome: cornersHome,
    cornersAway: cornersAway,
    foulsHome: foulsHome,
    foulsAway: foulsAway,
    yellowCardsHome: yellowCardsHome,
    yellowCardsAway: yellowCardsAway,
    redCardsHome: redCardsHome,
    redCardsAway: redCardsAway,
    offsidesHome: offsidesHome,
    offsidesAway: offsidesAway,
    passesHome: passesHome,
    passesAway: passesAway,
    passAccuracyHome: passAccuracyHome,
    passAccuracyAway: passAccuracyAway,
    xgHome: xgHome,
    xgAway: xgAway,
    shotsOnTargetHome: shotsOnTargetHome,
    shotsOnTargetAway: shotsOnTargetAway,
    savesHome: savesHome,
    savesAway: savesAway,
    homeTeam: homeTeam,
    awayTeam: awayTeam,
    tournament: tournament,
    events: events,
    lineups: lineups,
    formations: formations,
    serverLive: patch['is_live'],
    clock: patch['clock'],
    phase: patch['phase'],
    liveUpdatedAt: DateTime.tryParse(patch['live_updated_at'] ?? ''),
  );

  factory MatchModel.fromJson(Map<String, dynamic> json) => MatchModel(
    id: json['id'],
    dateTime: DateTime.parse(json['date_time']).toLocal(),
    status: json['status'],
    scoreHome: json['score_home'],
    scoreAway: json['score_away'],
    round: json['round'] ?? 1,
    possessionHome: json['possession_home'] ?? 50,
    possessionAway: json['possession_away'] ?? 50,
    shotsHome: json['shots_home'] ?? 0,
    shotsAway: json['shots_away'] ?? 0,
    cornersHome: json['corners_home'] ?? 0,
    cornersAway: json['corners_away'] ?? 0,
    foulsHome: json['fouls_home'] ?? 0,
    foulsAway: json['fouls_away'] ?? 0,
    yellowCardsHome: json['yellow_cards_home'] ?? 0,
    yellowCardsAway: json['yellow_cards_away'] ?? 0,
    redCardsHome: json['red_cards_home'] ?? 0,
    redCardsAway: json['red_cards_away'] ?? 0,
    offsidesHome: json['offsides_home'] ?? 0,
    offsidesAway: json['offsides_away'] ?? 0,
    passesHome: json['passes_home'] ?? 0,
    passesAway: json['passes_away'] ?? 0,
    passAccuracyHome: json['pass_accuracy_home'] ?? 0,
    passAccuracyAway: json['pass_accuracy_away'] ?? 0,
    xgHome: (json['xg_home'] ?? 0).toDouble(),
    xgAway: (json['xg_away'] ?? 0).toDouble(),
    shotsOnTargetHome: json['shots_on_target_home'] ?? 0,
    shotsOnTargetAway: json['shots_on_target_away'] ?? 0,
    savesHome: json['saves_home'] ?? 0,
    savesAway: json['saves_away'] ?? 0,
    homeTeam: Team.fromJson(json['home_team']),
    awayTeam: Team.fromJson(json['away_team']),
    tournament: Tournament.fromJson(json['tournament']),
    events: (json['events'] as List)
        .map((e) => MatchEvent.fromJson(e))
        .toList(),
    lineups: json['lineups'] != null
        ? (json['lineups'] as List)
              .map((e) => LineupPlayer.fromJson(e))
              .toList()
        : [],
    formations: Map<String, String>.from(json['formations'] ?? {}),
    serverLive: json['is_live'] as bool?,
    clock: json['clock'],
    phase: json['phase'],
    liveUpdatedAt: DateTime.tryParse(json['live_updated_at'] ?? ''),
  );
}

class LeaderboardEntry {
  final String username;
  final int points;
  LeaderboardEntry({required this.username, required this.points});
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        username: json['username'],
        points: json['total_points'],
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:futrat_mobile/core/profile_api.dart';
import 'package:futrat_mobile/models/all_models.dart';
import 'package:futrat_mobile/providers/data_provider.dart';
import 'package:futrat_mobile/screens/team_screen.dart';
import 'package:futrat_mobile/screens/player_screen.dart';
import 'package:futrat_mobile/widgets/lineup_view.dart';

Map<String, dynamic> game(int id, String home, {String status = 'FINISHED'}) =>
    {
      'id': id,
      'date_time': '2026-10-17T12:00:00Z',
      'status': status,
      'score_home': 1,
      'score_away': 0,
      'home_team': {'id': 1, 'name': home},
      'away_team': {'id': 2, 'name': 'Away'},
      'tournament': {'id': 1, 'name': 'League', 'type': 'League'},
      'events': [],
    };

class FakeProfiles extends ProfileApi {
  int get year => 2026;
  final List<int?> requestedSeasons = [];
  final bool calendar;
  FakeProfiles({this.calendar = false});

  @override
  Future<Map<String, dynamic>> team(
    int id, {
    int? season,
    int? cursor,
    String direction = 'past',
  }) async {
    requestedSeasons.add(season);
    return {
      'calendar_season': calendar,
      'team': {'id': 1, 'name': 'Club'},
      'season': year,
      'seasons': [year],
      'anchor': game(2, 'Latest'),
      'past': [game(1, 'Earlier')],
      'future': [game(3, 'Next', status: 'SCHEDULED')],
      'more_past': false,
      'more_future': false,
    };
  }

  @override
  Future<Map<String, dynamic>> player(int id) async => {
    'id': id,
    'name': 'Player One',
    'photo_url': null,
  };
  @override
  Future<Map<String, dynamic>> playerMatches(
    int id, {
    int? season,
    String kind = 'all',
    int offset = 0,
  }) async {
    requestedSeasons.add(season);
    return {
      'calendar_season': calendar,
      'season': year,
      'coverage': {'status': 'partial', 'checked': 1, 'candidates': 3},
      'more': false,
      'matches': [
        {
          'match': game(2, 'Latest'),
          'photo_url': null,
          'goals': null,
          'assists': 1,
          'minutes': null,
          'source_rating': 8.2,
          'rating_source': 'GOAL',
          'user_rating': 7.5,
          'rating_count': 2,
        },
      ],
    };
  }
}

Widget host(Widget child) => ChangeNotifierProvider<DataProvider>(
  create: (_) => DataProvider(),
  child: MaterialApp(home: child),
);

void main() {
  testWidgets('team timeline opens at last result with older matches above', (
    tester,
  ) async {
    await tester.pumpWidget(host(TeamScreen(teamId: 1, api: FakeProfiles())));
    await tester.pumpAndSettle();
    expect(find.text('Последняя сыгранная встреча'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Latest')).dy, greaterThan(0));
    expect(
      tester.getTopLeft(find.text('Next')).dy,
      greaterThan(tester.getTopLeft(find.text('Latest')).dy),
    );
    expect(find.text('Все турниры'), findsOneWidget);
  });
  testWidgets('player history distinguishes missing data from zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(PlayerScreen(playerId: 1, api: FakeProfiles())),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Голы: —'), findsOneWidget);
    expect(find.text('7.5 · 2 голосов'), findsOneWidget);
    expect(find.textContaining('Источник'), findsNothing);
    expect(find.textContaining('Futrat'), findsNothing);
    expect(find.textContaining('GOAL'), findsNothing);
    expect(find.textContaining('проверено 1 из 3'), findsOneWidget);
  });
  testWidgets('lineup preserves formation and displays only user ratings', (
    tester,
  ) async {
    final data = game(1, 'Home');
    data['formations'] = {'1': '4-2-3-1'};
    data['lineups'] = List.generate(
      11,
      (i) => {
        'id': i + 1,
        'player_id': i + 1,
        'team_id': 1,
        'player_name': 'Player $i',
        'jersey_number': '${i + 1}',
        'is_starter': true,
        'slot': i + 1,
        'appeared': true,
        'rating': '7.5',
        'source_rating': i == 0 ? 8.2 : null,
        'rating_source': i == 0 ? 'GOAL' : null,
      },
    );
    await tester.pumpWidget(
      host(
        Scaffold(
          body: LineupView(match: MatchModel.fromJson(data), onRate: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Схема 4-2-3-1'), findsOneWidget);
    expect(find.text('7.5'), findsNWidgets(11));
    expect(find.text('Источник'), findsNothing);
    expect(find.text('Futrat'), findsNothing);
    expect(find.text('8.2'), findsNothing);
    await tester.tap(find.text('Список'));
    await tester.pumpAndSettle();
    expect(find.text('7.5'), findsWidgets);
    expect(find.textContaining('GOAL'), findsNothing);
  });
  for (final calendar in [false, true]) {
    testWidgets(
      'profiles pin season 2026 and remove selectors, calendar=$calendar',
      (tester) async {
        final api = FakeProfiles(calendar: calendar);
        final label = calendar ? 'Сезон 2026' : 'Сезон 2026/27';
        await tester.pumpWidget(host(TeamScreen(teamId: 1, api: api)));
        await tester.pumpAndSettle();
        expect(api.requestedSeasons, [2026]);
        expect(find.text(label), findsOneWidget);
        expect(find.byType(DropdownButton<int>), findsNothing);
        await tester.pumpWidget(host(PlayerScreen(playerId: 1, api: api)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Сборная'));
        await tester.pumpAndSettle();
        expect(api.requestedSeasons, [2026, 2026, 2026]);
        expect(find.text(label), findsOneWidget);
        expect(find.byType(DropdownButton<int>), findsNothing);
      },
    );
  }
  testWidgets('missing slots fall back to list without invented formation', (
    tester,
  ) async {
    final data = game(1, 'Home');
    data['lineups'] = [
      {
        'id': 1,
        'team_id': 1,
        'player_name': 'Known Player',
        'is_starter': true,
      },
    ];
    await tester.pumpWidget(
      host(
        Scaffold(
          body: LineupView(match: MatchModel.fromJson(data), onRate: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Схема не опубликована'), findsOneWidget);
    expect(
      find.textContaining('не хватает подтверждённых позиций'),
      findsOneWidget,
    );
  });
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futrat_mobile/core/api_client.dart';
import 'package:futrat_mobile/models/all_models.dart';
import 'package:futrat_mobile/providers/data_provider.dart';
import 'package:futrat_mobile/screens/home_screen.dart';
import 'match_navigation_test.dart' show NavigationData, host;

Map<String, dynamic> liveGame({String? phase, String? clock = '47'}) => {
  'id': 1,
  'date_time': DateTime.now()
      .subtract(const Duration(minutes: 50))
      .toUtc()
      .toIso8601String(),
  'status': 'IN_PLAY',
  'score_home': 1,
  'score_away': 0,
  'home_team': {'id': 10, 'name': 'Home'},
  'away_team': {'id': 11, 'name': 'Away'},
  'tournament': {'id': 10, 'name': 'League 10', 'type': 'League'},
  'events': [],
  'clock': clock,
  'phase': phase ?? 'SECOND_HALF',
  'is_live': true,
  'live_updated_at': DateTime.now().toUtc().toIso8601String(),
};

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  for (final selection in [-1, -2, 10]) {
    testWidgets('live label and halftime in feed $selection', (tester) async {
      final data = NavigationData(selection: selection);
      data.games
        ..clear()
        ..add(MatchModel.fromJson(liveGame(clock: '90+3')));
      await tester.pumpWidget(host(const HomeScreen(), data));
      await tester.pumpAndSettle();
      if (selection == 10) {
        await tester.tap(find.text('Туры'));
        await tester.pumpAndSettle();
      }
      expect(find.text('90+3′ · LIVE'), findsOneWidget);
      data.games[0] = MatchModel.fromJson(liveGame(phase: 'HALF_TIME'));
      data.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('Перерыв'), findsOneWidget);
      expect(find.text('90+3′ · LIVE'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      data.dispose();
    });
  }

  testWidgets(
    'minute polling patches scores, keeps selection and pauses in background',
    (tester) async {
      final original = ApiClient().dio;
      final fake = Dio(BaseOptions(baseUrl: 'http://fixture.test'));
      var fullCalls = 0, liveCalls = 0;
      final base = liveGame();
      fake.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            dynamic body = [];
            if (options.path == '/api/tournaments') body = [base['tournament']];
            if (options.path == '/api/matches') {
              fullCalls++;
              body = [base];
            }
            if (options.path == '/api/matches/updates') {
              liveCalls++;
              body = [
                {...base, 'clock': '48', 'score_home': 2},
              ];
            }
            handler.resolve(
              Response(requestOptions: options, statusCode: 200, data: body),
            );
          },
        ),
      );
      ApiClient().dio = fake;
      final data = DataProvider();
      addTearDown(() {
        data.dispose();
        ApiClient().dio = original;
        fake.close(force: true);
      });
      await tester.runAsync(data.initData);
      data.setLiveUpdatesActive(false);
      data.setLiveUpdatesActive(true);
      await tester.pumpAndSettle();
      liveCalls = 0;
      data.selectLeague(data.tournaments.first);
      data.setSelectedRound(7);
      data.toggleLeagueCollapsed(-1, 10);
      await tester.pump(const Duration(seconds: 59));
      expect(liveCalls, 0);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(liveCalls, 1);
      expect(fullCalls, 1);
      expect(data.allMatches.first.scoreHome, 2);
      expect(data.allMatches.first.clock, '48');
      expect(data.selectedRound, 7);
      expect(data.isLeagueCollapsed(-1, 10), isTrue);
      data.setLiveUpdatesActive(false);
      await tester.pump(const Duration(minutes: 2));
      expect(liveCalls, 1);
      data.setLiveUpdatesActive(true);
      await tester.pumpAndSettle();
      expect(liveCalls, 2);
      data.setLiveUpdatesActive(false);
    },
  );

  test('stale clock is never advanced using kickoff time', () {
    final json = liveGame();
    json['live_updated_at'] = DateTime.now()
        .subtract(const Duration(minutes: 4))
        .toIso8601String();
    expect(MatchModel.fromJson(json).liveLabel, 'LIVE');
  });
}

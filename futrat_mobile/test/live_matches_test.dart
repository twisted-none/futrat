import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futrat_mobile/core/api_client.dart';
import 'package:futrat_mobile/models/all_models.dart';
import 'package:futrat_mobile/providers/data_provider.dart';
import 'package:futrat_mobile/screens/home_screen.dart';
import 'package:futrat_mobile/screens/match_detail_screen.dart';
import 'package:flutter/material.dart';
import 'match_navigation_test.dart' show NavigationData, host;

Map<String, dynamic> game(
  int id,
  String status,
  DateTime kickoff, {
  bool? serverLive,
}) => {
  'id': id,
  'date_time': kickoff.toIso8601String(),
  'status': status,
  'home_team': {'id': 1, 'name': 'Chertanovo'},
  'away_team': {'id': 2, 'name': 'Chita'},
  'tournament': {'id': 31, 'name': 'Russian Cup', 'type': 'Cup'},
  'events': [],
  if (serverLive != null) 'is_live': serverLive,
};

void main() {
  testWidgets('stale live fixture remains in history with unconfirmed status', (
    tester,
  ) async {
    final data = NavigationData(selection: 10);
    data.games[0] = MatchModel.fromJson(
      game(1, 'IN_PLAY', DateTime.utc(2026, 8, 12, 15)),
    );
    await tester.pumpWidget(host(const HomeScreen(), data));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Туры'));
    await tester.pumpAndSettle();
    expect(find.text('СТАТУС УТОЧНЯЕТСЯ'), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
    await tester.tap(find.text('Chertanovo'));
    await tester.pumpAndSettle();
    expect(find.byType(MatchDetailScreen), findsOneWidget);
    expect(find.text('СТАТУС УТОЧНЯЕТСЯ'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    data.dispose();
  });
  test(
    'live feed rejects old, future, suspended and unknown matches',
    () async {
      final now = DateTime.now().toUtc();
      final rows = [
        game(1, 'IN_PLAY', DateTime.utc(2026, 8, 12, 15)),
        game(2, 'IN_PLAY', now.subtract(const Duration(minutes: 60))),
        game(3, 'POSTPONED', now.subtract(const Duration(minutes: 20))),
        game(4, 'SUSPENDED', now.subtract(const Duration(minutes: 20))),
        game(5, 'UNKNOWN', now.subtract(const Duration(minutes: 20))),
        game(6, 'IN_PLAY', now.add(const Duration(minutes: 20))),
        game(
          7,
          'IN_PLAY',
          now.subtract(const Duration(minutes: 60)),
          serverLive: false,
        ),
      ];
      final original = ApiClient().dio;
      final fake = Dio(BaseOptions(baseUrl: 'http://fixture.test'));
      fake.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(requestOptions: options, statusCode: 200, data: rows),
            );
          },
        ),
      );
      ApiClient().dio = fake;
      final provider = DataProvider();
      addTearDown(() {
        provider.dispose();
        ApiClient().dio = original;
        fake.close(force: true);
      });
      provider.selectLeague(provider.liveVirtual);
      await provider.fetchMatches();
      expect(provider.matches.map((m) => m.id), [2]);
      expect(provider.allMatches.length, rows.length);
    },
  );

  test(
    'live classification supports clocks, midnight and six-hour boundary',
    () {
      final now = DateTime.utc(2026, 10, 18, 0, 20);
      MatchModel model(String status, Duration ago) =>
          MatchModel.fromJson(game(1, status, now.subtract(ago)));
      expect(
        model("90'+3'", const Duration(minutes: 100)).isLiveAt(now),
        isTrue,
      );
      expect(
        model('HALF_TIME', const Duration(minutes: 50)).isLiveAt(now),
        isTrue,
      );
      expect(model('IN_PLAY', const Duration(hours: 6)).isLiveAt(now), isTrue);
      expect(
        model('IN_PLAY', const Duration(hours: 6, seconds: 1)).isLiveAt(now),
        isFalse,
      );
      expect(
        model('IN_PLAY', const Duration(minutes: -1)).isLiveAt(now),
        isFalse,
      );
      expect(
        model('45+2\'', const Duration(minutes: 47)).isLiveAt(now),
        isTrue,
      );
      expect(
        model('ABANDONED', const Duration(minutes: 20)).isLiveAt(now),
        isFalse,
      );
    },
  );
}

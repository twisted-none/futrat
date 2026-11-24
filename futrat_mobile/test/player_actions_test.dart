import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:futrat_mobile/core/api_client.dart';
import 'package:futrat_mobile/models/all_models.dart';
import 'package:futrat_mobile/providers/auth_provider.dart';
import 'package:futrat_mobile/providers/data_provider.dart';
import 'package:futrat_mobile/providers/theme_provider.dart';
import 'package:futrat_mobile/screens/match_detail_screen.dart';
import 'package:futrat_mobile/screens/player_screen.dart';
import 'package:futrat_mobile/widgets/lineup_view.dart';

MatchModel game({
  String status = 'FINISHED',
  bool appeared = true,
  bool profile = true,
}) => MatchModel.fromJson({
  'id': 1,
  'date_time': '2026-10-26T12:00:00Z',
  'status': status,
  'home_team': {'id': 1, 'name': 'Home'},
  'away_team': {'id': 2, 'name': 'Away'},
  'tournament': {'id': 1, 'name': 'League', 'type': 'League'},
  'events': [],
  'formations': {'1': '4-4-2'},
  'lineups': List.generate(
    11,
    (i) => {
      'id': i + 1,
      'player_id': profile ? i + 101 : null,
      'team_id': 1,
      'player_name': 'Player ${i + 1}',
      'jersey_number': '${i + 1}',
      'is_starter': true,
      'slot': i + 1,
      'position': const [
        'Goalkeeper',
        'Left Back',
        'Center Left Defender',
        'Center Right Defender',
        'Right Back',
        'Left Midfielder',
        'Left Center Midfielder',
        'Right Center Midfielder',
        'Right Midfielder',
        'Left Forward',
        'Right Forward',
      ][i],
      'appeared': appeared,
      'rating': '-',
    },
  ),
});

class RatingData extends DataProvider {
  RatingData(this.match);
  final MatchModel match;
  final ratings = <(int, double)>[];
  @override
  Future<MatchModel?> getMatchDetails(int id) async => match;
  @override
  Future<bool> ratePlayer(int id, double value) async {
    ratings.add((id, value));
    return true;
  }
}

class RatingAuth extends AuthProvider {
  RatingAuth(this.signedIn);
  final bool signedIn;
  @override
  bool get isAuthenticated => signedIn;
}

void main() {
  late Dio original;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    original = ApiClient().dio;
    ApiClient().dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          ),
        ),
      );
  });
  tearDown(() {
    ApiClient().dio.close(force: true);
    ApiClient().dio = original;
  });

  Future<void> host(
    WidgetTester tester,
    Widget child, {
    RatingData? data,
    bool signedIn = false,
  }) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DataProvider>(
            create: (_) => data ?? RatingData(game()),
          ),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => RatingAuth(signedIn),
          ),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final field in [true, false]) {
    testWidgets('player tap offers statistics and rating, field=$field', (
      tester,
    ) async {
      final rated = <int>[];
      await host(
        tester,
        LineupView(match: game(), onRate: (p) => rated.add(p.id)),
      );
      if (!field) {
        await tester.tap(find.text('Список'));
        await tester.pumpAndSettle();
      }
      expect(
        find.byKey(const ValueKey('lineup-pitch')),
        field ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.text('1 Player 1'));
      await tester.pumpAndSettle();
      expect(find.text('Открыть статистику'), findsOneWidget);
      expect(find.text('Оценить за матч'), findsOneWidget);
      expect(find.byType(PlayerScreen), findsNothing);
      expect(rated, isEmpty);
      await tester.tap(find.text('Оценить за матч'));
      await tester.pumpAndSettle();
      expect(rated, [1]);
      expect(find.text('Открыть статистику'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('statistics choice opens the selected player without rating', (
    tester,
  ) async {
    var rated = false;
    await host(tester, LineupView(match: game(), onRate: (_) => rated = true));
    await tester.tap(find.text('1 Player 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Открыть статистику'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PlayerScreen>(find.byType(PlayerScreen)).playerId,
      101,
    );
    expect(rated, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  for (final playing in [true, false]) {
    testWidgets('unavailable rating explains why, playing=$playing', (
      tester,
    ) async {
      var rated = false;
      await host(
        tester,
        LineupView(
          match: game(
            status: playing ? 'IN_PLAY' : 'FINISHED',
            appeared: playing,
          ),
          onRate: (_) => rated = true,
        ),
      );
      await tester.tap(find.text('1 Player 1'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          playing
              ? 'Оценки доступны после завершения матча'
              : 'Оценивать можно только участвовавших игроков',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Оценить за матч'));
      await tester.pumpAndSettle();
      expect(rated, isFalse);
      expect(find.text('Открыть статистику'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('missing profile still allows a lineup rating', (tester) async {
    final rated = <int>[];
    await host(
      tester,
      LineupView(match: game(profile: false), onRate: (p) => rated.add(p.id)),
    );
    await tester.tap(find.text('1 Player 1'));
    await tester.pumpAndSettle();
    expect(find.text('Профиль игрока пока недоступен'), findsOneWidget);
    await tester.tap(find.text('Оценить за матч'));
    await tester.pumpAndSettle();
    expect(rated, [1]);
    await tester.pumpWidget(const SizedBox());
  });

  for (final signedIn in [true, false]) {
    testWidgets('match rating respects authentication, signedIn=$signedIn', (
      tester,
    ) async {
      final match = game();
      final data = RatingData(match);
      await host(
        tester,
        MatchDetailScreen(match: match),
        data: data,
        signedIn: signedIn,
      );
      await tester.tap(find.text('Составы'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('1 Player 1'));
      await tester.tap(find.text('1 Player 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Оценить за матч'));
      await tester.pumpAndSettle();
      expect(find.text('Оцените игрока'), findsOneWidget);
      await tester.tap(find.text('8').last);
      await tester.pumpAndSettle();
      if (signedIn) {
        expect(data.ratings, [(1, 8.0)]);
        expect(find.text('Оценка принята!'), findsOneWidget);
      } else {
        expect(find.text('Нужен аккаунт'), findsOneWidget);
        expect(data.ratings, isEmpty);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}

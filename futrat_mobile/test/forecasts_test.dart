import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:futrat_mobile/core/forecast_api.dart';
import 'package:futrat_mobile/models/all_models.dart';
import 'package:futrat_mobile/providers/auth_provider.dart';
import 'package:futrat_mobile/providers/data_provider.dart';
import 'package:futrat_mobile/screens/forecasts_screen.dart';

class ForecastAuth extends AuthProvider {
  final bool signedIn;
  ForecastAuth(this.signedIn);
  @override
  bool get isAuthenticated => signedIn;
}

class ForecastData extends DataProvider {
  ForecastData({this.games});
  final List<MatchModel>? games;
  final MatchModel game = MatchModel.fromJson({
    'id': 1,
    'date_time': DateTime.now()
        .toUtc()
        .add(const Duration(seconds: 30))
        .toIso8601String(),
    'status': 'SCHEDULED',
    'home_team': {'id': 1, 'name': 'Home'},
    'away_team': {'id': 2, 'name': 'Away'},
    'tournament': {'id': 1, 'name': 'League', 'type': 'League'},
    'events': [],
  });
  @override
  List<MatchModel> get allMatches => games ?? [game];
}

class FakeForecastApi extends ForecastApi {
  int count = 0;
  String? outcome;
  final List<Map<String, dynamic>> rows = [];
  Completer<void>? saving;
  final List<String?> rankingMonths = [];
  @override
  Future<List<Map<String, dynamic>>> mine({
    String? day,
    int offset = 0,
  }) async => List.of(rows);
  @override
  Future<int> used(String day) async => count;
  @override
  Future<void> choose(int matchId, String value) async {
    outcome = value;
    await saving?.future;
    rows.removeWhere((row) => row['match_id'] == matchId);
    rows.add({'match_id': matchId, 'outcome': value, 'status': 'OPEN'});
    count = rows.length;
  }

  @override
  Future<void> cancel(int matchId) async {
    await saving?.future;
    rows.removeWhere((row) => row['match_id'] == matchId);
    count = rows.length;
  }

  @override
  Future<Map<String, dynamic>> rankings({String? month, int offset = 0}) async {
    rankingMonths.add(month);
    return {'rows': [], 'total': 0};
  }

  @override
  Future<Map<String, dynamic>?> myRank({String? month}) async => null;
}

Widget screen(
  ForecastApi api,
  bool signedIn, {
  List<MatchModel>? games,
  DateTime Function()? now,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>(create: (_) => ForecastAuth(signedIn)),
    ChangeNotifierProvider<DataProvider>(
      create: (_) => ForecastData(games: games),
    ),
  ],
  child: MaterialApp(
    home: ForecastsScreen(api: api, now: now),
  ),
);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test('Moscow day switches at 21 UTC', () {
    expect(moscowDay(DateTime.utc(2026, 10, 17, 20, 59)), '2026-10-17');
    expect(moscowDay(DateTime.utc(2026, 10, 17, 21)), '2026-10-18');
  });
  testWidgets('signed in user chooses an outcome and sees day quota', (
    tester,
  ) async {
    final api = FakeForecastApi();
    await tester.pumpWidget(screen(api, true));
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpAndSettle();
    expect(find.text('Выбрано 0 из 10'), findsOneWidget);
    await tester.tap(find.text('П1'));
    await tester.pumpAndSettle();
    expect(api.outcome, 'HOME');
    expect(find.text('Выбрано 1 из 10'), findsOneWidget);
  });
  testWidgets('guest can view rankings and needs auth only when choosing', (
    tester,
  ) async {
    final api = FakeForecastApi();
    await tester.pumpWidget(screen(api, false));
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('П1'));
    await tester.pumpAndSettle();
    expect(find.text('Нужен аккаунт'), findsOneWidget);
    expect(api.outcome, isNull);
    await tester.tap(find.text('Позже'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Рейтинг'));
    await tester.pumpAndSettle();
    expect(
      find.text('В этом периоде ещё нет рассчитанных прогнозов'),
      findsOneWidget,
    );
  });

  testWidgets('choosing, changing and cancelling retain scroll while saving', (
    tester,
  ) async {
    final api = FakeForecastApi();
    final now = DateTime.utc(2026, 10, 22, 10);
    final games = List.generate(
      20,
      (i) => MatchModel.fromJson({
        'id': i + 1,
        'date_time': now.add(Duration(hours: 1, minutes: i)).toIso8601String(),
        'status': 'SCHEDULED',
        'home_team': {'id': i * 2, 'name': 'Home $i'},
        'away_team': {'id': i * 2 + 1, 'name': 'Away $i'},
        'tournament': {'id': 1, 'name': 'League', 'type': 'League'},
        'events': [],
      }),
    );
    await tester.pumpWidget(screen(api, true, games: games, now: () => now));
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1050));
    await tester.pumpAndSettle();
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable).last)
        .position;
    final before = scroll.pixels;
    expect(before, greaterThan(500));
    final button = find.byType(SegmentedButton<String>).hitTestable().first;
    api.saving = Completer<void>();
    await tester.tap(find.descendant(of: button, matching: find.text('П1')));
    await tester.pump();
    expect(scroll.pixels, before);
    expect(find.byType(ListView), findsOneWidget);
    api.saving!.complete();
    await tester.pumpAndSettle();
    expect(scroll.pixels, before);
    expect(find.text('Выбрано 1 из 10'), findsOneWidget);
    await tester.tap(find.descendant(of: button, matching: find.text('Х')));
    await tester.pumpAndSettle();
    expect(scroll.pixels, before);
    expect(find.text('Выбрано 1 из 10'), findsOneWidget);
    await tester.tap(find.text('Отменить прогноз').hitTestable().first);
    await tester.pumpAndSettle();
    expect(scroll.pixels, before);
    expect(find.text('Выбрано 0 из 10'), findsOneWidget);
  });

  testWidgets('rating starts October 2026 and rolls over at midnight Moscow', (
    tester,
  ) async {
    final api = FakeForecastApi();
    var now = DateTime.utc(2026, 10, 31, 20, 59, 59);
    await tester.pumpWidget(screen(api, false, now: () => now));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Рейтинг'));
    await tester.pumpAndSettle();
    expect(api.rankingMonths.last, '2026-10');
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('09.2026'), findsNothing);
    expect(find.text('За всё время'), findsWidgets);
    await tester.tap(find.text('За всё время').last);
    await tester.pumpAndSettle();
    expect(api.rankingMonths.last, isNull);
    now = DateTime.utc(2026, 10, 31, 21);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(api.rankingMonths.last, '2026-11');
    expect(find.text('11.2026'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('10.2026'), findsWidgets);
    expect(find.text('09.2026'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'resume detects a new month and preserves manual period within the same month',
    (tester) async {
      final api = FakeForecastApi();
      var now = DateTime.utc(2026, 10, 31, 20, 59);
      await tester.pumpWidget(screen(api, false, now: () => now));
      addTearDown(() => tester.pumpWidget(const SizedBox()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Рейтинг'));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now = DateTime.utc(2026, 11, 1, 10);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(api.rankingMonths.last, '2026-11');
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10.2026').last);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(api.rankingMonths.last, '2026-10');
    },
  );
}

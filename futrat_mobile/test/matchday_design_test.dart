import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futrat_mobile/core/api_client.dart';
import 'package:futrat_mobile/core/app_theme.dart';
import 'package:futrat_mobile/models/all_models.dart';
import 'package:futrat_mobile/providers/data_provider.dart';
import 'package:futrat_mobile/screens/home_screen.dart';
import 'package:futrat_mobile/screens/forecasts_screen.dart';
import 'package:futrat_mobile/screens/match_detail_screen.dart';
import 'package:futrat_mobile/widgets/lineup_view.dart';
import 'package:futrat_mobile/widgets/app_states.dart';
import 'package:futrat_mobile/widgets/standings_table.dart';
import 'match_navigation_test.dart' show NavigationData, host, fixture;
import 'forecasts_test.dart' show FakeForecastApi;
import 'player_actions_test.dart' as actions;

class PendingDetails extends NavigationData {
  Completer<MatchModel?> pending = Completer<MatchModel?>();
  @override
  Future<MatchModel?> getMatchDetails(int id) => pending.future;
}

class LoadingData extends NavigationData {
  bool loading = true;
  String? error;
  @override
  bool get isLoading => loading;
  @override
  String? get loadError => error;
  @override
  get allMatches => games;
  @override
  Future<void> retryPublicData() async {
    loading = false;
    error = null;
    games.add(fixture(5, 10, 'Restored Club', 12));
    notifyListeners();
  }
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('match details show skeleton then retryable error and recover', (
    tester,
  ) async {
    final data = PendingDetails();
    final game = fixture(1, 10, 'Home', 12);
    await tester.pumpWidget(host(MatchDetailScreen(match: game), data));
    await tester.pumpAndSettle();
    expect(find.byType(AppSkeleton), findsOneWidget);
    data.pending.complete(null);
    await tester.pumpAndSettle();
    expect(
      find.text('Не удалось обновить состав и статистику'),
      findsOneWidget,
    );
    expect(find.byType(AppSkeleton), findsNothing);
    data.pending = Completer<MatchModel?>();
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.byType(AppSkeleton), findsOneWidget);
    data.pending.complete(actions.game());
    await tester.pumpAndSettle();
    expect(find.byType(LineupView), findsOneWidget);
    expect(find.byType(AppSkeleton), findsNothing);
    await tester.pumpWidget(const SizedBox());
    data.dispose();
  });

  testWidgets(
    'already loaded lineup remains visible during an offline refresh',
    (tester) async {
      final data = PendingDetails();
      await tester.pumpWidget(
        host(MatchDetailScreen(match: actions.game()), data),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LineupView), findsOneWidget);
      expect(find.byType(AppSkeleton), findsNothing);
      data.pending.complete(null);
      await tester.pumpAndSettle();
      expect(find.byType(LineupView), findsOneWidget);
      expect(find.byType(UpdateNotice), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      data.dispose();
    },
  );

  testWidgets(
    'first load has a skeleton, failed load has retry, saved games stay visible',
    (tester) async {
      final data = LoadingData()..games.clear();
      await tester.pumpWidget(host(const HomeScreen(), data));
      await tester.pumpAndSettle();
      expect(find.byType(AppSkeleton), findsOneWidget);
      expect(find.text('Нет матчей'), findsNothing);
      data.loading = false;
      data.error = 'Проверьте подключение';
      data.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byType(AppSkeleton), findsNothing);
      expect(find.text('Не удалось загрузить матчи'), findsOneWidget);
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      expect(find.text('Restored Club'), findsOneWidget);
      data.loading = true;
      data.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byType(AppSkeleton), findsNothing);
      expect(find.text('Restored Club'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      data.dispose();
    },
  );

  testWidgets('standings keep the club pinned while numerical columns scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = NavigationData(selection: 10);
    await tester.pumpWidget(host(const HomeScreen(), data));
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.text('Table Club 1'));
    expect(tester.getSize(find.byType(StandingsTable)).width, greaterThan(0));
    final horizontal = find.descendant(
      of: find.byType(StandingsTable),
      matching: find.byType(SingleChildScrollView),
    );
    await tester.dragFrom(
      tester.getTopLeft(horizontal) + const Offset(24, 24),
      const Offset(-180, 0),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Table Club 1')), before);
    final scroller = tester.state<ScrollableState>(
      find.descendant(of: horizontal, matching: find.byType(Scrollable)).first,
    );
    expect(scroller.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    data.dispose();
  });

  for (final mode in AppThemeType.values) {
    testWidgets(
      'forecast controls remain usable at 320 wide with 200 percent text, $mode',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final data = NavigationData();
        await tester.pumpWidget(
          host(
            ForecastsScreen(api: FakeForecastApi()),
            data,
            scale: 2,
            mode: mode,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Мои прогнозы'), findsOneWidget);
        await tester.ensureVisible(find.text('Рейтинг'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Рейтинг'));
        await tester.pumpAndSettle();
        expect(
          find.text('В этом периоде ещё нет рассчитанных прогнозов'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        data.dispose();
      },
    );
  }

  test(
    'late standings response cannot replace a newer selected tournament',
    () async {
      final pending = <int, Completer<void>>{
        1: Completer<void>(),
        2: Completer<void>(),
      };
      final dio = Dio(BaseOptions(baseUrl: 'https://fixture.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            final id = int.parse(request.path.split('/')[3]);
            await pending[id]!.future;
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: [
                  {
                    'rank': 1,
                    'team': {'id': id, 'name': 'Club $id'},
                    'played': 1,
                    'won': 1,
                    'draw': 0,
                    'lost': 0,
                    'goals_for': 1,
                    'goals_against': 0,
                    'points': 3,
                  },
                ],
              ),
            );
          },
        ),
      );
      final data = DataProvider(client: ApiClient.configured(dio: dio));
      final first = data.fetchStandings(1), second = data.fetchStandings(2);
      pending[2]!.complete();
      await second;
      pending[1]!.complete();
      await first;
      expect(data.currentStandings.single.team.id, 2);
      expect(data.standingsLoading, isFalse);
      data.dispose();
      dio.close(force: true);
    },
  );
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:futrat_mobile/core/api_client.dart';
import 'package:futrat_mobile/core/app_theme.dart';
import 'package:futrat_mobile/models/all_models.dart';
import 'package:futrat_mobile/providers/auth_provider.dart';
import 'package:futrat_mobile/providers/data_provider.dart';
import 'package:futrat_mobile/providers/theme_provider.dart';
import 'package:futrat_mobile/screens/home_screen.dart';
import 'package:futrat_mobile/screens/match_detail_screen.dart';
import 'package:futrat_mobile/screens/team_screen.dart';
import 'package:futrat_mobile/widgets/grouped_matches_list.dart';
import 'package:futrat_mobile/widgets/round_selector.dart';
import 'package:futrat_mobile/widgets/team_link.dart';
import 'package:futrat_mobile/widgets/football_logo.dart';

MatchModel fixture(int id, int league, String team, int hour) =>
    MatchModel.fromJson({
      'id': id,
      'date_time': '2026-10-18T${hour.toString().padLeft(2, '0')}:00:00Z',
      'status': 'FINISHED',
      'score_home': 2,
      'score_away': 1,
      'home_team': {'id': id * 10, 'name': team},
      'away_team': {'id': id * 10 + 1, 'name': 'Away $id'},
      'tournament': {'id': league, 'name': 'League $league', 'type': 'League'},
      'events': [],
    });

class NavigationData extends DataProvider {
  NavigationData({this.selection = -1, this.national = false});
  final int selection;
  final bool national;
  final games = [
    fixture(1, 10, 'Late Club', 18),
    fixture(2, 10, 'Early Club', 12),
    fixture(3, 20, 'Favorite Club', 14),
  ];
  @override
  Future<void> initData() async {}
  @override
  Future<MatchModel?> getMatchDetails(int id) async =>
      games.firstWhere((m) => m.id == id);
  @override
  List<MatchModel> get matches => games;
  @override
  Tournament get selectedLeague => Tournament(
    id: selection,
    name: selection < 0 ? 'Today' : 'АПЛ (ENG-1)',
    type: 'League',
    apiCode: national ? 'uefa.nations' : null,
  );
  @override
  List<Tournament> get tournaments => [
    for (final id in [10, 20])
      Tournament(id: id, name: 'League $id', type: 'League'),
  ];
  @override
  List<Tournament> get favoriteTournaments => [tournaments.last];
  @override
  bool isLeagueFavorite(int id) => id == 20;
  @override
  List<StandingRow> get currentStandings => List.generate(
    20,
    (i) => StandingRow(
      rank: i + 1,
      team: Team(id: i + 1, name: 'Table Club ${i + 1}'),
      played: 5,
      won: 3,
      draw: 1,
      lost: 1,
      goalsFor: 9,
      goalsAgainst: 3,
      points: 10,
      form: [],
      groupName: national ? 'Группа A' : null,
    ),
  );
}

Widget host(
  Widget child,
  NavigationData data, {
  double scale = 1,
  AppThemeType mode = AppThemeType.dark,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
    ChangeNotifierProvider<DataProvider>.value(value: data),
    ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider()..setTheme(mode),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.getTheme(mode).themeData,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: child,
  ),
);

void main() {
  late Dio original;
  late Dio fake;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    original = ApiClient().dio;
    fake = Dio(BaseOptions(baseUrl: 'http://fixture.test'));
    fake.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final id = int.tryParse(options.path.split('/')[3]) ?? 1;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'team': {'id': id, 'name': 'Loaded Club $id'},
                'season': 2026,
                'seasons': [2026],
                'anchor': null,
                'past': [],
                'future': [],
                'more_past': false,
                'more_future': false,
              },
            ),
          );
        },
      ),
    );
    ApiClient().dio = fake;
  });
  tearDown(() {
    ApiClient().dio = original;
    fake.close(force: true);
  });

  for (final mode in AppThemeType.values) {
    testWidgets('match team blocks fit narrow screen with large text, $mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = NavigationData();
      data.games[0] = fixture(1, 10, 'Манчестер Юнайтед', 18);
      await tester.pumpWidget(
        host(
          MatchDetailScreen(match: data.games[0]),
          data,
          scale: 1.6,
          mode: mode,
        ),
      );
      await tester.pumpAndSettle();
      for (final id in [10, 11]) {
        final block = find.byKey(ValueKey('match-team-block-$id'));
        expect(block, findsOneWidget);
        final decoration =
            tester.widget<Container>(block).decoration! as BoxDecoration;
        expect((decoration.border! as Border).top.width, 1);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      data.dispose();
    });
  }

  test(
    'league groups prioritize favorites, sort times and retain every game',
    () {
      final data = NavigationData();
      final before = data.games.map((m) => m.id).toList();
      final groups = groupMatchesByLeague(data.games, data.tournaments, {20});
      expect(groups.map((g) => g.tournament.id), [20, 10]);
      expect(groups.last.matches.map((m) => m.id), [2, 1]);
      expect(groups.expand((g) => g.matches).length, 3);
      expect(data.games.map((m) => m.id), before);
      expect(groupMatchesByLeague([], [], {}), isEmpty);
      data.dispose();
    },
  );

  for (final selection in [-1, -2]) {
    testWidgets(
      'virtual feed $selection displays matches inside league groups',
      (tester) async {
        final data = NavigationData(selection: selection);
        await tester.pumpWidget(host(const HomeScreen(), data));
        await tester.pumpAndSettle();
        expect(find.byType(GroupedMatchesList), findsOneWidget);
        expect(find.text('League 20'), findsOneWidget);
        expect(find.text('League 10'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('League 20')).dy,
          lessThan(tester.getTopLeft(find.text('League 10')).dy),
        );
        expect(
          tester.getTopLeft(find.text('Early Club')).dy,
          lessThan(tester.getTopLeft(find.text('Late Club')).dy),
        );
        await tester.tap(find.byKey(const ValueKey('toggle-league-20')));
        await tester.pumpAndSettle();
        expect(find.text('Favorite Club'), findsNothing);
        expect(find.text('League 20'), findsOneWidget);
        expect(find.text('Early Club'), findsOneWidget);
        data.notifyListeners();
        await tester.pumpAndSettle();
        expect(find.text('Favorite Club'), findsNothing);
        expect(data.isLeagueCollapsed(selection == -1 ? -2 : -1, 20), isFalse);
        await tester.tap(find.byKey(const ValueKey('toggle-league-20')));
        await tester.pumpAndSettle();
        expect(find.text('Favorite Club'), findsOneWidget);
        await tester.tap(find.text('Favorite Club'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<MatchDetailScreen>(find.byType(MatchDetailScreen))
              .match
              .id,
          3,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        data.dispose();
      },
    );
  }

  testWidgets(
    'three league tabs have equal widths and wrap on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = NavigationData(selection: 10);
      await tester.pumpWidget(host(const HomeScreen(), data, scale: 1.6));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        expect(
          tester.getSize(find.byKey(ValueKey('league-tab-$i'))).width,
          closeTo(320 / 3, .1),
        );
      }
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Туры'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('choose-round')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('round-choice-2')));
      await tester.pumpAndSettle();
      expect(data.selectedRound, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      data.dispose();
    },
  );

  testWidgets('league match card name and badge open the match', (
    tester,
  ) async {
    final data = NavigationData(selection: 10);
    await tester.pumpWidget(host(const HomeScreen(), data));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Туры'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Late Club'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MatchDetailScreen>(find.byType(MatchDetailScreen)).match.id,
      1,
    );
    Navigator.of(tester.element(find.byType(MatchDetailScreen))).pop();
    await tester.pumpAndSettle();
    final card = find
        .ancestor(
          of: find.text('Late Club'),
          matching: find.byType(GestureDetector),
        )
        .first;
    await tester.tap(
      find.descendant(of: card, matching: find.byType(FootballLogo)).first,
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<MatchDetailScreen>(find.byType(MatchDetailScreen)).match.id,
      1,
    );
    await tester.pumpWidget(const SizedBox());
    data.dispose();
  });

  testWidgets(
    'round sheet opens at current round and stepper respects boundaries',
    (tester) async {
      var selected = 38;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getTheme(AppThemeType.light).themeData,
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: RoundSelector(
                current: selected,
                total: 38,
                onChanged: (v) => setState(() => selected = v),
              ),
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<IconButton>(
              find
                  .ancestor(
                    of: find.byTooltip('Следующий тур'),
                    matching: find.byType(IconButton),
                  )
                  .first,
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('choose-round')));
      await tester.pumpAndSettle();
      expect(find.text('Выберите тур'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('round-choice-38')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('round-choice-37')));
      await tester.pumpAndSettle();
      expect(selected, 37);
      await tester.tap(find.byTooltip('Следующий тур'));
      await tester.pumpAndSettle();
      expect(selected, 38);
      expect(tester.takeException(), isNull);
    },
  );

  for (final national in [false, true]) {
    testWidgets('table team opens profile, national=$national', (tester) async {
      final data = NavigationData(selection: 10, national: national);
      await tester.pumpWidget(host(const HomeScreen(), data));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Table Club 1'));
      await tester.pumpAndSettle();
      expect(find.byType(TeamScreen), findsOneWidget);
      expect(tester.widget<TeamScreen>(find.byType(TeamScreen)).teamId, 1);
      expect(find.text('Нужен аккаунт'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      data.dispose();
    });
  }

  testWidgets('grouped team and star have separate actions', (tester) async {
    final data = NavigationData();
    await tester.pumpWidget(host(const HomeScreen(), data));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('favorite-team-3-30')));
    await tester.pumpAndSettle();
    expect(find.text('Нужен аккаунт'), findsOneWidget);
    expect(find.byType(TeamScreen), findsNothing);
    await tester.tap(find.text('Позже'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorite Club'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MatchDetailScreen>(find.byType(MatchDetailScreen)).match.id,
      3,
    );
    await tester.pumpWidget(const SizedBox());
    data.dispose();
  });

  testWidgets(
    'match header team opens profile while score opens match from feed',
    (tester) async {
      final data = NavigationData();
      await tester.pumpWidget(host(const HomeScreen(), data));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('match-score-3')));
      await tester.pumpAndSettle();
      expect(find.byType(MatchDetailScreen), findsOneWidget);
      final block = tester.widget<Container>(
        find.byKey(const ValueKey('match-team-block-30')),
      );
      expect((block.decoration! as BoxDecoration).border, isNotNull);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('match-team-block-30')),
          matching: find.text('Favorite Club'),
        ),
        findsOneWidget,
      );
      final header = find
          .descendant(
            of: find.byType(MatchDetailScreen),
            matching: find.byType(TeamLink),
          )
          .first;
      await tester.tap(header);
      await tester.pumpAndSettle();
      expect(tester.widget<TeamScreen>(find.byType(TeamScreen)).teamId, 30);
      await tester.pumpWidget(const SizedBox());
      data.dispose();
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:futrat_mobile/core/auth_gate.dart';
import 'package:futrat_mobile/core/app_theme.dart';
import 'package:futrat_mobile/main.dart';
import 'package:futrat_mobile/providers/auth_provider.dart';
import 'package:futrat_mobile/providers/data_provider.dart';
import 'package:futrat_mobile/providers/theme_provider.dart';
import 'package:futrat_mobile/models/all_models.dart';
import 'package:futrat_mobile/screens/home_screen.dart';
import 'package:futrat_mobile/screens/profile_screen.dart';

class FakeDataProvider extends DataProvider {
  @override
  Future<void> initData() async {}

  @override
  Future<void> fetchFavorites() async {}
}

class FakeAuthProvider extends AuthProvider {
  bool signedIn = false;

  @override
  bool get isAuthenticated => signedIn;

  @override
  Future<void> register(String username, String password) async {
    signedIn = true;
    notifyListeners();
  }
}

class TournamentDataProvider extends FakeDataProvider {
  TournamentDataProvider(this.league);
  final Tournament league;
  @override
  Tournament get selectedLeague => league;
}

class AppearanceDataProvider extends FakeDataProvider {
  @override
  Tournament get selectedLeague =>
      Tournament(id: 1, name: 'АПЛ (ENG-1)', type: 'League');
  @override
  List<StandingRow> get currentStandings => List.generate(
    20,
    (i) => StandingRow(
      rank: i + 1,
      team: Team(id: i + 1, name: 'Команда ${i + 1}'),
      played: 8,
      won: 4,
      draw: 2,
      lost: 2,
      goalsFor: 12,
      goalsAgainst: 8,
      points: 14,
      form: ['W', 'D', 'L'],
    ),
  );
  @override
  List<MatchModel> get matches => [
    MatchModel.fromJson({
      'id': 1,
      'date_time': '2026-10-17T12:00:00Z',
      'status': 'FINISHED',
      'score_home': 2,
      'score_away': 1,
      'events': [],
      'home_team': {'id': 1, 'name': 'Арсенал'},
      'away_team': {'id': 2, 'name': 'Челси'},
      'tournament': {'id': 1, 'name': 'АПЛ', 'type': 'League'},
    }),
  ];
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets(
    'populated standings and match cards fit both themes on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final mode in AppThemeType.values) {
        final appearance = ThemeProvider();
        await appearance.ready;
        await appearance.setTheme(mode);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeProvider>.value(value: appearance),
              ChangeNotifierProvider<AuthProvider>(
                create: (_) => FakeAuthProvider(),
              ),
              ChangeNotifierProvider<DataProvider>(
                create: (_) => AppearanceDataProvider(),
              ),
            ],
            child: MaterialApp(
              theme: appearance.currentTheme.themeData,
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Команда 20'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Туры'));
        await tester.pumpAndSettle();
        expect(find.text('Арсенал'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        appearance.dispose();
      }
    },
  );

  testWidgets(
    'appearance picker stays usable on narrow screens with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final appearance = ThemeProvider();
      await appearance.ready;
      await appearance.setTheme(AppThemeType.light);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: appearance),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => FakeAuthProvider(),
            ),
            ChangeNotifierProvider<DataProvider>(
              create: (_) => FakeDataProvider(),
            ),
          ],
          child: Consumer<ThemeProvider>(
            builder: (_, p, _) => MaterialApp(
              theme: p.currentTheme.themeData,
              builder: (_, child) => MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 640),
                  textScaler: TextScaler.linear(1.8),
                ),
                child: child!,
              ),
              home: const ProfileScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Акцентный цвет'));
      final centers = [
        for (final accent in AppAccent.values)
          tester.getCenter(find.byKey(ValueKey('accent-${accent.name}'))),
      ];
      expect(centers.map((point) => point.dy).toSet(), hasLength(1));
      expect(centers.every((point) => point.dx > 0 && point.dx < 320), isTrue);
      await tester.tap(find.byKey(const ValueKey('accent-pink')));
      await tester.pumpAndSettle();
      expect(appearance.currentAccent, AppAccent.pink);
      expect(appearance.currentType, AppThemeType.light);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
    },
  );

  testWidgets('Euro placeholder shows no invented groups or sign in gate', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => FakeAuthProvider(),
          ),
          ChangeNotifierProvider<DataProvider>(
            create: (_) => TournamentDataProvider(
              Tournament(
                id: 31,
                name: 'Евро (EURO)',
                type: 'PendingDraw',
                apiCode: 'uefa.euro',
                currentSeason: '2028',
              ),
            ),
          ),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Евро — 2028'), findsOneWidget);
    expect(find.textContaining('Ждём полную жеребьёвку'), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Создание аккаунта'), findsNothing);
  });

  testWidgets('Nations League uses national groups and all fixtures', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => FakeAuthProvider(),
          ),
          ChangeNotifierProvider<DataProvider>(
            create: (_) => TournamentDataProvider(
              Tournament(
                id: 28,
                name: 'Лига наций (UEFA-NL)',
                type: 'League',
                apiCode: 'uefa.nations',
              ),
            ),
          ),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Группы'), findsOneWidget);
    expect(find.text('Матчи'), findsOneWidget);
    expect(find.text('Плей-офф'), findsNothing);
  });

  testWidgets('guest opens matches and can change theme from profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => FakeAuthProvider(),
          ),
          ChangeNotifierProvider<DataProvider>(
            create: (_) => FakeDataProvider(),
          ),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ],
        child: const FutratApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Создание аккаунта'), findsNothing);
    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();
    expect(find.text('Гость'), findsOneWidget);
    expect(find.text('Войти / зарегистрироваться'), findsOneWidget);

    await tester.tap(find.text('Тема оформления'));
    await tester.pumpAndSettle();
    expect(find.text('Выберите тему'), findsOneWidget);
    await tester.tap(find.text('Светлая'));
    await tester.pumpAndSettle();
    expect(find.text('Гость'), findsOneWidget);
    expect(find.text('Создание аккаунта'), findsNothing);

    await tester.ensureVisible(find.byKey(const ValueKey('accent-yellow')));
    await tester.tap(find.byKey(const ValueKey('accent-yellow')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Жёлтый'), findsOneWidget);
    expect(find.text('Выберите акцент'), findsNothing);
    expect(find.text('Светлая'), findsOneWidget);
  });

  testWidgets('guest action waits for sign in and resumes afterward', (
    tester,
  ) async {
    final auth = FakeAuthProvider();
    var completedActions = 0;
    final resumedFlags = <bool>[];
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<DataProvider>(
            create: (_) => FakeDataProvider(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => runAuthenticatedAction(
                    context,
                    action: 'добавить команду в избранное',
                    onAuthenticated: (resumed) async {
                      resumedFlags.add(resumed);
                      completedActions++;
                    },
                  ),
                  child: const Text('Добавить'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();
    expect(find.text('Нужен аккаунт'), findsOneWidget);
    expect(completedActions, 0);

    await tester.tap(find.text('Позже'));
    await tester.pumpAndSettle();
    expect(completedActions, 0);

    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Войти / зарегистрироваться'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Player');
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tester.ensureVisible(find.text('Создать аккаунт'));
    await tester.tap(find.text('Создать аккаунт'));
    await tester.pumpAndSettle();
    expect(auth.isAuthenticated, isTrue);
    expect(completedActions, 1);
    expect(resumedFlags, [true]);
    expect(find.text('Нужен аккаунт'), findsNothing);

    await tester.tap(find.text('Добавить'));
    await tester.pumpAndSettle();
    expect(completedActions, 2);
    expect(resumedFlags, [true, false]);
  });
}

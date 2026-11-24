import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futrat_mobile/core/app_theme.dart';
import 'package:futrat_mobile/core/tournament_menu.dart';
import 'package:futrat_mobile/models/all_models.dart';
import 'package:futrat_mobile/providers/tournament_menu_preferences.dart';
import 'package:futrat_mobile/widgets/tournament_menu.dart';

Tournament league(int id, String code, String name) => Tournament(
  id: id,
  apiCode: code,
  name: name,
  type: 'League',
  country: 'Global',
);
final leagues = [
  league(1, 'eng.1', 'АПЛ'),
  league(2, 'eng.2', 'Чемпионшип'),
  league(3, 'eng.fa', 'Кубок Англии'),
  league(4, 'esp.1', 'Ла Лига'),
  league(5, 'uefa.nations', 'Лига наций'),
  league(6, 'fifa.world', 'Чемпионат мира'),
  league(7, 'uefa.champions', 'Лига чемпионов'),
  league(8, 'uefa.super_cup', 'Суперкубок УЕФА'),
];

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'groups mixed favorites without losing or duplicating leagues',
    () async {
      final prefs = TournamentMenuPreferences(scope: 'guest');
      await prefs.ready;
      final groups = tournamentMenuGroups(leagues, {1, 7}, prefs);
      expect(groups.where((g) => g.favorite).map((g) => g.title), [
        'Англия',
        'Еврокубки',
      ]);
      final national = groups.singleWhere((g) => g.key == 'other:national');
      expect(national.leagues.map((t) => t.id), [5, 6]);
      expect(
        groups.expand((g) => g.leagues).map((t) => t.id).toSet().length,
        leagues.length,
      );
      expect(groups.expand((g) => g.leagues).length, leagues.length);
      expect(groups.takeWhile((g) => g.favorite).length, 2);
      prefs.dispose();
    },
  );

  test(
    'order and collapse survive restart and remain scoped to account',
    () async {
      final prefs = TournamentMenuPreferences(scope: 'user-1');
      await prefs.ready;
      await prefs.move(
        'other:eng',
        ['eng.1', 'eng.2', 'eng.fa'],
        'eng.fa',
        'eng.1',
      );
      await prefs.toggleCollapsed('other:eng');
      final restored = TournamentMenuPreferences(scope: 'user-1');
      await restored.ready;
      expect(
        tournamentMenuGroups(
          leagues,
          {},
          restored,
        ).first.leagues.map((t) => t.id),
        [3, 1, 2],
      );
      expect(restored.isCollapsed('other:eng'), isTrue);
      final guest = TournamentMenuPreferences(scope: 'guest');
      await guest.ready;
      expect(guest.isCollapsed('other:eng'), isFalse);
      expect(
        tournamentMenuGroups(leagues, {}, guest).first.leagues.first.id,
        1,
      );
      // A source from another zone must not enter this order.
      await restored.move(
        'other:eng',
        ['eng.1', 'eng.2', 'eng.fa'],
        'esp.1',
        'eng.1',
      );
      expect(
        tournamentMenuGroups(leagues, {}, restored).first.leagues.first.id,
        3,
      );
      prefs.dispose();
      restored.dispose();
      guest.dispose();
    },
  );

  Widget menu(
    TournamentMenuPreferences prefs, {
    Set<int> favorites = const {},
  }) => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 320,
        child: TournamentMenu(
          tournaments: leagues,
          favoriteIds: favorites,
          selectedId: 1,
          preferences: prefs,
          theme: AppTheme.getTheme(AppThemeType.dark),
          onSelect: (_) {},
          onFavorite: (_) {},
        ),
      ),
    ),
  );

  testWidgets('country collapse hides leagues and preserves section headings', (
    tester,
  ) async {
    final prefs = TournamentMenuPreferences(scope: 'guest');
    await prefs.ready;
    await tester.pumpWidget(menu(prefs, favorites: {1}));
    expect(find.text('Избранное'), findsOneWidget);
    expect(find.text('Все турниры'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('group-header-favorite:eng')));
    await tester.pumpAndSettle();
    expect(find.text('АПЛ'), findsNothing);
    expect(find.text('Чемпионшип'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    prefs.dispose();
  });

  testWidgets('country blocks reorder only inside their favorite section', (
    tester,
  ) async {
    final prefs = TournamentMenuPreferences(scope: 'guest');
    await prefs.ready;
    await tester.pumpWidget(menu(prefs, favorites: {1, 7}));
    final source = find.byKey(const ValueKey('group-header-favorite:european'));
    final target = find.byKey(const ValueKey('group-header-favorite:eng'));
    final handle = find.descendant(
      of: source,
      matching: find.byIcon(Icons.drag_indicator),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 990));
    expect(find.byKey(const ValueKey('menu-drag-feedback')), findsNothing);
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byKey(const ValueKey('menu-drag-feedback')), findsOneWidget);
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      tournamentMenuGroups(leagues, {1, 7}, prefs).first.title,
      'Еврокубки',
    );
    final other = find.byKey(const ValueKey('group-header-other:eng'));
    final forbidden = await tester.startGesture(tester.getCenter(other));
    await tester.pump(const Duration(milliseconds: 1010));
    await forbidden.moveTo(tester.getCenter(target));
    await tester.pump();
    await forbidden.up();
    await tester.pumpAndSettle();
    expect(
      tournamentMenuGroups(leagues, {
        1,
        7,
      }, prefs).take(2).every((g) => g.favorite),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    prefs.dispose();
  });

  testWidgets('country drag handle reorders non-favorites without a tooltip', (
    tester,
  ) async {
    final prefs = TournamentMenuPreferences(scope: 'guest');
    await prefs.ready;
    await prefs.toggleCollapsed('other:eng');
    await prefs.toggleCollapsed('other:esp');
    await tester.pumpWidget(menu(prefs));
    final source = find.byKey(const ValueKey('group-header-other:esp'));
    final target = find.byKey(const ValueKey('group-header-other:eng'));
    final handle = find.descendant(
      of: source,
      matching: find.byIcon(Icons.drag_indicator),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 1010));
    expect(find.byKey(const ValueKey('menu-drag-feedback')), findsOneWidget);
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tournamentMenuGroups(leagues, {}, prefs).first.code, 'esp');
    expect(
      find.descendant(of: source, matching: find.byType(Tooltip)),
      findsNothing,
    );
    expect(prefs.isCollapsed('other:esp'), isTrue);
    await tester.tap(source);
    await tester.pumpAndSettle();
    expect(find.text('Ла Лига'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    prefs.dispose();
  });

  testWidgets(
    'drawer stays open during a pending hold and horizontal dragging',
    (tester) async {
      final prefs = TournamentMenuPreferences(scope: 'guest');
      await prefs.ready;
      await prefs.toggleCollapsed('other:eng');
      await prefs.toggleCollapsed('other:esp');
      final scaffold = GlobalKey<ScaffoldState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            key: scaffold,
            drawer: Drawer(
              child: TournamentMenu(
                tournaments: leagues,
                favoriteIds: const {},
                selectedId: 1,
                preferences: prefs,
                theme: AppTheme.getTheme(AppThemeType.dark),
                onSelect: (_) {},
                onFavorite: (_) {},
              ),
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );
      scaffold.currentState!.openDrawer();
      await tester.pumpAndSettle();
      final source = find.byKey(const ValueKey('group-header-other:esp'));
      final target = find.byKey(const ValueKey('group-header-other:eng'));
      final pending = await tester.startGesture(tester.getCenter(source));
      await tester.pump(const Duration(milliseconds: 600));
      await pending.moveBy(const Offset(-70, 0));
      await tester.pump(const Duration(milliseconds: 100));
      await pending.moveBy(const Offset(-100, 0));
      await tester.pump(const Duration(milliseconds: 100));
      await pending.moveBy(const Offset(-100, 0));
      await pending.up();
      await tester.pumpAndSettle();
      expect(scaffold.currentState!.isDrawerOpen, isTrue);
      expect(prefs.isCollapsed('other:esp'), isTrue);

      final drag = await tester.startGesture(tester.getCenter(source));
      await tester.pump(const Duration(milliseconds: 1010));
      expect(find.byKey(const ValueKey('menu-drag-feedback')), findsOneWidget);
      await drag.moveBy(const Offset(-100, 0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(scaffold.currentState!.isDrawerOpen, isTrue);
      await drag.moveTo(tester.getCenter(target));
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();
      expect(tournamentMenuGroups(leagues, {}, prefs).first.code, 'esp');
      expect(prefs.isCollapsed('other:esp'), isTrue);
      await tester.tapAt(const Offset(700, 300));
      await tester.pumpAndSettle();
      expect(scaffold.currentState!.isDrawerOpen, isFalse);
      await tester.pumpWidget(const SizedBox());
      prefs.dispose();
    },
  );

  testWidgets('horizontal protection preserves vertical menu scrolling', (
    tester,
  ) async {
    final prefs = TournamentMenuPreferences(scope: 'guest');
    await prefs.ready;
    await tester.pumpWidget(menu(prefs));
    final list = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(list.position.pixels, 0);
    await tester.drag(
      find.byKey(const ValueKey('group-header-other:eng')),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(list.position.pixels, greaterThan(0));
    expect(find.byKey(const ValueKey('menu-drag-feedback')), findsNothing);
    expect(prefs.isCollapsed('other:eng'), isFalse);
    await tester.pumpWidget(const SizedBox());
    prefs.dispose();
  });

  for (final area in <String, Offset>{
    'left edge': const Offset(.001, .5),
    'left padding': const Offset(.025, .5),
    'title': const Offset(.15, .5),
    'empty space': const Offset(.55, .5),
    'right edge': const Offset(.999, .5),
    'top edge': const Offset(.5, .001),
    'bottom edge': const Offset(.5, .999),
  }.entries) {
    testWidgets('country header tap and hold work at ${area.key}', (
      tester,
    ) async {
      final prefs = TournamentMenuPreferences(scope: 'guest');
      await prefs.ready;
      await prefs.toggleCollapsed('other:eng');
      await prefs.toggleCollapsed('other:esp');
      await tester.pumpWidget(menu(prefs));
      final header = find.byKey(const ValueKey('group-header-other:esp'));
      final row = find.ancestor(
        of: header,
        matching: find.byWidgetPredicate((w) => w is LongPressDraggable),
      );
      final rect = tester.getRect(row);
      final point =
          rect.topLeft +
          Offset(rect.width * area.value.dx, rect.height * area.value.dy);

      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(prefs.isCollapsed('other:esp'), isFalse);
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(prefs.isCollapsed('other:esp'), isTrue);

      final gesture = await tester.startGesture(point);
      await tester.pump(const Duration(milliseconds: 990));
      expect(find.byKey(const ValueKey('menu-drag-feedback')), findsNothing);
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byKey(const ValueKey('menu-drag-feedback')), findsOneWidget);
      await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey('group-header-other:eng'))),
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tournamentMenuGroups(leagues, {}, prefs).first.code, 'esp');
      expect(prefs.isCollapsed('other:esp'), isTrue);
      await tester.pumpWidget(const SizedBox());
      prefs.dispose();
    });
  }

  for (final mode in AppThemeType.values) {
    testWidgets('menu fits narrow screens with larger text in $mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final prefs = TournamentMenuPreferences(scope: 'guest');
      await prefs.ready;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getTheme(mode).themeData,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.4)),
            child: child!,
          ),
          home: Scaffold(
            body: TournamentMenu(
              tournaments: [
                ...leagues,
                league(9, 'ksa.1', 'Саудовская Про-лига'),
              ],
              favoriteIds: const {1},
              selectedId: 1,
              preferences: prefs,
              theme: AppTheme.getTheme(mode),
              onSelect: (_) {},
              onFavorite: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('group-header-other:ksa')),
        300,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      prefs.dispose();
    });
  }

  testWidgets(
    '1 second hold reorders leagues but cannot cross favorite boundary',
    (tester) async {
      final prefs = TournamentMenuPreferences(scope: 'guest');
      await prefs.ready;
      await tester.pumpWidget(menu(prefs));
      final source = find.byKey(const ValueKey('league-other:eng-eng.fa'));
      final target = find.byKey(const ValueKey('league-other:eng-eng.1'));
      final gesture = await tester.startGesture(tester.getCenter(source));
      await tester.pump(const Duration(milliseconds: 990));
      expect(find.byKey(const ValueKey('menu-drag-feedback')), findsNothing);
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byKey(const ValueKey('menu-drag-feedback')), findsOneWidget);
      await gesture.moveTo(tester.getCenter(target));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        tournamentMenuGroups(leagues, {}, prefs).first.leagues.first.id,
        3,
      );
      await tester.pumpWidget(menu(prefs, favorites: {1}));
      final other = find.byKey(const ValueKey('league-other:eng-eng.2'));
      final favorite = find.byKey(const ValueKey('group-header-favorite:eng'));
      final forbidden = await tester.startGesture(tester.getCenter(other));
      await tester.pump(const Duration(milliseconds: 1010));
      await forbidden.moveTo(tester.getCenter(favorite));
      await tester.pump();
      await forbidden.up();
      await tester.pumpAndSettle();
      expect(
        tournamentMenuGroups(leagues, {
          1,
        }, prefs).first.leagues.map((t) => t.id),
        [1],
      );
      await tester.pumpWidget(const SizedBox());
      prefs.dispose();
    },
  );
}

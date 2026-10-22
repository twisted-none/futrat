import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:futrat_mobile/core/app_theme.dart';
import 'package:futrat_mobile/models/all_models.dart';
import 'package:futrat_mobile/providers/data_provider.dart';
import 'package:futrat_mobile/widgets/lineup_view.dart';

MatchModel lineupFixture() => MatchModel.fromJson({
  'id': 1,
  'date_time': '2026-10-18T12:00:00Z',
  'status': 'FINISHED',
  'home_team': {'id': 1, 'name': 'Брайтон энд Хоув Альбион'},
  'away_team': {'id': 2, 'name': 'Манчестер Юнайтед'},
  'tournament': {'id': 1, 'name': 'АПЛ', 'type': 'League'},
  'events': [],
  'lineups': [
    for (final team in [1, 2])
      {
        'id': team,
        'team_id': team,
        'player_name': team == 1 ? 'Home Player' : 'Away Player',
        'is_starter': true,
        'rating': '7.5',
      },
  ],
});

void main() {
  for (final mode in AppThemeType.values) {
    testWidgets('team selector switches lineups on narrow screen, $mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => DataProvider(),
          child: MaterialApp(
            theme: AppTheme.getTheme(mode).themeData,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: Scaffold(
              body: LineupView(match: lineupFixture(), onRate: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final home = find.byKey(const ValueKey('lineup-team-home'));
      final away = find.byKey(const ValueKey('lineup-team-away'));
      expect(tester.getSize(home).width, tester.getSize(away).width);
      expect(tester.getSize(home).height, tester.getSize(away).height);
      expect(find.textContaining('Home Player'), findsOneWidget);
      expect(find.textContaining('Away Player'), findsNothing);
      await tester.tap(away);
      await tester.pumpAndSettle();
      expect(find.textContaining('Away Player'), findsOneWidget);
      expect(find.textContaining('Home Player'), findsNothing);
      await tester.tap(find.text('Список'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Away Player'), findsOneWidget);
      await tester.tap(home);
      await tester.pumpAndSettle();
      expect(find.textContaining('Home Player'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:futrat_mobile/providers/data_provider.dart';
import 'package:futrat_mobile/widgets/lineup_view.dart';
import 'package:futrat_mobile/core/lineup_layout.dart';
import 'package:futrat_mobile/models/all_models.dart';

LineupPlayer player(int slot, String name, String role) => LineupPlayer(
  id: slot,
  teamId: 1,
  playerName: name,
  position: role,
  slot: slot,
  jersey: '$slot',
  isStarter: true,
  rating: '-',
);

final spurs = [
  player(1, 'Kinsky', 'Goalkeeper'),
  player(6, 'Senesi', 'Center Left Defender'),
  player(5, 'Van Hecke', 'Center Right Defender'),
  player(3, 'Udogie', 'Left Back'),
  player(2, 'Porro', 'Right Back'),
  player(10, 'Maddison', 'Attacking Midfielder'),
  player(4, 'Fernandes', 'Left Midfielder'),
  player(8, 'Gallagher', 'Right Midfielder'),
  player(9, 'Solanke', 'Forward'),
  player(11, 'Williams-Barnett', 'Attacking Midfielder Left'),
  player(7, 'Kudus', 'Attacking Midfielder Right'),
];

void main() {
  testWidgets('Spurs players render on their actual lines and sides', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = MatchModel.fromJson({
      'id': 604,
      'date_time': '2026-11-21T15:00:00Z',
      'status': 'FINISHED',
      'home_team': {'id': 1, 'name': 'Tottenham'},
      'away_team': {'id': 2, 'name': 'Ipswich'},
      'tournament': {'id': 1, 'name': 'League', 'type': 'League'},
      'events': [],
      'formations': {'1': '4-2-3-1'},
      'lineups': [
        for (final p in spurs)
          {
            'id': p.id,
            'team_id': 1,
            'player_name': p.playerName,
            'position': p.position,
            'slot': p.slot,
            'is_starter': true,
          },
      ],
    });
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => DataProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: LineupView(match: game, onRate: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Offset center(int id) =>
        tester.getCenter(find.byKey(ValueKey('field-player-$id')));
    expect(find.byKey(const ValueKey('lineup-pitch')), findsOneWidget);
    expect(
      center(9).dy,
      lessThan(center(10).dy),
    ); // Striker above attacking midfield.
    expect(center(10).dy, lessThan(center(4).dy));
    expect(center(4).dy, lessThan(center(6).dy));
    expect(
      center(6).dy,
      lessThan(center(1).dy),
    ); // Goalkeeper remains at the bottom.
    expect(center(11).dx, lessThan(center(10).dx));
    expect(center(10).dx, lessThan(center(7).dx));
    expect(center(3).dx, lessThan(center(6).dx));
    expect(center(6).dx, lessThan(center(5).dx));
    expect(center(5).dx, lessThan(center(2).dx));
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'ESPN tactical numbers are roles, not sequential positions in 4-2-3-1',
    () {
      final rows = confirmedLineupRows(spurs, '4-2-3-1')!;
      expect(
        rows.map((row) => row.map((p) => p.playerName).toList()).toList(),
        [
          ['Kinsky'],
          ['Udogie', 'Senesi', 'Van Hecke', 'Porro'],
          ['Fernandes', 'Gallagher'],
          ['Williams-Barnett', 'Maddison', 'Kudus'],
          ['Solanke'],
        ],
      );
      expect(
        confirmedLineupRows(
          spurs.reversed.toList(),
          '4-2-3-1',
        )!.last.single.playerName,
        'Solanke',
      );
    },
  );

  test(
    'unconfirmed, ambiguous or incomplete positions fall back to the list',
    () {
      expect(confirmedLineupRows(spurs, '4-3-3'), isNull);
      expect(confirmedLineupRows(spurs.take(10).toList(), '4-2-3-1'), isNull);
      expect(confirmedLineupRows(spurs, null), isNull);
      final unknown = [...spurs]..[1] = player(6, 'Senesi', 'Defender');
      unknown[2] = player(5, 'Van Hecke', 'Defender');
      expect(confirmedLineupRows(unknown, '4-2-3-1'), isNull);
      expect(
        confirmedLineupRows([
          for (final p in spurs) player(p.id, p.playerName, ''),
        ], '4-2-3-1'),
        isNull,
      );
    },
  );

  test(
    'one midfield line may contain both defensive and central midfielders',
    () {
      final team = [
        player(1, 'GK', 'Goalkeeper'),
        player(2, 'RB', 'Right Back'),
        player(3, 'LB', 'Left Back'),
        player(5, 'RCB', 'Center Right Defender'),
        player(6, 'LCB', 'Center Left Defender'),
        player(4, 'DM', 'Defensive Midfielder'),
        player(7, 'RCM', 'Right Center Midfielder'),
        player(8, 'LCM', 'Left Center Midfielder'),
        player(9, 'CF', 'Forward'),
        player(10, 'LW', 'Left Forward'),
        player(11, 'RW', 'Right Forward'),
      ];
      final rows = confirmedLineupRows(team, '4-3-3')!;
      expect(rows[2].map((p) => p.playerName), ['LCM', 'DM', 'RCM']);
      expect(rows[3].map((p) => p.playerName), ['LW', 'CF', 'RW']);
    },
  );
}

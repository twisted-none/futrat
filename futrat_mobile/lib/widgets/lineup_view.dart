import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/all_models.dart';
import '../providers/data_provider.dart';
import '../core/auth_gate.dart';
import '../screens/player_screen.dart';
import 'match_tile.dart';

class LineupView extends StatefulWidget {
  final MatchModel match;
  final ValueChanged<LineupPlayer> onRate;
  const LineupView({super.key, required this.match, required this.onRate});
  @override
  State<LineupView> createState() => _LineupViewState();
}

class _LineupViewState extends State<LineupView> {
  bool _field = true, _away = false;
  String _rating(LineupPlayer player) =>
      player.rating == '-' ? '—' : player.rating;
  void _profile(LineupPlayer player) {
    if (player.playerId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(playerId: player.playerId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.match;
    final compact =
        MediaQuery.sizeOf(context).width < 380 ||
        MediaQuery.textScalerOf(context).scale(14) > 18;
    if (game.lineups.isEmpty) {
      return const Center(child: Text('Составы недоступны у источника'));
    }
    final team = _away ? game.awayTeam : game.homeTeam;
    final rows = game.lineups.where((p) => p.teamId == team.id).toList();
    final starters = rows.where((p) => p.isStarter).toList()
      ..sort((a, b) => (a.slot ?? 99).compareTo(b.slot ?? 99));
    final subs = rows.where((p) => !p.isStarter).toList();
    final scheme = game.formations['${team.id}'];
    final formation = scheme
        ?.split('-')
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    final valid =
        formation != null &&
        formation.fold<int>(0, (a, b) => a + b) == 10 &&
        starters.length == 11 &&
        starters.map((p) => p.slot).toSet().length == 11 &&
        starters.every(
          (p) => p.slot != null && p.slot! >= 1 && p.slot! <= 11,
        ) &&
        MediaQuery.textScalerOf(context).scale(12) <= 18 &&
        MediaQuery.sizeOf(context).width >= 300;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _teamChoice(game.homeTeam, false)),
              const SizedBox(width: 8),
              Expanded(child: _teamChoice(game.awayTeam, true)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(scheme == null ? 'Схема не опубликована' : 'Схема $scheme'),
            SegmentedButton<bool>(
              showSelectedIcon: !compact,
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              segments: [
                ButtonSegment(
                  value: true,
                  icon: compact ? null : const Icon(Icons.sports_soccer),
                  label: const Text('Поле'),
                ),
                ButtonSegment(
                  value: false,
                  icon: compact ? null : const Icon(Icons.list),
                  label: const Text('Список'),
                ),
              ],
              selected: {_field},
              onSelectionChanged: (values) =>
                  setState(() => _field = values.first),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_field && valid)
          _pitch(starters, [1, ...formation])
        else ...[
          if (_field)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Для поля не хватает подтверждённых позиций. Показан список состава.',
              ),
            ),
          ...starters.map(_row),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('Запасные'),
        ),
        ...subs.map(_row),
      ],
    );
  }

  Widget _teamChoice(Team team, bool away) {
    final selected = _away == away;
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        key: ValueKey(away ? 'lineup-team-away' : 'lineup-team-home'),
        onPressed: () => setState(() => _away = away),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: selected ? colors.primary : colors.outline,
            width: selected ? 1.5 : 1,
          ),
          backgroundColor: selected
              ? colors.primary.withValues(alpha: 0.1)
              : colors.surface,
          foregroundColor: selected ? colors.primary : colors.onSurface,
          textStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        child: Text(team.name, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _pitch(List<LineupPlayer> players, List<int> rows) {
    var offset = 0;
    final lines = <List<LineupPlayer>>[];
    for (final count in rows) {
      lines.add(players.sublist(offset, offset + count));
      offset += count;
    }
    return AspectRatio(
      aspectRatio: 0.74,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xff1c593c),
          border: Border.all(color: Colors.white70),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _PitchLines())),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: lines.reversed
                    .map(
                      (line) => Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: line
                              .map(
                                (player) =>
                                    Expanded(child: _fieldPlayer(player)),
                              )
                              .toList(),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldPlayer(LineupPlayer player) => Semantics(
    label: '${player.playerName}, оценка ${_rating(player)}',
    button: true,
    child: InkWell(
      onTap: () => _profile(player),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: PlayerPhoto(url: player.photoUrl, size: 36),
              ),
              Positioned(
                right: -8,
                bottom: -3,
                child: Material(
                  color: const Color(0xff152d22),
                  borderRadius: BorderRadius.circular(4),
                  child: InkWell(
                    onTap: _canRate(player)
                        ? () => widget.onRate(player)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        _rating(player),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${player.jersey} ${player.playerName}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              height: 1.15,
            ),
          ),
          if ((player.goals ?? 0) > 0 || (player.assists ?? 0) > 0)
            Text(
              '${(player.goals ?? 0) > 0 ? 'Г:${player.goals} ' : ''}${(player.assists ?? 0) > 0 ? 'П:${player.assists}' : ''}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
        ],
      ),
    ),
  );

  bool _canRate(LineupPlayer player) =>
      widget.match.status == 'FINISHED' &&
      (player.appeared == true ||
          (player.appeared == null && player.isStarter));
  Widget _row(LineupPlayer player) {
    final data = context.watch<DataProvider>();
    final favorite =
        player.playerId != null && data.isPlayerFavorite(player.playerId!);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 2),
        leading: InkWell(
          onTap: () => _profile(player),
          child: PlayerPhoto(url: player.photoUrl),
        ),
        title: Text('${player.jersey} ${player.playerName}'),
        subtitle: Text(
          '${player.ratingCount} голосов · ${player.minutes ?? '—'} мин',
        ),
        onTap: () => _profile(player),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: _canRate(player) ? () => widget.onRate(player) : null,
              child: Text(_rating(player)),
            ),
            if (player.playerId != null)
              IconButton(
                tooltip: favorite ? 'Убрать из избранного' : 'В избранное',
                icon: Icon(favorite ? Icons.star : Icons.star_border),
                onPressed: () => runAuthenticatedAction(
                  context,
                  action: 'добавить игрока в избранное',
                  onAuthenticated: (resumed) async {
                    if (resumed && data.isPlayerFavorite(player.playerId!))
                      return;
                    await data.togglePlayerFavorite(player.playerId!);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PitchLines extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final inset = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawRect(inset, paint);
    canvas.drawLine(
      Offset(8, size.height / 2),
      Offset(size.width - 8, size.height / 2),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * .13,
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * .22, 8, size.width * .56, size.height * .13),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .22,
        size.height - size.height * .13 - 8,
        size.width * .56,
        size.height * .13,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PitchLines oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/auth_gate.dart';
import '../core/translator.dart';
import '../models/all_models.dart';
import '../providers/data_provider.dart';
import '../screens/match_detail_screen.dart';
import 'football_logo.dart';

class LeagueMatches {
  const LeagueMatches(this.tournament, this.matches);
  final Tournament tournament;
  final List<MatchModel> matches;
}

List<LeagueMatches> groupMatchesByLeague(
  List<MatchModel> matches,
  List<Tournament> catalog,
  Set<int> favorites,
) {
  final byLeague = <int, List<MatchModel>>{};
  for (final match in matches) {
    byLeague.putIfAbsent(match.tournament.id, () => []).add(match);
  }
  final order = {for (var i = 0; i < catalog.length; i++) catalog[i].id: i};
  final groups = byLeague.values.map((games) {
    games.sort((a, b) {
      final date = a.dateTime.compareTo(b.dateTime);
      return date == 0 ? a.id.compareTo(b.id) : date;
    });
    return LeagueMatches(games.first.tournament, List.unmodifiable(games));
  }).toList();
  groups.sort((a, b) {
    final x = a.tournament, y = b.tournament;
    final favorite = (favorites.contains(x.id) ? 0 : 1).compareTo(
      favorites.contains(y.id) ? 0 : 1,
    );
    if (favorite != 0) return favorite;
    final position = (order[x.id] ?? catalog.length).compareTo(
      order[y.id] ?? catalog.length,
    );
    if (position != 0) return position;
    final name = x.name.compareTo(y.name);
    return name == 0 ? x.id.compareTo(y.id) : name;
  });
  return groups;
}

class GroupedMatchesList extends StatelessWidget {
  const GroupedMatchesList({
    super.key,
    required this.matches,
    this.feedId = -1,
  });
  final List<MatchModel> matches;
  final int feedId;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final colors = Theme.of(context).colorScheme;
    final favorites = data.favoriteTournaments.map((t) => t.id).toSet();
    final groups = groupMatchesByLeague(matches, data.tournaments, favorites);
    if (groups.isEmpty) return const Center(child: Text('Нет матчей'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final collapsed = data.isLeagueCollapsed(feedId, group.tournament.id);
        return Card(
          key: ValueKey('league-group-${group.tournament.id}'),
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              Semantics(
                button: true,
                expanded: !collapsed,
                child: InkWell(
                  key: ValueKey('toggle-league-${group.tournament.id}'),
                  onTap: () =>
                      data.toggleLeagueCollapsed(feedId, group.tournament.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        FootballLogo(url: group.tournament.logoUrl, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            group.tournament.name.replaceAll(
                              RegExp(r'\s*\([^)]*\)'),
                              '',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (favorites.contains(group.tournament.id))
                          Icon(Icons.star, size: 18, color: colors.primary),
                        const SizedBox(width: 8),
                        Icon(collapsed ? Icons.expand_more : Icons.expand_less),
                      ],
                    ),
                  ),
                ),
              ),
              if (!collapsed) ...[
                const Divider(height: 1),
                for (var i = 0; i < group.matches.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 12, endIndent: 12),
                  _MatchRow(match: group.matches[i]),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match});
  final MatchModel match;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final live = match.isLive;
    final status = live
        ? 'LIVE'
        : match.needsStatusCheck
        ? 'Уточняется'
        : const {
            'FINISHED': 'Завершён',
            'CANCELLED': 'Отмена',
            'DELAYED': 'Отложен',
            'POSTPONED': 'Перенос',
            'ABANDONED': 'Прерван',
            'SUSPENDED': 'Приостановлен',
          }[match.status];
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MatchDetailScreen(match: match),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              child: Column(
                children: [
                  Text(
                    live
                        ? match.liveLabel
                        : DateFormat('HH:mm').format(match.dateTime.toLocal()),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (status != null && !live)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        status,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: live ? colors.error : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  _team(context, match.homeTeam, match.scoreHome),
                  _team(context, match.awayTeam, match.scoreAway),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _team(BuildContext context, Team team, int? score) {
    final data = context.watch<DataProvider>();
    final favorite = data.isTeamFavorite(team.id);
    final showScore = !const {
      'SCHEDULED',
      'DELAYED',
      'POSTPONED',
      'CANCELLED',
    }.contains(match.status);
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                FootballLogo(url: team.logoUrl, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr(team.name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 28,
          key: team.id == match.homeTeam.id
              ? ValueKey('match-score-${match.id}')
              : null,
          child: Text(
            showScore ? '${score ?? '—'}' : '—',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        IconButton(
          key: ValueKey('favorite-team-${match.id}-${team.id}'),
          tooltip: favorite
              ? 'Убрать команду из избранного'
              : 'Добавить команду в избранное',
          iconSize: 18,
          icon: Icon(
            favorite ? Icons.star : Icons.star_border,
            color: favorite
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: () => runAuthenticatedAction(
            context,
            action: 'добавить команду в избранное',
            onAuthenticated: (resumed) async {
              if (resumed && data.isTeamFavorite(team.id)) return;
              await data.toggleTeamFavorite(team.id);
            },
          ),
        ),
      ],
    );
  }
}

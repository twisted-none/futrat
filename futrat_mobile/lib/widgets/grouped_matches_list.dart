import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/all_models.dart';
import '../providers/data_provider.dart';
import 'football_logo.dart';
import 'match_summary.dart';
import 'app_states.dart';

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
    if (groups.isEmpty)
      return const AppEmptyState(
        title: 'Нет матчей',
        message: 'Когда появятся игры, они будут сгруппированы по турнирам.',
      );
    return ListView.builder(
      key: PageStorageKey('match-feed-$feedId'),
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
  Widget build(BuildContext context) =>
      MatchSummary(match: match, showFavorites: true);
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/translator.dart';
import '../core/auth_gate.dart';
import '../models/all_models.dart';
import '../providers/data_provider.dart';
import '../screens/match_detail_screen.dart';
import 'football_logo.dart';
import 'team_link.dart';

String matchStatusLabel(MatchModel match) {
  if (match.needsStatusCheck) return 'СТАТУС УТОЧНЯЕТСЯ';
  if (match.isLive) return match.liveLabel;
  return const {
        'FINISHED': 'Завершён',
        'SCHEDULED': 'По расписанию',
        'DELAYED': 'Отложен',
        'POSTPONED': 'Перенос',
        'CANCELLED': 'Отменён',
        'ABANDONED': 'Прерван',
        'SUSPENDED': 'Приостановлен',
      }[match.status] ??
      'Статус уточняется';
}

class MatchSummary extends StatelessWidget {
  const MatchSummary({
    super.key,
    required this.match,
    this.showFavorites = false,
    this.linkTeams = false,
    this.showTournament = false,
    this.caption,
    this.onTap,
  });
  final MatchModel match;
  final bool showFavorites, linkTeams, showTournament;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final live = match.isLive;
    final played = match.status == 'FINISHED' || live;
    Widget team(Team club, int? score) {
      final label = Row(
        children: [
          FootballLogo(url: club.logoUrl, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr(club.name),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      );
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Expanded(
              child: linkTeams ? TeamLink(team: club, child: label) : label,
            ),
            const SizedBox(width: 12),
            Text(
              key: club.id == match.homeTeam.id
                  ? ValueKey('match-score-${match.id}')
                  : null,
              played ? '${score ?? '—'}' : '—',
              style: AppTheme.numberStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            if (showFavorites)
              Builder(
                builder: (context) {
                  final data = context.watch<DataProvider>();
                  final favorite = data.isTeamFavorite(club.id);
                  return IconButton(
                    key: ValueKey('favorite-team-${match.id}-${club.id}'),
                    tooltip: favorite
                        ? 'Убрать команду из избранного'
                        : 'Добавить команду в избранное',
                    iconSize: 20,
                    icon: Icon(
                      favorite ? Icons.star : Icons.star_border,
                      color: favorite
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                    onPressed: () => runAuthenticatedAction(
                      context,
                      action: 'добавить команду в избранное',
                      onAuthenticated: (resumed) async {
                        if (resumed && data.isTeamFavorite(club.id)) return;
                        await data.toggleTeamFavorite(club.id);
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      );
    }

    return InkWell(
      onTap:
          onTap ??
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MatchDetailScreen(match: match),
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTournament) ...[
              Text(
                match.tournament.name,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 6),
            ],
            team(match.homeTeam, match.scoreHome),
            team(match.awayTeam, match.scoreAway),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  matchStatusLabel(match),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: live
                        ? AppTheme.liveColor(context)
                        : colors.onSurfaceVariant,
                  ),
                ),
                if (!live)
                  Text(
                    DateFormat(
                      'dd.MM · HH:mm',
                    ).format(match.dateTime.toLocal()),
                    style: AppTheme.numberStyle.copyWith(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (caption != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  caption!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

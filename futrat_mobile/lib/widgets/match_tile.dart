import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/all_models.dart';
import '../screens/match_detail_screen.dart';
import 'team_link.dart';

class MatchTile extends StatelessWidget {
  final MatchModel match;
  final String? caption;
  const MatchTile({super.key, required this.match, this.caption});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TeamLink(
            team: match.homeTeam,
            child: Text(
              match.homeTeam.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          TeamLink(
            team: match.awayTeam,
            child: Text(
              match.awayTeam.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        '${DateFormat('dd.MM.yyyy HH:mm').format(match.dateTime)} · ${match.tournament.name}${caption == null ? '' : '\n$caption'}',
      ),
      trailing: Text(
        match.needsStatusCheck
            ? 'Уточняется'
            : match.status == 'FINISHED'
            ? '${match.scoreHome ?? '—'} : ${match.scoreAway ?? '—'}'
            : const {
                    'SCHEDULED': 'План',
                    'POSTPONED': 'Перенос',
                    'CANCELLED': 'Отмена',
                    'DELAYED': 'Задержка',
                  }[match.status] ??
                  match.status,
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)),
      ),
    ),
  );
}

class PlayerPhoto extends StatelessWidget {
  final String? url;
  final double size;
  const PlayerPhoto({super.key, this.url, this.size = 44});
  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox(
      width: size,
      height: size,
      child: url == null || url!.isEmpty
          ? Icon(Icons.person_outline, size: size * .7)
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) =>
                  Icon(Icons.person_outline, size: size * .7),
            ),
    ),
  );
}

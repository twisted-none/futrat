import 'package:flutter/material.dart';
import '../models/all_models.dart';
import 'match_summary.dart';

class MatchTile extends StatelessWidget {
  final MatchModel match;
  final String? caption;
  const MatchTile({super.key, required this.match, this.caption});
  @override
  Widget build(BuildContext context) => Card(
    child: MatchSummary(
      match: match,
      caption: caption,
      linkTeams: true,
      showTournament: true,
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

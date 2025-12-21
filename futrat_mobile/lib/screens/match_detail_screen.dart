import 'package:flutter/material.dart';
import '../models/all_models.dart';
import '../core/app_theme.dart';

class MatchDetailScreen extends StatelessWidget {
  final MatchModel match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final events = List<MatchEvent>.from(match.events)
      ..sort((a, b) => a.minute.compareTo(b.minute));

    return Scaffold(
      backgroundColor: AppTheme.almostBlack,
      appBar: AppBar(title: Text(match.tournament.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.deepPurple, AppTheme.almostBlack],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter
                )
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _teamColumn(match.homeTeam),
                  Column(
                    children: [
                      Text(
                        "${match.scoreHome ?? '-'} : ${match.scoreAway ?? '-'}",
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Text(match.status, style: const TextStyle(color: AppTheme.neonPurple, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 5),
                      Text("Тур ${match.round}", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  _teamColumn(match.awayTeam),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text("Голы", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // GOALS LIST
            if (events.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Нет голов", style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) {
                  final e = events[index];
                  return ListTile(
                    leading: Text("${e.minute}'", style: const TextStyle(color: AppTheme.neonPurple, fontWeight: FontWeight.bold)),
                    title: Text(e.player.name, style: const TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.sports_soccer, color: Colors.white70),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _teamColumn(Team team) {
    return Column(
      children: [
        if (team.logoUrl != null && !team.logoUrl!.endsWith('.svg'))
          Image.network(team.logoUrl!, height: 60, width: 60, errorBuilder: (_,__,___) => const Icon(Icons.shield, size: 60, color: Colors.white))
        else
          const Icon(Icons.shield, size: 60, color: Colors.white),
        const SizedBox(height: 10),
        SizedBox(
          width: 100,
          child: Text(team.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../core/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataProvider>(context);

    return Container(
      decoration: AppTheme.mainGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text("Лидеры прогнозов")),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.leaderboard.length,
          itemBuilder: (context, index) {
            final user = data.leaderboard[index];
            final rank = index + 1;
            
            Color rankColor = Colors.white;
            if (rank == 1) rankColor = const Color(0xFFFFD700); // Gold
            if (rank == 2) rankColor = const Color(0xFFC0C0C0); // Silver
            if (rank == 3) rankColor = const Color(0xFFCD7F32); // Bronze

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: rank <= 3 ? rankColor.withOpacity(0.5) : Colors.transparent
                ),
              ),
              child: Row(
                children: [
                  Text(
                    "#$rank",
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: rankColor
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      user["username"],
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  Text(
                    "${user["points"]} pts",
                    style: const TextStyle(color: AppTheme.neonPurple, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
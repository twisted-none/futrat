import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/theme_provider.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;

    return Container(
      decoration: currentTheme.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text("Лидеры прогнозов")),
        body: data.leaderboard.isEmpty
            ? const Center(child: Text("Пока нет лидеров"))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: data.leaderboard.length,
                itemBuilder: (context, index) {
                  final entry = data.leaderboard[index];
                  final rank = index + 1;

                  return Card(
                    child: ListTile(
                      leading: Text(
                        "#$rank",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      title: Text(entry.username),
                      trailing: Text(
                        "${entry.points} pts",
                        style: TextStyle(
                          color: currentTheme.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

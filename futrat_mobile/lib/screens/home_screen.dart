import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../core/app_theme.dart';
import '../models/all_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<DataProvider>(context, listen: false).initData()
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataProvider>(context);

    return Container(
      decoration: AppTheme.mainGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(data.selectedLeague?.name ?? "Матчи"),
          centerTitle: true,
        ),
        
        // --- БУРГЕР МЕНЮ ---
        drawer: Drawer(
          backgroundColor: const Color(0xFF1E1E1E),
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.deepPurple, AppTheme.almostBlack]),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sports_soccer, size: 50, color: AppTheme.neonPurple),
                      const SizedBox(height: 10),
                      const Text("Лиги 25/26", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: data.tournaments.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: data.tournaments.length,
                      itemBuilder: (context, index) {
                        final league = data.tournaments[index];
                        final isSelected = league.id == data.selectedLeague?.id;
                        final isFav = data.isLeagueFavorite(league.id);
                        
                        return ListTile(
                          title: Text(
                            league.name,
                            style: TextStyle(
                              color: isSelected ? AppTheme.neonPurple : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          leading: Icon(
                            league.type == "Cup" ? Icons.emoji_events : Icons.table_chart,
                            color: isSelected ? AppTheme.neonPurple : Colors.grey,
                          ),
                          // ЗВЕЗДА ДЛЯ ЛИГИ
                          trailing: IconButton(
                            icon: Icon(
                              isFav ? Icons.star : Icons.star_border,
                              color: isFav ? Colors.amber : Colors.grey,
                            ),
                            onPressed: () => data.toggleTournamentFavorite(league.id),
                          ),
                          selected: isSelected,
                          selectedTileColor: AppTheme.neonPurple.withOpacity(0.1),
                          onTap: () {
                            data.selectLeague(league);
                            Navigator.pop(context); // Закрыть меню
                          },
                        );
                      },
                    ),
              ),
            ],
          ),
        ),

        body: data.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple))
            : data.matches.isEmpty
                ? Center(
                    child: Text(
                      "Нет матчей в ${data.selectedLeague?.name}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: data.matches.length,
                    itemBuilder: (context, index) {
                      final match = data.matches[index];
                      return _buildMatchCard(match, data);
                    },
                  ),
      ),
    );
  }

  Widget _buildMatchCard(MatchModel match, DataProvider data) {
    final isHomeFav = data.isTeamFavorite(match.homeTeam.id);
    final isAwayFav = data.isTeamFavorite(match.awayTeam.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM').format(match.dateTime),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.neonPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  match.status,
                  style: const TextStyle(color: AppTheme.neonPurple, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- ХОЗЯЕВА ---
              Expanded(
                child: Column(
                  children: [
                    // Кнопка избранного над названием
                    GestureDetector(
                      onTap: () => data.toggleTeamFavorite(match.homeTeam.id),
                      child: Icon(
                        isHomeFav ? Icons.star : Icons.star_border,
                        color: isHomeFav ? Colors.amber : Colors.white24,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Icon(Icons.shield_outlined, color: Colors.white70, size: 30),
                    const SizedBox(height: 5),
                    Text(
                      match.homeTeam.name, 
                      textAlign: TextAlign.center, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
              
              // --- СЧЕТ ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  match.status == "FINISHED" 
                      ? "${match.scoreHome} - ${match.scoreAway}"
                      : DateFormat('HH:mm').format(match.dateTime),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
              
              // --- ГОСТИ ---
              Expanded(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => data.toggleTeamFavorite(match.awayTeam.id),
                      child: Icon(
                        isAwayFav ? Icons.star : Icons.star_border,
                        color: isAwayFav ? Colors.amber : Colors.white24,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Icon(Icons.shield_outlined, color: Colors.white70, size: 30),
                    const SizedBox(height: 5),
                    Text(
                      match.awayTeam.name, 
                      textAlign: TextAlign.center, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../core/app_theme.dart';
import '../models/all_models.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => 
      Provider.of<DataProvider>(context, listen: false).fetchFavorites()
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataProvider>(context);

    return Container(
      decoration: AppTheme.mainGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Избранное"),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.neonPurple,
            labelColor: AppTheme.neonPurple,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Клубы", icon: Icon(Icons.shield_outlined)),
              Tab(text: "Лиги", icon: Icon(Icons.emoji_events_outlined)),
              Tab(text: "Игроки", icon: Icon(Icons.person_outline)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTeamsList(data),
            _buildTournamentsList(data),
            _buildPlayersList(data),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsList(DataProvider data) {
    if (data.favoriteTeams.isEmpty) return _buildEmptyState("Нет любимых команд", Icons.shield_outlined);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.favoriteTeams.length,
      itemBuilder: (ctx, i) {
        final team = data.favoriteTeams[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: _cardDecoration(),
          child: ListTile(
            leading: _buildLogo(team.logoUrl), // ПОКАЗЫВАЕМ ЛОГОТИП
            title: Text(team.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(team.country ?? "Unknown", style: const TextStyle(color: Colors.grey)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => data.toggleTeamFavorite(team.id, true),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTournamentsList(DataProvider data) {
    if (data.favoriteTournaments.isEmpty) return _buildEmptyState("Нет любимых лиг", Icons.emoji_events_outlined);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.favoriteTournaments.length,
      itemBuilder: (ctx, i) {
        final tournament = data.favoriteTournaments[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: _cardDecoration(),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.white10,
              child: Icon(Icons.emoji_events, color: AppTheme.neonPurple),
            ),
            title: Text(tournament.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(tournament.country ?? "Europe", style: const TextStyle(color: Colors.grey)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => data.toggleTournamentFavorite(tournament.id),
            ),
            onTap: () {
               data.selectLeague(tournament);
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Лига выбрана")));
            },
          ),
        );
      },
    );
  }

  Widget _buildPlayersList(DataProvider data) {
    if (data.favoritePlayers.isEmpty) return _buildEmptyState("Нет любимых игроков", Icons.person_off_outlined);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.favoritePlayers.length,
      itemBuilder: (ctx, i) {
        final player = data.favoritePlayers[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: _cardDecoration(),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.white10,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(player.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("Голы: ${player.goals}", style: const TextStyle(color: AppTheme.neonPurple)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {}, // Заглушка
            ),
          ),
        );
      },
    );
  }

  // Виджет для логотипа (как на главном экране)
  Widget _buildLogo(String? url) {
    if (url == null || url.isEmpty) return const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.shield, color: Colors.white));
    
    if (url.endsWith('.svg')) {
       return const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.shield, color: AppTheme.neonPurple)); 
    }
    return Image.network(
      url, height: 40, width: 40,
      errorBuilder: (_,__,___) => const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.shield, color: Colors.white)),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.white10),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: Colors.white38, fontSize: 16)),
        ],
      ),
    );
  }
}
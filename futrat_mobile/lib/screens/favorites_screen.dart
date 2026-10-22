import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/theme_provider.dart';
import '../core/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'team_screen.dart';
import 'player_screen.dart';
import '../widgets/match_tile.dart';
import '../widgets/football_logo.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(
      () => Provider.of<DataProvider>(context, listen: false).fetchFavorites(),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;

    return Container(
      decoration: currentTheme.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Избранное"),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: currentTheme.accentColor,
            labelColor: currentTheme.accentColor,
            indicatorWeight: 3,
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
            _buildTeamsList(data, currentTheme),
            _buildTournamentsList(data, currentTheme),
            _buildPlayersList(data, currentTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsList(DataProvider data, AppCustomTheme theme) {
    if (data.favoriteTeams.isEmpty)
      return _buildEmptyState("Нет любимых команд", Icons.shield_outlined);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.favoriteTeams.length,
      itemBuilder: (ctx, i) {
        final team = data.favoriteTeams[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: theme.panel(radius: 12),
          child: ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeamScreen(teamId: team.id, name: team.name),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: _buildThemedLogo(team.logoUrl, theme),
            title: Text(
              team.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => data.toggleTeamFavorite(team.id, true),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTournamentsList(DataProvider data, AppCustomTheme theme) {
    if (data.favoriteTournaments.isEmpty)
      return _buildEmptyState("Нет любимых лиг", Icons.emoji_events_outlined);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.favoriteTournaments.length,
      itemBuilder: (ctx, i) {
        final tournament = data.favoriteTournaments[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: theme.panel(radius: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: _buildThemedLogo(tournament.logoUrl, theme),
            title: Text(
              tournament.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () {
              data.selectLeague(tournament);
              context.go('/home');
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => data.toggleTournamentFavorite(tournament.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayersList(DataProvider data, AppCustomTheme theme) {
    if (data.favoritePlayers.isEmpty)
      return _buildEmptyState("Нет любимых игроков", Icons.person_off_outlined);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.favoritePlayers.length,
      itemBuilder: (ctx, i) {
        final player = data.favoritePlayers[i];
        return Card(
          child: ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerScreen(playerId: player.id),
              ),
            ),
            leading: PlayerPhoto(url: player.photoUrl),
            title: Text(
              player.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Матчи за клуб и сборную",
              style: TextStyle(
                color: theme.accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: IconButton(
              tooltip: 'Убрать из избранного',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => data.togglePlayerFavorite(player.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemedLogo(String? url, AppCustomTheme theme) {
    return FootballLogo(url: url, size: 50, padding: 5, framed: true);
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

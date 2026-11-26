import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/auth_gate.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/app_states.dart';
import '../widgets/football_logo.dart';
import '../widgets/match_tile.dart';
import 'team_screen.dart';
import 'player_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this);
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<DataProvider>().fetchFavorites();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final signedIn = context.watch<AuthProvider>().isAuthenticated;
    Widget empty(String title) => data.favoritesLoading
        ? const AppSkeleton()
        : AppEmptyState(
            title: data.favoritesError ?? title,
            message: data.favoritesError != null
                ? 'Проверьте подключение и попробуйте снова.'
                : signedIn
                ? 'Нажмите на звезду рядом с командой, лигой или игроком, чтобы сохранить их здесь.'
                : 'Избранное сохраняется в аккаунте. Матчи доступны и без входа.',
            icon: data.favoritesError != null
                ? Icons.wifi_off_outlined
                : Icons.star_outline,
            actionLabel: data.favoritesError != null
                ? 'Повторить'
                : signedIn
                ? 'К матчам'
                : 'Войти / зарегистрироваться',
            onAction: data.favoritesError != null
                ? data.fetchFavorites
                : signedIn
                ? () => context.go('/home')
                : () => openAuthScreen(context),
          );
    Widget list(String kind, List<Widget> children) => ListView(
      key: PageStorageKey('favorites-$kind'),
      padding: const EdgeInsets.all(16),
      children: children,
    );
    Widget entry({
      required Widget leading,
      required String name,
      required VoidCallback open,
      required VoidCallback remove,
      String? subtitle,
    }) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
        leading: leading,
        title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: subtitle == null ? null : Text(subtitle),
        onTap: open,
        trailing: IconButton(
          tooltip: 'Убрать из избранного',
          icon: Icon(Icons.star, color: Theme.of(context).colorScheme.primary),
          onPressed: remove,
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        bottom: appTabs(context, const [
          'Клубы',
          'Лиги',
          'Игроки',
        ], controller: _tabs),
      ),
      body: Column(
        children: [
          if (data.favoritesError != null &&
              (data.favoriteTeams.isNotEmpty ||
                  data.favoritePlayers.isNotEmpty ||
                  data.favoriteTournaments.isNotEmpty))
            UpdateNotice(
              message: data.favoritesError!,
              onRetry: data.fetchFavorites,
            ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                data.favoriteTeams.isEmpty
                    ? empty('Пока нет любимых команд')
                    : list('teams', [
                        for (final team in data.favoriteTeams)
                          entry(
                            leading: FootballLogo(url: team.logoUrl, size: 36),
                            name: team.name,
                            open: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeamScreen(
                                  teamId: team.id,
                                  name: team.name,
                                ),
                              ),
                            ),
                            remove: () =>
                                data.toggleTeamFavorite(team.id, true),
                          ),
                      ]),
                data.favoriteTournaments.isEmpty
                    ? empty('Пока нет любимых лиг')
                    : list('leagues', [
                        for (final league in data.favoriteTournaments)
                          entry(
                            leading: FootballLogo(
                              url: league.logoUrl,
                              size: 36,
                            ),
                            name: league.name,
                            open: () {
                              data.selectLeague(league);
                              context.go('/home');
                            },
                            remove: () =>
                                data.toggleTournamentFavorite(league.id),
                          ),
                      ]),
                data.favoritePlayers.isEmpty
                    ? empty('Пока нет любимых игроков')
                    : list('players', [
                        for (final player in data.favoritePlayers)
                          entry(
                            leading: PlayerPhoto(
                              url: player.photoUrl,
                              size: 36,
                            ),
                            name: player.name,
                            subtitle: 'Матчи за клуб и сборную',
                            open: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PlayerScreen(playerId: player.id),
                              ),
                            ),
                            remove: () => data.togglePlayerFavorite(player.id),
                          ),
                      ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

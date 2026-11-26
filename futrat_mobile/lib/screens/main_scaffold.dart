import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  final StatefulNavigationShell? navigationShell;
  const MainScaffold({super.key, required this.child, this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: themeProvider.currentTheme.cardBorder),
          ),
        ),
        child: NavigationBar(
          selectedIndex:
              navigationShell?.currentIndex ?? _calculateSelectedIndex(context),
          onDestinationSelected: (index) => _onItemTapped(index, context),
          backgroundColor: themeProvider.currentTheme.cardBg,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Theme.of(context).colorScheme.primaryContainer,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelPadding: EdgeInsets.zero,
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              fontSize: MediaQuery.sizeOf(context).width < 360 ? 11 : 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.sports_soccer),
              label: 'Матчи',
            ),
            NavigationDestination(
              icon: Icon(Icons.leaderboard),
              label: 'Прогнозы',
            ),
            NavigationDestination(icon: Icon(Icons.star), label: 'Избранное'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Профиль'),
          ],
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/leaderboard')) return 1;
    if (location.startsWith('/favorites')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    if (navigationShell != null) {
      navigationShell!.goBranch(
        index,
        initialLocation: index == navigationShell!.currentIndex,
      );
      return;
    }
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/leaderboard');
        break;
      case 2:
        context.go('/favorites');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}

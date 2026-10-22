import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

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
        child: BottomNavigationBar(
          currentIndex: _calculateSelectedIndex(context),
          onTap: (index) => _onItemTapped(index, context),
          selectedItemColor: themeProvider.currentTheme.accentColor,
          unselectedItemColor: themeProvider.currentTheme.dimTextColor,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer),
              label: 'Матчи',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard),
              label: 'Прогнозы',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Избранное'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
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

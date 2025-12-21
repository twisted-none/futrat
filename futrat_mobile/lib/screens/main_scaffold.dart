import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child, // Фон управляется внутри child (экранов)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: AppTheme.neonPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Чтобы поместилось 4 иконки
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Матчи'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Прогнозы'), // НОВОЕ
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Избранное'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
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
      case 0: context.go('/home'); break;
      case 1: context.go('/leaderboard'); break;
      case 2: context.go('/favorites'); break;
      case 3: context.go('/profile'); break;
    }
  }
}
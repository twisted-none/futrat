import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/app_theme.dart'; // Подключаем тему
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/leaderboard_screen.dart'; // НОВЫЙ ЭКРАН
import 'screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authProvider = AuthProvider();
  await authProvider.checkAuth(); 

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: const FutratApp(),
    ),
  );
}

class FutratApp extends StatelessWidget {
  const FutratApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    final router = GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider, 
      redirect: (context, state) {
        final isAuth = authProvider.isAuthenticated;
        final currentLocation = state.uri.path;

        if (!isAuth) {
          return currentLocation == '/login' ? null : '/login';
        }
        if (isAuth) {
          if (currentLocation == '/login') return '/home';
        }
        return null; 
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const AuthScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            GoRoute(path: '/leaderboard', builder: (context, state) => const LeaderboardScreen()), // НОВЫЙ РОУТ
            GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Futrat',
      theme: AppTheme.darkTheme, // ПРИМЕНЯЕМ ТЕМУ
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
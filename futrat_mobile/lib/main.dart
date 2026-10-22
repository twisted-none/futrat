import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'providers/theme_provider.dart';

import 'screens/home_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/forecasts_screen.dart';
import 'screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'IBM Plex Sans',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });

  // Создаем провайдеры заранее
  final authProvider = AuthProvider();
  final themeProvider = ThemeProvider();
  final dataProvider = DataProvider();

  await Future.wait([authProvider.checkAuth(), themeProvider.ready]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: dataProvider),
      ],
      child: const FutratApp(),
    ),
  );
}

class FutratApp extends StatefulWidget {
  const FutratApp({super.key});

  @override
  State<FutratApp> createState() => _FutratAppState();
}

class _FutratAppState extends State<FutratApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<DataProvider>().setLiveUpdatesActive(
      state == AppLifecycleState.resumed,
    );
  }

  late final GoRouter _router = GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const ForecastsScreen(),
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'Futrat',
      debugShowCheckedModeBanner: false,
      // Применяем тему из провайдера
      theme: themeProvider.currentTheme.themeData,
      routerConfig: _router,
    );
  }
}

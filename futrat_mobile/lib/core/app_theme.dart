import 'package:flutter/material.dart';

class AppTheme {
  static const Color almostBlack = Color(0xFF121212);
  static const Color deepPurple = Color(0xFF2E004E);
  static const Color neonPurple = Color(0xFFD500F9);
  static const Color textWhite = Colors.white;
  static const Color textGrey = Colors.white70;

  static BoxDecoration get mainGradient => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [almostBlack, deepPurple],
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: almostBlack, // Резервный фон
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: neonPurple,
      unselectedItemColor: Colors.grey,
    ),
    colorScheme: ColorScheme.dark(
      primary: neonPurple,
      secondary: deepPurple,
      surface: const Color(0xFF1E1E1E),
    ),
  );
}
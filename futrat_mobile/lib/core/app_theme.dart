import 'package:flutter/material.dart';

enum AppThemeType { light, dark }

enum AppAccent {
  red('Красный', Color(0xFFEF5350)),
  yellow('Жёлтый', Color(0xFFF6C945)),
  orange('Оранжевый', Color(0xFFF29538)),
  lightGreen('Светло-зелёный', Color(0xFF8EE8C1)),
  darkGreen('Тёмно-зелёный', Color(0xFF237A50)),
  skyBlue('Голубой', Color(0xFF65C7ED)),
  blue('Синий', Color(0xFF3974D8)),
  purple('Фиолетовый', Color(0xFF9968D9)),
  pink('Розовый', Color(0xFFEB80B0));

  const AppAccent(this.label, this.color);
  final String label;
  final Color color;
}

class AppCustomTheme {
  const AppCustomTheme({
    required this.themeData,
    required this.accentFill,
    required this.scaffoldBg,
    required this.isDark,
  });
  final ThemeData themeData;
  final Color accentFill;
  final Color scaffoldBg;
  final bool isDark;
  Color get accentColor => themeData.colorScheme.primary;
  Color get onAccentColor => themeData.colorScheme.onPrimary;
  Color get onAccentFill => AppTheme.foregroundOn(accentFill);
  Color get textColor => themeData.colorScheme.onSurface;
  Color get dimTextColor => themeData.colorScheme.onSurfaceVariant;
  Color get cardBg => themeData.colorScheme.surface;
  Color get cardBorder => themeData.colorScheme.outlineVariant;
  Color get dividerColor => cardBorder;
  Color get headerBg =>
      isDark ? const Color(0xFF25292F) : const Color(0xFFEBEEF2);
  BoxDecoration get background => BoxDecoration(color: scaffoldBg);
  BoxDecoration panel({double radius = 16}) => BoxDecoration(
    color: cardBg,
    border: Border.all(color: cardBorder),
    borderRadius: BorderRadius.circular(radius),
  );
}

class AppTheme {
  static double _contrast(Color a, Color b) {
    final x = a.computeLuminance(), y = b.computeLuminance();
    return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
  }

  static Color foregroundOn(Color background) =>
      _contrast(Colors.black, background) >= _contrast(Colors.white, background)
      ? Colors.black
      : Colors.white;

  // Labels stay readable; bright button fills retain the selected colour.
  static Color _readableAccent(Color color, Color surface, bool dark) {
    final target = dark ? Colors.white : Colors.black;
    for (var step = 0; step <= 100; step++) {
      final candidate = Color.lerp(color, target, step / 100)!;
      if (_contrast(candidate, surface) >= 4.5) return candidate;
    }
    return target;
  }

  static AppCustomTheme getTheme(
    AppThemeType type, [
    AppAccent accent = AppAccent.lightGreen,
  ]) {
    final dark = type == AppThemeType.dark;
    final bg = dark ? const Color(0xFF121416) : const Color(0xFFF4F5F7);
    final surface = dark ? const Color(0xFF1D2024) : Colors.white;
    final text = dark ? const Color(0xFFF4F6FA) : const Color(0xFF17202B);
    final dim = dark ? const Color(0xFFAFB7C2) : const Color(0xFF596371);
    final border = dark ? const Color(0xFF3C4149) : const Color(0xFFD6DAE0);
    final primary = _readableAccent(accent.color, dark ? surface : bg, dark);
    final onPrimary = foregroundOn(primary);
    final shape = RoundedRectangleBorder(
      side: BorderSide(color: border),
      borderRadius: BorderRadius.circular(16),
    );
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent.color,
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: onPrimary,
          primaryContainer: Color.alphaBlend(
            primary.withValues(alpha: .14),
            surface,
          ),
          onPrimaryContainer: primary,
          secondary: primary,
          onSecondary: onPrimary,
          secondaryContainer: Color.alphaBlend(
            primary.withValues(alpha: .14),
            surface,
          ),
          onSecondaryContainer: primary,
          tertiary: primary,
          onTertiary: onPrimary,
          surface: surface,
          onSurface: text,
          onSurfaceVariant: dim,
          surfaceContainerLowest: bg,
          surfaceContainerLow: surface,
          surfaceContainer: surface,
          surfaceContainerHigh: surface,
          surfaceContainerHighest: dark
              ? const Color(0xFF292D33)
              : const Color(0xFFEBEEF2),
          surfaceTint: Colors.transparent,
          outline: border,
          outlineVariant: border,
        );
    final button = ElevatedButton.styleFrom(
      backgroundColor: accent.color,
      foregroundColor: foregroundOn(accent.color),
      elevation: 0,
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    return AppCustomTheme(
      accentFill: accent.color,
      scaffoldBg: bg,
      isDark: dark,
      themeData: ThemeData(
        useMaterial3: true,
        fontFamily: 'IBMPlexSans',
        colorScheme: scheme,
        scaffoldBackgroundColor: bg,
        canvasColor: surface,
        dividerColor: border,
        appBarTheme: AppBarTheme(
          backgroundColor: bg,
          foregroundColor: text,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: shape,
          clipBehavior: Clip.antiAlias,
        ),
        dialogTheme: DialogThemeData(backgroundColor: surface, shape: shape),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: surface,
          modalBackgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: border),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: dim,
          elevation: 0,
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: surface,
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(style: button),
        filledButtonTheme: FilledButtonThemeData(style: button),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 2),
          ),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: primary,
          unselectedLabelColor: dim,
          indicatorColor: primary,
          dividerColor: border,
        ),
      ),
    );
  }
}

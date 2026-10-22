import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futrat_mobile/core/app_theme.dart';
import 'package:futrat_mobile/providers/theme_provider.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'two neutral themes and nine accents have readable controls and borders',
    () {
      expect(AppThemeType.values, hasLength(2));
      expect(AppAccent.values, hasLength(9));
      for (final mode in AppThemeType.values) {
        final baseline = AppTheme.getTheme(mode, AppAccent.lightGreen);
        for (final accent in AppAccent.values) {
          final theme = AppTheme.getTheme(mode, accent);
          expect(
            theme.themeData.textTheme.bodyMedium!.fontFamily,
            'IBMPlexSans',
          );
          final scheme = theme.themeData.colorScheme;
          expect(theme.scaffoldBg, baseline.scaffoldBg);
          expect(theme.cardBg, baseline.cardBg);
          expect(theme.background.gradient, isNull);
          expect(
            contrast(theme.textColor, theme.cardBg),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(theme.accentColor, theme.cardBg),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(theme.accentColor, theme.scaffoldBg),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(scheme.primary, scheme.onPrimary),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(theme.accentFill, theme.onAccentFill),
            greaterThanOrEqualTo(4.5),
          );
          final shape =
              theme.themeData.cardTheme.shape! as RoundedRectangleBorder;
          expect(shape.side.width, 1);
          expect(shape.side.color, theme.cardBorder);
        }
      }
    },
  );

  test(
    'theme and accent persist independently and restore after restart',
    () async {
      final provider = ThemeProvider();
      await provider.ready;
      expect(provider.currentType, AppThemeType.dark);
      expect(provider.currentAccent, AppAccent.lightGreen);
      await provider.setAccent(AppAccent.yellow);
      await provider.setTheme(AppThemeType.light);
      expect(provider.currentAccent, AppAccent.yellow);
      final restored = ThemeProvider();
      await restored.ready;
      expect(restored.currentType, AppThemeType.light);
      expect(restored.currentAccent, AppAccent.yellow);
      await restored.setTheme(AppThemeType.dark);
      expect(restored.currentAccent, AppAccent.yellow);
      provider.dispose();
      restored.dispose();
    },
  );

  test('all seven legacy choices migrate to a supported pair', () async {
    final legacy = <String, (AppThemeType, AppAccent)>{
      'lightLavender': (AppThemeType.light, AppAccent.purple),
      'softDark': (AppThemeType.dark, AppAccent.purple),
      'purplePink': (AppThemeType.dark, AppAccent.pink),
      'plumPink': (AppThemeType.dark, AppAccent.pink),
      'tealLime': (AppThemeType.dark, AppAccent.lightGreen),
      'navyMint': (AppThemeType.dark, AppAccent.lightGreen),
      'coralBlue': (AppThemeType.dark, AppAccent.red),
    };
    for (final entry in legacy.entries) {
      FlutterSecureStorage.setMockInitialValues({
        'user_theme': 'AppThemeType.${entry.key}',
      });
      final provider = ThemeProvider();
      await provider.ready;
      expect(provider.currentType, entry.value.$1);
      expect(provider.currentAccent, entry.value.$2);
      final restored = ThemeProvider();
      await restored.ready;
      expect(restored.currentAccent, entry.value.$2);
      provider.dispose();
      restored.dispose();
    }
  });

  test('invalid saved values safely use defaults', () async {
    FlutterSecureStorage.setMockInitialValues({
      'appearance_theme': 'unknown',
      'appearance_accent': 'unknown',
    });
    final provider = ThemeProvider();
    await provider.ready;
    expect(provider.currentType, AppThemeType.dark);
    expect(provider.currentAccent, AppAccent.lightGreen);
    provider.dispose();
  });

  test('startup restore cannot overwrite quick user changes', () async {
    FlutterSecureStorage.setMockInitialValues({
      'user_theme': 'AppThemeType.lightLavender',
    });
    final provider = ThemeProvider();
    final accent = provider.setAccent(AppAccent.orange);
    final mode = provider.setTheme(AppThemeType.dark);
    await Future.wait([provider.ready, accent, mode]);
    final restored = ThemeProvider();
    await restored.ready;
    expect(restored.currentType, AppThemeType.dark);
    expect(restored.currentAccent, AppAccent.orange);
    provider.dispose();
    restored.dispose();
  });
}

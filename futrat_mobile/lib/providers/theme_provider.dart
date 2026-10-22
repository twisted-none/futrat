import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    ready = _load();
  }
  final FlutterSecureStorage _storage;
  late final Future<void> ready;
  Future<void> _writes = Future.value();
  int _revision = 0;
  bool _disposed = false;
  AppThemeType _type = AppThemeType.dark;
  AppAccent _accent = AppAccent.lightGreen;
  AppCustomTheme? _theme;
  AppThemeType get currentType => _type;
  AppAccent get currentAccent => _accent;
  AppCustomTheme get currentTheme =>
      _theme ??= AppTheme.getTheme(_type, _accent);

  static const _legacy = <String, (AppThemeType, AppAccent)>{
    'lightLavender': (AppThemeType.light, AppAccent.purple),
    'softDark': (AppThemeType.dark, AppAccent.purple),
    'purplePink': (AppThemeType.dark, AppAccent.pink),
    'plumPink': (AppThemeType.dark, AppAccent.pink),
    'tealLime': (AppThemeType.dark, AppAccent.lightGreen),
    'navyMint': (AppThemeType.dark, AppAccent.lightGreen),
    'coralBlue': (AppThemeType.dark, AppAccent.red),
  };

  Future<void> _load() async {
    final revision = _revision;
    try {
      final values = await Future.wait([
        _storage.read(key: 'appearance_theme'),
        _storage.read(key: 'appearance_accent'),
        _storage.read(key: 'user_theme'),
      ]);
      if (_disposed || revision != _revision) return;
      final legacy = _legacy[values[2]?.split('.').last];
      _type = values[0] == null
          ? legacy?.$1 ?? AppThemeType.dark
          : AppThemeType.values.where((e) => e.name == values[0]).firstOrNull ??
                AppThemeType.dark;
      _accent = values[1] == null
          ? legacy?.$2 ?? AppAccent.lightGreen
          : AppAccent.values.where((e) => e.name == values[1]).firstOrNull ??
                AppAccent.lightGreen;
      _theme = null;
      notifyListeners();
      if (legacy != null && (values[0] == null || values[1] == null)) {
        await _save();
      }
    } catch (error) {
      debugPrint(
        'Appearance preferences could not be restored: ${error.runtimeType}',
      );
    }
  }

  Future<void> setTheme(AppThemeType type) {
    _revision++;
    _type = type;
    _theme = null;
    notifyListeners();
    return _save();
  }

  Future<void> setAccent(AppAccent accent) {
    _revision++;
    _accent = accent;
    _theme = null;
    notifyListeners();
    return _save();
  }

  Future<void> _save() {
    final theme = _type.name, accent = _accent.name;
    return _writes = _writes.then((_) async {
      try {
        await _storage.write(key: 'appearance_theme', value: theme);
        await _storage.write(key: 'appearance_accent', value: accent);
      } catch (error) {
        debugPrint(
          'Appearance preferences could not be saved: ${error.runtimeType}',
        );
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

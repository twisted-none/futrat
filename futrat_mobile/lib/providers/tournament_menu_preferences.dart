import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device preferences, isolated per account; never changes favorite membership.
class TournamentMenuPreferences extends ChangeNotifier {
  TournamentMenuPreferences({
    required this.scope,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage() {
    ready = _load();
  }
  final String scope;
  final FlutterSecureStorage _storage;
  final Map<String, List<String>> _orders = {};
  final Set<String> _collapsed = {};
  late final Future<void> ready;
  Future<void> _writes = Future.value();
  int _revision = 0;
  bool _disposed = false;
  String get _key => 'tournament_menu_v1_$scope';

  Future<void> _load() async {
    final revision = _revision;
    try {
      final raw = await _storage.read(key: _key);
      if (_disposed || revision != _revision || raw == null) return;
      final value = jsonDecode(raw) as Map;
      final orders = value['orders'];
      if (orders is Map) {
        for (final entry in orders.entries) {
          if (entry.key is String && entry.value is List) {
            _orders[entry.key] = (entry.value as List)
                .whereType<String>()
                .toSet()
                .toList();
          }
        }
      }
      final collapsed = value['collapsed'];
      if (collapsed is List) _collapsed.addAll(collapsed.whereType<String>());
      notifyListeners();
    } catch (error) {
      debugPrint('Tournament preferences unavailable: ${error.runtimeType}');
    }
  }

  List<T> ordered<T>(String zone, Iterable<T> items, String Function(T) key) {
    final list = items.toList();
    final saved = _orders[zone] ?? [];
    final ranks = {for (var i = 0; i < saved.length; i++) saved[i]: i};
    final fallback = {
      for (var i = 0; i < list.length; i++) key(list[i]): saved.length + i,
    };
    list.sort(
      (a, b) => (ranks[key(a)] ?? fallback[key(a)]!).compareTo(
        ranks[key(b)] ?? fallback[key(b)]!,
      ),
    );
    return list;
  }

  Future<void> move(
    String zone,
    List<String> visible,
    String source,
    String target,
  ) {
    final from = visible.indexOf(source), to = visible.indexOf(target);
    if (from < 0 || to < 0 || from == to) return Future.value();
    final changed = [...visible]..removeAt(from);
    changed.insert(to, source);
    _orders[zone] = changed;
    return _changed();
  }

  bool isCollapsed(String group) => _collapsed.contains(group);
  Future<void> toggleCollapsed(String group) {
    if (!_collapsed.remove(group)) _collapsed.add(group);
    return _changed();
  }

  Future<void> _changed() {
    _revision++;
    notifyListeners();
    final value = jsonEncode({
      'orders': _orders,
      'collapsed': _collapsed.toList(),
    });
    return _writes = _writes.then((_) async {
      try {
        await _storage.write(key: _key, value: value);
      } catch (error) {
        debugPrint('Tournament preferences not saved: ${error.runtimeType}');
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Owns ordered credential writes and a single in-flight device-session refresh.
class PersistentSession extends ChangeNotifier {
  PersistentSession({required this.storage, required this.transport});
  final FlutterSecureStorage storage;
  final Dio Function() transport;
  Future<void> _writes = Future.value();
  Future<String?>? _refreshing;
  int _generation = 0;
  int get generation => _generation;
  bool _wasRejected = false;
  bool get wasRejected => _wasRejected;

  Future<T> write<T>(Future<T> Function() action) {
    final next = _writes.then((_) => action());
    _writes = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> saveTokens(
    String access,
    String? refresh, {
    required bool Function() isCurrent,
  }) async {
    if (!isCurrent()) return;
    _generation++;
    _refreshing = null;
    await write(() async {
      if (!isCurrent()) return;
      // Do not pair an old account's access token with a new device key if
      // the process stops between credential writes.
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'auth_profile');
      await storage.delete(key: 'auth_refresh_token');
      if (refresh != null && refresh.isNotEmpty) {
        await storage.write(key: 'auth_refresh_token', value: refresh);
      }
      await storage.write(key: 'auth_token', value: access);
    });
  }

  Future<String?> refresh(String? rejectedAccess) {
    if (_refreshing != null) return _refreshing!;
    final pending = _refresh(rejectedAccess, _generation);
    _refreshing = pending;
    return pending.whenComplete(() {
      if (identical(_refreshing, pending)) _refreshing = null;
    });
  }

  Future<String?> _refresh(String? rejectedAccess, int generation) async {
    final key = await storage.read(key: 'auth_refresh_token');
    final previousAccess = await storage.read(key: 'auth_token');
    if (generation != _generation) return null;
    if (rejectedAccess != null && previousAccess != rejectedAccess) {
      return previousAccess;
    }
    if (key == null || key.isEmpty) return null;
    Response<dynamic> response;
    try {
      response = await transport().post(
        '/auth/refresh',
        data: {'refresh_token': key},
      );
    } on DioException catch (error) {
      if (generation == _generation && error.response?.statusCode == 401) {
        await clear(invalid: true);
      }
      rethrow;
    }
    if (generation != _generation) return null;
    final body = response.data;
    final access = body is Map ? body['access_token'] : null;
    if (access is! String || access.isEmpty) {
      throw const FormatException('Invalid refresh response');
    }
    await write(() async {
      if (generation != _generation) return;
      final cached = await storage.read(key: 'auth_profile');
      final refreshedKey = body['refresh_token'];
      await storage.write(
        key: 'auth_refresh_token',
        value: refreshedKey is String && refreshedKey.isNotEmpty
            ? refreshedKey
            : key,
      );
      await storage.write(key: 'auth_token', value: access);
      if (cached != null) {
        try {
          final profile = jsonDecode(cached);
          if (profile is Map<String, dynamic> &&
              profile['token'] == previousAccess) {
            profile['token'] = access;
            await storage.write(
              key: 'auth_profile',
              value: jsonEncode(profile),
            );
          }
        } on FormatException {
          // The profile can be fetched again; a damaged cache is not a logout.
        }
      }
    });
    return generation == _generation ? access : null;
  }

  Future<void> clear({bool revoke = false, bool invalid = false}) async {
    _generation++;
    _refreshing = null;
    _wasRejected = invalid;
    notifyListeners();
    final key = await write(() async {
      final saved = await storage.read(key: 'auth_refresh_token');
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'auth_refresh_token');
      await storage.delete(key: 'auth_profile');
      return saved;
    });
    if (revoke && key != null) {
      try {
        await transport().post('/auth/logout', data: {'refresh_token': key});
      } on DioException {
        // Explicit local logout works offline; an unreachable server cannot
        // acknowledge remote revocation. Never retain the key on the device.
      }
    }
  }
}

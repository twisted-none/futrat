import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';
import '../models/all_models.dart';
import '../core/persistent_session.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({ApiClient? client}) : _client = client ?? ApiClient() {
    _session.addListener(_sessionCleared);
  }
  final ApiClient _client;
  FlutterSecureStorage get _storage => _client.storage;
  PersistentSession get _session => _client.session;
  int _revision = 0;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoginMode = true;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoginMode => _isLoginMode;

  void toggleAuthMode() {
    _isLoginMode = !_isLoginMode;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    if (_isLoading) return;
    final revision = ++_revision;
    try {
      var token = await _storage.read(key: 'auth_token');
      if (revision != _revision) return;
      if (token == null || token.isEmpty) {
        token = await _session.refresh(null);
        if (revision != _revision) return;
      }
      if (token == null || token.isEmpty) {
        _currentUser = null;
        notifyListeners();
        return;
      }
      final cached = await _storage.read(key: 'auth_profile');
      if (revision != _revision) return;
      _currentUser = _cachedUser(cached, token);
      notifyListeners();
      await _fetchProfile(token, revision);
    } on DioException catch (error) {
      if (revision != _revision) return;
      if (error.response?.statusCode == 401) {
        await logout();
      } else {
        _errorMessage =
            'Не удалось проверить вход. Сохранённая сессия остаётся на устройстве';
        notifyListeners();
      }
    } catch (_) {
      if (revision != _revision) return;
      _errorMessage = 'Не удалось восстановить вход. Попробуйте ещё раз позже';
      notifyListeners();
    }
  }

  User? _cachedUser(String? cached, String token) {
    if (cached == null) return null;
    try {
      final session = jsonDecode(cached);
      if (session is! Map || session['token'] != token) return null;
      final user = session['user'];
      if (user is! Map ||
          user['id'] is! int ||
          user['id'] <= 0 ||
          user['username'] is! String ||
          (user['username'] as String).isEmpty) {
        return null;
      }
      return User.fromJson(Map<String, dynamic>.from(user));
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(Future<void> Function() action) {
    return _session.write(action);
  }

  Future<void> register(String username, String password) => _authenticate(
    '/auth/register',
    {'username': username, 'password': password},
    registering: true,
  );

  Future<void> login(String username, String password) => _authenticate(
    '/auth/login',
    {'username': username, 'password': password},
    registering: false,
  );

  Future<void> _authenticate(
    String path,
    Map<String, String> data, {
    required bool registering,
  }) async {
    if (_isLoading) return;
    final revision = ++_revision;
    _errorMessage = null;
    _setLoading(true);
    bool receivedToken = false;
    bool invalidToken = false;
    try {
      final response = await _client.dio.post(path, data: data);
      final token = response.data is Map ? response.data['access_token'] : null;
      if (token is! String || token.isEmpty) throw const FormatException();
      if (revision != _revision) return;
      final refresh = response.data['refresh_token'];
      await _session.saveTokens(
        token,
        refresh is String ? refresh : null,
        isCurrent: () => revision == _revision,
      );
      if (revision != _revision) return;
      _currentUser = null;
      receivedToken = true;
      await _fetchProfile(token, revision);
    } on DioException catch (error) {
      if (revision != _revision) return;
      invalidToken = receivedToken && error.response?.statusCode == 401;
      _errorMessage = receivedToken
          ? (registering
                ? 'Аккаунт создан, но профиль не загрузился. Попробуйте войти'
                : 'Не удалось загрузить профиль. Попробуйте войти ещё раз')
          : _readableError(error);
    } catch (_) {
      if (revision != _revision) return;
      _errorMessage = receivedToken
          ? (registering
                ? 'Аккаунт создан, но профиль не загрузился. Попробуйте войти'
                : 'Не удалось загрузить профиль. Попробуйте войти ещё раз')
          : 'Не удалось завершить вход. Попробуйте ещё раз';
    } finally {
      if (invalidToken && revision == _revision) {
        _currentUser = null;
        try {
          await _session.clear(invalid: true);
        } catch (_) {
          _errorMessage =
              'Не удалось обновить данные входа на устройстве. Попробуйте ещё раз';
        }
      }
      if (revision == _revision) _setLoading(false);
    }
  }

  String _readableError(DioException error) {
    if (error.type == DioExceptionType.connectionError) {
      return 'Не удалось подключиться к серверу. Проверьте соединение и попробуйте ещё раз';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Сервер не отвечает. Попробуйте ещё раз чуть позже';
    }
    final status = error.response?.statusCode;
    if (status != null && status >= 500) {
      return 'На сервере произошла ошибка. Попробуйте ещё раз позже';
    }
    if (status == 401) return 'Неверный никнейм или пароль';
    final body = error.response?.data;
    final detail = body is Map ? body['detail'] : null;
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail is List && detail.isNotEmpty && detail.first is Map) {
      final item = detail.first as Map;
      final location = item['loc'];
      final field = location is List && location.isNotEmpty
          ? location.last
          : null;
      if (field == 'password') {
        return 'Пароль должен содержать не менее 6 символов';
      }
      if (field == 'username' || field == 'email') {
        return 'Никнейм должен содержать не менее 3 символов';
      }
    }
    if (status == 409) return 'Этот никнейм уже занят';
    if (status == 422) return 'Проверьте никнейм и пароль';
    return 'Не удалось выполнить запрос. Проверьте соединение и попробуйте ещё раз';
  }

  Future<void> fetchProfile() async {
    final revision = _revision;
    final token = await _storage.read(key: 'auth_token');
    if (token != null && revision == _revision) {
      await _fetchProfile(token, revision);
    }
  }

  Future<void> _fetchProfile(String token, int revision) async {
    final response = await _client.dio.get(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (revision != _revision) return;
    final user = User.fromJson(response.data);
    final verifiedToken = await _storage.read(key: 'auth_token');
    if (revision != _revision || verifiedToken == null) return;
    await _write(() async {
      if (revision != _revision) return;
      await _storage.write(
        key: 'auth_profile',
        value: jsonEncode({
          'token': verifiedToken,
          'user': {'id': user.id, 'username': user.username},
        }),
      );
    });
    if (revision != _revision) return;
    _currentUser = user;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _session.clear(revoke: true);
  }

  void _sessionCleared() {
    _revision++;
    _currentUser = null;
    _isLoading = false;
    _errorMessage = _session.wasRejected
        ? 'Сессия недействительна. Войдите снова'
        : null;
    notifyListeners();
  }

  @override
  void dispose() {
    _session.removeListener(_sessionCleared);
    _revision++;
    super.dispose();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}

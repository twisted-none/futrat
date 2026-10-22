import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';
import '../models/all_models.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

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
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      try {
        await fetchProfile();
      } catch (e) {
        await logout();
      }
    } else {
      _currentUser = null;
      notifyListeners();
    }
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
    _errorMessage = null;
    _setLoading(true);
    bool receivedToken = false;
    try {
      final response = await _client.dio.post(path, data: data);
      final token = response.data is Map ? response.data['access_token'] : null;
      if (token is! String || token.isEmpty) throw const FormatException();
      await _storage.write(key: 'auth_token', value: token);
      receivedToken = true;
      await fetchProfile();
    } on DioException catch (error) {
      _errorMessage = receivedToken
          ? (registering
                ? 'Аккаунт создан, но профиль не загрузился. Попробуйте войти'
                : 'Не удалось загрузить профиль. Попробуйте войти ещё раз')
          : _readableError(error);
    } catch (_) {
      _errorMessage = receivedToken
          ? (registering
                ? 'Аккаунт создан, но профиль не загрузился. Попробуйте войти'
                : 'Не удалось загрузить профиль. Попробуйте войти ещё раз')
          : 'Не удалось завершить вход. Попробуйте ещё раз';
    } finally {
      if (_errorMessage != null && receivedToken) {
        _currentUser = null;
        try {
          await _storage.delete(key: 'auth_token');
        } catch (_) {
          _errorMessage =
              'Не удалось обновить данные входа на устройстве. Попробуйте ещё раз';
        }
      }
      _setLoading(false);
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
    try {
      final response = await _client.dio.get('/auth/me');
      _currentUser = User.fromJson(response.data);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
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

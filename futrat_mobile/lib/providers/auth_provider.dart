import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';
import '../models/all_models.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuth() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      try {
        await fetchProfile();
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> register(String email, String username, String password) async {
    _setLoading(true);
    try {
      final response = await _client.dio.post('/auth/register', data: {
        "email": email,
        "username": username,
        "password": password
      });
      final token = response.data['access_token'];
      await _storage.write(key: 'auth_token', value: token);
      await fetchProfile();
    } on DioException catch (e) {
      _errorMessage = e.response?.data['detail'] ?? "Ошибка регистрации";
    } catch (e) {
      _errorMessage = "Произошла ошибка: $e";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _client.dio.post('/auth/login', data: {
        "email": email,
        "password": password
      });
      final token = response.data['access_token'];
      await _storage.write(key: 'auth_token', value: token);
      await fetchProfile();
    } on DioException catch (e) {
      _errorMessage = e.response?.data['detail'] ?? "Неверный логин или пароль";
    } catch (e) {
      _errorMessage = "Произошла ошибка: $e";
    } finally {
      _setLoading(false);
    }
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
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null;
    notifyListeners();
  }
  
  // Просто очистка текста ошибки, используем аккуратно
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
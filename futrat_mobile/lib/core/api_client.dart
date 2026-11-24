import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';
import 'persistent_session.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  factory ApiClient.configured({
    required Dio dio,
    FlutterSecureStorage? storage,
  }) => ApiClient._internal(transport: dio, secureStorage: storage);

  late Dio dio;

  // Общий доступ к защищённому хранилищу токена и сохранённого профиля.
  final FlutterSecureStorage storage;
  late final PersistentSession session;

  ApiClient._internal({Dio? transport, FlutterSecureStorage? secureStorage})
    : storage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          ) {
    dio =
        transport ??
        Dio(
          BaseOptions(
            baseUrl: AppConstants.baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );
    session = PersistentSession(storage: storage, transport: () => dio);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_credentialEndpoint(options.path)) return handler.next(options);
          options.extra['auth_generation'] = session.generation;
          final token = await storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final request = error.requestOptions;
          if (error.response?.statusCode != 401 ||
              _credentialEndpoint(request.path) ||
              request.extra['auth_retried'] == true ||
              request.extra['auth_generation'] != session.generation ||
              request.headers['Authorization'] == null) {
            return handler.next(error);
          }
          try {
            final bearer = request.headers['Authorization'] as String;
            final access = await session.refresh(
              bearer.startsWith('Bearer ') ? bearer.substring(7) : null,
            );
            if (access == null) return handler.next(error);
            request.extra['auth_retried'] = true;
            request.headers['Authorization'] = 'Bearer $access';
            return handler.resolve(await dio.fetch(request));
          } on DioException catch (refreshError) {
            // Preserve refresh network/5xx failures, so callers don't interpret
            // the original expired-access 401 as a revoked device session.
            return handler.reject(refreshError);
          } catch (refreshError) {
            return handler.reject(
              DioException(requestOptions: request, error: refreshError),
            );
          }
        },
      ),
    );
  }

  static bool _credentialEndpoint(String path) => const [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/logout',
  ].contains(path);
}

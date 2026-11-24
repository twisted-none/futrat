import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futrat_mobile/core/api_client.dart';
import 'package:futrat_mobile/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio original, fake;
  late AuthProvider auth;
  final storage = ApiClient().storage;
  int? status;
  bool offline = false;
  var userId = 1;
  var nickname = 'Player';
  var token = 'fake-token-1';
  Completer<void>? release, started;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    original = ApiClient().dio;
    status = null;
    offline = false;
    userId = 1;
    nickname = 'Player';
    token = 'fake-token-1';
    release = started = null;
    fake = Dio(BaseOptions(baseUrl: 'https://fixture.test'));
    fake.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.path == '/auth/me') {
            started?.complete();
            await release?.future;
            if (offline || status != null) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: offline
                      ? DioExceptionType.connectionError
                      : DioExceptionType.badResponse,
                  response: offline
                      ? null
                      : Response(requestOptions: options, statusCode: status),
                ),
              );
              return;
            }
          }
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: options.path == '/auth/me'
                  ? {'id': userId, 'username': nickname, 'email': null}
                  : {'access_token': token},
            ),
          );
        },
      ),
    );
    ApiClient().dio = fake;
    auth = AuthProvider();
  });
  tearDown(() {
    auth.dispose();
    fake.close(force: true);
    ApiClient().dio = original;
  });

  Future<void> restart() async {
    auth.dispose();
    auth = AuthProvider();
    await auth.checkAuth();
  }

  test('saved login restores after cold start', () async {
    await auth.login('Player', 'secret');
    await restart();
    expect(auth.currentUser?.id, 1);
    expect(auth.currentUser?.username, 'Player');
    expect(await storage.read(key: 'auth_token'), 'fake-token-1');
  });

  for (final failure in ['offline', '500', '503', '403', '429']) {
    test('cold start retains token and profile on $failure', () async {
      await auth.login('Player', 'secret');
      offline = failure == 'offline';
      status = int.tryParse(failure);
      await restart();
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser?.username, 'Player');
      expect(await storage.read(key: 'auth_token'), 'fake-token-1');
      offline = false;
      status = null;
      nickname = 'Updated Player';
      await auth.checkAuth();
      expect(auth.currentUser?.username, 'Updated Player');
    });
  }

  test('401 clears invalid or expired session and cached profile', () async {
    await auth.login('Player', 'secret');
    status = 401;
    await restart();
    expect(auth.isAuthenticated, isFalse);
    expect(await storage.read(key: 'auth_token'), isNull);
    expect(await storage.read(key: 'auth_profile'), isNull);
  });

  test(
    'explicit logout removes session and does not restore on restart',
    () async {
      await auth.login('Player', 'secret');
      await auth.logout();
      expect(await storage.read(key: 'auth_token'), isNull);
      expect(await storage.read(key: 'auth_profile'), isNull);
      await restart();
      expect(auth.isAuthenticated, isFalse);
    },
  );

  test(
    'legacy token survives offline start and gains a cache after recovery',
    () async {
      await storage.write(key: 'auth_token', value: token);
      offline = true;
      await auth.checkAuth();
      expect(await storage.read(key: 'auth_token'), token);
      expect(auth.isAuthenticated, isFalse);
      offline = false;
      await auth.checkAuth();
      offline = true;
      await restart();
      expect(auth.currentUser?.id, 1);
    },
  );

  test(
    'cache without a token or for another token cannot authenticate',
    () async {
      await auth.login('Player', 'secret');
      await storage.delete(key: 'auth_token');
      offline = true;
      await restart();
      expect(auth.isAuthenticated, isFalse);
      await storage.write(key: 'auth_token', value: 'different-fake-token');
      await auth.checkAuth();
      expect(auth.isAuthenticated, isFalse);
    },
  );

  test(
    'corrupt cache does not delete token or prevent online recovery',
    () async {
      await storage.write(key: 'auth_token', value: token);
      await storage.write(key: 'auth_profile', value: 'broken json');
      await auth.checkAuth();
      expect(auth.currentUser?.id, 1);
      expect(await storage.read(key: 'auth_token'), token);
    },
  );

  test(
    'failed profile after account switch never restores previous account',
    () async {
      await auth.login('Player', 'secret');
      token = 'fake-token-2';
      userId = 2;
      nickname = 'Second';
      offline = true;
      await auth.login('Second', 'secret');
      await restart();
      expect(auth.isAuthenticated, isFalse);
      expect(await storage.read(key: 'auth_token'), 'fake-token-2');
      offline = false;
      await auth.checkAuth();
      expect(auth.currentUser?.id, 2);
    },
  );

  test('logout during profile request cannot resurrect a session', () async {
    await auth.login('Player', 'secret');
    started = Completer<void>();
    release = Completer<void>();
    final check = auth.checkAuth();
    await started!.future;
    await auth.logout();
    release!.complete();
    await check;
    expect(auth.isAuthenticated, isFalse);
    expect(await storage.read(key: 'auth_token'), isNull);
    expect(await storage.read(key: 'auth_profile'), isNull);
  });

  test('a new failed login cannot cancel pending logout cleanup', () async {
    await auth.login('Player', 'secret');
    fake.interceptors.clear();
    fake.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(requestOptions: options, statusCode: 401),
            ),
          );
        },
      ),
    );
    final exiting = auth.logout();
    await auth.login('Wrong', 'wrong-password');
    await exiting;
    expect(auth.isAuthenticated, isFalse);
    expect(await storage.read(key: 'auth_token'), isNull);
    expect(await storage.read(key: 'auth_profile'), isNull);
  });

  test(
    'cache stores only session binding, id and nickname, never password',
    () async {
      await auth.login('Player', 'private-password');
      final cached =
          jsonDecode((await storage.read(key: 'auth_profile'))!) as Map;
      expect(cached['user'], {'id': 1, 'username': 'Player'});
      expect(cached.toString(), isNot(contains('private-password')));
    },
  );
}

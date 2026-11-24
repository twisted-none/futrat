import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futrat_mobile/core/api_client.dart';
import 'package:futrat_mobile/providers/auth_provider.dart';

class SessionAdapter implements HttpClientAdapter {
  int refreshes = 0, attempts = 0, refreshStatus = 200;
  bool expired = true, alwaysReject = false;
  Completer<void>? release, started;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    if (options.path == '/auth/refresh') {
      refreshes++;
      started?.complete();
      await release?.future;
      return ResponseBody.fromString(
        jsonEncode(
          refreshStatus == 200
              ? {
                  'access_token': 'new-test-access',
                  'refresh_token': 'test-refresh-key',
                }
              : {'detail': 'Refresh failed'},
        ),
        refreshStatus,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path == '/auth/logout') {
      return ResponseBody.fromString('', 204);
    }
    attempts++;
    final rejected =
        alwaysReject ||
        (expired &&
            options.headers['Authorization'] != 'Bearer new-test-access');
    return ResponseBody.fromString(
      jsonEncode(
        rejected ? {'detail': 'Expired'} : {'id': 1, 'username': 'Player'},
      ),
      rejected ? 401 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ApiClient client;
  late SessionAdapter adapter;
  late AuthProvider auth;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'old-test-access',
      'auth_refresh_token': 'test-refresh-key',
      'auth_profile': jsonEncode({
        'token': 'old-test-access',
        'user': {'id': 1, 'username': 'Player'},
      }),
    });
    adapter = SessionAdapter();
    client = ApiClient.configured(
      dio: Dio(BaseOptions(baseUrl: 'https://fixture.test'))
        ..httpClientAdapter = adapter,
    );
    auth = AuthProvider(client: client);
  });
  tearDown(() {
    auth.dispose();
    client.dio.close(force: true);
  });

  test(
    'expired access refreshes and cold-start profile remains signed in',
    () async {
      await auth.checkAuth();
      expect(auth.currentUser?.username, 'Player');
      expect(adapter.refreshes, 1);
      expect(await client.storage.read(key: 'auth_token'), 'new-test-access');
      final cache = jsonDecode(
        (await client.storage.read(key: 'auth_profile'))!,
      );
      expect(cache['token'], 'new-test-access');
    },
  );

  test('a device key recovers a missing access token', () async {
    await client.storage.delete(key: 'auth_token');
    await auth.checkAuth();
    expect(auth.currentUser?.username, 'Player');
    expect(adapter.refreshes, 1);
    expect(await client.storage.read(key: 'auth_token'), 'new-test-access');
  });

  test(
    'concurrent 401s share one refresh and retry each request once',
    () async {
      adapter.release = Completer<void>();
      adapter.started = Completer<void>();
      final requests = Future.wait(
        List.generate(3, (_) => client.dio.get('/protected')),
      );
      await adapter.started!.future;
      adapter.release!.complete();
      expect((await requests).every((r) => r.statusCode == 200), isTrue);
      expect(adapter.refreshes, 1);
    },
  );

  test(
    'temporary refresh failure retains the complete session for retry',
    () async {
      adapter.refreshStatus = 503;
      await auth.checkAuth();
      expect(auth.isAuthenticated, isTrue);
      expect(
        await client.storage.read(key: 'auth_refresh_token'),
        'test-refresh-key',
      );
      expect(await client.storage.read(key: 'auth_token'), 'old-test-access');
      adapter.refreshStatus = 200;
      await auth.checkAuth();
      expect(auth.isAuthenticated, isTrue);
    },
  );

  test('revoked refresh clears session and account state', () async {
    adapter.refreshStatus = 401;
    await auth.checkAuth();
    expect(auth.isAuthenticated, isFalse);
    expect(auth.errorMessage, contains('Сессия'));
    for (final key in ['auth_token', 'auth_refresh_token', 'auth_profile']) {
      expect(await client.storage.read(key: key), isNull);
    }
    expect(adapter.refreshes, 1);
  });

  test(
    'logout while refresh is pending cannot resurrect credentials',
    () async {
      adapter.release = Completer<void>();
      adapter.started = Completer<void>();
      final request = client.dio.get('/protected');
      final failure = expectLater(request, throwsA(isA<DioException>()));
      await adapter.started!.future;
      await auth.logout();
      adapter.release!.complete();
      await failure;
      expect(await client.storage.read(key: 'auth_token'), isNull);
      expect(await client.storage.read(key: 'auth_refresh_token'), isNull);
      expect(auth.isAuthenticated, isFalse);
    },
  );

  test('a second 401 is not retried indefinitely', () async {
    adapter.alwaysReject = true;
    await expectLater(
      client.dio.post('/protected', data: {'rating': 8}),
      throwsA(isA<DioException>()),
    );
    expect(adapter.refreshes, 1);
    expect(adapter.attempts, 2);
  });

  test('credential rejection at login never triggers a refresh', () async {
    await expectLater(
      client.dio.post('/auth/login'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.refreshes, 0);
    expect(
      await client.storage.read(key: 'auth_refresh_token'),
      'test-refresh-key',
    );
  });
}

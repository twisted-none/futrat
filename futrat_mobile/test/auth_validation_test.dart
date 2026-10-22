import 'package:dio/dio.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:futrat_mobile/core/api_client.dart';
import 'package:futrat_mobile/providers/auth_provider.dart';
import 'package:futrat_mobile/screens/auth_screen.dart';

void main() {
  late Dio original, fake;
  late AuthProvider auth;
  final requests = <RequestOptions>[];
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    requests.clear();
    original = ApiClient().dio;
    fake = Dio(BaseOptions(baseUrl: 'http://fixture.test'));
    ApiClient().dio = fake;
    auth = AuthProvider();
  });
  tearDown(() {
    auth.dispose();
    fake.close(force: true);
    ApiClient().dio = original;
  });
  void fail({
    int? code,
    dynamic data,
    DioExceptionType type = DioExceptionType.badResponse,
  }) {
    fake.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.reject(
            DioException(
              requestOptions: options,
              type: type,
              response: code == null
                  ? null
                  : Response(
                      requestOptions: options,
                      statusCode: code,
                      data: data,
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<void> host(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: AuthScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'registration has two fields and rejects empty or short values locally',
    (tester) async {
      fail(type: DioExceptionType.connectionError);
      await host(tester);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsNothing);
      await press(tester, 'Создать аккаунт');
      expect(find.text('Введите никнейм'), findsOneWidget);
      expect(find.text('Введите пароль'), findsOneWidget);
      expect(requests, isEmpty);
      await tester.enterText(find.byType(TextFormField).first, ' ab ');
      await tester.enterText(find.byType(TextFormField).last, '12345');
      await press(tester, 'Создать аккаунт');
      expect(find.textContaining('не менее 3'), findsOneWidget);
      expect(find.textContaining('не менее 6'), findsOneWidget);
      expect(requests, isEmpty);
    },
  );

  testWidgets(
    'registration preserves server errors and sends no email or trimmed password',
    (tester) async {
      fail(code: 409, data: {'detail': 'Этот никнейм уже занят'});
      await host(tester);
      await tester.enterText(find.byType(TextFormField).first, ' Player ');
      await tester.enterText(find.byType(TextFormField).last, ' secret ');
      await press(tester, 'Создать аккаунт');
      expect(requests.single.data, {
        'username': 'Player',
        'password': ' secret ',
      });
      expect(find.text('Этот никнейм уже занят'), findsOneWidget);
      expect(auth.isLoading, isFalse);
      expect(auth.isAuthenticated, isFalse);
      await tester.enterText(find.byType(TextFormField).first, 'Other');
      await tester.pumpAndSettle();
      expect(find.text('Этот никнейм уже занят'), findsNothing);
    },
  );

  testWidgets('login shows readable authentication and network errors', (
    tester,
  ) async {
    fail(code: 401, data: {'detail': 'Неверный никнейм или пароль'});
    await host(tester);
    await press(tester, 'Уже есть аккаунт? Войти');
    await tester.enterText(find.byType(TextFormField).first, 'Player');
    await tester.enterText(find.byType(TextFormField).last, 'wrong');
    await press(tester, 'ВОЙТИ');
    expect(find.text('Неверный никнейм или пароль'), findsOneWidget);
    fake.interceptors.clear();
    fail(type: DioExceptionType.connectionError);
    await press(tester, 'ВОЙТИ');
    expect(find.textContaining('подключиться к серверу'), findsOneWidget);
    expect(auth.isLoading, isFalse);
  });

  test(
    'structured validation details and server failures become plain messages',
    () async {
      fail(
        code: 422,
        data: {
          'detail': [
            {
              'loc': ['body', 'password'],
              'msg': 'String should have at least 6 characters',
              'input': 'private',
            },
          ],
        },
      );
      await auth.login('Player', 'wrong');
      expect(auth.errorMessage, contains('6'));
      expect(auth.errorMessage, isNot(contains('private')));
      fake.interceptors.clear();
      fail(code: 500, data: {'detail': 'internal database error'});
      await auth.login('Player', 'wrong');
      expect(auth.errorMessage, contains('сервере'));
      expect(auth.errorMessage, isNot(contains('database')));
    },
  );

  test('successful nickname login accepts a profile without email', () async {
    fake.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: options.path == '/auth/me'
                  ? {'id': 1, 'username': 'Player', 'email': null}
                  : {'access_token': 'fake-test-token', 'token_type': 'bearer'},
            ),
          );
        },
      ),
    );
    await auth.login('Player', 'secret');
    expect(auth.isAuthenticated, isTrue);
    expect(auth.errorMessage, isNull);
    expect(requests.first.data, {'username': 'Player', 'password': 'secret'});
  });

  test(
    'profile failure after registration explains that the account was created',
    () async {
      fake.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/auth/me') {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                ),
              );
            } else {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'access_token': 'fake-test-token'},
                ),
              );
            }
          },
        ),
      );
      await auth.register('Player', 'secret');
      expect(auth.errorMessage, startsWith('Аккаунт создан'));
      expect(auth.isLoading, isFalse);
      expect(auth.isAuthenticated, isFalse);
    },
  );

  test(
    'repeated submission during an active request does not duplicate login',
    () async {
      final release = Completer<void>();
      fake.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            requests.add(options);
            if (options.path != '/auth/me') await release.future;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: options.path == '/auth/me'
                    ? {'id': 1, 'username': 'Player', 'email': null}
                    : {'access_token': 'fake-test-token'},
              ),
            );
          },
        ),
      );
      final first = auth.login('Player', 'secret');
      await auth.login('Player', 'secret');
      release.complete();
      await first;
      expect(requests.where((r) => r.path == '/auth/login'), hasLength(1));
      expect(auth.isAuthenticated, isTrue);
    },
  );
}

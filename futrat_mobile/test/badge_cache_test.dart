import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'football_logo_test.dart' show badge;
import 'package:futrat_mobile/core/badge_cache.dart';

void main() {
  late Directory root;
  late Uint8List png;
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    root = await Directory.systemTemp.createTemp('futrat-badge-test-');
    png = (await badge(Colors.black)).bytes;
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });
  test(
    'concurrent requests share one download; artwork survives restart',
    () async {
      var calls = 0;
      final release = Completer<void>();
      final cache = BadgeCache(
        directory: () async => root,
        download: (_) async {
          calls++;
          await release.future;
          return png;
        },
      );
      final first = cache.get('https://fixture.test/team.png');
      final second = cache.get('https://fixture.test/team.png');
      release.complete();
      final files = await Future.wait([first, second]);
      expect(calls, 1);
      expect(files[0]?.path, files[1]?.path);
      final restarted = BadgeCache(
        directory: () async => root,
        download: (_) async => throw StateError('offline'),
      );
      expect(
        (await restarted.get('https://fixture.test/team.png'))?.path,
        files[0]?.path,
      );
    },
  );
  test(
    'failed/HTML responses are not permanently cached and can retry',
    () async {
      var now = DateTime.utc(2026);
      var calls = 0;
      final cache = BadgeCache(
        directory: () async => root,
        now: () => now,
        download: (_) async =>
            ++calls == 1 ? Uint8List.fromList('HTML'.codeUnits) : png,
      );
      expect(await cache.get('https://fixture.test/team'), isNull);
      expect(await cache.get('https://fixture.test/team'), isNull);
      expect(calls, 1);
      now = now.add(const Duration(minutes: 2));
      expect(await cache.get('https://fixture.test/team'), isNotNull);
    },
  );
  test('prefetch deduplicates and bounds concurrent downloads', () async {
    var active = 0, peak = 0, calls = 0;
    final cache = BadgeCache(
      directory: () async => root,
      download: (_) async {
        active++;
        calls++;
        if (active > peak) peak = active;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        active--;
        return png;
      },
    );
    final urls = List.generate(12, (i) => 'https://fixture.test/$i');
    await Future.wait([
      cache.prefetch([...urls, ...urls]),
      cache.get(urls.first),
    ]);
    expect(calls, 12);
    expect(peak, lessThanOrEqualTo(4));
    expect(peak, greaterThan(1));
  });
  test('invalid URLs do not reach the download transport', () async {
    var calls = 0;
    final cache = BadgeCache(
      directory: () async => root,
      download: (_) async {
        calls++;
        return png;
      },
    );
    for (final url in [
      null,
      '',
      'file:///etc/passwd',
      'https://user:secret@fixture.test',
    ]) {
      expect(await cache.get(url), isNull);
    }
    expect(calls, 0);
  });

  test(
    'truncated PNG is rejected even with the correct file signature',
    () async {
      final cache = BadgeCache(
        directory: () async => root,
        download: (_) async => Uint8List.fromList([...png.take(8), 0]),
      );
      expect(await cache.get('https://fixture.test/broken'), isNull);
      expect(
        await root
            .list(recursive: true)
            .where((file) => file.path.endsWith('.png'))
            .length,
        0,
      );
    },
  );

  for (final source in [
    'https://a.espncdn.com/i/leaguelogos/soccer/500/106.png',
    'https://media.goal-api.com/badges/logo_leagues/275_cup.png',
  ]) {
    test(
      'original badge downloads without depending on the proxy: $source',
      () async {
        final requested = <String>[];
        final dio = Dio();
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              requested.add(request.uri.toString());
              expect(request.headers.containsKey('Authorization'), isFalse);
              handler.resolve(
                Response(requestOptions: request, data: png, statusCode: 200),
              );
            },
          ),
        );
        final bytes = await BadgeDownloader(transport: dio).download(source);
        expect(bytes.take(8), png.take(8));
        expect(requested, [source]);
        dio.close(force: true);
      },
    );
  }

  for (final failure in ['403', 'invalid image', 'oversized response']) {
    test('proxy fallback handles $failure from the original source', () async {
      const source = 'https://fixture.test/badge';
      final requested = <String>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requested.add(request.uri.toString());
            if (request.uri.host == 'fixture.test') {
              if (failure == '403') {
                handler.reject(
                  DioException(
                    requestOptions: request,
                    response: Response(
                      requestOptions: request,
                      statusCode: 403,
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );
                return;
              }
              handler.resolve(
                Response(
                  requestOptions: request,
                  statusCode: 200,
                  data: failure == 'invalid image'
                      ? Uint8List.fromList('HTML'.codeUnits)
                      : Uint8List(BadgeCache.maxBytes + 1),
                ),
              );
              return;
            }
            handler.resolve(
              Response(requestOptions: request, statusCode: 200, data: png),
            );
          },
        ),
      );
      final bytes = await BadgeDownloader(transport: dio).download(source);
      expect(bytes.take(8), png.take(8));
      expect(requested, [source, BadgeCache.proxyUrl(source)]);
      dio.close(force: true);
    });
  }

  test(
    'original and proxy failures never leave an image in permanent storage',
    () async {
      final dio = Dio();
      var calls = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            calls++;
            handler.resolve(
              Response(
                requestOptions: request,
                data: [1, 2, 3],
                statusCode: 200,
              ),
            );
          },
        ),
      );
      final cache = BadgeCache(
        directory: () async => root,
        download: BadgeDownloader(transport: dio).download,
      );
      expect(await cache.get('https://fixture.test/broken'), isNull);
      expect(calls, 2);
      expect(
        await root
            .list(recursive: true)
            .where((f) => f.path.endsWith('.png'))
            .length,
        0,
      );
      dio.close(force: true);
    },
  );
}

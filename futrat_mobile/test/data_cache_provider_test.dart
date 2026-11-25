import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futrat_mobile/core/api_client.dart';
import 'package:futrat_mobile/core/badge_cache.dart';
import 'package:futrat_mobile/core/public_data_cache.dart';
import 'package:futrat_mobile/providers/data_provider.dart';
import 'live_matches_test.dart' show game;

class MemoryDailyCache extends PublicDataCache {
  MemoryDailyCache(this.now) : super(origin: 'https://fixture.test');
  final DateTime Function() now;
  DailySnapshot? snapshot;
  int expirations = 0;
  @override
  Future<DailySnapshot?> read() async =>
      snapshot?.day == moscowDay(now()) ? snapshot : null;
  @override
  Future<void> save(DailySnapshot value) async {
    snapshot = value;
  }

  @override
  Future<void> expire() async {
    snapshot = null;
    expirations++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late DateTime now;
  late Dio dio;
  late ApiClient client;
  late PublicDataCache cache;
  late BadgeCache badges;
  final providers = <DataProvider>[];
  final counts = <String, int>{};
  var offline = false;
  var score = 0;
  List<Map<String, dynamic>> artwork = [];
  Completer<void>? leaderboard;
  DataProvider create() {
    final data = DataProvider(
      client: client,
      cache: cache,
      badges: badges,
      now: () => now,
    );
    providers.add(data);
    return data;
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 30));

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('futrat-provider-test-');
    now = DateTime.utc(2026, 11, 25, 20, 59);
    counts.clear();
    offline = false;
    score = 0;
    artwork = [];
    leaderboard = null;
    dio = Dio(BaseOptions(baseUrl: 'https://fixture.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) async {
          counts.update(request.path, (n) => n + 1, ifAbsent: () => 1);
          if (request.path == '/users/leaderboard') await leaderboard?.future;
          if (offline) {
            handler.reject(
              DioException(
                requestOptions: request,
                type: DioExceptionType.connectionError,
              ),
            );
            return;
          }
          final data = switch (request.path) {
            '/api/team-badges' => artwork,
            '/api/tournaments' => [
              {'id': 31, 'name': 'Cup', 'type': 'Cup'},
            ],
            '/api/matches' => [
              game(1, 'IN_PLAY', now.subtract(const Duration(minutes: 20))),
            ],
            '/api/matches/updates' => [
              {
                'id': 1,
                'date_time': now
                    .subtract(const Duration(minutes: 20))
                    .toIso8601String(),
                'score_home': score,
                'score_away': 0,
                'clock': "25'",
                'status': 'IN_PLAY',
              },
            ],
            _ => [],
          };
          handler.resolve(
            Response(requestOptions: request, statusCode: 200, data: data),
          );
        },
      ),
    );
    client = ApiClient.configured(dio: dio);
    cache = PublicDataCache(
      origin: dio.options.baseUrl,
      directory: () async => root,
      now: () => now,
    );
    badges = BadgeCache(
      directory: () async => root,
      download: (_) async => throw StateError('no badge URLs'),
    );
  });
  tearDown(() async {
    leaderboard?.complete();
    for (final provider in providers) {
      provider.dispose();
    }
    providers.clear();
    await settle();
    await cache.expire();
    dio.close(force: true);
    badges.dispose();
    await root.delete(recursive: true);
  });

  test(
    'same-day cold start uses local fixtures even with an offline server',
    () async {
      final first = create();
      await first.initData();
      await settle();
      await cache.read();
      offline = true;
      final second = create();
      await second.initData();
      expect(second.isLoading, isFalse);
      expect(second.matches.single.id, 1);
      expect(counts['/api/matches'], 1);
      expect(counts['/api/tournaments'], 1);
    },
  );
  test('slow personal data does not block the match list', () async {
    leaderboard = Completer<void>();
    final provider = create();
    await provider.initData();
    expect(leaderboard!.isCompleted, isFalse);
    expect(provider.isLoading, isFalse);
    expect(provider.matches.single.id, 1);
    await provider.initData();
    expect(counts['/api/matches'], 1);
  });
  test(
    'live patches update disk scores without reloading the season',
    () async {
      final provider = create();
      await provider.initData();
      await settle();
      score = 3;
      await provider.fetchLiveUpdates();
      final saved = await cache.read();
      expect(provider.allMatches.single.scoreHome, 3);
      expect(saved?.matches.single['score_home'], 3);
      expect(counts['/api/matches'], 1);
    },
  );
  test(
    'resume after MSK midnight expires the old cache and loads the new day',
    () async {
      final provider = create();
      await provider.initData();
      await settle();
      now = DateTime.utc(2026, 11, 25, 21, 1);
      provider.setLiveUpdatesActive(false);
      provider.setLiveUpdatesActive(true);
      await settle();
      await provider.initData();
      expect(counts['/api/matches'], 2);
      expect(counts['/api/tournaments'], 2);
      expect((await cache.read())?.day, '2026-11-26');
    },
  );
  test('invalid cached model falls back to fresh network data', () async {
    await cache.save(
      DailySnapshot(
        day: moscowDay(now),
        matches: [
          {'id': 'bad'},
        ],
        tournaments: [],
      ),
    );
    final provider = create();
    await provider.initData();
    expect(provider.allMatches.single.id, 1);
    expect(counts['/api/matches'], 1);
  });

  testWidgets('active app rolls its daily snapshot at Moscow midnight', (
    tester,
  ) async {
    final memory = MemoryDailyCache(() => now);
    final provider = DataProvider(
      client: client,
      cache: memory,
      badges: badges,
      now: () => now,
    );
    providers.add(provider);
    await tester.runAsync(provider.initData);
    await tester.runAsync(provider.fetchLiveUpdates);
    provider.setLiveUpdatesActive(false);
    provider.setLiveUpdatesActive(true);
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(memory.expirations, greaterThan(0));
    expect(counts['/api/matches'], 2);
    expect(memory.snapshot?.day, '2026-11-26');
    provider.setLiveUpdatesActive(false);
  });

  test('unavailable disk does not prevent network loading', () async {
    final unavailable = PublicDataCache(
      origin: 'https://fixture.test',
      directory: () async => throw const FileSystemException('unavailable'),
    );
    final provider = DataProvider(
      client: client,
      cache: unavailable,
      badges: badges,
      now: () => now,
    );
    providers.add(provider);
    await provider.initData();
    expect(provider.allMatches.single.id, 1);
    expect(provider.isLoading, isFalse);
  });

  test(
    'new club badges fill today\'s cached fixtures without a season reload',
    () async {
      final provider = create();
      await provider.initData();
      await provider.fetchLiveUpdates();
      await settle();
      expect(provider.allMatches.single.homeTeam.logoUrl, isNull);
      artwork = [
        {'id': 1, 'logo_url': 'https://espn.test/krasnodar.png'},
      ];
      await provider.fetchMissingTeamBadges(force: true);
      expect(
        provider.allMatches.single.homeTeam.logoUrl,
        artwork.single['logo_url'],
      );
      final saved = await cache.read();
      expect(
        saved?.matches.single['home_team']['logo_url'],
        artwork.single['logo_url'],
      );
      expect(counts['/api/matches'], 1);
      final restarted = create();
      await restarted.initData();
      expect(
        restarted.allMatches.single.homeTeam.logoUrl,
        artwork.single['logo_url'],
      );
      expect(counts['/api/matches'], 1);
    },
  );

  test(
    'badge metadata preserves known artwork and rejects non-network URLs',
    () async {
      final provider = create();
      await provider.initData();
      await provider.fetchLiveUpdates();
      await settle();
      artwork = [
        {'id': 1, 'logo_url': 'https://espn.test/verified.png'},
      ];
      await provider.fetchMissingTeamBadges(force: true);
      artwork = [
        {'id': 1, 'logo_url': 'https://other.test/replacement.png'},
        {'id': 2, 'logo_url': 'file:///private/image'},
        {'id': 999, 'logo_url': 'https://other.test/unknown.png'},
      ];
      await provider.fetchMissingTeamBadges(force: true);
      expect(
        provider.allMatches.single.homeTeam.logoUrl,
        'https://espn.test/verified.png',
      );
      expect(provider.allMatches.single.awayTeam.logoUrl, isNull);
      expect(counts['/api/matches'], 1);
    },
  );
}

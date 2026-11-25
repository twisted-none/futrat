import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:futrat_mobile/core/public_data_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late DateTime now;
  PublicDataCache cache([String origin = 'https://fixture.test']) =>
      PublicDataCache(
        origin: origin,
        directory: () async => root,
        now: () => now,
      );
  DailySnapshot snapshot() => DailySnapshot(
    day: moscowDay(now),
    matches: [
      {'id': 1, 'home_score': 2},
    ],
    tournaments: [
      {'id': 9},
    ],
  );
  setUp(() async {
    root = await Directory.systemTemp.createTemp('futrat-cache-test-');
    now = DateTime.utc(2026, 11, 25, 20, 59);
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  test(
    'public snapshot survives restart and repeated writes on the same day',
    () async {
      await cache().save(snapshot());
      await cache().save(
        DailySnapshot(
          day: moscowDay(now),
          matches: [
            {'id': 1, 'home_score': 3},
          ],
          tournaments: [
            {'id': 9},
          ],
        ),
      );
      final restored = await cache().read();
      expect(restored?.matches.single['home_score'], 3);
      expect(restored?.tournaments.single['id'], 9);
    },
  );
  test(
    'MSK midnight removes daily data and preserves permanent artwork',
    () async {
      await cache().save(snapshot());
      final logo = File('${root.path}/badges/team.png');
      await logo.parent.create();
      await logo.writeAsString('artwork');
      now = DateTime.utc(2026, 11, 25, 21);
      expect(moscowDay(now), '2026-11-26');
      expect(await cache().read(), isNull);
      expect(await logo.exists(), isTrue);
      expect(
        await root
            .list(recursive: true)
            .where((f) => f.path.endsWith('.json'))
            .length,
        0,
      );
    },
  );
  test(
    'old in-flight responses cannot be saved as a new-day snapshot',
    () async {
      final old = snapshot();
      now = now.add(const Duration(minutes: 2));
      await cache().save(old);
      expect(await cache().read(), isNull);
    },
  );
  test('cache belongs to its backend origin', () async {
    await cache().save(snapshot());
    expect(await cache('https://another.test').read(), isNull);
  });
  test('damaged JSON safely falls back to the network', () async {
    await cache().save(snapshot());
    final file = await root
        .list(recursive: true)
        .where((f) => f.path.endsWith('.json'))
        .first;
    await (file as File).writeAsString('{broken');
    expect(await cache().read(), isNull);
  });
  test('next midnight is independent of device timezone', () {
    expect(nextMoscowMidnight(now), DateTime.utc(2026, 11, 25, 21));
    expect(
      nextMoscowMidnight(DateTime.utc(2026, 11, 25, 21)),
      DateTime.utc(2026, 11, 26, 21),
    );
  });
}

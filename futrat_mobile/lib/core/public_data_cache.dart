import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

typedef CacheDirectory = Future<Directory> Function();

String moscowDay(DateTime time) => time
    .toUtc()
    .add(const Duration(hours: 3))
    .toIso8601String()
    .substring(0, 10);

DateTime nextMoscowMidnight(DateTime time) {
  final moscow = time.toUtc().add(const Duration(hours: 3));
  return DateTime.utc(
    moscow.year,
    moscow.month,
    moscow.day + 1,
  ).subtract(const Duration(hours: 3));
}

Future<Directory> publicCacheDirectory() async => Directory(
  '${(await getApplicationSupportDirectory()).path}/football_public',
).create(recursive: true);

class DailySnapshot {
  const DailySnapshot({
    required this.day,
    required this.matches,
    required this.tournaments,
  });
  final String day;
  final List<Map<String, dynamic>> matches, tournaments;
}

/// Public fixtures only. Credentials and user-specific data never enter this file.
class PublicDataCache {
  PublicDataCache({
    required String origin,
    CacheDirectory? directory,
    DateTime Function()? now,
  }) : _namespace = sha256.convert(utf8.encode(origin)).toString(),
       _directory = directory ?? publicCacheDirectory,
       _now = now ?? DateTime.now;

  final String _namespace;
  final CacheDirectory _directory;
  final DateTime Function() _now;
  Future<void> _writes = Future.value();

  Future<Directory> _folder() async => Directory(
    '${(await _directory()).path}/daily/$_namespace',
  ).create(recursive: true);

  Future<void> expire() async {
    // Serialize cleanup with writes, so an old in-flight write cannot resurrect
    // yesterday's data after midnight.
    final task = _writes.then((_) async {
      try {
        final folder = await _folder();
        final current = 'daily-${moscowDay(_now())}.json';
        await for (final entry in folder.list()) {
          final name = entry.uri.pathSegments.last;
          if (entry is File &&
              RegExp(
                r'^daily-\d{4}-\d{2}-\d{2}\.json(?:\.tmp)?$',
              ).hasMatch(name) &&
              name != current) {
            await entry.delete();
          }
        }
      } catch (_) {
        // Unavailable/full storage must not prevent ordinary network loading.
      }
    });
    _writes = task;
    return task;
  }

  Future<DailySnapshot?> read() async {
    await expire();
    try {
      final day = moscowDay(_now());
      final file = File('${(await _folder()).path}/daily-$day.json');
      final data = await compute(jsonDecode, await file.readAsString());
      if (data['version'] != 1 ||
          data['day'] != day ||
          moscowDay(_now()) != day) {
        return null;
      }
      return DailySnapshot(
        day: day,
        matches: (data['matches'] as List)
            .map((row) => Map<String, dynamic>.from(row))
            .toList(),
        tournaments: (data['tournaments'] as List)
            .map((row) => Map<String, dynamic>.from(row))
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(DailySnapshot snapshot) {
    final task = _writes.then((_) async {
      if (snapshot.day != moscowDay(_now())) return;
      try {
        final folder = await _folder();
        final file = File('${folder.path}/daily-${snapshot.day}.json');
        final temporary = File('${file.path}.tmp');
        final encoded = await compute(jsonEncode, {
          'version': 1,
          'day': snapshot.day,
          'matches': snapshot.matches,
          'tournaments': snapshot.tournaments,
        });
        await temporary.writeAsString(encoded, flush: true);
        if (snapshot.day != moscowDay(_now())) {
          await temporary.delete();
          return;
        }
        // Dart replaces the target on Android; serialized writes avoid races.
        await temporary.rename(file.path);
      } catch (_) {
        // The in-memory data remains usable if the disk is unavailable.
      }
    });
    _writes = task;
    return task;
  }
}

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'public_data_cache.dart';

/// Artwork is kept in application support, not the OS's disposable cache.
/// This transport deliberately has no API authentication interceptor.
class BadgeCache extends ChangeNotifier {
  BadgeCache({
    CacheDirectory? directory,
    Future<Uint8List> Function(String url)? download,
    DateTime Function()? now,
  }) : _directory = directory ?? publicCacheDirectory,
       _download = download ?? _downloadPng,
       _now = now ?? DateTime.now;

  static final instance = BadgeCache();
  final CacheDirectory _directory;
  final Future<Uint8List> Function(String) _download;
  final DateTime Function() _now;
  final _pending = <String, Future<File?>>{};
  final _failed = <String, DateTime>{};
  final Queue<Completer<void>> _waiting = Queue();
  int _active = 0;
  String? latestReadyUrl;
  static const maxBytes = 2 * 1024 * 1024;
  static const _signature = [137, 80, 78, 71, 13, 10, 26, 10];

  static String proxyUrl(String url) => Uri.https('wsrv.nl', '/', {
    'url': url.replaceFirst(RegExp(r'^https?://'), ''),
    'output': 'png',
    'w': '256',
    'h': '256',
    'fit': 'inside',
  }).toString();

  static Future<Uint8List> _downloadPng(String url) =>
      BadgeDownloader().download(url);

  Future<File?> get(String? url) {
    final uri = Uri.tryParse(url ?? '');
    if (url == null ||
        uri == null ||
        !uri.hasAuthority ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.userInfo.isNotEmpty) {
      return Future.value(null);
    }
    final failed = _failed[url];
    if (failed != null &&
        _now().difference(failed) < const Duration(minutes: 1)) {
      return Future.value(null);
    }
    return _pending.putIfAbsent(
      url,
      () => _load(url).whenComplete(() {
        _pending.remove(url);
      }),
    );
  }

  Future<void> _acquire() async {
    if (_active < 4) {
      _active++;
    } else {
      final ready = Completer<void>();
      _waiting.add(ready);
      await ready.future;
    }
  }

  void _release() {
    if (_waiting.isNotEmpty) {
      _waiting.removeFirst().complete();
    } else {
      _active--;
    }
  }

  bool _isPng(List<int> bytes) =>
      bytes.length > 8 &&
      bytes.length <= maxBytes &&
      List.generate(
        8,
        (i) => bytes[i] == _signature[i],
      ).every((value) => value);

  Future<File?> _load(String url) async {
    try {
      final folder = await _directory();
      final hash = sha256.convert(utf8.encode(url));
      final file = File('${folder.path}/badges/$hash.png');
      if (await file.exists()) {
        if (_isPng(await file.readAsBytes())) return file;
        await file.delete();
      }
      await _acquire();
      try {
        final bytes = await _download(url);
        if (!_isPng(bytes)) throw const FormatException('Invalid artwork');
        // Reject truncated images with a valid signature as well as HTML errors.
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: 256,
          targetHeight: 256,
          allowUpscaling: false,
        );
        try {
          final frame = await codec.getNextFrame();
          frame.image.dispose();
        } finally {
          codec.dispose();
        }
        await file.parent.create(recursive: true);
        final temporary = File('${file.path}.tmp');
        await temporary.writeAsBytes(bytes, flush: true);
        await temporary.rename(file.path);
        _failed.remove(url);
        latestReadyUrl = url;
        notifyListeners();
        return file;
      } finally {
        _release();
      }
    } catch (_) {
      if (_failed.length >= 512) _failed.remove(_failed.keys.first);
      _failed[url] = _now();
      return null;
    }
  }

  Future<void> invalidate(String url) async {
    try {
      final hash = sha256.convert(utf8.encode(url));
      final file = File('${(await _directory()).path}/badges/$hash.png');
      if (await file.exists()) await file.delete();
      _failed[url] = _now();
    } catch (_) {
      // Read-only/unavailable storage is handled by a placeholder in the UI.
    }
  }

  Future<void> prefetch(Iterable<String?> urls) async {
    final queue = Queue<String>.of(urls.whereType<String>().toSet());
    Future<void> worker() async {
      while (queue.isNotEmpty) {
        await get(queue.removeFirst());
      }
    }

    await Future.wait(List.generate(3, (_) => worker()));
  }
}

/// Original artwork is preferred; the external proxy is an optional fallback.
/// Normalize decodable PNG/JPEG/WebP images before writing the permanent cache.
class BadgeDownloader {
  BadgeDownloader({Dio? transport}) : _transport = transport;
  final Dio? _transport;

  Future<Uint8List> download(String url) async {
    // Never reuse ApiClient: artwork requests must not contain session tokens.
    final dio =
        _transport ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );
    try {
      for (final candidate in [url, BadgeCache.proxyUrl(url)]) {
        // Each attempt needs its own token; an oversized original must not
        // cancel the independent proxy fallback.
        final cancel = CancelToken();
        try {
          final response = await dio.get<List<int>>(
            candidate,
            options: Options(responseType: ResponseType.bytes),
            cancelToken: cancel,
            onReceiveProgress: (count, _) {
              if (count > BadgeCache.maxBytes) {
                cancel.cancel('Artwork is too large');
              }
            },
          );
          final bytes = Uint8List.fromList(response.data ?? []);
          if (bytes.isEmpty || bytes.length > BadgeCache.maxBytes) {
            throw const FormatException('Invalid artwork size');
          }
          final codec = await ui.instantiateImageCodec(
            bytes,
            targetWidth: 256,
            targetHeight: 256,
            allowUpscaling: false,
          );
          try {
            final frame = await codec.getNextFrame();
            try {
              final png = await frame.image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              if (png == null || png.lengthInBytes > BadgeCache.maxBytes) {
                throw const FormatException('Invalid decoded artwork');
              }
              return png.buffer.asUint8List(
                png.offsetInBytes,
                png.lengthInBytes,
              );
            } finally {
              frame.image.dispose();
            }
          } finally {
            codec.dispose();
          }
        } catch (_) {
          if (candidate != url) rethrow;
        }
      }
      throw const FormatException('Artwork unavailable');
    } finally {
      if (_transport == null) dio.close(force: true);
    }
  }
}

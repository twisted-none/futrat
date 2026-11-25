import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../core/badge_cache.dart';

/// Transparent padding carries no weight in the badge's contrast decision.
bool logoNeedsLightBackground(Uint8List rgba) {
  const background = Color(0xFF25292F);
  final luminance = background.computeLuminance();
  double visible = 0, lowContrast = 0;
  for (var i = 0; i + 3 < rgba.length; i += 4) {
    final alpha = rgba[i + 3] / 255;
    if (alpha < .08) continue;
    final color = Color.alphaBlend(
      Color.fromARGB(rgba[i + 3], rgba[i], rgba[i + 1], rgba[i + 2]),
      background,
    );
    final light = color.computeLuminance();
    final contrast = (light > luminance)
        ? (light + .05) / (luminance + .05)
        : (luminance + .05) / (light + .05);
    visible += alpha;
    if (contrast < 3) lowContrast += alpha;
  }
  return visible > 0 && lowContrast / visible >= .6;
}

/// Shared team/tournament artwork; the tile occupies the existing logo slot.
class FootballLogo extends StatefulWidget {
  const FootballLogo({
    super.key,
    this.url,
    this.image,
    this.size = 28,
    this.padding = 0,
    this.framed = false,
    this.cache,
  });
  final String? url;
  final ImageProvider? image;
  final double size, padding;
  final bool framed;
  final BadgeCache? cache;
  static const lightBackground = Color(0xFFF1F3F5);

  @override
  State<FootballLogo> createState() => _FootballLogoState();
}

class _FootballLogoState extends State<FootballLogo> {
  // Bounded and shared: repeated badges share both decoding and analysis work.
  static final _contrast = <ImageProvider, Future<bool>>{};
  ImageProvider? _provider;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  bool _lightTile = false;
  bool _broken = false;
  bool _dark = false;
  late ImageConfiguration _configuration;
  int _generation = 0;
  BadgeCache get _cache => widget.cache ?? BadgeCache.instance;

  @override
  void initState() {
    super.initState();
    _cache.addListener(_badgeReady);
  }

  void _badgeReady() {
    if (mounted &&
        (_provider == null || _broken) &&
        _cache.latestReadyUrl == widget.url) {
      setState(_resolve);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(FootballLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cache != widget.cache) {
      (oldWidget.cache ?? BadgeCache.instance).removeListener(_badgeReady);
      _cache.addListener(_badgeReady);
    }
    if (oldWidget.url != widget.url ||
        oldWidget.image != widget.image ||
        oldWidget.cache != widget.cache) {
      _resolve();
    }
  }

  void _disconnect() {
    _generation++;
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = null;
    _listener = null;
  }

  void _resolve() {
    _disconnect();
    // Register inherited-widget dependencies before asynchronous disk access.
    _dark = Theme.of(context).brightness == Brightness.dark;
    _configuration = createLocalImageConfiguration(context);
    _lightTile = false;
    _broken = false;
    final url = widget.url;
    if (widget.image != null || url == null || url.isEmpty) {
      _useImage(widget.image);
      return;
    }
    _provider = null;
    final generation = _generation;
    _cache.get(url).then((file) {
      if (!mounted || generation != _generation || file == null) return;
      setState(() => _useImage(FileImage(file)));
    });
  }

  void _useImage(ImageProvider? original) {
    _provider = original == null
        ? null
        : ResizeImage(
            original,
            width: 128,
            height: 128,
            policy: ResizeImagePolicy.fit,
            allowUpscaling: false,
          );
    if (_provider == null || !_dark) {
      return;
    }
    final provider = _provider!;
    final generation = _generation;
    _stream = provider.resolve(_configuration);
    _listener = ImageStreamListener(
      (info, synchronousCall) {
        if (!_contrast.containsKey(provider)) {
          if (_contrast.length >= 256) _contrast.remove(_contrast.keys.first);
          _contrast[provider] = _analyze(info.image.clone());
        }
        info.dispose();
        _contrast[provider]!.then((light) {
          if (mounted && generation == _generation && _lightTile != light) {
            setState(() => _lightTile = light);
          }
        });
      },
      onError: (Object error, StackTrace? stack) {
        _imageFailed();
      },
    );
    _stream!.addListener(_listener!);
  }

  void _imageFailed() {
    if (!_broken && widget.image == null && widget.url != null) {
      _broken = true;
      unawaited(_cache.invalidate(widget.url!));
    }
  }

  static Future<bool> _analyze(ui.Image image) async {
    try {
      final bytes = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      return bytes != null &&
          logoNeedsLightBackground(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
    } catch (_) {
      return false;
    } finally {
      image.dispose();
    }
  }

  @override
  void dispose() {
    _cache.removeListener(_badgeReady);
    _disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final tile = dark && _lightTile;
    final radius = BorderRadius.circular(widget.size * .2);
    final inset = tile && widget.padding < widget.size * .1
        ? widget.size * .1
        : widget.padding;
    Widget placeholder() => Icon(
      Icons.shield_outlined,
      color: theme.colorScheme.onSurfaceVariant,
      size: widget.size * .65,
    );
    return Container(
      width: widget.size,
      height: widget.size,
      padding: EdgeInsets.all(inset),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: tile
            ? FootballLogo.lightBackground
            : widget.framed
            ? (dark ? const Color(0xFF25292F) : const Color(0xFFEBEEF2))
            : null,
        border: widget.framed || tile
            ? Border.all(
                color: tile
                    ? const Color(0xFFD6DAE0)
                    : theme.colorScheme.outlineVariant,
              )
            : null,
      ),
      child: _provider == null
          ? placeholder()
          : Image(
              image: _provider!,
              fit: BoxFit.contain,
              errorBuilder: (_, error, stack) {
                _imageFailed();
                return placeholder();
              },
            ),
    );
  }
}

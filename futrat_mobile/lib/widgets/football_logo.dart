import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

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
  });
  final String? url;
  final ImageProvider? image;
  final double size, padding;
  final bool framed;
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
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(FootballLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.image != widget.image) {
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
    _lightTile = false;
    final url = widget.url;
    final original =
        widget.image ??
        (url == null || url.isEmpty
            ? null
            : NetworkImage(
                Uri.https('wsrv.nl', '/', {
                  'url': url.replaceFirst(RegExp(r'^https?://'), ''),
                  'output': 'png',
                }).toString(),
              ));
    _provider = original == null
        ? null
        : ResizeImage(
            original,
            width: 128,
            height: 128,
            policy: ResizeImagePolicy.fit,
            allowUpscaling: false,
          );
    if (_provider == null || Theme.of(context).brightness != Brightness.dark) {
      return;
    }
    final provider = _provider!;
    final generation = _generation;
    _stream = provider.resolve(createLocalImageConfiguration(context));
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
        // The Image below renders a readable placeholder on network/decode errors.
      },
    );
    _stream!.addListener(_listener!);
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
              errorBuilder: (_, error, stack) => placeholder(),
            ),
    );
  }
}

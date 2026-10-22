import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futrat_mobile/core/app_theme.dart';
import 'package:futrat_mobile/widgets/football_logo.dart';

Uint8List pixels(List<List<int>> colors) =>
    Uint8List.fromList(colors.expand((c) => c).toList());

Future<MemoryImage> badge(Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(8, 8, 16, 16), Paint()..color = color);
  final picture = recorder.endRecording();
  final image = await picture.toImage(32, 32);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final result = MemoryImage(Uint8List.fromList(bytes!.buffer.asUint8List()));
  image.dispose();
  picture.dispose();
  return result;
}

void main() {
  test('transparent borders do not dilute a dark badge', () {
    expect(
      logoNeedsLightBackground(
        pixels([
          [0, 0, 0, 0],
          [255, 255, 255, 0],
          [30, 10, 50, 255],
        ]),
      ),
      isTrue,
    );
    expect(logoNeedsLightBackground(Uint8List(16)), isFalse);
  });

  test('only predominantly low contrast artwork gets a light tile', () {
    final dark = [20, 15, 40, 255], white = [250, 250, 250, 255];
    expect(logoNeedsLightBackground(pixels([dark, dark, white])), isTrue);
    expect(logoNeedsLightBackground(pixels([dark, white, white])), isFalse);
    expect(
      logoNeedsLightBackground(
        pixels([
          [240, 30, 40, 255],
        ]),
      ),
      isFalse,
    );
    expect(
      logoNeedsLightBackground(
        pixels([
          [255, 255, 255, 255],
        ]),
      ),
      isFalse,
    );
  });

  testWidgets(
    'dark tile follows the decoded image and theme without resizing',
    (tester) async {
      final dark = await tester.runAsync(() => badge(const Color(0xFF271143)));
      final bright = await tester.runAsync(() => badge(Colors.yellow));
      Future<void> show(ImageProvider image, AppThemeType mode) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.getTheme(mode).themeData,
            home: Center(child: FootballLogo(image: image, size: 28)),
          ),
        );
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
      }

      bool hasTile() {
        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(FootballLogo),
                matching: find.byType(Container),
              )
              .first,
        );
        return (container.decoration as BoxDecoration).color ==
            FootballLogo.lightBackground;
      }

      await show(dark!, AppThemeType.dark);
      expect(hasTile(), isTrue);
      expect(tester.getSize(find.byType(FootballLogo)), const Size(28, 28));
      await show(dark, AppThemeType.light);
      expect(hasTile(), isFalse);
      await show(bright!, AppThemeType.dark);
      expect(hasTile(), isFalse);
      await show(dark, AppThemeType.dark);
      expect(hasTile(), isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing or invalid artwork keeps a readable placeholder', (
    tester,
  ) async {
    for (final image in <ImageProvider?>[
      null,
      MemoryImage(Uint8List.fromList([1, 2, 3])),
    ]) {
      await tester.pumpWidget(
        MaterialApp(home: FootballLogo(image: image, size: 22)),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

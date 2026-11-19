import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_editor/photo_editor.dart';

/// Builds a two-tone test image: pure red on the left half, pure blue on the
/// right half, so geometric transforms and color filters can be asserted at the
/// pixel level.
Future<ui.Image> _createTwoToneImage(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width / 2, height.toDouble()),
    Paint()..color = const Color(0xFFFF2020),
  );
  canvas.drawRect(
    Rect.fromLTWH(width / 2, 0, width / 2, height.toDouble()),
    Paint()..color = const Color(0xFF2040FF),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhotoExportEngine', () {
    test('exports cropped + rotated PNG with exact dimensions', () async {
      final source = await _createTwoToneImage(200, 100);
      addTearDown(source.dispose);

      const state = PhotoEditState(
        transform: PhotoTransform(
          quarterTurns: 1, // Oriented size becomes 100 x 200
          cropRect: Rect.fromLTRB(0.0, 0.25, 1.0, 0.75), // 100 x 100
        ),
      );

      final result = await PhotoExportEngine.export(
        image: source,
        state: state,
      );

      expect(result.format, PhotoExportFormat.png);
      expect(result.mimeType, 'image/png');
      expect(result.fileExtension, 'png');
      expect(result.width, 100);
      expect(result.height, 100);
      expect(result.bytes.length, greaterThan(50));

      final codec = await ui.instantiateImageCodec(result.bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      try {
        expect(frame.image.width, 100);
        expect(frame.image.height, 100);
      } finally {
        frame.image.dispose();
      }
    });

    test('respects maxWidth and maxHeight proportionally', () async {
      final source = await _createTwoToneImage(400, 200);
      addTearDown(source.dispose);

      final result = await PhotoExportEngine.export(
        image: source,
        state: PhotoEditState.initial,
        options: const PhotoExportOptions(maxWidth: 100, maxHeight: 100),
      );

      expect(result.width, 100);
      expect(result.height, 50);
    });

    test('exports decodable JPEG and raw RGBA buffers', () async {
      final source = await _createTwoToneImage(120, 80);
      addTearDown(source.dispose);

      final jpegResult = await PhotoExportEngine.export(
        image: source,
        state: const PhotoEditState(
          filter: PhotoFilters.vivid,
          adjustments: PhotoAdjustments(vignette: 0.35, warmth: 0.2),
        ),
        options: const PhotoExportOptions(
          format: PhotoExportFormat.jpeg,
          jpegQuality: 88,
        ),
      );
      expect(jpegResult.mimeType, 'image/jpeg');
      expect(jpegResult.fileExtension, 'jpg');
      expect(jpegResult.bytes[0], 0xFF);
      expect(jpegResult.bytes[1], 0xD8);

      final codec = await ui.instantiateImageCodec(jpegResult.bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      try {
        expect(frame.image.width, 120);
        expect(frame.image.height, 80);
      } finally {
        frame.image.dispose();
      }

      final rgbaResult = await PhotoExportEngine.export(
        image: source,
        state: PhotoEditState.initial,
        options: const PhotoExportOptions(format: PhotoExportFormat.rawRgba),
      );
      expect(rgbaResult.bytes.length, 120 * 80 * 4);
    });

    test('mono filter produces neutral grayscale pixels', () async {
      final source = await _createTwoToneImage(60, 40);
      addTearDown(source.dispose);

      final result = await PhotoExportEngine.export(
        image: source,
        state: const PhotoEditState(filter: PhotoFilters.mono),
        options: const PhotoExportOptions(format: PhotoExportFormat.rawRgba),
      );

      // Sample left-side pixel (originally red).
      const idx = (20 * 60 + 10) * 4;
      final r = result.bytes[idx];
      final g = result.bytes[idx + 1];
      final b = result.bytes[idx + 2];
      expect((r - g).abs(), lessThanOrEqualTo(2));
      expect((g - b).abs(), lessThanOrEqualTo(2));
    });

    test('horizontal flip swaps left red and right blue pixels', () async {
      final source = await _createTwoToneImage(60, 40);
      addTearDown(source.dispose);

      final result = await PhotoExportEngine.export(
        image: source,
        state: const PhotoEditState(
          transform: PhotoTransform(flipHorizontal: true),
        ),
        options: const PhotoExportOptions(format: PhotoExportFormat.rawRgba),
      );

      // Left pixel should now be blue (high B, low R).
      const leftIdx = (20 * 60 + 10) * 4;
      expect(result.bytes[leftIdx + 2], greaterThan(200));
      expect(result.bytes[leftIdx], lessThan(60));

      // Right pixel should now be red (high R, low B).
      const rightIdx = (20 * 60 + 50) * 4;
      expect(result.bytes[rightIdx], greaterThan(200));
      expect(result.bytes[rightIdx + 2], lessThan(60));
    });

    test(
      'renders strokes, text overlays, stickers, blur, and straighten cleanly',
      () async {
        final source = await _createTwoToneImage(160, 120);
        addTearDown(source.dispose);

        const state = PhotoEditState(
          filter: PhotoFilters.goldenHour,
          filterIntensity: 0.8,
          adjustments: PhotoAdjustments(
            brightness: 0.1,
            contrast: 0.15,
            vignette: 0.4,
            blur: 0.15,
          ),
          transform: PhotoTransform(rotationAngle: 0.12),
          strokes: <DrawingStroke>[
            DrawingStroke(
              id: 's1',
              points: <Offset>[
                Offset(0.1, 0.2),
                Offset(0.4, 0.5),
                Offset(0.8, 0.3),
              ],
              color: Colors.white,
              strokeWidth: 0.02,
            ),
            DrawingStroke(
              id: 's2',
              points: <Offset>[Offset(0.2, 0.7), Offset(0.7, 0.8)],
              color: Colors.amber,
              strokeWidth: 0.02,
              tool: BrushTool.arrow,
            ),
            DrawingStroke(
              id: 's3',
              points: <Offset>[Offset(0.2, 0.2), Offset(0.5, 0.5)],
              color: Colors.cyan,
              strokeWidth: 0.015,
              tool: BrushTool.rectangle,
            ),
            DrawingStroke(
              id: 's4',
              points: <Offset>[Offset(0.5, 0.5), Offset(0.8, 0.8)],
              color: Colors.pink,
              strokeWidth: 0.015,
              tool: BrushTool.oval,
            ),
          ],
          overlays: <PhotoOverlayLayer>[
            TextOverlayLayer(
              id: 't1',
              text: 'Studio Shot',
              backgroundStyle: TextBackgroundStyle.outline,
            ),
            StickerOverlayLayer(id: 'st1', content: '✨'),
          ],
        );

        final result = await PhotoExportEngine.export(
          image: source,
          state: state,
        );
        expect(result.width, 160);
        expect(result.height, 120);
        expect(result.bytes.isNotEmpty, isTrue);
      },
    );
  });
}

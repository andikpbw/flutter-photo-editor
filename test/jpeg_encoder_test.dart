import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_editor/photo_editor.dart';

Uint8List _makeGradientRgba(int width, int height) {
  final data = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      data[i] = (x * 255 ~/ width).clamp(0, 255);
      data[i + 1] = (y * 255 ~/ height).clamp(0, 255);
      data[i + 2] = ((x + y) * 127 ~/ (width + height)).clamp(0, 255);
      data[i + 3] = 255;
    }
  }
  return data;
}

Uint8List _makeSolidRgba(int width, int height, int r, int g, int b) {
  final data = Uint8List(width * height * 4);
  for (var i = 0; i < data.length; i += 4) {
    data[i] = r;
    data[i + 1] = g;
    data[i + 2] = b;
    data[i + 3] = 255;
  }
  return data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JpegEncoder', () {
    test(
      'produces valid JPEG with SOI/EOI markers and decodes via codec',
      () async {
        const width = 45;
        const height = 37; // intentionally non-multiple of 8
        final rgba = _makeGradientRgba(width, height);
        final jpeg = JpegEncoder.encodeRgba(rgba, width, height, quality: 92);

        // Valid JPEG SOI (FFD8) and EOI (FFD9) markers.
        expect(jpeg.length, greaterThan(100));
        expect(jpeg[0], 0xFF);
        expect(jpeg[1], 0xD8);
        expect(jpeg[jpeg.length - 2], 0xFF);
        expect(jpeg[jpeg.length - 1], 0xD9);

        // Decode back using Flutter's native image codec!
        final codec = await ui.instantiateImageCodec(jpeg);
        final frame = await codec.getNextFrame();
        codec.dispose();
        try {
          expect(frame.image.width, width);
          expect(frame.image.height, height);
        } finally {
          frame.image.dispose();
        }
      },
    );

    test(
      'preserves solid colors accurately after JPEG decode round-trip',
      () async {
        const width = 24;
        const height = 24;
        final rgba = _makeSolidRgba(width, height, 42, 165, 224);
        final jpeg = JpegEncoder.encodeRgba(rgba, width, height, quality: 95);

        final codec = await ui.instantiateImageCodec(jpeg);
        final frame = await codec.getNextFrame();
        codec.dispose();
        try {
          final decoded = (await frame.image.toByteData())!.buffer
              .asUint8List();
          const centerOffset = ((height ~/ 2) * width + (width ~/ 2)) * 4;
          expect(decoded[centerOffset], closeTo(42, 4));
          expect(decoded[centerOffset + 1], closeTo(165, 4));
          expect(decoded[centerOffset + 2], closeTo(224, 4));
        } finally {
          frame.image.dispose();
        }
      },
    );

    test('handles extreme high-contrast checkerboard at quality 100', () async {
      const width = 32;
      const height = 32;
      final rgba = Uint8List(width * height * 4);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final i = (y * width + x) * 4;
          final v = ((x + y).isEven) ? 255 : 0;
          rgba[i] = v;
          rgba[i + 1] = v;
          rgba[i + 2] = v;
          rgba[i + 3] = 255;
        }
      }
      final jpeg = JpegEncoder.encodeRgba(rgba, width, height, quality: 100);
      final codec = await ui.instantiateImageCodec(jpeg);
      final frame = await codec.getNextFrame();
      codec.dispose();
      try {
        expect(frame.image.width, width);
        expect(frame.image.height, height);
      } finally {
        frame.image.dispose();
      }
    });

    test('lower quality produces smaller file size than higher quality', () {
      final rgba = _makeGradientRgba(80, 60);
      final lowQ = JpegEncoder.encodeRgba(rgba, 80, 60, quality: 20);
      final highQ = JpegEncoder.encodeRgba(rgba, 80, 60, quality: 95);
      expect(lowQ.length, lessThan(highQ.length));
    });

    test('throws ArgumentError for invalid inputs', () {
      expect(
        () => JpegEncoder.encodeRgba(Uint8List(0), 0, 10),
        throwsArgumentError,
      );
      expect(
        () => JpegEncoder.encodeRgba(Uint8List(10), 10, 10),
        throwsArgumentError,
      );
    });
  });
}

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_editor_studio/photo_editor_studio.dart';

List<double> _applyMatrix(
  List<double> m,
  double r,
  double g,
  double b,
  double a,
) {
  return <double>[
    (m[0] * r + m[1] * g + m[2] * b + m[3] * a + m[4]).clamp(0.0, 255.0),
    (m[5] * r + m[6] * g + m[7] * b + m[8] * a + m[9]).clamp(0.0, 255.0),
    (m[10] * r + m[11] * g + m[12] * b + m[13] * a + m[14]).clamp(0.0, 255.0),
    (m[15] * r + m[16] * g + m[17] * b + m[18] * a + m[19]).clamp(0.0, 255.0),
  ];
}

void main() {
  group('PhotoColorMatrix', () {
    test('identity matrix leaves pixels unchanged', () {
      expect(PhotoColorMatrix.isIdentity(PhotoColorMatrix.identity), isTrue);
      final out = _applyMatrix(PhotoColorMatrix.identity, 120, 80, 200, 255);
      expect(out, equals(<double>[120, 80, 200, 255]));
    });

    test(
      'all built-in filter presets have 20 finite values and unique ids',
      () {
        final seenIds = <String>{};
        for (final filter in PhotoFilters.presets) {
          expect(
            seenIds.add(filter.id),
            isTrue,
            reason: 'Duplicate ${filter.id}',
          );
          expect(filter.matrix.length, 20);
          for (final v in filter.matrix) {
            expect(v.isFinite, isTrue);
          }
        }
        expect(PhotoFilters.presets.length, greaterThanOrEqualTo(24));
        final monoOnly = PhotoFilters.forCategory(
          PhotoFilters.presets,
          PhotoFilterCategory.monochrome,
        );
        expect(monoOnly.first.isOriginal, isTrue);
        expect(monoOnly.length, greaterThanOrEqualTo(5));
      },
    );

    test('lerp interpolates cleanly between identity and target filter', () {
      final half = PhotoColorMatrix.lerp(
        PhotoColorMatrix.identity,
        PhotoFilters.mono.matrix,
        0.5,
      );
      expect(half[0], closeTo((1.0 + 0.2126) / 2, 1e-6));
      expect(
        PhotoColorMatrix.lerp(
          PhotoColorMatrix.identity,
          PhotoFilters.mono.matrix,
          0.0,
        ),
        equals(PhotoColorMatrix.identity),
      );
      expect(
        PhotoColorMatrix.lerp(
          PhotoColorMatrix.identity,
          PhotoFilters.mono.matrix,
          1.0,
        ),
        equals(PhotoFilters.mono.matrix),
      );
    });

    test('brightness raises and lowers RGB channels equally', () {
      final brighter = _applyMatrix(
        PhotoColorMatrix.brightness(0.5),
        100,
        100,
        100,
        255,
      );
      final darker = _applyMatrix(
        PhotoColorMatrix.brightness(-0.5),
        100,
        100,
        100,
        255,
      );
      expect(brighter[0], greaterThan(100));
      expect(brighter[0], closeTo(brighter[1], 1e-6));
      expect(darker[0], lessThan(100));
    });

    test('contrast keeps mid-gray anchored at 128', () {
      final mid = _applyMatrix(
        PhotoColorMatrix.contrast(0.6),
        128,
        128,
        128,
        255,
      );
      expect(mid[0], closeTo(128, 1e-4));
      final bright = _applyMatrix(
        PhotoColorMatrix.contrast(0.6),
        200,
        200,
        200,
        255,
      );
      final dark = _applyMatrix(
        PhotoColorMatrix.contrast(0.6),
        60,
        60,
        60,
        255,
      );
      expect(bright[0], greaterThan(200));
      expect(dark[0], lessThan(60));
    });

    test('saturation -1.0 converts colorful pixel to neutral grayscale', () {
      final gray = _applyMatrix(
        PhotoColorMatrix.saturation(-1.0),
        220,
        60,
        30,
        255,
      );
      expect(gray[0], closeTo(gray[1], 1e-4));
      expect(gray[1], closeTo(gray[2], 1e-4));
    });

    test('warmth shifts red up and blue down for positive values', () {
      final warm = _applyMatrix(
        PhotoColorMatrix.warmth(0.8),
        128,
        128,
        128,
        255,
      );
      expect(warm[0], greaterThan(warm[2]));
    });

    test('fade lifts pure black above zero', () {
      final faded = _applyMatrix(PhotoColorMatrix.fade(0.5), 0, 0, 0, 255);
      expect(faded[0], greaterThan(15));
      expect(faded[0], closeTo(faded[1], 1e-6));
    });

    test('compose combines filter intensity and adjustments', () {
      final composed = PhotoColorMatrix.compose(
        filter: PhotoFilters.cinematic,
        filterIntensity: 0.75,
        adjustments: const PhotoAdjustments(
          exposure: 0.2,
          contrast: 0.15,
          warmth: 0.25,
          clarity: 0.3,
        ),
      );
      expect(composed.length, 20);
      expect(PhotoColorMatrix.isIdentity(composed), isFalse);
      final neutral = PhotoColorMatrix.compose();
      expect(PhotoColorMatrix.isIdentity(neutral), isTrue);
    });

    test('vibrance boosts cool channels while staying finite', () {
      final vib = PhotoColorMatrix.vibrance(0.75);
      expect(vib.length, 20);
      expect(PhotoColorMatrix.isIdentity(vib), isFalse);
      final out = _applyMatrix(vib, 100, 120, 180, 255);
      expect(out[2], greaterThan(180));
    });
  });

  group('PhotoHistogramCalculator', () {
    test('computes normalized 64-bin RGB and luminance distributions', () {
      final rgba = Uint8List(4 * 4 * 4);
      for (var i = 0; i < rgba.length; i += 4) {
        rgba[i] = 200; // R
        rgba[i + 1] = 100; // G
        rgba[i + 2] = 50; // B
        rgba[i + 3] = 255; // A
      }
      final hist = PhotoHistogramCalculator.computeFromRgba(rgba);
      expect(hist.binCount, 64);
      expect(hist.red.reduce((a, b) => a > b ? a : b), closeTo(1.0, 1e-6));
      expect(hist.green.reduce((a, b) => a > b ? a : b), closeTo(1.0, 1e-6));
      expect(hist.blue.reduce((a, b) => a > b ? a : b), closeTo(1.0, 1e-6));

      // Brightness adjustment shifts histogram peak to the right.
      final brightHist = PhotoHistogramCalculator.computeFromRgba(
        rgba,
        adjustments: const PhotoAdjustments(brightness: 0.4),
      );
      final origPeakIdx = hist.luminance.indexOf(
        hist.luminance.reduce((a, b) => a > b ? a : b),
      );
      final brightPeakIdx = brightHist.luminance.indexOf(
        brightHist.luminance.reduce((a, b) => a > b ? a : b),
      );
      expect(brightPeakIdx, greaterThan(origPeakIdx));
    });
  });
}

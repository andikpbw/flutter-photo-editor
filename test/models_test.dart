import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_editor/photo_editor.dart';

void main() {
  group('PhotoAdjustments', () {
    test('default instance has all zero fields', () {
      expect(PhotoAdjustments.none.isDefault, isTrue);
      for (final type in PhotoAdjustmentType.values) {
        expect(PhotoAdjustments.none.valueFor(type), 0.0);
      }
    });

    test('withValue clamps bipolar and unipolar ranges properly', () {
      final updated = PhotoAdjustments.none
          .withValue(PhotoAdjustmentType.brightness, 5.0)
          .withValue(PhotoAdjustmentType.contrast, -5.0)
          .withValue(PhotoAdjustmentType.vignette, -0.5)
          .withValue(PhotoAdjustmentType.blur, 2.0);
      expect(updated.brightness, 1.0);
      expect(updated.contrast, -1.0);
      expect(updated.vignette, 0.0);
      expect(updated.blur, 1.0);
      expect(updated.isDefault, isFalse);
    });

    test('JSON round-trip preserves all fields', () {
      const original = PhotoAdjustments(
        brightness: 0.25,
        contrast: -0.15,
        saturation: 0.4,
        exposure: 0.1,
        warmth: 0.35,
        tint: -0.2,
        fade: 0.2,
        clarity: 0.45,
        vignette: 0.3,
        blur: 0.12,
      );
      final restored = PhotoAdjustments.fromJson(original.toJson());
      expect(restored, equals(original));
    });
  });

  group('PhotoTransform', () {
    test('4x rotateRight returns to exact original transform', () {
      const start = PhotoTransform(
        cropRect: Rect.fromLTRB(0.1, 0.2, 0.8, 0.7),
        flipHorizontal: true,
        rotationAngle: 0.15,
      );
      final cycled = start
          .rotatedRight()
          .rotatedRight()
          .rotatedRight()
          .rotatedRight();
      expect(cycled.quarterTurns, start.quarterTurns);
      expect(cycled.flipHorizontal, start.flipHorizontal);
      expect(cycled.flipVertical, start.flipVertical);
      expect(cycled.cropRect.left, closeTo(start.cropRect.left, 1e-6));
      expect(cycled.cropRect.top, closeTo(start.cropRect.top, 1e-6));
      expect(cycled.cropRect.right, closeTo(start.cropRect.right, 1e-6));
      expect(cycled.cropRect.bottom, closeTo(start.cropRect.bottom, 1e-6));
    });

    test('rotateRight followed by rotateLeft restores original transform', () {
      const start = PhotoTransform(
        cropRect: Rect.fromLTRB(0.15, 0.1, 0.9, 0.85),
        flipVertical: true,
      );
      final restored = start.rotatedRight().rotatedLeft();
      expect(restored.quarterTurns, start.quarterTurns);
      expect(restored.flipHorizontal, start.flipHorizontal);
      expect(restored.flipVertical, start.flipVertical);
      expect(restored.cropRect.left, closeTo(start.cropRect.left, 1e-6));
      expect(restored.cropRect.bottom, closeTo(start.cropRect.bottom, 1e-6));
    });

    test('double flip restores crop and straighten angle', () {
      const start = PhotoTransform(
        cropRect: Rect.fromLTRB(0.2, 0.1, 0.9, 0.8),
        rotationAngle: 0.25,
      );
      final h2 = start.flippedHorizontal().flippedHorizontal();
      final v2 = start.flippedVertical().flippedVertical();
      expect(h2.flipHorizontal, isFalse);
      expect(h2.rotationAngle, closeTo(0.25, 1e-6));
      expect(h2.cropRect.left, closeTo(0.2, 1e-6));
      expect(v2.flipVertical, isFalse);
      expect(v2.rotationAngle, closeTo(0.25, 1e-6));
      expect(v2.cropRect.top, closeTo(0.1, 1e-6));
    });

    test('straightenAutoScale covers all 4 corners with zero clipping', () {
      const size = Size(400, 200);
      const transform = PhotoTransform(rotationAngle: math.pi / 6); // 30 deg
      final scale = transform.straightenAutoScale(size);
      expect(scale, greaterThan(1.0));
      // Check that each corner of the axis-aligned rect rotated by -angle
      // lies within [-scale*W/2, scale*W/2] x [-scale*H/2, scale*H/2].
      final cosA = math.cos(-transform.rotationAngle);
      final sinA = math.sin(-transform.rotationAngle);
      for (final sx in <double>[-1, 1]) {
        for (final sy in <double>[-1, 1]) {
          final cx = sx * size.width / 2;
          final cy = sy * size.height / 2;
          final rx = (cx * cosA - cy * sinA).abs();
          final ry = (cx * sinA + cy * cosA).abs();
          expect(rx, lessThanOrEqualTo(scale * size.width / 2 + 1e-6));
          expect(ry, lessThanOrEqualTo(scale * size.height / 2 + 1e-6));
        }
      }
    });

    test('centeredCropForAspectRatio produces exact ratio inside [0, 1]', () {
      final crop = PhotoTransform.centeredCropForAspectRatio(
        orientedSize: const Size(1600, 900),
        targetAspectRatio: 1.0,
      );
      expect(crop.top, closeTo(0.0, 1e-6));
      expect(crop.bottom, closeTo(1.0, 1e-6));
      expect((crop.width * 1600) / (crop.height * 900), closeTo(1.0, 1e-5));
    });
  });

  group('PhotoEditState serialization', () {
    test('full PhotoEditState JSON round-trip preserves everything', () {
      const state = PhotoEditState(
        filter: PhotoFilters.cinematic,
        filterIntensity: 0.82,
        adjustments: PhotoAdjustments(brightness: 0.15, vignette: 0.4),
        transform: PhotoTransform(
          cropRect: Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
          quarterTurns: 1,
          rotationAngle: -0.1,
          flipHorizontal: true,
        ),
        strokes: <DrawingStroke>[
          DrawingStroke(
            id: 'stroke_1',
            points: <Offset>[Offset(0.1, 0.2), Offset(0.5, 0.6)],
            color: Color(0xFFFF4D5E),
            strokeWidth: 0.015,
            tool: BrushTool.arrow,
            opacity: 0.9,
          ),
        ],
        overlays: <PhotoOverlayLayer>[
          TextOverlayLayer(
            id: 'text_1',
            text: 'Golden Hour',
            position: Offset(0.5, 0.25),
            scale: 1.25,
            rotation: 0.12,
            color: Color(0xFFFFD13B),
            backgroundStyle: TextBackgroundStyle.solid,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            textAlign: TextAlign.left,
          ),
          StickerOverlayLayer(
            id: 'sticker_1',
            content: '✨',
            position: Offset(0.8, 0.8),
            scale: 1.4,
            rotation: -0.3,
          ),
        ],
      );

      expect(state.isModified, isTrue);
      final restored = PhotoEditState.fromJson(state.toJson());
      expect(restored, equals(state));
    });
  });
}

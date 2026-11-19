import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Immutable geometric transform state for cropping, rotation, straightening,
/// and mirroring.
///
/// The [cropRect] is expressed in normalized `[0.0, 1.0]` coordinates relative
/// to the **oriented** image (after applying [quarterTurns]).
@immutable
class PhotoTransform {
  /// Creates a [PhotoTransform].
  const PhotoTransform({
    this.cropRect = fullCropRect,
    this.quarterTurns = 0,
    this.rotationAngle = 0.0,
    this.flipHorizontal = false,
    this.flipVertical = false,
  });

  /// Restores a [PhotoTransform] from a JSON map produced by [toJson].
  factory PhotoTransform.fromJson(Map<String, dynamic> json) {
    final cropMap = json['cropRect'];
    Rect parsedCrop = fullCropRect;
    if (cropMap is Map<String, dynamic>) {
      final left = ((cropMap['left'] as num?)?.toDouble() ?? 0.0).clamp(
        0.0,
        0.95,
      );
      final top = ((cropMap['top'] as num?)?.toDouble() ?? 0.0).clamp(
        0.0,
        0.95,
      );
      final right = ((cropMap['right'] as num?)?.toDouble() ?? 1.0).clamp(
        left + minCropExtent,
        1.0,
      );
      final bottom = ((cropMap['bottom'] as num?)?.toDouble() ?? 1.0).clamp(
        top + minCropExtent,
        1.0,
      );
      parsedCrop = Rect.fromLTRB(left, top, right, bottom);
    }

    final rawTurns = (json['quarterTurns'] as num?)?.toInt() ?? 0;
    final rawAngle = (json['rotationAngle'] as num?)?.toDouble() ?? 0.0;

    return PhotoTransform(
      cropRect: parsedCrop,
      quarterTurns: ((rawTurns % 4) + 4) % 4,
      rotationAngle: rawAngle.clamp(
        -maxStraightenRadians,
        maxStraightenRadians,
      ),
      flipHorizontal: json['flipHorizontal'] == true,
      flipVertical: json['flipVertical'] == true,
    );
  }

  /// Full uncropped normalized rectangle `[0, 0, 1, 1]`.
  static const Rect fullCropRect = Rect.fromLTRB(0.0, 0.0, 1.0, 1.0);

  /// Minimum normalized width/height permitted for a valid crop rectangle.
  static const double minCropExtent = 0.05;

  /// Maximum fine straighten angle in radians (`45°`).
  static const double maxStraightenRadians = math.pi / 4.0;

  /// Identity transform with no crop, rotation, straighten, or flip.
  static const PhotoTransform identity = PhotoTransform();

  /// Normalized crop region in `[0.0, 1.0]` coordinates of the oriented image.
  final Rect cropRect;

  /// Number of clockwise 90° quarter turns, normalized to `0..3`.
  final int quarterTurns;

  /// Fine straighten rotation angle in radians, clamped to `[-pi/4, pi/4]`.
  final double rotationAngle;

  /// Whether the oriented image is mirrored horizontally.
  final bool flipHorizontal;

  /// Whether the oriented image is mirrored vertically.
  final bool flipVertical;

  /// Fine straighten angle expressed in degrees (`-45.0` to `+45.0`).
  double get rotationDegrees => rotationAngle * 180.0 / math.pi;

  /// Returns `true` when no geometric transformation has been applied.
  bool get isIdentity =>
      cropRect == fullCropRect &&
      (quarterTurns % 4) == 0 &&
      rotationAngle == 0.0 &&
      !flipHorizontal &&
      !flipVertical;

  /// Returns `true` when [cropRect] differs from [fullCropRect].
  bool get isCropped =>
      (cropRect.left - 0.0).abs() > 1e-4 ||
      (cropRect.top - 0.0).abs() > 1e-4 ||
      (cropRect.right - 1.0).abs() > 1e-4 ||
      (cropRect.bottom - 1.0).abs() > 1e-4;

  /// Computes the oriented dimensions of an image of [sourceSize] after
  /// applying [quarterTurns].
  Size orientedSize(Size sourceSize) {
    if ((quarterTurns % 2).abs() == 1) {
      return Size(sourceSize.height, sourceSize.width);
    }
    return sourceSize;
  }

  /// Computes the cropped pixel size for an image of [sourceSize].
  Size croppedSize(Size sourceSize) {
    final oriented = orientedSize(sourceSize);
    return Size(
      math.max(1.0, oriented.width * cropRect.width),
      math.max(1.0, oriented.height * cropRect.height),
    );
  }

  /// Computes the exact inscribed zoom scale factor required when straightening
  /// a rectangle of [orientedSize] by [rotationAngle] so no empty background
  /// corners are exposed.
  double straightenAutoScale(Size orientedSize) {
    if (rotationAngle == 0.0 ||
        orientedSize.width <= 0 ||
        orientedSize.height <= 0) {
      return 1.0;
    }
    final cosA = math.cos(rotationAngle).abs();
    final sinA = math.sin(rotationAngle).abs();
    final scaleW =
        (orientedSize.width * cosA + orientedSize.height * sinA) /
        orientedSize.width;
    final scaleH =
        (orientedSize.width * sinA + orientedSize.height * cosA) /
        orientedSize.height;
    return math.max(scaleW, scaleH);
  }

  /// Returns a sanitized crop rectangle clamped inside `[0.0, 1.0]`.
  static Rect clampCropRect(Rect rect) {
    final width = rect.width.clamp(minCropExtent, 1.0);
    final height = rect.height.clamp(minCropExtent, 1.0);
    final left = rect.left.clamp(0.0, 1.0 - width);
    final top = rect.top.clamp(0.0, 1.0 - height);
    return Rect.fromLTWH(left, top, width, height);
  }

  /// Computes the largest centered crop rectangle inside `[0.0, 1.0]` matching
  /// [targetAspectRatio] for an oriented image with [orientedSize].
  static Rect centeredCropForAspectRatio({
    required Size orientedSize,
    required double targetAspectRatio,
  }) {
    if (orientedSize.width <= 0 ||
        orientedSize.height <= 0 ||
        targetAspectRatio <= 0) {
      return fullCropRect;
    }
    final imageRatio = orientedSize.width / orientedSize.height;
    if (targetAspectRatio > imageRatio) {
      final normHeight = (imageRatio / targetAspectRatio).clamp(
        minCropExtent,
        1.0,
      );
      final top = (1.0 - normHeight) / 2.0;
      return Rect.fromLTWH(0.0, top, 1.0, normHeight);
    } else {
      final normWidth = (targetAspectRatio / imageRatio).clamp(
        minCropExtent,
        1.0,
      );
      final left = (1.0 - normWidth) / 2.0;
      return Rect.fromLTWH(left, 0.0, normWidth, 1.0);
    }
  }

  /// Returns a new [PhotoTransform] rotated 90° clockwise, rotating [cropRect]
  /// and preserving visual mirror axes.
  PhotoTransform rotatedRight() {
    final rotatedCrop = Rect.fromLTRB(
      1.0 - cropRect.bottom,
      cropRect.left,
      1.0 - cropRect.top,
      cropRect.right,
    );
    return PhotoTransform(
      cropRect: clampCropRect(rotatedCrop),
      quarterTurns: (quarterTurns + 1) % 4,
      rotationAngle: rotationAngle,
      flipHorizontal: flipVertical,
      flipVertical: flipHorizontal,
    );
  }

  /// Returns a new [PhotoTransform] rotated 90° counter-clockwise, rotating
  /// [cropRect] and preserving visual mirror axes.
  PhotoTransform rotatedLeft() {
    final rotatedCrop = Rect.fromLTRB(
      cropRect.top,
      1.0 - cropRect.right,
      cropRect.bottom,
      1.0 - cropRect.left,
    );
    return PhotoTransform(
      cropRect: clampCropRect(rotatedCrop),
      quarterTurns: (quarterTurns + 3) % 4,
      rotationAngle: rotationAngle,
      flipHorizontal: flipVertical,
      flipVertical: flipHorizontal,
    );
  }

  /// Returns a new [PhotoTransform] mirrored horizontally, mirroring [cropRect]
  /// and preserving visual leveling.
  PhotoTransform flippedHorizontal() {
    final flippedCrop = Rect.fromLTRB(
      1.0 - cropRect.right,
      cropRect.top,
      1.0 - cropRect.left,
      cropRect.bottom,
    );
    return copyWith(
      cropRect: clampCropRect(flippedCrop),
      rotationAngle: rotationAngle == 0.0 ? 0.0 : -rotationAngle,
      flipHorizontal: !flipHorizontal,
    );
  }

  /// Returns a new [PhotoTransform] mirrored vertically, mirroring [cropRect]
  /// and preserving visual leveling.
  PhotoTransform flippedVertical() {
    final flippedCrop = Rect.fromLTRB(
      cropRect.left,
      1.0 - cropRect.bottom,
      cropRect.right,
      1.0 - cropRect.top,
    );
    return copyWith(
      cropRect: clampCropRect(flippedCrop),
      rotationAngle: rotationAngle == 0.0 ? 0.0 : -rotationAngle,
      flipVertical: !flipVertical,
    );
  }

  /// Returns a copy with selectively updated fields.
  PhotoTransform copyWith({
    Rect? cropRect,
    int? quarterTurns,
    double? rotationAngle,
    bool? flipHorizontal,
    bool? flipVertical,
  }) {
    final normalizedTurns = (((quarterTurns ?? this.quarterTurns) % 4) + 4) % 4;
    return PhotoTransform(
      cropRect: cropRect != null ? clampCropRect(cropRect) : this.cropRect,
      quarterTurns: normalizedTurns,
      rotationAngle: (rotationAngle ?? this.rotationAngle).clamp(
        -maxStraightenRadians,
        maxStraightenRadians,
      ),
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      flipVertical: flipVertical ?? this.flipVertical,
    );
  }

  /// Serializes this transform to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cropRect': <String, double>{
        'left': cropRect.left,
        'top': cropRect.top,
        'right': cropRect.right,
        'bottom': cropRect.bottom,
      },
      'quarterTurns': quarterTurns,
      'rotationAngle': rotationAngle,
      'flipHorizontal': flipHorizontal,
      'flipVertical': flipVertical,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PhotoTransform &&
        other.cropRect == cropRect &&
        other.quarterTurns == quarterTurns &&
        other.rotationAngle == rotationAngle &&
        other.flipHorizontal == flipHorizontal &&
        other.flipVertical == flipVertical;
  }

  @override
  int get hashCode => Object.hash(
    cropRect,
    quarterTurns,
    rotationAngle,
    flipHorizontal,
    flipVertical,
  );
}

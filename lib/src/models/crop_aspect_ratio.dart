import 'package:flutter/foundation.dart';

/// Represents an aspect-ratio preset for interactive cropping.
@immutable
class CropAspectRatio {
  /// Creates a [CropAspectRatio] preset.
  ///
  /// Set [ratio] to `null` for unconstrained freeform cropping, or set
  /// [useOriginalRatio] to `true` to lock to the source image's aspect ratio.
  const CropAspectRatio({
    required this.id,
    required this.label,
    this.ratio,
    this.useOriginalRatio = false,
  }) : assert(
         ratio == null || ratio > 0,
         'Aspect ratio must be strictly positive when provided.',
       );

  /// Unconstrained freeform crop.
  static const CropAspectRatio free = CropAspectRatio(
    id: 'free',
    label: 'Free',
  );

  /// Locks the crop frame to the original image's aspect ratio.
  static const CropAspectRatio original = CropAspectRatio(
    id: 'original',
    label: 'Original',
    useOriginalRatio: true,
  );

  /// Square `1:1` crop ratio.
  static const CropAspectRatio square = CropAspectRatio(
    id: '1:1',
    label: '1:1',
    ratio: 1.0,
  );

  /// Classic `4:3` landscape crop ratio.
  static const CropAspectRatio ratio4x3 = CropAspectRatio(
    id: '4:3',
    label: '4:3',
    ratio: 4.0 / 3.0,
  );

  /// Classic `3:2` DSLR photo ratio.
  static const CropAspectRatio ratio3x2 = CropAspectRatio(
    id: '3:2',
    label: '3:2',
    ratio: 3.0 / 2.0,
  );

  /// Widescreen `16:9` ratio.
  static const CropAspectRatio ratio16x9 = CropAspectRatio(
    id: '16:9',
    label: '16:9',
    ratio: 16.0 / 9.0,
  );

  /// Portrait `4:5` social feed ratio.
  static const CropAspectRatio ratio4x5 = CropAspectRatio(
    id: '4:5',
    label: '4:5',
    ratio: 4.0 / 5.0,
  );

  /// Vertical `9:16` stories/reels ratio.
  static const CropAspectRatio ratio9x16 = CropAspectRatio(
    id: '9:16',
    label: '9:16',
    ratio: 9.0 / 16.0,
  );

  /// Default built-in aspect ratio presets.
  static const List<CropAspectRatio> presets = <CropAspectRatio>[
    free,
    original,
    square,
    ratio4x3,
    ratio3x2,
    ratio16x9,
    ratio4x5,
    ratio9x16,
  ];

  /// Unique identifier for this preset.
  final String id;

  /// Human-readable label displayed in the crop selector.
  final String label;

  /// Fixed width-to-height ratio, or `null` when freeform or [useOriginalRatio].
  final double? ratio;

  /// When `true`, resolves to the oriented source image's aspect ratio.
  final bool useOriginalRatio;

  /// Resolves the effective width-to-height ratio given the [orientedAspectRatio]
  /// of the image, or returns `null` for freeform cropping.
  double? resolve(double orientedAspectRatio) {
    if (useOriginalRatio) {
      return orientedAspectRatio;
    }
    return ratio;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CropAspectRatio &&
        other.id == id &&
        other.label == label &&
        other.ratio == ratio &&
        other.useOriginalRatio == useOriginalRatio;
  }

  @override
  int get hashCode => Object.hash(id, label, ratio, useOriginalRatio);
}

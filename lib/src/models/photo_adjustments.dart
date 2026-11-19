import 'package:flutter/foundation.dart';

/// Identifies an individual photo adjustment parameter.
enum PhotoAdjustmentType {
  /// Overall additive brightness (`-1.0` to `1.0`).
  brightness,

  /// Midtone contrast expansion or compression (`-1.0` to `1.0`).
  contrast,

  /// Color saturation (`-1.0` grayscale to `1.0` vivid).
  saturation,

  /// Photographic exposure stops (`-1.0` to `1.0`).
  exposure,

  /// Color temperature shift from cool blue (`-1.0`) to warm amber (`1.0`).
  warmth,

  /// Green (`-1.0`) to magenta (`1.0`) white-balance tint.
  tint,

  /// Matte lifted shadows fade (`0.0` to `1.0`).
  fade,

  /// Midtone micro-contrast clarity punch (`0.0` to `1.0`).
  clarity,

  /// Radial corner darkening vignette (`0.0` to `1.0`).
  vignette,

  /// Gaussian blur intensity (`0.0` to `1.0`).
  blur,
}

/// Immutable set of real-time tonal, color, and optical photo adjustments.
@immutable
class PhotoAdjustments {
  /// Creates a [PhotoAdjustments] configuration.
  ///
  /// Bipolar controls default to `0.0` within `[-1.0, 1.0]`; unipolar controls
  /// ([fade], [clarity], [vignette], [blur]) default to `0.0` within `[0.0, 1.0]`.
  const PhotoAdjustments({
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.exposure = 0.0,
    this.warmth = 0.0,
    this.tint = 0.0,
    this.fade = 0.0,
    this.clarity = 0.0,
    this.vignette = 0.0,
    this.blur = 0.0,
  });

  /// Restores [PhotoAdjustments] from a JSON map produced by [toJson].
  factory PhotoAdjustments.fromJson(Map<String, dynamic> json) {
    double readBipolar(String key) {
      final raw = json[key];
      if (raw is num) {
        return raw.toDouble().clamp(-1.0, 1.0);
      }
      return 0.0;
    }

    double readUnipolar(String key) {
      final raw = json[key];
      if (raw is num) {
        return raw.toDouble().clamp(0.0, 1.0);
      }
      return 0.0;
    }

    return PhotoAdjustments(
      brightness: readBipolar('brightness'),
      contrast: readBipolar('contrast'),
      saturation: readBipolar('saturation'),
      exposure: readBipolar('exposure'),
      warmth: readBipolar('warmth'),
      tint: readBipolar('tint'),
      fade: readUnipolar('fade'),
      clarity: readUnipolar('clarity'),
      vignette: readUnipolar('vignette'),
      blur: readUnipolar('blur'),
    );
  }

  /// Neutral identity adjustments where all parameters are zero.
  static const PhotoAdjustments none = PhotoAdjustments();

  /// Additive brightness in `[-1.0, 1.0]`.
  final double brightness;

  /// Contrast adjustment in `[-1.0, 1.0]`.
  final double contrast;

  /// Saturation adjustment in `[-1.0, 1.0]`.
  final double saturation;

  /// Photographic exposure adjustment in `[-1.0, 1.0]`.
  final double exposure;

  /// Warmth (temperature) adjustment in `[-1.0, 1.0]`.
  final double warmth;

  /// Green/magenta tint adjustment in `[-1.0, 1.0]`.
  final double tint;

  /// Matte film fade amount in `[0.0, 1.0]`.
  final double fade;

  /// Midtone clarity punch in `[0.0, 1.0]`.
  final double clarity;

  /// Radial vignette darkening strength in `[0.0, 1.0]`.
  final double vignette;

  /// Gaussian blur intensity in `[0.0, 1.0]`.
  final double blur;

  /// Returns `true` if all adjustment parameters are effectively zero.
  bool get isDefault =>
      brightness == 0.0 &&
      contrast == 0.0 &&
      saturation == 0.0 &&
      exposure == 0.0 &&
      warmth == 0.0 &&
      tint == 0.0 &&
      fade == 0.0 &&
      clarity == 0.0 &&
      vignette == 0.0 &&
      blur == 0.0;

  /// Returns the current value for a given [type].
  double valueFor(PhotoAdjustmentType type) {
    switch (type) {
      case PhotoAdjustmentType.brightness:
        return brightness;
      case PhotoAdjustmentType.contrast:
        return contrast;
      case PhotoAdjustmentType.saturation:
        return saturation;
      case PhotoAdjustmentType.exposure:
        return exposure;
      case PhotoAdjustmentType.warmth:
        return warmth;
      case PhotoAdjustmentType.tint:
        return tint;
      case PhotoAdjustmentType.fade:
        return fade;
      case PhotoAdjustmentType.clarity:
        return clarity;
      case PhotoAdjustmentType.vignette:
        return vignette;
      case PhotoAdjustmentType.blur:
        return blur;
    }
  }

  /// Returns the minimum valid range value for a given [type].
  static double minFor(PhotoAdjustmentType type) {
    switch (type) {
      case PhotoAdjustmentType.fade:
      case PhotoAdjustmentType.clarity:
      case PhotoAdjustmentType.vignette:
      case PhotoAdjustmentType.blur:
        return 0.0;
      case PhotoAdjustmentType.brightness:
      case PhotoAdjustmentType.contrast:
      case PhotoAdjustmentType.saturation:
      case PhotoAdjustmentType.exposure:
      case PhotoAdjustmentType.warmth:
      case PhotoAdjustmentType.tint:
        return -1.0;
    }
  }

  /// Returns the maximum valid range value for a given [type].
  static double maxFor(PhotoAdjustmentType type) => 1.0;

  /// Returns a copy of these adjustments with the single [type] set to [value],
  /// clamped to the valid bounds for [type].
  PhotoAdjustments withValue(PhotoAdjustmentType type, double value) {
    final clamped = value.clamp(minFor(type), maxFor(type));
    switch (type) {
      case PhotoAdjustmentType.brightness:
        return copyWith(brightness: clamped);
      case PhotoAdjustmentType.contrast:
        return copyWith(contrast: clamped);
      case PhotoAdjustmentType.saturation:
        return copyWith(saturation: clamped);
      case PhotoAdjustmentType.exposure:
        return copyWith(exposure: clamped);
      case PhotoAdjustmentType.warmth:
        return copyWith(warmth: clamped);
      case PhotoAdjustmentType.tint:
        return copyWith(tint: clamped);
      case PhotoAdjustmentType.fade:
        return copyWith(fade: clamped);
      case PhotoAdjustmentType.clarity:
        return copyWith(clarity: clamped);
      case PhotoAdjustmentType.vignette:
        return copyWith(vignette: clamped);
      case PhotoAdjustmentType.blur:
        return copyWith(blur: clamped);
    }
  }

  /// Returns a copy with selectively updated adjustment fields.
  PhotoAdjustments copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? exposure,
    double? warmth,
    double? tint,
    double? fade,
    double? clarity,
    double? vignette,
    double? blur,
  }) {
    return PhotoAdjustments(
      brightness: (brightness ?? this.brightness).clamp(-1.0, 1.0),
      contrast: (contrast ?? this.contrast).clamp(-1.0, 1.0),
      saturation: (saturation ?? this.saturation).clamp(-1.0, 1.0),
      exposure: (exposure ?? this.exposure).clamp(-1.0, 1.0),
      warmth: (warmth ?? this.warmth).clamp(-1.0, 1.0),
      tint: (tint ?? this.tint).clamp(-1.0, 1.0),
      fade: (fade ?? this.fade).clamp(0.0, 1.0),
      clarity: (clarity ?? this.clarity).clamp(0.0, 1.0),
      vignette: (vignette ?? this.vignette).clamp(0.0, 1.0),
      blur: (blur ?? this.blur).clamp(0.0, 1.0),
    );
  }

  /// Serializes these adjustments to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
      'exposure': exposure,
      'warmth': warmth,
      'tint': tint,
      'fade': fade,
      'clarity': clarity,
      'vignette': vignette,
      'blur': blur,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PhotoAdjustments &&
        other.brightness == brightness &&
        other.contrast == contrast &&
        other.saturation == saturation &&
        other.exposure == exposure &&
        other.warmth == warmth &&
        other.tint == tint &&
        other.fade == fade &&
        other.clarity == clarity &&
        other.vignette == vignette &&
        other.blur == blur;
  }

  @override
  int get hashCode => Object.hash(
    brightness,
    contrast,
    saturation,
    exposure,
    warmth,
    tint,
    fade,
    clarity,
    vignette,
    blur,
  );
}

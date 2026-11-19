import 'package:flutter/foundation.dart';

/// Identifies an individual pro photo adjustment parameter.
enum PhotoAdjustmentType {
  /// Photographic exposure stops (`-1.0` to `1.0`).
  exposure,

  /// Overall additive brightness (`-1.0` to `1.0`).
  brightness,

  /// Midtone contrast expansion or compression (`-1.0` to `1.0`).
  contrast,

  /// Non-linear bright highlight recovery or boost (`-1.0` to `1.0`).
  highlights,

  /// Non-linear dark shadow lift or deepening (`-1.0` to `1.0`).
  shadows,

  /// Color saturation (`-1.0` grayscale to `1.0` vivid).
  saturation,

  /// Intelligent midtone vibrancy (`-1.0` to `1.0`).
  vibrance,

  /// Color temperature shift from cool blue (`-1.0`) to warm amber (`1.0`).
  warmth,

  /// Green (`-1.0`) to magenta (`1.0`) white-balance tint.
  tint,

  /// Midtone micro-contrast clarity punch (`0.0` to `1.0`).
  clarity,

  /// Matte lifted shadows fade (`0.0` to `1.0`).
  fade,

  /// Radial corner darkening vignette (`0.0` to `1.0`).
  vignette,

  /// Organic analog film grain texture (`0.0` to `1.0`).
  grain,

  /// Gaussian blur intensity (`0.0` to `1.0`).
  blur,
}

/// Immutable set of 14 real-time tonal, color, optical, and texture photo
/// adjustments modeled after pro desktop color-grading suites.
@immutable
class PhotoAdjustments {
  /// Creates a [PhotoAdjustments] configuration.
  ///
  /// Bipolar controls default to `0.0` within `[-1.0, 1.0]`; unipolar controls
  /// ([clarity], [fade], [vignette], [grain], [blur]) default to `0.0` within
  /// `[0.0, 1.0]`.
  const PhotoAdjustments({
    this.exposure = 0.0,
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.saturation = 0.0,
    this.vibrance = 0.0,
    this.warmth = 0.0,
    this.tint = 0.0,
    this.clarity = 0.0,
    this.fade = 0.0,
    this.vignette = 0.0,
    this.grain = 0.0,
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
      exposure: readBipolar('exposure'),
      brightness: readBipolar('brightness'),
      contrast: readBipolar('contrast'),
      highlights: readBipolar('highlights'),
      shadows: readBipolar('shadows'),
      saturation: readBipolar('saturation'),
      vibrance: readBipolar('vibrance'),
      warmth: readBipolar('warmth'),
      tint: readBipolar('tint'),
      clarity: readUnipolar('clarity'),
      fade: readUnipolar('fade'),
      vignette: readUnipolar('vignette'),
      grain: readUnipolar('grain'),
      blur: readUnipolar('blur'),
    );
  }

  /// Neutral identity adjustments where all parameters are zero.
  static const PhotoAdjustments none = PhotoAdjustments();

  /// Photographic exposure adjustment in `[-1.0, 1.0]`.
  final double exposure;

  /// Additive brightness in `[-1.0, 1.0]`.
  final double brightness;

  /// Contrast adjustment in `[-1.0, 1.0]`.
  final double contrast;

  /// Bright highlight recovery (`< 0`) or boost (`> 0`) in `[-1.0, 1.0]`.
  final double highlights;

  /// Dark shadow deepening (`< 0`) or lift (`> 0`) in `[-1.0, 1.0]`.
  final double shadows;

  /// Saturation adjustment in `[-1.0, 1.0]`.
  final double saturation;

  /// Subtle balanced vibrance boost in `[-1.0, 1.0]`.
  final double vibrance;

  /// Warmth (temperature) adjustment in `[-1.0, 1.0]`.
  final double warmth;

  /// Green/magenta tint adjustment in `[-1.0, 1.0]`.
  final double tint;

  /// Midtone clarity punch in `[0.0, 1.0]`.
  final double clarity;

  /// Matte film fade amount in `[0.0, 1.0]`.
  final double fade;

  /// Radial vignette darkening strength in `[0.0, 1.0]`.
  final double vignette;

  /// Organic analog film grain strength in `[0.0, 1.0]`.
  final double grain;

  /// Gaussian blur intensity in `[0.0, 1.0]`.
  final double blur;

  /// Returns `true` if all adjustment parameters are effectively zero.
  bool get isDefault =>
      exposure == 0.0 &&
      brightness == 0.0 &&
      contrast == 0.0 &&
      highlights == 0.0 &&
      shadows == 0.0 &&
      saturation == 0.0 &&
      vibrance == 0.0 &&
      warmth == 0.0 &&
      tint == 0.0 &&
      clarity == 0.0 &&
      fade == 0.0 &&
      vignette == 0.0 &&
      grain == 0.0 &&
      blur == 0.0;

  /// Returns the current value for a given [type].
  double valueFor(PhotoAdjustmentType type) {
    switch (type) {
      case PhotoAdjustmentType.exposure:
        return exposure;
      case PhotoAdjustmentType.brightness:
        return brightness;
      case PhotoAdjustmentType.contrast:
        return contrast;
      case PhotoAdjustmentType.highlights:
        return highlights;
      case PhotoAdjustmentType.shadows:
        return shadows;
      case PhotoAdjustmentType.saturation:
        return saturation;
      case PhotoAdjustmentType.vibrance:
        return vibrance;
      case PhotoAdjustmentType.warmth:
        return warmth;
      case PhotoAdjustmentType.tint:
        return tint;
      case PhotoAdjustmentType.clarity:
        return clarity;
      case PhotoAdjustmentType.fade:
        return fade;
      case PhotoAdjustmentType.vignette:
        return vignette;
      case PhotoAdjustmentType.grain:
        return grain;
      case PhotoAdjustmentType.blur:
        return blur;
    }
  }

  /// Returns the minimum valid range value for a given [type].
  static double minFor(PhotoAdjustmentType type) {
    switch (type) {
      case PhotoAdjustmentType.clarity:
      case PhotoAdjustmentType.fade:
      case PhotoAdjustmentType.vignette:
      case PhotoAdjustmentType.grain:
      case PhotoAdjustmentType.blur:
        return 0.0;
      case PhotoAdjustmentType.exposure:
      case PhotoAdjustmentType.brightness:
      case PhotoAdjustmentType.contrast:
      case PhotoAdjustmentType.highlights:
      case PhotoAdjustmentType.shadows:
      case PhotoAdjustmentType.saturation:
      case PhotoAdjustmentType.vibrance:
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
      case PhotoAdjustmentType.exposure:
        return copyWith(exposure: clamped);
      case PhotoAdjustmentType.brightness:
        return copyWith(brightness: clamped);
      case PhotoAdjustmentType.contrast:
        return copyWith(contrast: clamped);
      case PhotoAdjustmentType.highlights:
        return copyWith(highlights: clamped);
      case PhotoAdjustmentType.shadows:
        return copyWith(shadows: clamped);
      case PhotoAdjustmentType.saturation:
        return copyWith(saturation: clamped);
      case PhotoAdjustmentType.vibrance:
        return copyWith(vibrance: clamped);
      case PhotoAdjustmentType.warmth:
        return copyWith(warmth: clamped);
      case PhotoAdjustmentType.tint:
        return copyWith(tint: clamped);
      case PhotoAdjustmentType.clarity:
        return copyWith(clarity: clamped);
      case PhotoAdjustmentType.fade:
        return copyWith(fade: clamped);
      case PhotoAdjustmentType.vignette:
        return copyWith(vignette: clamped);
      case PhotoAdjustmentType.grain:
        return copyWith(grain: clamped);
      case PhotoAdjustmentType.blur:
        return copyWith(blur: clamped);
    }
  }

  /// Returns a copy with selectively updated adjustment fields.
  PhotoAdjustments copyWith({
    double? exposure,
    double? brightness,
    double? contrast,
    double? highlights,
    double? shadows,
    double? saturation,
    double? vibrance,
    double? warmth,
    double? tint,
    double? clarity,
    double? fade,
    double? vignette,
    double? grain,
    double? blur,
  }) {
    return PhotoAdjustments(
      exposure: (exposure ?? this.exposure).clamp(-1.0, 1.0),
      brightness: (brightness ?? this.brightness).clamp(-1.0, 1.0),
      contrast: (contrast ?? this.contrast).clamp(-1.0, 1.0),
      highlights: (highlights ?? this.highlights).clamp(-1.0, 1.0),
      shadows: (shadows ?? this.shadows).clamp(-1.0, 1.0),
      saturation: (saturation ?? this.saturation).clamp(-1.0, 1.0),
      vibrance: (vibrance ?? this.vibrance).clamp(-1.0, 1.0),
      warmth: (warmth ?? this.warmth).clamp(-1.0, 1.0),
      tint: (tint ?? this.tint).clamp(-1.0, 1.0),
      clarity: (clarity ?? this.clarity).clamp(0.0, 1.0),
      fade: (fade ?? this.fade).clamp(0.0, 1.0),
      vignette: (vignette ?? this.vignette).clamp(0.0, 1.0),
      grain: (grain ?? this.grain).clamp(0.0, 1.0),
      blur: (blur ?? this.blur).clamp(0.0, 1.0),
    );
  }

  /// Serializes these adjustments to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'exposure': exposure,
      'brightness': brightness,
      'contrast': contrast,
      'highlights': highlights,
      'shadows': shadows,
      'saturation': saturation,
      'vibrance': vibrance,
      'warmth': warmth,
      'tint': tint,
      'clarity': clarity,
      'fade': fade,
      'vignette': vignette,
      'grain': grain,
      'blur': blur,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PhotoAdjustments &&
        other.exposure == exposure &&
        other.brightness == brightness &&
        other.contrast == contrast &&
        other.highlights == highlights &&
        other.shadows == shadows &&
        other.saturation == saturation &&
        other.vibrance == vibrance &&
        other.warmth == warmth &&
        other.tint == tint &&
        other.clarity == clarity &&
        other.fade == fade &&
        other.vignette == vignette &&
        other.grain == grain &&
        other.blur == blur;
  }

  @override
  int get hashCode => Object.hash(
    exposure,
    brightness,
    contrast,
    highlights,
    shadows,
    saturation,
    vibrance,
    warmth,
    tint,
    clarity,
    fade,
    vignette,
    grain,
    blur,
  );
}

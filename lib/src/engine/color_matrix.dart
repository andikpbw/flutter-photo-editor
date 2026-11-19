import 'dart:math' as math;

import '../models/photo_adjustments.dart';
import '../models/photo_filter.dart';

/// Pure mathematical utilities for composing 4x5 RGBA color matrices compatible
/// with Flutter's `ColorFilter.matrix`.
abstract final class PhotoColorMatrix {
  /// Identity 4x5 RGBA matrix that leaves all pixels unchanged.
  static const List<double> identity = <double>[
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  /// Returns `true` if [matrix] is effectively equal to [identity].
  static bool isIdentity(List<double> matrix, {double epsilon = 1e-4}) {
    if (matrix.length != 20) {
      return false;
    }
    for (var i = 0; i < 20; i++) {
      if ((matrix[i] - identity[i]).abs() > epsilon) {
        return false;
      }
    }
    return true;
  }

  /// Multiplies two 4x5 color matrices (`first` applied first, then `second`).
  static List<double> multiply(List<double> second, List<double> first) {
    assert(second.length == 20 && first.length == 20);
    final result = List<double>.filled(20, 0.0);
    for (var row = 0; row < 4; row++) {
      final r = row * 5;
      for (var col = 0; col < 4; col++) {
        result[r + col] =
            second[r] * first[col] +
            second[r + 1] * first[5 + col] +
            second[r + 2] * first[10 + col] +
            second[r + 3] * first[15 + col];
      }
      result[r + 4] =
          second[r] * first[4] +
          second[r + 1] * first[9] +
          second[r + 2] * first[14] +
          second[r + 3] * first[19] +
          second[r + 4];
    }
    return result;
  }

  /// Linearly interpolates between two 4x5 color matrices [a] and [b] by [t].
  static List<double> lerp(List<double> a, List<double> b, double t) {
    assert(a.length == 20 && b.length == 20);
    final factor = t.clamp(0.0, 1.0);
    if (factor <= 0.0) {
      return List<double>.of(a);
    }
    if (factor >= 1.0) {
      return List<double>.of(b);
    }
    final inv = 1.0 - factor;
    return List<double>.generate(
      20,
      (i) => a[i] * inv + b[i] * factor,
      growable: false,
    );
  }

  /// Builds an exposure matrix (`value` in `[-1.0, 1.0]`, photographic stops).
  static List<double> exposure(double value) {
    final v = value.clamp(-1.0, 1.0);
    if (v == 0.0) {
      return List<double>.of(identity);
    }
    final gain = math.pow(2.0, v).toDouble();
    return <double>[
      gain,
      0,
      0,
      0,
      0,
      0,
      gain,
      0,
      0,
      0,
      0,
      0,
      gain,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  /// Builds an additive brightness matrix (`value` in `[-1.0, 1.0]`).
  static List<double> brightness(double value) {
    final v = value.clamp(-1.0, 1.0);
    if (v == 0.0) {
      return List<double>.of(identity);
    }
    final offset = v * 110.0;
    return <double>[
      1,
      0,
      0,
      0,
      offset,
      0,
      1,
      0,
      0,
      offset,
      0,
      0,
      1,
      0,
      offset,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  /// Builds a midtone-anchored contrast matrix (`value` in `[-1.0, 1.0]`).
  static List<double> contrast(double value) {
    final v = value.clamp(-1.0, 1.0);
    if (v == 0.0) {
      return List<double>.of(identity);
    }
    final scale = v >= 0.0 ? 1.0 + v * 1.15 : 1.0 + v * 0.72;
    final offset = 128.0 * (1.0 - scale);
    return <double>[
      scale,
      0,
      0,
      0,
      offset,
      0,
      scale,
      0,
      0,
      offset,
      0,
      0,
      scale,
      0,
      offset,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  /// Builds a Rec.709 luminance-preserving saturation matrix (`value` in `[-1.0, 1.0]`).
  static List<double> saturation(double value) {
    final v = value.clamp(-1.0, 1.0);
    if (v == 0.0) {
      return List<double>.of(identity);
    }
    final s = 1.0 + v;
    const rw = 0.2126;
    const gw = 0.7152;
    const bw = 0.0722;
    final inv = 1.0 - s;
    final r = inv * rw;
    final g = inv * gw;
    final b = inv * bw;
    return <double>[
      r + s,
      g,
      b,
      0,
      0,
      r,
      g + s,
      b,
      0,
      0,
      r,
      g,
      b + s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  /// Builds a color-temperature warmth matrix (`-1.0` cool blue to `1.0` warm amber).
  static List<double> warmth(double value) {
    final v = value.clamp(-1.0, 1.0);
    if (v == 0.0) {
      return List<double>.of(identity);
    }
    final rScale = 1.0 + v * 0.14;
    final gScale = 1.0 + v * 0.03;
    final bScale = 1.0 - v * 0.16;
    final rOffset = v * 10.0;
    final bOffset = -v * 10.0;
    return <double>[
      rScale,
      0,
      0,
      0,
      rOffset,
      0,
      gScale,
      0,
      0,
      0,
      0,
      0,
      bScale,
      0,
      bOffset,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  /// Builds a green (`-1.0`) to magenta (`1.0`) white-balance tint matrix.
  static List<double> tint(double value) {
    final v = value.clamp(-1.0, 1.0);
    if (v == 0.0) {
      return List<double>.of(identity);
    }
    final rScale = 1.0 + v * 0.08;
    final gScale = 1.0 - v * 0.14;
    final bScale = 1.0 + v * 0.08;
    final gOffset = -v * 8.0;
    return <double>[
      rScale,
      0,
      0,
      0,
      0,
      0,
      gScale,
      0,
      0,
      gOffset,
      0,
      0,
      bScale,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  /// Builds a matte lifted-blacks film fade matrix (`value` in `[0.0, 1.0]`).
  static List<double> fade(double value) {
    final v = value.clamp(0.0, 1.0);
    if (v == 0.0) {
      return List<double>.of(identity);
    }
    final scale = 1.0 - 0.24 * v;
    final lift = 42.0 * v;
    return <double>[
      scale,
      0,
      0,
      0,
      lift,
      0,
      scale,
      0,
      0,
      lift,
      0,
      0,
      scale,
      0,
      lift,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  /// Builds a clarity micro-contrast + vibrancy punch matrix (`value` in `[0.0, 1.0]`).
  static List<double> clarity(double value) {
    final v = value.clamp(0.0, 1.0);
    if (v == 0.0) {
      return List<double>.of(identity);
    }
    final c = contrast(v * 0.28);
    final s = saturation(v * 0.16);
    return multiply(s, c);
  }

  /// Composes a single 4x5 RGBA color matrix combining [filter] at
  /// [filterIntensity] with all matrix-based [adjustments].
  static List<double> compose({
    PhotoFilter filter = PhotoFilters.original,
    double filterIntensity = 1.0,
    PhotoAdjustments adjustments = PhotoAdjustments.none,
  }) {
    var result = List<double>.of(identity);

    if (!filter.isOriginal && filterIntensity > 0.0) {
      result = lerp(identity, filter.matrix, filterIntensity);
    }
    if (adjustments.exposure != 0.0) {
      result = multiply(exposure(adjustments.exposure), result);
    }
    if (adjustments.brightness != 0.0) {
      result = multiply(brightness(adjustments.brightness), result);
    }
    if (adjustments.contrast != 0.0) {
      result = multiply(contrast(adjustments.contrast), result);
    }
    if (adjustments.saturation != 0.0) {
      result = multiply(saturation(adjustments.saturation), result);
    }
    if (adjustments.warmth != 0.0) {
      result = multiply(warmth(adjustments.warmth), result);
    }
    if (adjustments.tint != 0.0) {
      result = multiply(tint(adjustments.tint), result);
    }
    if (adjustments.clarity != 0.0) {
      result = multiply(clarity(adjustments.clarity), result);
    }
    if (adjustments.fade != 0.0) {
      result = multiply(fade(adjustments.fade), result);
    }
    return result;
  }
}

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/photo_adjustments.dart';
import '../models/photo_filter.dart';
import 'color_matrix.dart';

/// Normalized per-channel RGB and luminance histogram buckets (`0.0..1.0`).
@immutable
class PhotoHistogramData {
  /// Creates a [PhotoHistogramData] snapshot.
  const PhotoHistogramData({
    required this.red,
    required this.green,
    required this.blue,
    required this.luminance,
  });

  /// Empty flat histogram with 64 zeroed bins.
  static final PhotoHistogramData empty = PhotoHistogramData(
    red: List<double>.filled(64, 0.0),
    green: List<double>.filled(64, 0.0),
    blue: List<double>.filled(64, 0.0),
    luminance: List<double>.filled(64, 0.0),
  );

  /// Normalized red channel distribution (`0.0` to `1.0`).
  final List<double> red;

  /// Normalized green channel distribution (`0.0` to `1.0`).
  final List<double> green;

  /// Normalized blue channel distribution (`0.0` to `1.0`).
  final List<double> blue;

  /// Normalized Rec.709 luminance distribution (`0.0` to `1.0`).
  final List<double> luminance;

  /// Number of tonal buckets per channel.
  int get binCount => luminance.length;
}

/// Computes live RGB and luminance histograms from an RGBA image buffer with
/// optional real-time color grading ([PhotoFilter] and [PhotoAdjustments]).
abstract final class PhotoHistogramCalculator {
  /// Computes a normalized [PhotoHistogramData] with [bins] tonal buckets from
  /// [rgba] pixel bytes, projecting each pixel through [filter] at
  /// [filterIntensity] and [adjustments].
  static PhotoHistogramData computeFromRgba(
    Uint8List rgba, {
    PhotoFilter filter = PhotoFilters.original,
    double filterIntensity = 1.0,
    PhotoAdjustments adjustments = PhotoAdjustments.none,
    int bins = 64,
  }) {
    if (rgba.length < 4 || bins < 4) {
      return PhotoHistogramData.empty;
    }

    final matrix = PhotoColorMatrix.compose(
      filter: filter,
      filterIntensity: filterIntensity,
      adjustments: adjustments,
    );
    final isIdentity = PhotoColorMatrix.isIdentity(matrix);
    final shadows = adjustments.shadows;
    final highlights = adjustments.highlights;

    final rBins = Int32List(bins);
    final gBins = Int32List(bins);
    final bBins = Int32List(bins);
    final lBins = Int32List(bins);

    final scaleToBin = (bins - 1) / 255.0;
    final pixelCount = rgba.length ~/ 4;
    // Stride large images cleanly while keeping full accuracy on thumbnails.
    final stride = pixelCount > 24000 ? (pixelCount ~/ 24000) : 1;

    for (var px = 0; px < pixelCount; px += stride) {
      final offset = px * 4;
      final a = rgba[offset + 3];
      if (a == 0) {
        continue;
      }

      var r = rgba[offset].toDouble();
      var g = rgba[offset + 1].toDouble();
      var b = rgba[offset + 2].toDouble();

      if (!isIdentity) {
        final nr =
            matrix[0] * r +
            matrix[1] * g +
            matrix[2] * b +
            matrix[3] * a +
            matrix[4];
        final ng =
            matrix[5] * r +
            matrix[6] * g +
            matrix[7] * b +
            matrix[8] * a +
            matrix[9];
        final nb =
            matrix[10] * r +
            matrix[11] * g +
            matrix[12] * b +
            matrix[13] * a +
            matrix[14];
        r = nr.clamp(0.0, 255.0);
        g = ng.clamp(0.0, 255.0);
        b = nb.clamp(0.0, 255.0);
      }

      if (shadows != 0.0 || highlights != 0.0) {
        final lumaNorm = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0;
        final shadowWeight = (1.0 - lumaNorm) * (1.0 - lumaNorm);
        final highlightWeight = lumaNorm * lumaNorm;
        final delta =
            shadows * 68.0 * shadowWeight + highlights * 68.0 * highlightWeight;
        r = (r + delta).clamp(0.0, 255.0);
        g = (g + delta).clamp(0.0, 255.0);
        b = (b + delta).clamp(0.0, 255.0);
      }

      final luma = (0.2126 * r + 0.7152 * g + 0.0722 * b).clamp(0.0, 255.0);

      rBins[(r * scaleToBin).round().clamp(0, bins - 1)] += 1;
      gBins[(g * scaleToBin).round().clamp(0, bins - 1)] += 1;
      bBins[(b * scaleToBin).round().clamp(0, bins - 1)] += 1;
      lBins[(luma * scaleToBin).round().clamp(0, bins - 1)] += 1;
    }

    // Ignore clipped extreme shadow/highlight edge bins when computing peak so
    // midtone RGB tonal distribution remains vivid and legible like Lightroom.
    final startBin = bins > 8 ? 3 : 0;
    final endBin = bins > 8 ? bins - 3 : bins;
    var peak = 1;
    for (var i = startBin; i < endBin; i++) {
      peak = math.max(peak, rBins[i]);
      peak = math.max(peak, gBins[i]);
      peak = math.max(peak, bBins[i]);
      peak = math.max(peak, lBins[i]);
    }
    if (peak <= 1) {
      for (var i = 0; i < bins; i++) {
        peak = math.max(peak, rBins[i]);
        peak = math.max(peak, gBins[i]);
        peak = math.max(peak, bBins[i]);
        peak = math.max(peak, lBins[i]);
      }
    }
    final invPeak = 1.0 / math.max(1, peak);

    double shape(int count) {
      final linear = (count * invPeak).clamp(0.0, 1.0);
      return math.pow(linear, 0.72).toDouble().clamp(0.0, 1.0);
    }

    return PhotoHistogramData(
      red: List<double>.generate(bins, (i) => shape(rBins[i]), growable: false),
      green: List<double>.generate(
        bins,
        (i) => shape(gBins[i]),
        growable: false,
      ),
      blue: List<double>.generate(
        bins,
        (i) => shape(bBins[i]),
        growable: false,
      ),
      luminance: List<double>.generate(
        bins,
        (i) => shape(lBins[i]),
        growable: false,
      ),
    );
  }
}

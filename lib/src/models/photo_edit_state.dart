import 'package:flutter/foundation.dart';

import 'drawing_stroke.dart';
import 'overlay_layer.dart';
import 'photo_adjustments.dart';
import 'photo_filter.dart';
import 'photo_frame.dart';
import 'photo_transform.dart';

/// Complete immutable snapshot of all non-destructive edits applied to a photo.
///
/// Can be persisted and restored via [toJson] and [PhotoEditState.fromJson].
@immutable
class PhotoEditState {
  /// Creates a [PhotoEditState].
  const PhotoEditState({
    this.filter = PhotoFilters.original,
    this.filterIntensity = 1.0,
    this.adjustments = PhotoAdjustments.none,
    this.transform = PhotoTransform.identity,
    this.frame = PhotoFrame.none,
    this.strokes = const <DrawingStroke>[],
    this.overlays = const <PhotoOverlayLayer>[],
  });

  /// Restores a [PhotoEditState] from a JSON map produced by [toJson].
  ///
  /// Supply [extraFilters] if custom filters were registered in your app.
  factory PhotoEditState.fromJson(
    Map<String, dynamic> json, {
    List<PhotoFilter>? extraFilters,
  }) {
    final filterId = (json['filterId'] as String?) ?? PhotoFilters.original.id;
    final filterIntensity =
        ((json['filterIntensity'] as num?)?.toDouble() ?? 1.0).clamp(0.0, 1.0);

    final adjustmentsMap = json['adjustments'];
    final adjustments = adjustmentsMap is Map<String, dynamic>
        ? PhotoAdjustments.fromJson(adjustmentsMap)
        : PhotoAdjustments.none;

    final transformMap = json['transform'];
    final transform = transformMap is Map<String, dynamic>
        ? PhotoTransform.fromJson(transformMap)
        : PhotoTransform.identity;

    final frameMap = json['frame'];
    final frame = frameMap is Map<String, dynamic>
        ? PhotoFrame.fromJson(frameMap)
        : PhotoFrame.none;

    final rawStrokes = json['strokes'];
    final strokes = <DrawingStroke>[];
    if (rawStrokes is List<dynamic>) {
      for (final item in rawStrokes) {
        if (item is Map<String, dynamic>) {
          strokes.add(DrawingStroke.fromJson(item));
        }
      }
    }

    final rawOverlays = json['overlays'];
    final overlays = <PhotoOverlayLayer>[];
    if (rawOverlays is List<dynamic>) {
      for (final item in rawOverlays) {
        if (item is Map<String, dynamic>) {
          overlays.add(PhotoOverlayLayer.fromJson(item));
        }
      }
    }

    return PhotoEditState(
      filter: PhotoFilters.byId(filterId, extraFilters: extraFilters),
      filterIntensity: filterIntensity,
      adjustments: adjustments,
      transform: transform,
      frame: frame,
      strokes: List<DrawingStroke>.unmodifiable(strokes),
      overlays: List<PhotoOverlayLayer>.unmodifiable(overlays),
    );
  }

  /// Unmodified initial state with no edits.
  static const PhotoEditState initial = PhotoEditState();

  /// Active color-grading filter preset.
  final PhotoFilter filter;

  /// Blend strength of [filter] between `0.0` (original) and `1.0` (full).
  final double filterIntensity;

  /// Active tonal, color, optical, and film-grain adjustments.
  final PhotoAdjustments adjustments;

  /// Active crop, rotation, straighten, and mirror transforms.
  final PhotoTransform transform;

  /// Active studio frame, border, and corner-radius configuration.
  final PhotoFrame frame;

  /// Ordered markup and privacy-blur strokes drawn onto the photo.
  final List<DrawingStroke> strokes;

  /// Ordered text, sticker, and studio-badge overlays placed on the photo.
  final List<PhotoOverlayLayer> overlays;

  /// Returns `true` if any edit differs from [PhotoEditState.initial].
  bool get isModified =>
      (!filter.isOriginal && filterIntensity > 0.0) ||
      !adjustments.isDefault ||
      !transform.isIdentity ||
      !frame.isNone ||
      strokes.isNotEmpty ||
      overlays.isNotEmpty;

  /// Returns a copy with selectively updated properties.
  PhotoEditState copyWith({
    PhotoFilter? filter,
    double? filterIntensity,
    PhotoAdjustments? adjustments,
    PhotoTransform? transform,
    PhotoFrame? frame,
    List<DrawingStroke>? strokes,
    List<PhotoOverlayLayer>? overlays,
  }) {
    return PhotoEditState(
      filter: filter ?? this.filter,
      filterIntensity: (filterIntensity ?? this.filterIntensity).clamp(
        0.0,
        1.0,
      ),
      adjustments: adjustments ?? this.adjustments,
      transform: transform ?? this.transform,
      frame: frame ?? this.frame,
      strokes: strokes ?? this.strokes,
      overlays: overlays ?? this.overlays,
    );
  }

  /// Serializes this edit state to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'filterId': filter.id,
      'filterIntensity': filterIntensity,
      'adjustments': adjustments.toJson(),
      'transform': transform.toJson(),
      'frame': frame.toJson(),
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'overlays': overlays.map((o) => o.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PhotoEditState &&
        other.filter == filter &&
        other.filterIntensity == filterIntensity &&
        other.adjustments == adjustments &&
        other.transform == transform &&
        other.frame == frame &&
        listEquals(other.strokes, strokes) &&
        listEquals(other.overlays, overlays);
  }

  @override
  int get hashCode => Object.hash(
    filter,
    filterIntensity,
    adjustments,
    transform,
    frame,
    Object.hashAll(strokes),
    Object.hashAll(overlays),
  );
}

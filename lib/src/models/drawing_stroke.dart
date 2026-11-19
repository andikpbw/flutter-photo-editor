import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Drawing and redaction instrument type used for markup strokes.
enum BrushTool {
  /// Smooth freehand round pen stroke.
  pen,

  /// Semi-transparent marker highlighter stroke.
  highlighter,

  /// Crisp straight vector line from start point to end point.
  line,

  /// Vector straight arrow from start point to end point.
  arrow,

  /// Vector stroked rectangle from start corner to end corner.
  rectangle,

  /// Solid filled rectangle for emphasis or redaction.
  filledRectangle,

  /// Vector stroked ellipse inscribed between start and end points.
  oval,

  /// Non-destructive privacy blur region masking sensitive image areas.
  blurRect,
}

/// An immutable markup stroke stored in normalized `[0.0, 1.0]` image
/// coordinates so strokes scale cleanly across viewports and exports.
@immutable
class DrawingStroke {
  /// Creates a [DrawingStroke].
  ///
  /// [points] are normalized offsets in `[0.0, 1.0]` oriented-image space.
  /// [strokeWidth] is expressed as a fraction of the image's shortest side
  /// (typically `0.004` to `0.05`).
  const DrawingStroke({
    required this.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.tool = BrushTool.pen,
    this.opacity = 1.0,
  });

  /// Restores a [DrawingStroke] from a JSON map produced by [toJson].
  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'];
    final parsedPoints = <Offset>[];
    if (rawPoints is List<dynamic>) {
      for (final item in rawPoints) {
        if (item is Map<String, dynamic>) {
          final dx = (item['x'] as num?)?.toDouble();
          final dy = (item['y'] as num?)?.toDouble();
          if (dx != null && dy != null) {
            parsedPoints.add(Offset(dx, dy));
          }
        }
      }
    }

    final toolName = json['tool'] as String?;
    final parsedTool = BrushTool.values.firstWhere(
      (t) => t.name == toolName,
      orElse: () => BrushTool.pen,
    );

    return DrawingStroke(
      id: (json['id'] as String?) ?? 'stroke',
      points: List<Offset>.unmodifiable(parsedPoints),
      color: Color((json['color'] as num?)?.toInt() ?? 0xFFFFFFFF),
      strokeWidth: ((json['strokeWidth'] as num?)?.toDouble() ?? 0.012).clamp(
        0.002,
        0.1,
      ),
      tool: parsedTool,
      opacity: ((json['opacity'] as num?)?.toDouble() ?? 1.0).clamp(0.05, 1.0),
    );
  }

  /// Unique identifier for this stroke.
  final String id;

  /// Ordered normalized points in oriented-image `[0.0, 1.0]` coordinates.
  final List<Offset> points;

  /// Stroke color.
  final Color color;

  /// Normalized stroke width relative to `min(imageWidth, imageHeight)`.
  final double strokeWidth;

  /// Instrument used to render this stroke.
  final BrushTool tool;

  /// Stroke opacity multiplier in `[0.05, 1.0]`.
  final double opacity;

  /// Returns `true` if this stroke is defined strictly by start & end points.
  bool get isTwoPointShape =>
      tool == BrushTool.line ||
      tool == BrushTool.arrow ||
      tool == BrushTool.rectangle ||
      tool == BrushTool.filledRectangle ||
      tool == BrushTool.oval ||
      tool == BrushTool.blurRect;

  /// Returns a copy with all [points] transformed by [mapper].
  DrawingStroke mapPoints(Offset Function(Offset point) mapper) {
    return copyWith(points: List<Offset>.unmodifiable(points.map(mapper)));
  }

  /// Returns a copy with selectively updated fields.
  DrawingStroke copyWith({
    String? id,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    BrushTool? tool,
    double? opacity,
  }) {
    return DrawingStroke(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      tool: tool ?? this.tool,
      opacity: (opacity ?? this.opacity).clamp(0.05, 1.0),
    );
  }

  /// Serializes this stroke to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'points': points
          .map((p) => <String, double>{'x': p.dx, 'y': p.dy})
          .toList(),
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'tool': tool.name,
      'opacity': opacity,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DrawingStroke &&
        other.id == id &&
        listEquals(other.points, points) &&
        other.color == color &&
        other.strokeWidth == strokeWidth &&
        other.tool == tool &&
        other.opacity == opacity;
  }

  @override
  int get hashCode => Object.hash(
    id,
    Object.hashAll(points),
    color,
    strokeWidth,
    tool,
    opacity,
  );
}

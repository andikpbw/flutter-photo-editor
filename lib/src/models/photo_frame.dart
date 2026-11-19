import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Decorative studio frame preset applied around the edited photo.
enum PhotoFrameStyle {
  /// No frame or border.
  none,

  /// Clean uniform hairline-to-medium border around the photo.
  minimal,

  /// Generous museum gallery mat border with subtle inner hairline.
  gallery,

  /// Classic instant-film Polaroid frame with weighted bottom margin.
  polaroid,

  /// Widescreen theatrical cinema letterbox bars top and bottom.
  cinema,

  /// Rounded studio card framed inside a solid canvas backdrop.
  rounded,
}

/// Immutable studio frame and border configuration rendered on both the live
/// canvas and full-resolution export.
@immutable
class PhotoFrame {
  /// Creates a [PhotoFrame].
  const PhotoFrame({
    this.style = PhotoFrameStyle.none,
    this.color = const Color(0xFFFFFFFF),
    this.thickness = 0.45,
    this.cornerRadius = 0.0,
  });

  /// Restores a [PhotoFrame] from a JSON map produced by [toJson].
  factory PhotoFrame.fromJson(Map<String, dynamic> json) {
    final styleName = json['style'] as String?;
    final parsedStyle = PhotoFrameStyle.values.firstWhere(
      (s) => s.name == styleName,
      orElse: () => PhotoFrameStyle.none,
    );
    return PhotoFrame(
      style: parsedStyle,
      color: Color((json['color'] as num?)?.toInt() ?? 0xFFFFFFFF),
      thickness: ((json['thickness'] as num?)?.toDouble() ?? 0.45).clamp(
        0.05,
        1.0,
      ),
      cornerRadius: ((json['cornerRadius'] as num?)?.toDouble() ?? 0.0).clamp(
        0.0,
        1.0,
      ),
    );
  }

  /// Neutral frame configuration with no border or rounding.
  static const PhotoFrame none = PhotoFrame();

  /// Active frame layout preset.
  final PhotoFrameStyle style;

  /// Frame/mat fill color.
  final Color color;

  /// Normalized border thickness factor (`0.05` to `1.0`).
  final double thickness;

  /// Normalized inner photo corner radius (`0.0` to `1.0`).
  final double cornerRadius;

  /// Returns `true` when no frame or corner rounding is active.
  bool get isNone => style == PhotoFrameStyle.none && cornerRadius == 0.0;

  /// Returns a copy with selectively updated properties.
  PhotoFrame copyWith({
    PhotoFrameStyle? style,
    Color? color,
    double? thickness,
    double? cornerRadius,
  }) {
    return PhotoFrame(
      style: style ?? this.style,
      color: color ?? this.color,
      thickness: (thickness ?? this.thickness).clamp(0.05, 1.0),
      cornerRadius: (cornerRadius ?? this.cornerRadius).clamp(0.0, 1.0),
    );
  }

  /// Serializes this frame configuration to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'style': style.name,
      'color': color.toARGB32(),
      'thickness': thickness,
      'cornerRadius': cornerRadius,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PhotoFrame &&
        other.style == style &&
        other.color == color &&
        other.thickness == thickness &&
        other.cornerRadius == cornerRadius;
  }

  @override
  int get hashCode => Object.hash(style, color, thickness, cornerRadius);
}

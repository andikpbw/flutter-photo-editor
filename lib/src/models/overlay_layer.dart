import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Background presentation style for a [TextOverlayLayer].
enum TextBackgroundStyle {
  /// Plain text with optional drop shadow for legibility.
  none,

  /// Solid filled rounded pill behind the text.
  solid,

  /// Translucent frosted-style pill behind the text.
  translucent,

  /// Crisp outline border around the text pill.
  outline,
}

/// Base class for interactive overlay elements placed over the edited photo.
///
/// Positions are stored as normalized `[0.0, 1.0]` coordinates in the
/// oriented-image coordinate space so overlays stay aligned across viewport
/// resizes and full-resolution exports.
@immutable
sealed class PhotoOverlayLayer {
  /// Creates a [PhotoOverlayLayer].
  const PhotoOverlayLayer({
    required this.id,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.isVisible = true,
  });

  /// Restores either a [TextOverlayLayer] or [StickerOverlayLayer] from JSON.
  factory PhotoOverlayLayer.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == 'sticker') {
      return StickerOverlayLayer.fromJson(json);
    }
    return TextOverlayLayer.fromJson(json);
  }

  /// Unique identifier for selecting, updating, and removing this layer.
  final String id;

  /// Normalized center position in `[0.0, 1.0]` oriented-image coordinates.
  final Offset position;

  /// Scale multiplier (`0.25` to `5.0`).
  final double scale;

  /// Clockwise rotation angle in radians.
  final double rotation;

  /// Layer opacity multiplier (`0.1` to `1.0`).
  final double opacity;

  /// Whether this layer is rendered on the canvas and in exports.
  final bool isVisible;

  /// Returns a copy with updated transform or visibility properties.
  PhotoOverlayLayer copyTransform({
    Offset? position,
    double? scale,
    double? rotation,
    double? opacity,
    bool? isVisible,
  });

  /// Serializes this overlay layer to a JSON-compatible map.
  Map<String, dynamic> toJson();
}

/// An editable text overlay layer rendered onto the photo with pro typography
/// controls including letter spacing, line height, opacity, shadow, and pill
/// styling.
@immutable
class TextOverlayLayer extends PhotoOverlayLayer {
  /// Creates a [TextOverlayLayer].
  const TextOverlayLayer({
    required super.id,
    required this.text,
    super.position = const Offset(0.5, 0.5),
    super.scale = 1.0,
    super.rotation = 0.0,
    super.opacity = 1.0,
    super.isVisible = true,
    this.color = const Color(0xFFFFFFFF),
    this.backgroundColor = const Color(0xCC111318),
    this.backgroundStyle = TextBackgroundStyle.translucent,
    this.fontSize = 0.055,
    this.fontWeight = FontWeight.w700,
    this.fontStyle = FontStyle.normal,
    this.fontFamily,
    this.textAlign = TextAlign.center,
    this.letterSpacing = 0.0,
    this.lineHeight = 1.2,
    this.hasShadow = true,
  });

  /// Restores a [TextOverlayLayer] from a JSON map produced by [toJson].
  factory TextOverlayLayer.fromJson(Map<String, dynamic> json) {
    final posMap = json['position'];
    Offset parsedPosition = const Offset(0.5, 0.5);
    if (posMap is Map<String, dynamic>) {
      parsedPosition = Offset(
        ((posMap['x'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
        ((posMap['y'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
      );
    }

    final bgName = json['backgroundStyle'] as String?;
    final parsedBgStyle = TextBackgroundStyle.values.firstWhere(
      (s) => s.name == bgName,
      orElse: () => TextBackgroundStyle.translucent,
    );

    final alignName = json['textAlign'] as String?;
    final parsedAlign = TextAlign.values.firstWhere(
      (a) => a.name == alignName,
      orElse: () => TextAlign.center,
    );

    final weightVal = (json['fontWeight'] as num?)?.toInt() ?? 700;
    final parsedWeight = FontWeight.values.firstWhere(
      (w) => w.value == weightVal,
      orElse: () => FontWeight.w700,
    );

    return TextOverlayLayer(
      id: (json['id'] as String?) ?? 'text',
      text: (json['text'] as String?) ?? '',
      position: parsedPosition,
      scale: ((json['scale'] as num?)?.toDouble() ?? 1.0).clamp(0.25, 5.0),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      opacity: ((json['opacity'] as num?)?.toDouble() ?? 1.0).clamp(0.1, 1.0),
      isVisible: json['isVisible'] != false,
      color: Color((json['color'] as num?)?.toInt() ?? 0xFFFFFFFF),
      backgroundColor: Color(
        (json['backgroundColor'] as num?)?.toInt() ?? 0xCC111318,
      ),
      backgroundStyle: parsedBgStyle,
      fontSize: ((json['fontSize'] as num?)?.toDouble() ?? 0.055).clamp(
        0.015,
        0.25,
      ),
      fontWeight: parsedWeight,
      fontStyle: json['italic'] == true ? FontStyle.italic : FontStyle.normal,
      fontFamily: json['fontFamily'] as String?,
      textAlign: parsedAlign,
      letterSpacing: ((json['letterSpacing'] as num?)?.toDouble() ?? 0.0).clamp(
        -2.0,
        16.0,
      ),
      lineHeight: ((json['lineHeight'] as num?)?.toDouble() ?? 1.2).clamp(
        0.85,
        2.2,
      ),
      hasShadow: json['hasShadow'] != false,
    );
  }

  /// Text string rendered on the image (supports multi-line text).
  final String text;

  /// Foreground text color.
  final Color color;

  /// Pill fill or border color used when [backgroundStyle] is not `none`.
  final Color backgroundColor;

  /// Background pill style around the text.
  final TextBackgroundStyle backgroundStyle;

  /// Base normalized font size relative to `min(imageWidth, imageHeight)`.
  final double fontSize;

  /// Font weight for rendering the text.
  final FontWeight fontWeight;

  /// Normal or italic font style.
  final FontStyle fontStyle;

  /// Optional custom font family name.
  final String? fontFamily;

  /// Horizontal text alignment for multi-line text.
  final TextAlign textAlign;

  /// Tracking / letter spacing in typographic units (`-2.0` to `16.0`).
  final double letterSpacing;

  /// Line height multiplier for multi-line copy (`0.85` to `2.2`).
  final double lineHeight;

  /// Whether a soft contrast drop shadow is drawn behind plain text.
  final bool hasShadow;

  @override
  TextOverlayLayer copyTransform({
    Offset? position,
    double? scale,
    double? rotation,
    double? opacity,
    bool? isVisible,
  }) {
    return copyWith(
      position: position,
      scale: scale,
      rotation: rotation,
      opacity: opacity,
      isVisible: isVisible,
    );
  }

  /// Returns a copy with selectively updated properties.
  TextOverlayLayer copyWith({
    String? id,
    String? text,
    Offset? position,
    double? scale,
    double? rotation,
    double? opacity,
    bool? isVisible,
    Color? color,
    Color? backgroundColor,
    TextBackgroundStyle? backgroundStyle,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    String? fontFamily,
    TextAlign? textAlign,
    double? letterSpacing,
    double? lineHeight,
    bool? hasShadow,
  }) {
    return TextOverlayLayer(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      scale: (scale ?? this.scale).clamp(0.25, 5.0),
      rotation: rotation ?? this.rotation,
      opacity: (opacity ?? this.opacity).clamp(0.1, 1.0),
      isVisible: isVisible ?? this.isVisible,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      fontSize: (fontSize ?? this.fontSize).clamp(0.015, 0.25),
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      fontFamily: fontFamily ?? this.fontFamily,
      textAlign: textAlign ?? this.textAlign,
      letterSpacing: (letterSpacing ?? this.letterSpacing).clamp(-2.0, 16.0),
      lineHeight: (lineHeight ?? this.lineHeight).clamp(0.85, 2.2),
      hasShadow: hasShadow ?? this.hasShadow,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': 'text',
      'id': id,
      'text': text,
      'position': <String, double>{'x': position.dx, 'y': position.dy},
      'scale': scale,
      'rotation': rotation,
      'opacity': opacity,
      'isVisible': isVisible,
      'color': color.toARGB32(),
      'backgroundColor': backgroundColor.toARGB32(),
      'backgroundStyle': backgroundStyle.name,
      'fontSize': fontSize,
      'fontWeight': fontWeight.value,
      'italic': fontStyle == FontStyle.italic,
      'fontFamily': fontFamily,
      'textAlign': textAlign.name,
      'letterSpacing': letterSpacing,
      'lineHeight': lineHeight,
      'hasShadow': hasShadow,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TextOverlayLayer &&
        other.id == id &&
        other.text == text &&
        other.position == position &&
        other.scale == scale &&
        other.rotation == rotation &&
        other.opacity == opacity &&
        other.isVisible == isVisible &&
        other.color == color &&
        other.backgroundColor == backgroundColor &&
        other.backgroundStyle == backgroundStyle &&
        other.fontSize == fontSize &&
        other.fontWeight == fontWeight &&
        other.fontStyle == fontStyle &&
        other.fontFamily == fontFamily &&
        other.textAlign == textAlign &&
        other.letterSpacing == letterSpacing &&
        other.lineHeight == lineHeight &&
        other.hasShadow == hasShadow;
  }

  @override
  int get hashCode => Object.hash(
    id,
    text,
    position,
    scale,
    rotation,
    opacity,
    isVisible,
    color,
    backgroundColor,
    backgroundStyle,
    fontSize,
    fontWeight,
    fontStyle,
    fontFamily,
    textAlign,
    letterSpacing,
    lineHeight,
    hasShadow,
  );
}

/// A sticker, emoji, or vector studio badge overlay rendered onto the photo.
@immutable
class StickerOverlayLayer extends PhotoOverlayLayer {
  /// Creates a [StickerOverlayLayer].
  const StickerOverlayLayer({
    required super.id,
    required this.content,
    super.position = const Offset(0.5, 0.5),
    super.scale = 1.0,
    super.rotation = 0.0,
    super.opacity = 1.0,
    super.isVisible = true,
    this.baseSize = 0.14,
    this.isBadge = false,
    this.badgeColor = const Color(0xFF4F8BFF),
    this.fontFamily,
  });

  /// Restores a [StickerOverlayLayer] from a JSON map produced by [toJson].
  factory StickerOverlayLayer.fromJson(Map<String, dynamic> json) {
    final posMap = json['position'];
    Offset parsedPosition = const Offset(0.5, 0.5);
    if (posMap is Map<String, dynamic>) {
      parsedPosition = Offset(
        ((posMap['x'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
        ((posMap['y'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0),
      );
    }

    return StickerOverlayLayer(
      id: (json['id'] as String?) ?? 'sticker',
      content: (json['content'] as String?) ?? '✨',
      position: parsedPosition,
      scale: ((json['scale'] as num?)?.toDouble() ?? 1.0).clamp(0.25, 5.0),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      opacity: ((json['opacity'] as num?)?.toDouble() ?? 1.0).clamp(0.1, 1.0),
      isVisible: json['isVisible'] != false,
      baseSize: ((json['baseSize'] as num?)?.toDouble() ?? 0.14).clamp(
        0.04,
        0.4,
      ),
      isBadge: json['isBadge'] == true,
      badgeColor: Color((json['badgeColor'] as num?)?.toInt() ?? 0xFF4F8BFF),
      fontFamily: json['fontFamily'] as String?,
    );
  }

  /// Sticker glyph, emoji string, or badge text.
  final String content;

  /// Base normalized sticker size relative to `min(imageWidth, imageHeight)`.
  final double baseSize;

  /// When `true`, renders [content] as a crisp studio pill badge (e.g. `RAW`,
  /// `PRO`, `4K`) using [badgeColor].
  final bool isBadge;

  /// Accent fill color used when [isBadge] is `true`.
  final Color badgeColor;

  /// Optional custom font family used when [isBadge] is `true`.
  final String? fontFamily;

  @override
  StickerOverlayLayer copyTransform({
    Offset? position,
    double? scale,
    double? rotation,
    double? opacity,
    bool? isVisible,
  }) {
    return copyWith(
      position: position,
      scale: scale,
      rotation: rotation,
      opacity: opacity,
      isVisible: isVisible,
    );
  }

  /// Returns a copy with selectively updated fields.
  StickerOverlayLayer copyWith({
    String? id,
    String? content,
    Offset? position,
    double? scale,
    double? rotation,
    double? opacity,
    bool? isVisible,
    double? baseSize,
    bool? isBadge,
    Color? badgeColor,
    String? fontFamily,
  }) {
    return StickerOverlayLayer(
      id: id ?? this.id,
      content: content ?? this.content,
      position: position ?? this.position,
      scale: (scale ?? this.scale).clamp(0.25, 5.0),
      rotation: rotation ?? this.rotation,
      opacity: (opacity ?? this.opacity).clamp(0.1, 1.0),
      isVisible: isVisible ?? this.isVisible,
      baseSize: (baseSize ?? this.baseSize).clamp(0.04, 0.4),
      isBadge: isBadge ?? this.isBadge,
      badgeColor: badgeColor ?? this.badgeColor,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': 'sticker',
      'id': id,
      'content': content,
      'position': <String, double>{'x': position.dx, 'y': position.dy},
      'scale': scale,
      'rotation': rotation,
      'opacity': opacity,
      'isVisible': isVisible,
      'baseSize': baseSize,
      'isBadge': isBadge,
      'badgeColor': badgeColor.toARGB32(),
      'fontFamily': fontFamily,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is StickerOverlayLayer &&
        other.id == id &&
        other.content == content &&
        other.position == position &&
        other.scale == scale &&
        other.rotation == rotation &&
        other.opacity == opacity &&
        other.isVisible == isVisible &&
        other.baseSize == baseSize &&
        other.isBadge == isBadge &&
        other.badgeColor == badgeColor &&
        other.fontFamily == fontFamily;
  }

  @override
  int get hashCode => Object.hash(
    id,
    content,
    position,
    scale,
    rotation,
    opacity,
    isVisible,
    baseSize,
    isBadge,
    badgeColor,
    fontFamily,
  );
}

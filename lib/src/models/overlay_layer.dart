import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Background presentation style for a [TextOverlayLayer].
enum TextBackgroundStyle {
  /// Plain text with subtle drop shadow for legibility.
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

  /// Returns a copy with updated transform properties.
  PhotoOverlayLayer copyTransform({
    Offset? position,
    double? scale,
    double? rotation,
  });

  /// Serializes this overlay layer to a JSON-compatible map.
  Map<String, dynamic> toJson();
}

/// An editable text overlay layer rendered onto the photo.
@immutable
class TextOverlayLayer extends PhotoOverlayLayer {
  /// Creates a [TextOverlayLayer].
  const TextOverlayLayer({
    required super.id,
    required this.text,
    super.position = const Offset(0.5, 0.5),
    super.scale = 1.0,
    super.rotation = 0.0,
    this.color = const Color(0xFFFFFFFF),
    this.backgroundColor = const Color(0xCC111318),
    this.backgroundStyle = TextBackgroundStyle.translucent,
    this.fontSize = 0.055,
    this.fontWeight = FontWeight.w700,
    this.fontStyle = FontStyle.normal,
    this.fontFamily,
    this.textAlign = TextAlign.center,
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

  @override
  TextOverlayLayer copyTransform({
    Offset? position,
    double? scale,
    double? rotation,
  }) {
    return copyWith(position: position, scale: scale, rotation: rotation);
  }

  /// Returns a copy with selectively updated properties.
  TextOverlayLayer copyWith({
    String? id,
    String? text,
    Offset? position,
    double? scale,
    double? rotation,
    Color? color,
    Color? backgroundColor,
    TextBackgroundStyle? backgroundStyle,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    String? fontFamily,
    TextAlign? textAlign,
  }) {
    return TextOverlayLayer(
      id: id ?? this.id,
      text: text ?? this.text,
      position: position ?? this.position,
      scale: (scale ?? this.scale).clamp(0.25, 5.0),
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      fontSize: (fontSize ?? this.fontSize).clamp(0.015, 0.25),
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      fontFamily: fontFamily ?? this.fontFamily,
      textAlign: textAlign ?? this.textAlign,
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
      'color': color.toARGB32(),
      'backgroundColor': backgroundColor.toARGB32(),
      'backgroundStyle': backgroundStyle.name,
      'fontSize': fontSize,
      'fontWeight': fontWeight.value,
      'italic': fontStyle == FontStyle.italic,
      'fontFamily': fontFamily,
      'textAlign': textAlign.name,
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
        other.color == color &&
        other.backgroundColor == backgroundColor &&
        other.backgroundStyle == backgroundStyle &&
        other.fontSize == fontSize &&
        other.fontWeight == fontWeight &&
        other.fontStyle == fontStyle &&
        other.fontFamily == fontFamily &&
        other.textAlign == textAlign;
  }

  @override
  int get hashCode => Object.hash(
    id,
    text,
    position,
    scale,
    rotation,
    color,
    backgroundColor,
    backgroundStyle,
    fontSize,
    fontWeight,
    fontStyle,
    fontFamily,
    textAlign,
  );
}

/// A sticker or emoji badge overlay layer rendered onto the photo.
@immutable
class StickerOverlayLayer extends PhotoOverlayLayer {
  /// Creates a [StickerOverlayLayer].
  const StickerOverlayLayer({
    required super.id,
    required this.content,
    super.position = const Offset(0.5, 0.5),
    super.scale = 1.0,
    super.rotation = 0.0,
    this.baseSize = 0.14,
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
      baseSize: ((json['baseSize'] as num?)?.toDouble() ?? 0.14).clamp(
        0.04,
        0.4,
      ),
    );
  }

  /// Sticker glyph or emoji string.
  final String content;

  /// Base normalized sticker size relative to `min(imageWidth, imageHeight)`.
  final double baseSize;

  @override
  StickerOverlayLayer copyTransform({
    Offset? position,
    double? scale,
    double? rotation,
  }) {
    return copyWith(position: position, scale: scale, rotation: rotation);
  }

  /// Returns a copy with selectively updated fields.
  StickerOverlayLayer copyWith({
    String? id,
    String? content,
    Offset? position,
    double? scale,
    double? rotation,
    double? baseSize,
  }) {
    return StickerOverlayLayer(
      id: id ?? this.id,
      content: content ?? this.content,
      position: position ?? this.position,
      scale: (scale ?? this.scale).clamp(0.25, 5.0),
      rotation: rotation ?? this.rotation,
      baseSize: (baseSize ?? this.baseSize).clamp(0.04, 0.4),
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
      'baseSize': baseSize,
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
        other.baseSize == baseSize;
  }

  @override
  int get hashCode =>
      Object.hash(id, content, position, scale, rotation, baseSize);
}

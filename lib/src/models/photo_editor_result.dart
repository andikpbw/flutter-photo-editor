import 'package:flutter/foundation.dart';

import 'photo_edit_state.dart';

/// Output image encoding format used when exporting an edited photo.
enum PhotoExportFormat {
  /// Lossless Portable Network Graphics (`image/png`).
  png,

  /// Baseline JPEG encoded in pure Dart (`image/jpeg`) with configurable
  /// quality (`1..100`).
  jpeg,

  /// Uncompressed 32-bit RGBA pixel buffer (`4 * width * height` bytes).
  rawRgba,
}

/// Options controlling the exported image dimensions and encoding format.
@immutable
class PhotoExportOptions {
  /// Creates [PhotoExportOptions].
  ///
  /// When [maxWidth] or [maxHeight] is provided, the exported image is
  /// proportionally scaled down so neither dimension exceeds the constraint.
  /// [jpegQuality] is used only when [format] is [PhotoExportFormat.jpeg].
  const PhotoExportOptions({
    this.format = PhotoExportFormat.png,
    this.jpegQuality = 90,
    this.maxWidth,
    this.maxHeight,
  }) : assert(
         jpegQuality >= 1 && jpegQuality <= 100,
         'jpegQuality must be between 1 and 100.',
       ),
       assert(
         maxWidth == null || maxWidth > 0,
         'maxWidth must be positive when provided.',
       ),
       assert(
         maxHeight == null || maxHeight > 0,
         'maxHeight must be positive when provided.',
       );

  /// Target image encoding format.
  final PhotoExportFormat format;

  /// JPEG compression quality (`1` = smallest, `100` = highest quality).
  final int jpegQuality;

  /// Optional maximum output width in pixels (aspect ratio preserved).
  final int? maxWidth;

  /// Optional maximum output height in pixels (aspect ratio preserved).
  final int? maxHeight;

  /// Returns a copy with selectively updated fields.
  PhotoExportOptions copyWith({
    PhotoExportFormat? format,
    int? jpegQuality,
    int? maxWidth,
    int? maxHeight,
  }) {
    return PhotoExportOptions(
      format: format ?? this.format,
      jpegQuality: (jpegQuality ?? this.jpegQuality).clamp(1, 100),
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
    );
  }
}

/// Result returned when the user exports or finishes editing a photo.
@immutable
class PhotoEditorResult {
  /// Creates a [PhotoEditorResult].
  const PhotoEditorResult({
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
    required this.state,
  });

  /// Encoded image bytes in [format].
  final Uint8List bytes;

  /// Exported image width in pixels.
  final int width;

  /// Exported image height in pixels.
  final int height;

  /// Encoding format of [bytes].
  final PhotoExportFormat format;

  /// Final non-destructive [PhotoEditState] used to render this image.
  final PhotoEditState state;

  /// MIME type corresponding to [format].
  String get mimeType {
    switch (format) {
      case PhotoExportFormat.png:
        return 'image/png';
      case PhotoExportFormat.jpeg:
        return 'image/jpeg';
      case PhotoExportFormat.rawRgba:
        return 'application/octet-stream';
    }
  }

  /// Suggested file extension (without leading dot) for [format].
  String get fileExtension {
    switch (format) {
      case PhotoExportFormat.png:
        return 'png';
      case PhotoExportFormat.jpeg:
        return 'jpg';
      case PhotoExportFormat.rawRgba:
        return 'rgba';
    }
  }
}

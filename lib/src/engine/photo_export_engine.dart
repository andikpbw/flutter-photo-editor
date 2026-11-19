import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../models/photo_edit_state.dart';
import '../models/photo_editor_result.dart';
import 'jpeg_encoder.dart';
import 'photo_scene_renderer.dart';

/// Renders a [ui.Image] together with a non-destructive [PhotoEditState] into
/// a full-resolution or bounded output [ui.Image] or encoded byte buffer.
abstract final class PhotoExportEngine {
  /// Computes the final pixel dimensions for exporting [sourceSize] with
  /// [state] and optional [maxWidth]/[maxHeight] constraints.
  static ui.Size computeOutputSize({
    required ui.Size sourceSize,
    required PhotoEditState state,
    int? maxWidth,
    int? maxHeight,
  }) {
    final cropped = state.transform.croppedSize(sourceSize);
    var width = cropped.width;
    var height = cropped.height;

    var scale = 1.0;
    if (maxWidth != null && width > maxWidth) {
      scale = math.min(scale, maxWidth / width);
    }
    if (maxHeight != null && height > maxHeight) {
      scale = math.min(scale, maxHeight / height);
    }

    width = math.max(1.0, (width * scale).roundToDouble());
    height = math.max(1.0, (height * scale).roundToDouble());
    return ui.Size(width, height);
  }

  /// Renders [image] with [state] into a new [ui.Image].
  ///
  /// The caller is responsible for calling `dispose()` on the returned image
  /// once it is no longer needed.
  static Future<ui.Image> renderImage({
    required ui.Image image,
    required PhotoEditState state,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final sourceSize = ui.Size(image.width.toDouble(), image.height.toDouble());
    final targetSize = computeOutputSize(
      sourceSize: sourceSize,
      state: state,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    final targetW = targetSize.width.round().clamp(1, 16384);
    final targetH = targetSize.height.round().clamp(1, 16384);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, targetW.toDouble(), targetH.toDouble()),
    );

    PhotoSceneRenderer.paint(
      canvas: canvas,
      outputSize: ui.Size(targetW.toDouble(), targetH.toDouble()),
      image: image,
      state: state,
    );

    final picture = recorder.endRecording();
    try {
      return await picture.toImage(targetW, targetH);
    } finally {
      picture.dispose();
    }
  }

  /// Renders and encodes [image] with [state] according to [options].
  static Future<PhotoEditorResult> export({
    required ui.Image image,
    required PhotoEditState state,
    PhotoExportOptions options = const PhotoExportOptions(),
  }) async {
    final rendered = await renderImage(
      image: image,
      state: state,
      maxWidth: options.maxWidth,
      maxHeight: options.maxHeight,
    );
    try {
      final width = rendered.width;
      final height = rendered.height;
      final Uint8List bytes;

      switch (options.format) {
        case PhotoExportFormat.png:
          final byteData = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (byteData == null) {
            throw StateError('Failed to encode edited image to PNG.');
          }
          bytes = byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          );

        case PhotoExportFormat.rawRgba:
          final byteData = await rendered.toByteData();
          if (byteData == null) {
            throw StateError('Failed to extract raw RGBA bytes.');
          }
          bytes = byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          );

        case PhotoExportFormat.jpeg:
          final byteData = await rendered.toByteData();
          if (byteData == null) {
            throw StateError(
              'Failed to extract RGBA pixels for JPEG encoding.',
            );
          }
          final rgba = byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          );
          bytes = JpegEncoder.encodeRgba(
            rgba,
            width,
            height,
            quality: options.jpegQuality,
          );
      }

      return PhotoEditorResult(
        bytes: bytes,
        width: width,
        height: height,
        format: options.format,
        state: state,
      );
    } finally {
      rendered.dispose();
    }
  }
}

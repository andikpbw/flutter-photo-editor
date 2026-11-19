/// A modern & professional Flutter photo editor library for editing images
/// with studio color filters, precision adjustments, live RGB histogram,
/// interactive split-screen comparison, cropping, straightening, vector
/// markup & privacy blur, typography layers with smart snap guides, stickers,
/// studio badges, and gallery/Polaroid frames across mobile, desktop, and web.
///
/// Supported by [Humanize AI](https://humanize.id).
///
/// ## Quick Start
///
/// ```dart
/// import 'dart:typed_data';
/// import 'package:flutter/widgets.dart';
/// import 'package:photo_editor_studio/photo_editor_studio.dart';
///
/// Future<void> openEditor(BuildContext context, Uint8List imageBytes) async {
///   final PhotoEditorResult? result = await PhotoEditor.open(
///     context,
///     bytes: imageBytes,
///   );
///   if (result != null) {
///     // Use result.bytes (PNG or JPEG) and result.state
///   }
/// }
/// ```
library;

export 'src/controller/photo_editor_controller.dart';
export 'src/engine/color_matrix.dart';
export 'src/engine/histogram_calculator.dart';
export 'src/engine/jpeg_encoder.dart';
export 'src/engine/photo_export_engine.dart';
export 'src/engine/photo_scene_renderer.dart';
export 'src/models/crop_aspect_ratio.dart';
export 'src/models/drawing_stroke.dart';
export 'src/models/overlay_layer.dart';
export 'src/models/photo_adjustments.dart';
export 'src/models/photo_edit_state.dart';
export 'src/models/photo_editor_config.dart';
export 'src/models/photo_editor_labels.dart';
export 'src/models/photo_editor_result.dart';
export 'src/models/photo_editor_theme.dart';
export 'src/models/photo_filter.dart';
export 'src/models/photo_frame.dart';
export 'src/models/photo_transform.dart';
export 'src/widgets/canvas/crop_overlay.dart';
export 'src/widgets/canvas/photo_editor_canvas.dart';
export 'src/widgets/controls/histogram_widget.dart';
export 'src/widgets/photo_editor_widget.dart';

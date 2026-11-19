import 'package:flutter/material.dart';

import 'crop_aspect_ratio.dart';
import 'photo_adjustments.dart';
import 'photo_editor_labels.dart';
import 'photo_editor_result.dart';
import 'photo_editor_theme.dart';
import 'photo_filter.dart';

/// Top-level editing tools available in `photo_editor`.
enum PhotoEditorTool {
  /// Crop, straighten, 90° rotation, and horizontal/vertical flip.
  crop,

  /// Curated and custom color-grading filters with intensity blending.
  filters,

  /// Fine-tuned brightness, contrast, saturation, exposure, warmth, and more.
  adjust,

  /// Freehand pen, highlighter, arrow, rectangle, and oval markup tools.
  draw,

  /// Styled multi-line text overlays with positioning, scaling, and rotation.
  text,

  /// Emoji and badge stickers with positioning, scaling, and rotation.
  stickers,
}

/// Controls how the editor adapts between mobile and desktop studio layouts.
enum PhotoEditorLayoutMode {
  /// Automatically switches to desktop layout when width >= [PhotoEditorConfig.desktopBreakpoint].
  auto,

  /// Always uses the compact bottom-panel mobile layout.
  mobile,

  /// Always uses the three-pane desktop studio layout (left rail, canvas, right inspector).
  desktop,
}

/// Configuration options controlling enabled tools, presets, theme, labels,
/// and export settings for [PhotoEditor].
@immutable
class PhotoEditorConfig {
  /// Creates a [PhotoEditorConfig].
  PhotoEditorConfig({
    this.tools = defaultTools,
    this.initialTool = PhotoEditorTool.filters,
    this.filters = PhotoFilters.presets,
    this.aspectRatios = CropAspectRatio.presets,
    this.adjustments = PhotoAdjustmentType.values,
    this.brushColors = defaultBrushColors,
    this.textColors = defaultTextColors,
    this.stickers = defaultStickers,
    this.exportOptions = const PhotoExportOptions(),
    this.layoutMode = PhotoEditorLayoutMode.auto,
    this.desktopBreakpoint = 840.0,
    this.maxHistoryLength = 50,
    this.enableZoomPan = true,
    this.enableKeyboardShortcuts = true,
    this.showCloseButton = true,
    PhotoEditorTheme? theme,
    this.labels = const PhotoEditorLabels(),
  }) : assert(
         tools.isNotEmpty,
         'At least one PhotoEditorTool must be enabled.',
       ),
       assert(maxHistoryLength >= 1, 'maxHistoryLength must be at least 1.'),
       theme = theme ?? PhotoEditorTheme.dark();

  /// Default ordered list of enabled editing tools.
  static const List<PhotoEditorTool> defaultTools = <PhotoEditorTool>[
    PhotoEditorTool.crop,
    PhotoEditorTool.filters,
    PhotoEditorTool.adjust,
    PhotoEditorTool.draw,
    PhotoEditorTool.text,
    PhotoEditorTool.stickers,
  ];

  /// Default color swatch palette for drawing tools.
  static const List<Color> defaultBrushColors = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFF111318),
    Color(0xFFFF4D5E),
    Color(0xFFFF8A3D),
    Color(0xFFFFD13B),
    Color(0xFF34D399),
    Color(0xFF38BDF8),
    Color(0xFF4F8BFF),
    Color(0xFFA855F7),
    Color(0xFFF472B6),
  ];

  /// Default color swatch palette for text overlays.
  static const List<Color> defaultTextColors = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFF111318),
    Color(0xFFFFD13B),
    Color(0xFFFF5C6C),
    Color(0xFF34D399),
    Color(0xFF4F8BFF),
    Color(0xFFA855F7),
    Color(0xFFFF8A3D),
  ];

  /// Default curated sticker/emoji collection.
  static const List<String> defaultStickers = <String>[
    '✨',
    '🔥',
    '❤️',
    '🌟',
    '📸',
    '🎨',
    '🌈',
    '☀️',
    '🌙',
    '🌸',
    '🌿',
    '🏔️',
    '🌊',
    '⚡',
    '💫',
    '🎉',
    '😎',
    '💯',
    '👑',
    '🦋',
    '☕',
    '✈️',
    '📍',
    '🏷️',
  ];

  /// Ordered list of editing tools shown in the editor navigation.
  final List<PhotoEditorTool> tools;

  /// Tool selected when the editor opens (falls back to `tools.first` if not in [tools]).
  final PhotoEditorTool initialTool;

  /// Available color-grading filters.
  final List<PhotoFilter> filters;

  /// Available crop aspect ratio presets.
  final List<CropAspectRatio> aspectRatios;

  /// Available tonal and optical adjustment sliders.
  final List<PhotoAdjustmentType> adjustments;

  /// Color swatches offered in the drawing panel.
  final List<Color> brushColors;

  /// Color swatches offered in the text overlay panel.
  final List<Color> textColors;

  /// Stickers/emojis offered in the sticker panel.
  final List<String> stickers;

  /// Default format, quality, and dimension bounds when exporting.
  final PhotoExportOptions exportOptions;

  /// Responsive layout strategy.
  final PhotoEditorLayoutMode layoutMode;

  /// Minimum logical width (in dp) at which [PhotoEditorLayoutMode.auto]
  /// switches from mobile to desktop layout.
  final double desktopBreakpoint;

  /// Maximum number of undo history checkpoints retained.
  final int maxHistoryLength;

  /// Whether interactive pinch/scroll zoom and pan is enabled on the canvas.
  final bool enableZoomPan;

  /// Whether desktop/web keyboard shortcuts (Undo/Redo/Rotate/Delete) are active.
  final bool enableKeyboardShortcuts;

  /// Whether a Cancel/Close button is shown in the top bar.
  final bool showCloseButton;

  /// Visual theme tokens.
  final PhotoEditorTheme theme;

  /// Localizable string labels.
  final PhotoEditorLabels labels;

  /// Resolves the initial active tool guaranteed to exist inside [tools].
  PhotoEditorTool get resolvedInitialTool =>
      tools.contains(initialTool) ? initialTool : tools.first;
}

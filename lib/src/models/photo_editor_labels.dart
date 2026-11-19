import 'package:flutter/foundation.dart';

import 'drawing_stroke.dart';
import 'photo_adjustments.dart';
import 'photo_filter.dart';
import 'photo_frame.dart';

/// Localizable UI text labels used throughout the `photo_editor` interface.
@immutable
class PhotoEditorLabels {
  /// Creates a [PhotoEditorLabels] bundle with sensible English defaults.
  const PhotoEditorLabels({
    this.title = 'Photo Editor',
    this.done = 'Export',
    this.cancel = 'Cancel',
    this.reset = 'Reset',
    this.resetAll = 'Reset All',
    this.undo = 'Undo',
    this.redo = 'Redo',
    this.compare = 'Split Compare',
    this.originalBadge = 'ORIGINAL',
    this.beforeBadge = 'BEFORE',
    this.afterBadge = 'AFTER',
    this.exporting = 'Exporting...',
    this.loading = 'Loading image...',
    this.loadError = 'Unable to load image.',
    this.cropTab = 'Crop',
    this.filtersTab = 'Filters',
    this.adjustTab = 'Adjust',
    this.drawTab = 'Draw',
    this.textTab = 'Text',
    this.stickersTab = 'Stickers',
    this.framesTab = 'Frames',
    this.filterIntensity = 'Intensity',
    this.straighten = 'Straighten',
    this.aspectRatio = 'Aspect Ratio',
    this.rotateLeft = 'Rotate Left',
    this.rotateRight = 'Rotate Right',
    this.flipHorizontal = 'Flip H',
    this.flipVertical = 'Flip V',
    this.exposure = 'Exposure',
    this.brightness = 'Brightness',
    this.contrast = 'Contrast',
    this.highlights = 'Highlights',
    this.shadows = 'Shadows',
    this.saturation = 'Saturation',
    this.vibrance = 'Vibrance',
    this.warmth = 'Warmth',
    this.tint = 'Tint',
    this.clarity = 'Clarity',
    this.fade = 'Fade',
    this.vignette = 'Vignette',
    this.grain = 'Grain',
    this.blur = 'Blur',
    this.histogram = 'RGB Histogram',
    this.brushSize = 'Size',
    this.brushOpacity = 'Opacity',
    this.clearStrokes = 'Clear',
    this.penTool = 'Pen',
    this.highlighterTool = 'Marker',
    this.lineTool = 'Line',
    this.arrowTool = 'Arrow',
    this.rectangleTool = 'Box',
    this.filledBoxTool = 'Fill Box',
    this.ovalTool = 'Oval',
    this.blurBoxTool = 'Privacy Blur',
    this.addText = 'Add Text',
    this.editText = 'Edit Text',
    this.textPlaceholder = 'Type something...',
    this.textStyle = 'Style',
    this.textColor = 'Text Color',
    this.textScale = 'Scale',
    this.textRotation = 'Rotation',
    this.layerOpacity = 'Opacity',
    this.letterSpacing = 'Spacing',
    this.lineHeight = 'Line Height',
    this.deleteLayer = 'Delete',
    this.duplicateLayer = 'Duplicate',
    this.layersHeading = 'Layers',
    this.badgesHeading = 'Studio Badges',
    this.noLayersHint = 'Tap Add Text or pick a sticker to place on photo',
    this.frameStyle = 'Frame Style',
    this.frameColor = 'Frame Color',
    this.frameThickness = 'Thickness',
    this.frameCornerRadius = 'Corners',
    this.fitToScreen = 'Fit',
  });

  /// Editor title shown in desktop studio header.
  final String title;

  /// Primary completion/export button label.
  final String done;

  /// Cancel/close action label.
  final String cancel;

  /// Reset current tool label.
  final String reset;

  /// Reset all edits label.
  final String resetAll;

  /// Undo tooltip/label.
  final String undo;

  /// Redo tooltip/label.
  final String redo;

  /// Compare with original tooltip/label.
  final String compare;

  /// Badge text shown on canvas while comparing full original.
  final String originalBadge;

  /// Left-side badge shown during interactive split-screen comparison.
  final String beforeBadge;

  /// Right-side badge shown during interactive split-screen comparison.
  final String afterBadge;

  /// Progress message shown while exporting.
  final String exporting;

  /// Loading indicator text while decoding the source image.
  final String loading;

  /// Fallback message if the source image fails to decode.
  final String loadError;

  /// Navigation label for the Crop & Transform tool.
  final String cropTab;

  /// Navigation label for the Filters tool.
  final String filtersTab;

  /// Navigation label for the Adjustments tool.
  final String adjustTab;

  /// Navigation label for the Draw/Markup tool.
  final String drawTab;

  /// Navigation label for the Text overlay tool.
  final String textTab;

  /// Navigation label for the Stickers & Badges tool.
  final String stickersTab;

  /// Navigation label for the Studio Frames & Borders tool.
  final String framesTab;

  /// Slider label for filter strength.
  final String filterIntensity;

  /// Slider label for fine straighten angle.
  final String straighten;

  /// Section label for crop aspect ratios.
  final String aspectRatio;

  /// Tooltip/label for 90° counter-clockwise rotation.
  final String rotateLeft;

  /// Tooltip/label for 90° clockwise rotation.
  final String rotateRight;

  /// Tooltip/label for horizontal flip.
  final String flipHorizontal;

  /// Tooltip/label for vertical flip.
  final String flipVertical;

  /// Label for exposure slider.
  final String exposure;

  /// Label for brightness slider.
  final String brightness;

  /// Label for contrast slider.
  final String contrast;

  /// Label for highlights slider.
  final String highlights;

  /// Label for shadows slider.
  final String shadows;

  /// Label for saturation slider.
  final String saturation;

  /// Label for vibrance slider.
  final String vibrance;

  /// Label for warmth slider.
  final String warmth;

  /// Label for tint slider.
  final String tint;

  /// Label for clarity slider.
  final String clarity;

  /// Label for fade slider.
  final String fade;

  /// Label for vignette slider.
  final String vignette;

  /// Label for film grain slider.
  final String grain;

  /// Label for blur slider.
  final String blur;

  /// Heading label for live RGB histogram chart.
  final String histogram;

  /// Label for brush stroke size slider.
  final String brushSize;

  /// Label for brush opacity slider.
  final String brushOpacity;

  /// Label for clearing all markup strokes.
  final String clearStrokes;

  /// Label for pen brush tool.
  final String penTool;

  /// Label for highlighter brush tool.
  final String highlighterTool;

  /// Label for straight line tool.
  final String lineTool;

  /// Label for arrow markup tool.
  final String arrowTool;

  /// Label for rectangle markup tool.
  final String rectangleTool;

  /// Label for filled redaction box tool.
  final String filledBoxTool;

  /// Label for oval markup tool.
  final String ovalTool;

  /// Label for privacy blur region tool.
  final String blurBoxTool;

  /// Button label for adding a new text overlay.
  final String addText;

  /// Button/dialog title for editing an existing text overlay.
  final String editText;

  /// Text field hint in the text editor dialog.
  final String textPlaceholder;

  /// Section label for text style presets.
  final String textStyle;

  /// Section label for text color picker.
  final String textColor;

  /// Slider label for overlay scale.
  final String textScale;

  /// Slider label for overlay rotation.
  final String textRotation;

  /// Slider label for overlay layer opacity.
  final String layerOpacity;

  /// Slider label for text letter spacing.
  final String letterSpacing;

  /// Slider label for text line height.
  final String lineHeight;

  /// Button label for removing the selected overlay.
  final String deleteLayer;

  /// Button label for duplicating the selected overlay.
  final String duplicateLayer;

  /// Heading for active overlay layers list.
  final String layersHeading;

  /// Heading for crisp vector studio badges.
  final String badgesHeading;

  /// Empty-state hint when no overlays exist yet.
  final String noLayersHint;

  /// Section label for frame presets.
  final String frameStyle;

  /// Section label for frame fill color.
  final String frameColor;

  /// Slider label for frame thickness.
  final String frameThickness;

  /// Slider label for inner photo corner radius.
  final String frameCornerRadius;

  /// Tooltip for resetting canvas zoom to fit.
  final String fitToScreen;

  /// Returns the localized label for a given [PhotoAdjustmentType].
  String adjustmentLabel(PhotoAdjustmentType type) {
    switch (type) {
      case PhotoAdjustmentType.exposure:
        return exposure;
      case PhotoAdjustmentType.brightness:
        return brightness;
      case PhotoAdjustmentType.contrast:
        return contrast;
      case PhotoAdjustmentType.highlights:
        return highlights;
      case PhotoAdjustmentType.shadows:
        return shadows;
      case PhotoAdjustmentType.saturation:
        return saturation;
      case PhotoAdjustmentType.vibrance:
        return vibrance;
      case PhotoAdjustmentType.warmth:
        return warmth;
      case PhotoAdjustmentType.tint:
        return tint;
      case PhotoAdjustmentType.clarity:
        return clarity;
      case PhotoAdjustmentType.fade:
        return fade;
      case PhotoAdjustmentType.vignette:
        return vignette;
      case PhotoAdjustmentType.grain:
        return grain;
      case PhotoAdjustmentType.blur:
        return blur;
    }
  }

  /// Returns the localized label for a given [BrushTool].
  String brushToolLabel(BrushTool tool) {
    switch (tool) {
      case BrushTool.pen:
        return penTool;
      case BrushTool.highlighter:
        return highlighterTool;
      case BrushTool.line:
        return lineTool;
      case BrushTool.arrow:
        return arrowTool;
      case BrushTool.rectangle:
        return rectangleTool;
      case BrushTool.filledRectangle:
        return filledBoxTool;
      case BrushTool.oval:
        return ovalTool;
      case BrushTool.blurRect:
        return blurBoxTool;
    }
  }

  /// Returns a readable label for a [PhotoFilterCategory].
  String filterCategoryLabel(PhotoFilterCategory category) {
    switch (category) {
      case PhotoFilterCategory.all:
        return 'All';
      case PhotoFilterCategory.vivid:
        return 'Vivid';
      case PhotoFilterCategory.cinematic:
        return 'Cinema';
      case PhotoFilterCategory.film:
        return 'Film';
      case PhotoFilterCategory.monochrome:
        return 'B&W';
      case PhotoFilterCategory.moody:
        return 'Moody';
    }
  }

  /// Returns a readable label for a [PhotoFrameStyle].
  String frameStyleLabel(PhotoFrameStyle style) {
    switch (style) {
      case PhotoFrameStyle.none:
        return 'None';
      case PhotoFrameStyle.minimal:
        return 'Minimal';
      case PhotoFrameStyle.gallery:
        return 'Gallery';
      case PhotoFrameStyle.polaroid:
        return 'Polaroid';
      case PhotoFrameStyle.cinema:
        return 'Cinema';
      case PhotoFrameStyle.rounded:
        return 'Card';
    }
  }
}

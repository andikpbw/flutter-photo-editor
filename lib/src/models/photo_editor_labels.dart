import 'package:flutter/foundation.dart';

import 'drawing_stroke.dart';
import 'photo_adjustments.dart';

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
    this.compare = 'Compare',
    this.originalBadge = 'ORIGINAL',
    this.exporting = 'Exporting...',
    this.loading = 'Loading image...',
    this.loadError = 'Unable to load image.',
    this.cropTab = 'Crop',
    this.filtersTab = 'Filters',
    this.adjustTab = 'Adjust',
    this.drawTab = 'Draw',
    this.textTab = 'Text',
    this.stickersTab = 'Stickers',
    this.filterIntensity = 'Intensity',
    this.straighten = 'Straighten',
    this.aspectRatio = 'Aspect Ratio',
    this.rotateLeft = 'Rotate Left',
    this.rotateRight = 'Rotate Right',
    this.flipHorizontal = 'Flip H',
    this.flipVertical = 'Flip V',
    this.brightness = 'Brightness',
    this.contrast = 'Contrast',
    this.saturation = 'Saturation',
    this.exposure = 'Exposure',
    this.warmth = 'Warmth',
    this.tint = 'Tint',
    this.fade = 'Fade',
    this.clarity = 'Clarity',
    this.vignette = 'Vignette',
    this.blur = 'Blur',
    this.brushSize = 'Size',
    this.brushOpacity = 'Opacity',
    this.clearStrokes = 'Clear',
    this.penTool = 'Pen',
    this.highlighterTool = 'Marker',
    this.arrowTool = 'Arrow',
    this.rectangleTool = 'Box',
    this.ovalTool = 'Oval',
    this.addText = 'Add Text',
    this.editText = 'Edit Text',
    this.textPlaceholder = 'Type something...',
    this.textStyle = 'Style',
    this.textColor = 'Text Color',
    this.textScale = 'Scale',
    this.textRotation = 'Rotation',
    this.deleteLayer = 'Delete',
    this.duplicateLayer = 'Duplicate',
    this.layersHeading = 'Layers',
    this.noLayersHint = 'Tap Add Text or pick a sticker to place on photo',
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

  /// Badge text shown on canvas while comparing with the original photo.
  final String originalBadge;

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

  /// Navigation label for the Stickers tool.
  final String stickersTab;

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

  /// Label for brightness slider.
  final String brightness;

  /// Label for contrast slider.
  final String contrast;

  /// Label for saturation slider.
  final String saturation;

  /// Label for exposure slider.
  final String exposure;

  /// Label for warmth slider.
  final String warmth;

  /// Label for tint slider.
  final String tint;

  /// Label for fade slider.
  final String fade;

  /// Label for clarity slider.
  final String clarity;

  /// Label for vignette slider.
  final String vignette;

  /// Label for blur slider.
  final String blur;

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

  /// Label for arrow markup tool.
  final String arrowTool;

  /// Label for rectangle markup tool.
  final String rectangleTool;

  /// Label for oval markup tool.
  final String ovalTool;

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

  /// Button label for removing the selected overlay.
  final String deleteLayer;

  /// Button label for duplicating the selected overlay.
  final String duplicateLayer;

  /// Heading for active overlay layers list.
  final String layersHeading;

  /// Empty-state hint when no overlays exist yet.
  final String noLayersHint;

  /// Tooltip for resetting canvas zoom to fit.
  final String fitToScreen;

  /// Returns the localized label for a given [PhotoAdjustmentType].
  String adjustmentLabel(PhotoAdjustmentType type) {
    switch (type) {
      case PhotoAdjustmentType.brightness:
        return brightness;
      case PhotoAdjustmentType.contrast:
        return contrast;
      case PhotoAdjustmentType.saturation:
        return saturation;
      case PhotoAdjustmentType.exposure:
        return exposure;
      case PhotoAdjustmentType.warmth:
        return warmth;
      case PhotoAdjustmentType.tint:
        return tint;
      case PhotoAdjustmentType.fade:
        return fade;
      case PhotoAdjustmentType.clarity:
        return clarity;
      case PhotoAdjustmentType.vignette:
        return vignette;
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
      case BrushTool.arrow:
        return arrowTool;
      case BrushTool.rectangle:
        return rectangleTool;
      case BrushTool.oval:
        return ovalTool;
    }
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../engine/photo_export_engine.dart';
import '../models/crop_aspect_ratio.dart';
import '../models/drawing_stroke.dart';
import '../models/overlay_layer.dart';
import '../models/photo_adjustments.dart';
import '../models/photo_edit_state.dart';
import '../models/photo_editor_config.dart';
import '../models/photo_editor_result.dart';
import '../models/photo_filter.dart';
import '../models/photo_transform.dart';

/// Stateful controller that manages non-destructive photo edits, undo/redo
/// history, active tools, live drawing strokes, overlay selection, and export.
///
/// Can be passed directly to [PhotoEditor] for programmatic control or used
/// headless with [PhotoExportEngine] to build completely custom editing UIs.
class PhotoEditorController extends ChangeNotifier {
  /// Creates a [PhotoEditorController] initialized with [initialState].
  PhotoEditorController({
    PhotoEditState initialState = PhotoEditState.initial,
    PhotoEditorTool initialTool = PhotoEditorTool.filters,
    this.maxHistoryLength = 50,
    Color initialBrushColor = const Color(0xFFFFFFFF),
    double initialBrushWidth = 0.012,
  }) : assert(maxHistoryLength >= 1, 'maxHistoryLength must be at least 1.'),
       _state = initialState,
       _activeTool = initialTool,
       _brushColor = initialBrushColor,
       _brushWidth = initialBrushWidth.clamp(0.003, 0.06);

  /// Maximum number of undo states retained in history.
  final int maxHistoryLength;

  PhotoEditState _state;
  final List<PhotoEditState> _undoStack = <PhotoEditState>[];
  final List<PhotoEditState> _redoStack = <PhotoEditState>[];

  PhotoEditState? _interactionBaseline;
  PhotoEditorTool _activeTool;
  CropAspectRatio _activeAspectRatio = CropAspectRatio.free;
  PhotoAdjustmentType _activeAdjustment = PhotoAdjustmentType.brightness;

  BrushTool _brushTool = BrushTool.pen;
  Color _brushColor;
  double _brushWidth;
  double _brushOpacity = 1.0;
  DrawingStroke? _activeStroke;

  String? _selectedOverlayId;
  bool _isComparingOriginal = false;
  double _zoomScale = 1.0;
  int _idCounter = 0;

  /// Current immutable snapshot of all edits.
  PhotoEditState get state => _state;

  /// Currently selected top-level editing tool.
  PhotoEditorTool get activeTool => _activeTool;

  /// Currently selected crop aspect ratio preset.
  CropAspectRatio get activeAspectRatio => _activeAspectRatio;

  /// Currently focused adjustment parameter (used in compact mobile UI).
  PhotoAdjustmentType get activeAdjustment => _activeAdjustment;

  /// Active drawing instrument.
  BrushTool get brushTool => _brushTool;

  /// Active drawing stroke color.
  Color get brushColor => _brushColor;

  /// Active normalized drawing stroke width (`0.003` to `0.06`).
  double get brushWidth => _brushWidth;

  /// Active drawing opacity (`0.1` to `1.0`).
  double get brushOpacity => _brushOpacity;

  /// In-progress drawing stroke currently being dragged by the user, if any.
  DrawingStroke? get activeStroke => _activeStroke;

  /// Identifier of the currently selected text or sticker overlay, if any.
  String? get selectedOverlayId => _selectedOverlayId;

  /// Currently selected overlay layer, or `null` if none is selected.
  PhotoOverlayLayer? get selectedOverlay {
    final id = _selectedOverlayId;
    if (id == null) {
      return null;
    }
    for (final layer in _state.overlays) {
      if (layer.id == id) {
        return layer;
      }
    }
    return null;
  }

  /// Whether the canvas is temporarily displaying the unmodified original photo.
  bool get isComparingOriginal => _isComparingOriginal;

  /// Current canvas zoom factor (`1.0` = fit to viewport).
  double get zoomScale => _zoomScale;

  /// Returns `true` if there is at least one state available to undo.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Returns `true` if there is at least one state available to redo.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Returns `true` if any edit has been applied relative to [PhotoEditState.initial].
  bool get hasChanges => _state.isModified;

  String _nextId(String prefix) {
    _idCounter += 1;
    return '${prefix}_$_idCounter';
  }

  /// Marks the start of a continuous gesture (such as dragging a slider, crop
  /// handle, or overlay) so intermediate updates coalesce into a single undo
  /// history entry when [commitInteraction] is called.
  void beginInteraction() {
    _interactionBaseline ??= _state;
  }

  /// Finalizes a continuous gesture started by [beginInteraction], pushing a
  /// single undo checkpoint if the state changed.
  void commitInteraction() {
    final baseline = _interactionBaseline;
    _interactionBaseline = null;
    if (baseline != null && baseline != _state) {
      _pushUndo(baseline);
      notifyListeners();
    }
  }

  void _applyState(PhotoEditState next, {bool recordHistory = true}) {
    if (next == _state) {
      return;
    }
    if (recordHistory && _interactionBaseline == null) {
      _pushUndo(_state);
    }
    _state = next;
    _pruneSelection();
    notifyListeners();
  }

  void _pushUndo(PhotoEditState snapshot) {
    _undoStack.add(snapshot);
    while (_undoStack.length > maxHistoryLength) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _pruneSelection() {
    final id = _selectedOverlayId;
    if (id != null && !_state.overlays.any((layer) => layer.id == id)) {
      _selectedOverlayId = null;
    }
  }

  /// Switches the active editing [tool].
  void setActiveTool(PhotoEditorTool tool) {
    if (_activeTool == tool) {
      return;
    }
    _activeTool = tool;
    if (tool != PhotoEditorTool.text && tool != PhotoEditorTool.stickers) {
      _selectedOverlayId = null;
    }
    notifyListeners();
  }

  /// Focuses a specific [adjustment] in compact mobile controls.
  void setActiveAdjustment(PhotoAdjustmentType adjustment) {
    if (_activeAdjustment == adjustment) {
      return;
    }
    _activeAdjustment = adjustment;
    notifyListeners();
  }

  /// Toggles or explicitly sets original comparison preview mode.
  void setComparingOriginal(bool comparing) {
    if (_isComparingOriginal == comparing) {
      return;
    }
    _isComparingOriginal = comparing;
    notifyListeners();
  }

  /// Updates the tracked canvas [scale] (`1.0` to `5.0`).
  void setZoomScale(double scale) {
    final clamped = scale.clamp(1.0, 5.0);
    if ((_zoomScale - clamped).abs() < 1e-3) {
      return;
    }
    _zoomScale = clamped;
    notifyListeners();
  }

  /// Reverts the most recent edit checkpoint.
  void undo() {
    if (_undoStack.isEmpty) {
      return;
    }
    _interactionBaseline = null;
    _redoStack.add(_state);
    _state = _undoStack.removeLast();
    _pruneSelection();
    notifyListeners();
  }

  /// Re-applies the most recently undone edit checkpoint.
  void redo() {
    if (_redoStack.isEmpty) {
      return;
    }
    _interactionBaseline = null;
    _undoStack.add(_state);
    _state = _redoStack.removeLast();
    _pruneSelection();
    notifyListeners();
  }

  /// Restores a previously serialized or preset [newState].
  void restoreState(PhotoEditState newState, {bool recordHistory = true}) {
    _applyState(newState, recordHistory: recordHistory);
  }

  /// Resets all filters, adjustments, transforms, strokes, and overlays back
  /// to [PhotoEditState.initial].
  void resetAll() {
    _activeAspectRatio = CropAspectRatio.free;
    _selectedOverlayId = null;
    _activeStroke = null;
    _applyState(PhotoEditState.initial);
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  /// Selects a color-grading [filter].
  ///
  /// When switching away from `Original` while [PhotoEditState.filterIntensity]
  /// is `0.0`, intensity automatically resets to `1.0`.
  void selectFilter(PhotoFilter filter) {
    final nextIntensity = !filter.isOriginal && _state.filterIntensity == 0.0
        ? 1.0
        : _state.filterIntensity;
    _applyState(
      _state.copyWith(filter: filter, filterIntensity: nextIntensity),
    );
  }

  /// Sets the blend strength of the active filter (`0.0` to `1.0`).
  void setFilterIntensity(double intensity, {bool recordHistory = true}) {
    _applyState(
      _state.copyWith(filterIntensity: intensity.clamp(0.0, 1.0)),
      recordHistory: recordHistory,
    );
  }

  // ---------------------------------------------------------------------------
  // Adjustments
  // ---------------------------------------------------------------------------

  /// Updates a single adjustment [type] to [value].
  void setAdjustment(
    PhotoAdjustmentType type,
    double value, {
    bool recordHistory = true,
  }) {
    _applyState(
      _state.copyWith(adjustments: _state.adjustments.withValue(type, value)),
      recordHistory: recordHistory,
    );
  }

  /// Resets a single adjustment [type] back to `0.0`.
  void resetAdjustment(PhotoAdjustmentType type) {
    setAdjustment(type, 0.0);
  }

  /// Resets all tonal, color, vignette, and blur adjustments back to default.
  void resetAdjustments() {
    _applyState(_state.copyWith(adjustments: PhotoAdjustments.none));
  }

  // ---------------------------------------------------------------------------
  // Crop & Transform
  // ---------------------------------------------------------------------------

  /// Updates the normalized crop rectangle `[0.0, 1.0]`.
  void setCropRect(Rect cropRect, {bool recordHistory = true}) {
    _applyState(
      _state.copyWith(transform: _state.transform.copyWith(cropRect: cropRect)),
      recordHistory: recordHistory,
    );
  }

  /// Selects an aspect ratio preset and, when [sourceImageSize] is known and
  /// the preset specifies a fixed ratio, immediately fits the largest centered
  /// crop rectangle matching that aspect ratio.
  void selectAspectRatio(CropAspectRatio preset, {Size? sourceImageSize}) {
    _activeAspectRatio = preset;
    if (sourceImageSize != null &&
        sourceImageSize.width > 0 &&
        sourceImageSize.height > 0) {
      final oriented = _state.transform.orientedSize(sourceImageSize);
      final targetRatio = preset.resolve(oriented.width / oriented.height);
      if (targetRatio != null) {
        final nextCrop = PhotoTransform.centeredCropForAspectRatio(
          orientedSize: oriented,
          targetAspectRatio: targetRatio,
        );
        _applyState(
          _state.copyWith(
            transform: _state.transform.copyWith(cropRect: nextCrop),
          ),
        );
        return;
      }
    }
    notifyListeners();
  }

  /// Rotates the photo 90° clockwise along with crop, strokes, and overlays.
  void rotateRight() {
    Offset mapCw(Offset p) => Offset(1.0 - p.dy, p.dx);
    _applyState(
      _state.copyWith(
        transform: _state.transform.rotatedRight(),
        strokes: _state.strokes.map((s) => s.mapPoints(mapCw)).toList(),
        overlays: _state.overlays
            .map(
              (o) => o.copyTransform(
                position: mapCw(o.position),
                rotation: o.rotation + math.pi / 2.0,
              ),
            )
            .toList(),
      ),
    );
  }

  /// Rotates the photo 90° counter-clockwise along with crop, strokes, and
  /// overlays.
  void rotateLeft() {
    Offset mapCcw(Offset p) => Offset(p.dy, 1.0 - p.dx);
    _applyState(
      _state.copyWith(
        transform: _state.transform.rotatedLeft(),
        strokes: _state.strokes.map((s) => s.mapPoints(mapCcw)).toList(),
        overlays: _state.overlays
            .map(
              (o) => o.copyTransform(
                position: mapCcw(o.position),
                rotation: o.rotation - math.pi / 2.0,
              ),
            )
            .toList(),
      ),
    );
  }

  /// Mirrors the photo horizontally along with crop, strokes, and overlays.
  void flipHorizontal() {
    Offset mapH(Offset p) => Offset(1.0 - p.dx, p.dy);
    _applyState(
      _state.copyWith(
        transform: _state.transform.flippedHorizontal(),
        strokes: _state.strokes.map((s) => s.mapPoints(mapH)).toList(),
        overlays: _state.overlays
            .map(
              (o) => o.copyTransform(
                position: mapH(o.position),
                rotation: o.rotation == 0.0 ? 0.0 : -o.rotation,
              ),
            )
            .toList(),
      ),
    );
  }

  /// Mirrors the photo vertically along with crop, strokes, and overlays.
  void flipVertical() {
    Offset mapV(Offset p) => Offset(p.dx, 1.0 - p.dy);
    _applyState(
      _state.copyWith(
        transform: _state.transform.flippedVertical(),
        strokes: _state.strokes.map((s) => s.mapPoints(mapV)).toList(),
        overlays: _state.overlays
            .map(
              (o) => o.copyTransform(
                position: mapV(o.position),
                rotation: o.rotation == 0.0 ? 0.0 : -o.rotation,
              ),
            )
            .toList(),
      ),
    );
  }

  /// Sets the fine straighten angle in [radians] (`-pi/4` to `+pi/4`).
  void setStraightenAngle(double radians, {bool recordHistory = true}) {
    _applyState(
      _state.copyWith(
        transform: _state.transform.copyWith(rotationAngle: radians),
      ),
      recordHistory: recordHistory,
    );
  }

  /// Sets the fine straighten angle in [degrees] (`-45.0` to `+45.0`).
  void setStraightenDegrees(double degrees, {bool recordHistory = true}) {
    setStraightenAngle(degrees * math.pi / 180.0, recordHistory: recordHistory);
  }

  /// Resets crop, rotation, straighten, and flip back to identity.
  void resetTransform() {
    _activeAspectRatio = CropAspectRatio.free;
    _applyState(_state.copyWith(transform: PhotoTransform.identity));
  }

  // ---------------------------------------------------------------------------
  // Drawing & Markup
  // ---------------------------------------------------------------------------

  /// Sets the active drawing [tool].
  void setBrushTool(BrushTool tool) {
    if (_brushTool == tool) {
      return;
    }
    _brushTool = tool;
    notifyListeners();
  }

  /// Sets the active drawing [color].
  void setBrushColor(Color color) {
    if (_brushColor == color) {
      return;
    }
    _brushColor = color;
    notifyListeners();
  }

  /// Sets the normalized drawing stroke [width] (`0.003` to `0.06`).
  void setBrushWidth(double width) {
    final clamped = width.clamp(0.003, 0.06);
    if (_brushWidth == clamped) {
      return;
    }
    _brushWidth = clamped;
    notifyListeners();
  }

  /// Sets the drawing stroke [opacity] (`0.1` to `1.0`).
  void setBrushOpacity(double opacity) {
    final clamped = opacity.clamp(0.1, 1.0);
    if (_brushOpacity == clamped) {
      return;
    }
    _brushOpacity = clamped;
    notifyListeners();
  }

  /// Starts a new live drawing stroke at [normalizedPoint] in oriented-image
  /// coordinates `[0.0, 1.0]`.
  void startStroke(Offset normalizedPoint) {
    _activeStroke = DrawingStroke(
      id: _nextId('stroke'),
      points: <Offset>[normalizedPoint],
      color: _brushColor,
      strokeWidth: _brushWidth,
      tool: _brushTool,
      opacity: _brushOpacity,
    );
    notifyListeners();
  }

  /// Appends [normalizedPoint] to the in-progress drawing stroke.
  void appendStrokePoint(Offset normalizedPoint) {
    final current = _activeStroke;
    if (current == null) {
      return;
    }
    if (current.tool == BrushTool.arrow ||
        current.tool == BrushTool.rectangle ||
        current.tool == BrushTool.oval) {
      _activeStroke = current.copyWith(
        points: <Offset>[current.points.first, normalizedPoint],
      );
    } else {
      final last = current.points.last;
      if ((normalizedPoint - last).distanceSquared < 1e-6) {
        return;
      }
      _activeStroke = current.copyWith(
        points: <Offset>[...current.points, normalizedPoint],
      );
    }
    notifyListeners();
  }

  /// Commits the in-progress drawing stroke into the edit state and history.
  void endStroke() {
    final current = _activeStroke;
    if (current == null) {
      return;
    }
    _activeStroke = null;
    if (current.points.isEmpty) {
      notifyListeners();
      return;
    }
    final nextStrokes = List<DrawingStroke>.unmodifiable(<DrawingStroke>[
      ..._state.strokes,
      current,
    ]);
    _applyState(_state.copyWith(strokes: nextStrokes));
  }

  /// Removes the most recently drawn stroke.
  void undoLastStroke() {
    if (_state.strokes.isEmpty) {
      return;
    }
    final nextStrokes = List<DrawingStroke>.unmodifiable(
      _state.strokes.sublist(0, _state.strokes.length - 1),
    );
    _applyState(_state.copyWith(strokes: nextStrokes));
  }

  /// Removes all drawing strokes.
  void clearStrokes() {
    if (_state.strokes.isEmpty) {
      return;
    }
    _activeStroke = null;
    _applyState(_state.copyWith(strokes: const <DrawingStroke>[]));
  }

  // ---------------------------------------------------------------------------
  // Text & Sticker Overlays
  // ---------------------------------------------------------------------------

  /// Selects an overlay by [id], or clears selection when `null`.
  void selectOverlay(String? id) {
    if (_selectedOverlayId == id) {
      return;
    }
    _selectedOverlayId = id;
    notifyListeners();
  }

  /// Adds a new [TextOverlayLayer] centered in the currently visible crop
  /// region (unless [position] is specified) and selects it.
  TextOverlayLayer addTextLayer({
    required String text,
    Offset? position,
    Color color = const Color(0xFFFFFFFF),
    Color backgroundColor = const Color(0xCC111318),
    TextBackgroundStyle backgroundStyle = TextBackgroundStyle.translucent,
    double fontSize = 0.06,
    FontWeight fontWeight = FontWeight.w700,
    FontStyle fontStyle = FontStyle.normal,
    String? fontFamily,
    TextAlign textAlign = TextAlign.center,
  }) {
    final crop = _state.transform.cropRect;
    final layer = TextOverlayLayer(
      id: _nextId('text'),
      text: text,
      position: position ?? crop.center,
      color: color,
      backgroundColor: backgroundColor,
      backgroundStyle: backgroundStyle,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      fontFamily: fontFamily,
      textAlign: textAlign,
    );
    _selectedOverlayId = layer.id;
    _applyState(
      _state.copyWith(
        overlays: List<PhotoOverlayLayer>.unmodifiable(<PhotoOverlayLayer>[
          ..._state.overlays,
          layer,
        ]),
      ),
    );
    return layer;
  }

  /// Adds a new [StickerOverlayLayer] centered in the currently visible crop
  /// region (unless [position] is specified) and selects it.
  StickerOverlayLayer addStickerLayer(
    String content, {
    Offset? position,
    double baseSize = 0.14,
  }) {
    final crop = _state.transform.cropRect;
    final layer = StickerOverlayLayer(
      id: _nextId('sticker'),
      content: content,
      position: position ?? crop.center,
      baseSize: baseSize,
    );
    _selectedOverlayId = layer.id;
    _applyState(
      _state.copyWith(
        overlays: List<PhotoOverlayLayer>.unmodifiable(<PhotoOverlayLayer>[
          ..._state.overlays,
          layer,
        ]),
      ),
    );
    return layer;
  }

  /// Replaces an existing overlay matching `updated.id`.
  void updateOverlay(PhotoOverlayLayer updated, {bool recordHistory = true}) {
    final idx = _state.overlays.indexWhere((o) => o.id == updated.id);
    if (idx == -1) {
      return;
    }
    final next = List<PhotoOverlayLayer>.of(_state.overlays);
    next[idx] = updated;
    _applyState(
      _state.copyWith(overlays: List<PhotoOverlayLayer>.unmodifiable(next)),
      recordHistory: recordHistory,
    );
  }

  /// Moves the overlay with [id] to the top of the visual stacking order.
  void bringOverlayToFront(String id) {
    final idx = _state.overlays.indexWhere((o) => o.id == id);
    if (idx == -1 || idx == _state.overlays.length - 1) {
      return;
    }
    final next = List<PhotoOverlayLayer>.of(_state.overlays);
    final layer = next.removeAt(idx);
    next.add(layer);
    _applyState(
      _state.copyWith(overlays: List<PhotoOverlayLayer>.unmodifiable(next)),
      recordHistory: false,
    );
  }

  /// Duplicates the currently selected overlay with a slight positional offset.
  void duplicateSelectedOverlay() {
    final current = selectedOverlay;
    if (current == null) {
      return;
    }
    final offsetPos = Offset(
      (current.position.dx + 0.04).clamp(0.05, 0.95),
      (current.position.dy + 0.04).clamp(0.05, 0.95),
    );
    final PhotoOverlayLayer clone = switch (current) {
      TextOverlayLayer() => current.copyWith(
        id: _nextId('text'),
        position: offsetPos,
      ),
      StickerOverlayLayer() => current.copyWith(
        id: _nextId('sticker'),
        position: offsetPos,
      ),
    };
    _selectedOverlayId = clone.id;
    _applyState(
      _state.copyWith(
        overlays: List<PhotoOverlayLayer>.unmodifiable(<PhotoOverlayLayer>[
          ..._state.overlays,
          clone,
        ]),
      ),
    );
  }

  /// Deletes the overlay matching [id].
  void deleteOverlay(String id) {
    if (!_state.overlays.any((o) => o.id == id)) {
      return;
    }
    if (_selectedOverlayId == id) {
      _selectedOverlayId = null;
    }
    final next = _state.overlays.where((o) => o.id != id).toList();
    _applyState(
      _state.copyWith(overlays: List<PhotoOverlayLayer>.unmodifiable(next)),
    );
  }

  /// Deletes the currently selected overlay, if any.
  void deleteSelectedOverlay() {
    final id = _selectedOverlayId;
    if (id != null) {
      deleteOverlay(id);
    }
  }

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  /// Renders and encodes [image] with the controller's current [state].
  Future<PhotoEditorResult> export(
    ui.Image image, {
    PhotoExportOptions options = const PhotoExportOptions(),
  }) {
    return PhotoExportEngine.export(
      image: image,
      state: _state,
      options: options,
    );
  }
}

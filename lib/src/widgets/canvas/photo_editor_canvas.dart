import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../controller/photo_editor_controller.dart';
import '../../engine/photo_scene_renderer.dart';
import '../../models/drawing_stroke.dart';
import '../../models/overlay_layer.dart';
import '../../models/photo_edit_state.dart';
import '../../models/photo_editor_config.dart';
import '../../models/photo_editor_theme.dart';
import '../../models/photo_transform.dart';
import 'crop_overlay.dart';

/// Interactive studio canvas that renders the live edited photo, crop handles,
/// drawing surface, and draggable/scalable/rotatable text & sticker overlays.
///
/// Can be embedded standalone when building a custom photo editor UI around
/// [PhotoEditorController].
class PhotoEditorCanvas extends StatefulWidget {
  /// Creates a [PhotoEditorCanvas].
  const PhotoEditorCanvas({
    super.key,
    required this.image,
    required this.controller,
    this.theme,
    this.enableZoomPan = true,
    this.originalBadgeLabel = 'ORIGINAL',
    this.transformationController,
    this.onEditTextLayer,
  });

  /// Source decoded image being edited.
  final ui.Image image;

  /// Controller holding edit state, active tool, and selection.
  final PhotoEditorController controller;

  /// Optional theme overrides (defaults to [PhotoEditorTheme.dark]).
  final PhotoEditorTheme? theme;

  /// Whether interactive pinch/scroll zoom and pan is enabled.
  final bool enableZoomPan;

  /// Floating badge label displayed while comparing against the original image.
  final String originalBadgeLabel;

  /// Optional external [TransformationController] for synchronizing desktop
  /// toolbar zoom controls.
  final TransformationController? transformationController;

  /// Invoked when the user double-taps a [TextOverlayLayer] to edit its copy.
  final ValueChanged<TextOverlayLayer>? onEditTextLayer;

  @override
  State<PhotoEditorCanvas> createState() => _PhotoEditorCanvasState();
}

class _PhotoEditorCanvasState extends State<PhotoEditorCanvas> {
  final GlobalKey _frameKey = GlobalKey();
  TransformationController? _internalTransformController;
  String? _draggingOverlayId;
  Offset _dragStartNormPos = Offset.zero;
  Offset _dragStartGlobal = Offset.zero;
  double _handleStartScale = 1.0;
  double _handleStartRotation = 0.0;
  double _handleStartAngle = 0.0;
  double _handleStartDistance = 1.0;

  Offset _frameLocalToGlobal(Offset localPoint) {
    final box = _frameKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return localPoint;
    }
    return box.localToGlobal(localPoint);
  }

  TransformationController get _transformController =>
      widget.transformationController ??
      (_internalTransformController ??= TransformationController());

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_handleMatrixChanged);
  }

  @override
  void didUpdateWidget(covariant PhotoEditorCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transformationController != widget.transformationController) {
      oldWidget.transformationController?.removeListener(_handleMatrixChanged);
      _transformController.addListener(_handleMatrixChanged);
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_handleMatrixChanged);
    _internalTransformController?.dispose();
    super.dispose();
  }

  void _handleMatrixChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    widget.controller.setZoomScale(scale);
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
    widget.controller.setZoomScale(1.0);
  }

  Offset _localToNormalized(Offset local, Size canvasSize, Rect visibleRect) {
    final u = (local.dx / math.max(1.0, canvasSize.width)).clamp(0.0, 1.0);
    final v = (local.dy / math.max(1.0, canvasSize.height)).clamp(0.0, 1.0);
    return Offset(
      visibleRect.left + u * visibleRect.width,
      visibleRect.top + v * visibleRect.height,
    );
  }

  Offset _normalizedToLocal(Offset norm, Size canvasSize, Rect visibleRect) {
    final u = (norm.dx - visibleRect.left) / math.max(1e-5, visibleRect.width);
    final v = (norm.dy - visibleRect.top) / math.max(1e-5, visibleRect.height);
    return Offset(u * canvasSize.width, v * canvasSize.height);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? PhotoEditorTheme.dark();

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final state = controller.state;
        final sourceSize = Size(
          widget.image.width.toDouble(),
          widget.image.height.toDouble(),
        );
        final orientedSize = state.transform.orientedSize(sourceSize);
        final isCropMode =
            controller.activeTool == PhotoEditorTool.crop &&
            !controller.isComparingOriginal;
        final isDrawMode =
            controller.activeTool == PhotoEditorTool.draw &&
            !controller.isComparingOriginal;
        final isOverlayMode =
            (controller.activeTool == PhotoEditorTool.text ||
                controller.activeTool == PhotoEditorTool.stickers) &&
            !controller.isComparingOriginal;

        final visibleRect = isCropMode
            ? PhotoTransform.fullCropRect
            : state.transform.cropRect;

        final displayAspect = controller.isComparingOriginal
            ? sourceSize.width / math.max(1.0, sourceSize.height)
            : (orientedSize.width * visibleRect.width) /
                  math.max(1.0, orientedSize.height * visibleRect.height);

        final allowInteractiveViewer =
            widget.enableZoomPan && !isCropMode && !isDrawMode;

        return Container(
          color: theme.canvasBackground,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pad = constraints.maxWidth >= 600 ? 28.0 : 16.0;
              final availW = math.max(40.0, constraints.maxWidth - pad * 2);
              final availH = math.max(40.0, constraints.maxHeight - pad * 2);

              final double frameW;
              final double frameH;
              if (availW / availH > displayAspect) {
                frameH = availH;
                frameW = frameH * displayAspect;
              } else {
                frameW = availW;
                frameH = frameW / displayAspect;
              }
              final canvasSize = Size(frameW, frameH);

              Widget photoFrame = SizedBox(
                key: _frameKey,
                width: frameW,
                height: frameH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.42),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      // Primary WYSIWYG scene painter.
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _PhotoScenePainter(
                            image: widget.image,
                            state: state,
                            showFullUncropped: isCropMode,
                            showOriginal: controller.isComparingOriginal,
                            activeStroke: controller.activeStroke,
                          ),
                        ),
                      ),

                      // Interactive crop frame overlay.
                      if (isCropMode)
                        Positioned.fill(
                          child: CropOverlay(
                            cropRect: state.transform.cropRect,
                            orientedImageSize: orientedSize,
                            lockedAspectRatio: controller.activeAspectRatio
                                .resolve(
                                  orientedSize.width /
                                      math.max(1.0, orientedSize.height),
                                ),
                            theme: theme,
                            onInteractionStart: controller.beginInteraction,
                            onInteractionEnd: controller.commitInteraction,
                            onCropChanged: (rect) => controller.setCropRect(
                              rect,
                              recordHistory: false,
                            ),
                          ),
                        ),

                      // Interactive drawing surface.
                      if (isDrawMode)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) {
                              controller.startStroke(
                                _localToNormalized(
                                  details.localPosition,
                                  canvasSize,
                                  visibleRect,
                                ),
                              );
                            },
                            onPanUpdate: (details) {
                              controller.appendStrokePoint(
                                _localToNormalized(
                                  details.localPosition,
                                  canvasSize,
                                  visibleRect,
                                ),
                              );
                            },
                            onPanEnd: (_) => controller.endStroke(),
                            onPanCancel: () => controller.endStroke(),
                          ),
                        ),

                      // Interactive overlay hit targets & selection frame.
                      if (isOverlayMode)
                        ..._buildOverlayInteractionLayers(
                          context: context,
                          controller: controller,
                          canvasSize: canvasSize,
                          orientedSize: orientedSize,
                          visibleRect: visibleRect,
                          theme: theme,
                        ),
                    ],
                  ),
                ),
              );

              if (allowInteractiveViewer) {
                photoFrame = GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: _resetZoom,
                  onTap: () {
                    if (controller.selectedOverlayId != null) {
                      controller.selectOverlay(null);
                    }
                  },
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 1.0,
                    maxScale: 5.0,
                    boundaryMargin: const EdgeInsets.all(120),
                    panEnabled: controller.zoomScale > 1.01,
                    child: Center(child: photoFrame),
                  ),
                );
              } else {
                photoFrame = Center(child: photoFrame);
              }

              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  photoFrame,
                  if (controller.isComparingOriginal)
                    Positioned(
                      top: 14,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Text(
                              widget.originalBadgeLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildOverlayInteractionLayers({
    required BuildContext context,
    required PhotoEditorController controller,
    required Size canvasSize,
    required Size orientedSize,
    required Rect visibleRect,
    required PhotoEditorTheme theme,
  }) {
    final visiblePxW = math.max(1.0, visibleRect.width * orientedSize.width);
    final canvasScale = canvasSize.width / visiblePxW;
    final widgets = <Widget>[];

    for (final overlay in controller.state.overlays) {
      final isSelected = controller.selectedOverlayId == overlay.id;
      final center = _normalizedToLocal(
        overlay.position,
        canvasSize,
        visibleRect,
      );
      final baseSize = PhotoSceneRenderer.measureOverlaySize(
        overlay,
        orientedSize,
      );
      final boxW = math.max(
        48.0,
        baseSize.width * canvasScale * overlay.scale + 16.0,
      );
      final boxH = math.max(
        40.0,
        baseSize.height * canvasScale * overlay.scale + 16.0,
      );

      widgets.add(
        Positioned(
          left: center.dx - boxW / 2.0,
          top: center.dy - boxH / 2.0,
          width: boxW,
          height: boxH,
          child: Transform.rotate(
            angle: overlay.rotation,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                // Main body hit/drag surface.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      controller.selectOverlay(overlay.id);
                      controller.bringOverlayToFront(overlay.id);
                    },
                    onDoubleTap: () {
                      if (overlay is TextOverlayLayer) {
                        controller.selectOverlay(overlay.id);
                        widget.onEditTextLayer?.call(overlay);
                      }
                    },
                    onPanStart: (details) {
                      controller.selectOverlay(overlay.id);
                      controller.bringOverlayToFront(overlay.id);
                      controller.beginInteraction();
                      _draggingOverlayId = overlay.id;
                      _dragStartNormPos = overlay.position;
                      _dragStartGlobal = details.globalPosition;
                    },
                    onPanUpdate: (details) {
                      if (_draggingOverlayId != overlay.id) {
                        return;
                      }
                      final deltaPx =
                          (details.globalPosition - _dragStartGlobal) /
                          math.max(1.0, controller.zoomScale);
                      final nextNorm = Offset(
                        (_dragStartNormPos.dx +
                                (deltaPx.dx / math.max(1.0, canvasSize.width)) *
                                    visibleRect.width)
                            .clamp(0.0, 1.0),
                        (_dragStartNormPos.dy +
                                (deltaPx.dy /
                                        math.max(1.0, canvasSize.height)) *
                                    visibleRect.height)
                            .clamp(0.0, 1.0),
                      );
                      controller.updateOverlay(
                        overlay.copyTransform(position: nextNorm),
                        recordHistory: false,
                      );
                    },
                    onPanEnd: (_) {
                      _draggingOverlayId = null;
                      controller.commitInteraction();
                    },
                    onPanCancel: () {
                      _draggingOverlayId = null;
                      controller.commitInteraction();
                    },
                    child: Container(
                      decoration: isSelected
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.accentColor,
                                width: 1.6,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),

                // Delete button badge (top-left of selected overlay).
                if (isSelected)
                  Positioned(
                    left: -12,
                    top: -12,
                    child: GestureDetector(
                      onTap: () => controller.deleteOverlay(overlay.id),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.dangerColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Scale & Rotate drag handle (bottom-right of selected overlay).
                if (isSelected)
                  Positioned(
                    right: -12,
                    bottom: -12,
                    child: GestureDetector(
                      onPanStart: (details) {
                        controller.beginInteraction();
                        final centerGlobal = _frameLocalToGlobal(center);
                        final vec = details.globalPosition - centerGlobal;
                        _handleStartScale = overlay.scale;
                        _handleStartRotation = overlay.rotation;
                        _handleStartDistance = math.max(12.0, vec.distance);
                        _handleStartAngle = math.atan2(vec.dy, vec.dx);
                      },
                      onPanUpdate: (details) {
                        final centerGlobal = _frameLocalToGlobal(center);
                        final vec = details.globalPosition - centerGlobal;
                        final ratio =
                            math.max(12.0, vec.distance) / _handleStartDistance;
                        final angleDelta =
                            math.atan2(vec.dy, vec.dx) - _handleStartAngle;
                        controller.updateOverlay(
                          overlay.copyTransform(
                            scale: (_handleStartScale * ratio).clamp(0.25, 5.0),
                            rotation: _handleStartRotation + angleDelta,
                          ),
                          recordHistory: false,
                        );
                      },
                      onPanEnd: (_) => controller.commitInteraction(),
                      onPanCancel: () => controller.commitInteraction(),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.open_in_full,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _PhotoScenePainter extends CustomPainter {
  const _PhotoScenePainter({
    required this.image,
    required this.state,
    required this.showFullUncropped,
    required this.showOriginal,
    required this.activeStroke,
  });

  final ui.Image image;
  final PhotoEditState state;
  final bool showFullUncropped;
  final bool showOriginal;
  final DrawingStroke? activeStroke;

  @override
  void paint(Canvas canvas, Size size) {
    PhotoSceneRenderer.paint(
      canvas: canvas,
      outputSize: size,
      image: image,
      state: state,
      showFullUncropped: showFullUncropped,
      showOriginal: showOriginal,
      activeStroke: activeStroke,
    );
  }

  @override
  bool shouldRepaint(_PhotoScenePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.state != state ||
        oldDelegate.showFullUncropped != showFullUncropped ||
        oldDelegate.showOriginal != showOriginal ||
        oldDelegate.activeStroke != activeStroke;
  }
}

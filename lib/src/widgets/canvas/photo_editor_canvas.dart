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
import '../../models/photo_frame.dart';
import '../../models/photo_transform.dart';
import 'crop_overlay.dart';

/// Interactive studio canvas that renders the live edited photo, studio frames,
/// split-screen before/after curtain, interactive crop handles, vector markup
/// & privacy blur surface, magnetic center snap guides, and draggable/scalable/
/// rotatable text, sticker, and studio-badge overlays.
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
    this.enableSnapGuides = true,
    this.originalBadgeLabel = 'ORIGINAL',
    this.beforeBadgeLabel = 'BEFORE',
    this.afterBadgeLabel = 'AFTER',
    this.transformationController,
    this.onEditTextLayer,
  });

  /// Source decoded image being edited.
  final ui.Image image;

  /// Controller holding edit state, active tool, compare mode, and selection.
  final PhotoEditorController controller;

  /// Optional theme overrides (defaults to [PhotoEditorTheme.dark]).
  final PhotoEditorTheme? theme;

  /// Whether interactive pinch/scroll zoom and pan is enabled.
  final bool enableZoomPan;

  /// Whether magnetic center alignment guides appear while dragging overlays.
  final bool enableSnapGuides;

  /// Floating badge label displayed in full-original comparison mode.
  final String originalBadgeLabel;

  /// Left badge label displayed in split-screen comparison mode.
  final String beforeBadgeLabel;

  /// Right badge label displayed in split-screen comparison mode.
  final String afterBadgeLabel;

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

  bool _snappedVerticalCenter = false;
  bool _snappedHorizontalCenter = false;

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

  Offset _frameLocalToGlobal(Offset localPoint) {
    final box = _frameKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return localPoint;
    }
    return box.localToGlobal(localPoint);
  }

  Offset _localToNormalized(Offset local, Rect contentRect, Rect visibleRect) {
    final u = ((local.dx - contentRect.left) / math.max(1.0, contentRect.width))
        .clamp(0.0, 1.0);
    final v = ((local.dy - contentRect.top) / math.max(1.0, contentRect.height))
        .clamp(0.0, 1.0);
    return Offset(
      visibleRect.left + u * visibleRect.width,
      visibleRect.top + v * visibleRect.height,
    );
  }

  Offset _normalizedToLocal(Offset norm, Rect contentRect, Rect visibleRect) {
    final u = (norm.dx - visibleRect.left) / math.max(1e-5, visibleRect.width);
    final v = (norm.dy - visibleRect.top) / math.max(1e-5, visibleRect.height);
    return Offset(
      contentRect.left + u * contentRect.width,
      contentRect.top + v * contentRect.height,
    );
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
        final isFullOriginal =
            controller.compareMode == PhotoCompareMode.fullOriginal;
        final isSplitCompare =
            controller.compareMode == PhotoCompareMode.splitCurtain;
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

        final displayAspect = isFullOriginal
            ? sourceSize.width / math.max(1.0, sourceSize.height)
            : (orientedSize.width * visibleRect.width) /
                  math.max(1.0, orientedSize.height * visibleRect.height);

        final allowInteractiveViewer =
            widget.enableZoomPan &&
            !isCropMode &&
            !isDrawMode &&
            !isSplitCompare;

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
              final outerSize = Size(frameW, frameH);
              final activeFrame = isCropMode ? PhotoFrame.none : state.frame;
              final contentRect = PhotoSceneRenderer.computeFramedContentRect(
                outerSize,
                activeFrame,
              );

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
                      // Primary WYSIWYG scene painter (normal or split curtain).
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _PhotoScenePainter(
                            image: widget.image,
                            state: state,
                            showFullUncropped: isCropMode,
                            compareMode: controller.compareMode,
                            splitPosition: controller.splitPosition,
                            activeStroke: controller.activeStroke,
                          ),
                        ),
                      ),

                      // Interactive Canva/Figma magnetic center snap guides.
                      if (isOverlayMode &&
                          (_snappedVerticalCenter || _snappedHorizontalCenter))
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _SnapGuidesPainter(
                                contentRect: contentRect,
                                showVertical: _snappedVerticalCenter,
                                showHorizontal: _snappedHorizontalCenter,
                                color: theme.accentColor,
                              ),
                            ),
                          ),
                        ),

                      // Interactive split-screen before/after curtain divider.
                      if (isSplitCompare)
                        Positioned.fill(
                          child: _SplitCompareCurtain(
                            splitPosition: controller.splitPosition,
                            beforeLabel: widget.beforeBadgeLabel,
                            afterLabel: widget.afterBadgeLabel,
                            accentColor: theme.accentColor,
                            onChanged: controller.setSplitPosition,
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

                      // Interactive drawing & privacy-blur surface.
                      if (isDrawMode)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) {
                              controller.startStroke(
                                _localToNormalized(
                                  details.localPosition,
                                  contentRect,
                                  visibleRect,
                                ),
                              );
                            },
                            onPanUpdate: (details) {
                              controller.appendStrokePoint(
                                _localToNormalized(
                                  details.localPosition,
                                  contentRect,
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
                          controller: controller,
                          contentRect: contentRect,
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
                  if (isFullOriginal)
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
    required PhotoEditorController controller,
    required Rect contentRect,
    required Size orientedSize,
    required Rect visibleRect,
    required PhotoEditorTheme theme,
  }) {
    final visiblePxW = math.max(1.0, visibleRect.width * orientedSize.width);
    final canvasScale = contentRect.width / visiblePxW;
    final widgets = <Widget>[];

    for (final overlay in controller.state.overlays) {
      if (!overlay.isVisible) {
        continue;
      }
      final isSelected = controller.selectedOverlayId == overlay.id;
      final center = _normalizedToLocal(
        overlay.position,
        contentRect,
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
                      var nextX =
                          (_dragStartNormPos.dx +
                                  (deltaPx.dx /
                                          math.max(1.0, contentRect.width)) *
                                      visibleRect.width)
                              .clamp(0.0, 1.0);
                      var nextY =
                          (_dragStartNormPos.dy +
                                  (deltaPx.dy /
                                          math.max(1.0, contentRect.height)) *
                                      visibleRect.height)
                              .clamp(0.0, 1.0);

                      var snapV = false;
                      var snapH = false;
                      if (widget.enableSnapGuides) {
                        final snapTolX = visibleRect.width * 0.018;
                        final snapTolY = visibleRect.height * 0.018;
                        if ((nextX - visibleRect.center.dx).abs() <= snapTolX) {
                          nextX = visibleRect.center.dx;
                          snapV = true;
                        }
                        if ((nextY - visibleRect.center.dy).abs() <= snapTolY) {
                          nextY = visibleRect.center.dy;
                          snapH = true;
                        }
                      }

                      if (snapV != _snappedVerticalCenter ||
                          snapH != _snappedHorizontalCenter) {
                        setState(() {
                          _snappedVerticalCenter = snapV;
                          _snappedHorizontalCenter = snapH;
                        });
                      }

                      controller.updateOverlay(
                        overlay.copyTransform(position: Offset(nextX, nextY)),
                        recordHistory: false,
                      );
                    },
                    onPanEnd: (_) {
                      _draggingOverlayId = null;
                      if (_snappedVerticalCenter || _snappedHorizontalCenter) {
                        setState(() {
                          _snappedVerticalCenter = false;
                          _snappedHorizontalCenter = false;
                        });
                      }
                      controller.commitInteraction();
                    },
                    onPanCancel: () {
                      _draggingOverlayId = null;
                      if (_snappedVerticalCenter || _snappedHorizontalCenter) {
                        setState(() {
                          _snappedVerticalCenter = false;
                          _snappedHorizontalCenter = false;
                        });
                      }
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

class _SplitCompareCurtain extends StatelessWidget {
  const _SplitCompareCurtain({
    required this.splitPosition,
    required this.beforeLabel,
    required this.afterLabel,
    required this.accentColor,
    required this.onChanged,
  });

  final double splitPosition;
  final String beforeLabel;
  final String afterLabel;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = math.max(1.0, constraints.maxWidth);
        final h = math.max(1.0, constraints.maxHeight);
        final splitX = w * splitPosition.clamp(0.05, 0.95);

        void updateFromX(double dx) {
          onChanged((dx / w).clamp(0.05, 0.95));
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => updateFromX(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => updateFromX(d.localPosition.dx),
          onTapDown: (d) => updateFromX(d.localPosition.dx),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              // Vertical hairline divider.
              Positioned(
                left: splitX - 1.0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2.0,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),

              // Draggable center thumb knob.
              Positioned(
                left: splitX - 18,
                top: h / 2 - 18,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.0),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.45),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.compare_arrows_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),

              // BEFORE pill (top-left).
              if (splitX > 70)
                Positioned(
                  left: 12,
                  top: 12,
                  child: _SplitBadge(label: beforeLabel),
                ),

              // AFTER pill (top-right).
              if (w - splitX > 70)
                Positioned(
                  right: 12,
                  top: 12,
                  child: _SplitBadge(label: afterLabel, accent: accentColor),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SplitBadge extends StatelessWidget {
  const _SplitBadge({required this.label, this.accent});

  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent != null
            ? accent!.withValues(alpha: 0.85)
            : Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SnapGuidesPainter extends CustomPainter {
  const _SnapGuidesPainter({
    required this.contentRect,
    required this.showVertical,
    required this.showHorizontal,
    required this.color,
  });

  final Rect contentRect;
  final bool showVertical;
  final bool showHorizontal;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 1.25;
    if (showVertical) {
      canvas.drawLine(
        Offset(contentRect.center.dx, contentRect.top),
        Offset(contentRect.center.dx, contentRect.bottom),
        paint,
      );
    }
    if (showHorizontal) {
      canvas.drawLine(
        Offset(contentRect.left, contentRect.center.dy),
        Offset(contentRect.right, contentRect.center.dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SnapGuidesPainter oldDelegate) {
    return oldDelegate.contentRect != contentRect ||
        oldDelegate.showVertical != showVertical ||
        oldDelegate.showHorizontal != showHorizontal ||
        oldDelegate.color != color;
  }
}

class _PhotoScenePainter extends CustomPainter {
  const _PhotoScenePainter({
    required this.image,
    required this.state,
    required this.showFullUncropped,
    required this.compareMode,
    required this.splitPosition,
    required this.activeStroke,
  });

  final ui.Image image;
  final PhotoEditState state;
  final bool showFullUncropped;
  final PhotoCompareMode compareMode;
  final double splitPosition;
  final DrawingStroke? activeStroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (compareMode == PhotoCompareMode.splitCurtain && !showFullUncropped) {
      PhotoSceneRenderer.paintSplitComparison(
        canvas: canvas,
        outputSize: size,
        image: image,
        state: state,
        splitPosition: splitPosition,
        activeStroke: activeStroke,
      );
      return;
    }

    PhotoSceneRenderer.paint(
      canvas: canvas,
      outputSize: size,
      image: image,
      state: state,
      showFullUncropped: showFullUncropped,
      showOriginal: compareMode == PhotoCompareMode.fullOriginal,
      activeStroke: activeStroke,
    );
  }

  @override
  bool shouldRepaint(_PhotoScenePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.state != state ||
        oldDelegate.showFullUncropped != showFullUncropped ||
        oldDelegate.compareMode != compareMode ||
        oldDelegate.splitPosition != splitPosition ||
        oldDelegate.activeStroke != activeStroke;
  }
}

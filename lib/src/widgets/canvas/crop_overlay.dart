import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../models/photo_editor_theme.dart';
import '../../models/photo_transform.dart';
import '../controls/studio_primitives.dart';

enum _CropDragZone {
  none,
  move,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
}

/// Interactive crop overlay rendered directly above the full oriented image
/// while the Crop tool is active.
class CropOverlay extends StatefulWidget {
  /// Creates a [CropOverlay].
  const CropOverlay({
    super.key,
    required this.cropRect,
    required this.orientedImageSize,
    required this.theme,
    required this.onCropChanged,
    this.lockedAspectRatio,
    this.onInteractionStart,
    this.onInteractionEnd,
  });

  /// Current normalized crop rectangle in `[0.0, 1.0]` space.
  final Rect cropRect;

  /// Full pixel dimensions of the oriented source image (for dimension badge).
  final Size orientedImageSize;

  /// Optional locked width-to-height ratio, or `null` for freeform cropping.
  final double? lockedAspectRatio;

  /// Visual styling tokens.
  final PhotoEditorTheme theme;

  /// Called continuously as the user drags a crop handle or moves the box.
  final ValueChanged<Rect> onCropChanged;

  /// Called when a crop drag gesture starts.
  final VoidCallback? onInteractionStart;

  /// Called when a crop drag gesture ends.
  final VoidCallback? onInteractionEnd;

  @override
  State<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<CropOverlay> {
  _CropDragZone _activeZone = _CropDragZone.none;
  Rect _dragStartPixelRect = Rect.zero;
  Offset _dragStartLocal = Offset.zero;
  bool _isDragging = false;

  _CropDragZone _hitTest(Offset point, Rect pxRect) {
    const cornerRadius = 26.0;
    const edgeThreshold = 18.0;

    if ((point - pxRect.topLeft).distance <= cornerRadius) {
      return _CropDragZone.topLeft;
    }
    if ((point - pxRect.topRight).distance <= cornerRadius) {
      return _CropDragZone.topRight;
    }
    if ((point - pxRect.bottomLeft).distance <= cornerRadius) {
      return _CropDragZone.bottomLeft;
    }
    if ((point - pxRect.bottomRight).distance <= cornerRadius) {
      return _CropDragZone.bottomRight;
    }

    if ((point.dx - pxRect.left).abs() <= edgeThreshold &&
        point.dy >= pxRect.top - edgeThreshold &&
        point.dy <= pxRect.bottom + edgeThreshold) {
      return _CropDragZone.left;
    }
    if ((point.dx - pxRect.right).abs() <= edgeThreshold &&
        point.dy >= pxRect.top - edgeThreshold &&
        point.dy <= pxRect.bottom + edgeThreshold) {
      return _CropDragZone.right;
    }
    if ((point.dy - pxRect.top).abs() <= edgeThreshold &&
        point.dx >= pxRect.left - edgeThreshold &&
        point.dx <= pxRect.right + edgeThreshold) {
      return _CropDragZone.top;
    }
    if ((point.dy - pxRect.bottom).abs() <= edgeThreshold &&
        point.dx >= pxRect.left - edgeThreshold &&
        point.dx <= pxRect.right + edgeThreshold) {
      return _CropDragZone.bottom;
    }

    if (pxRect.contains(point)) {
      return _CropDragZone.move;
    }
    return _CropDragZone.none;
  }

  Rect _toPixelRect(Rect norm, Size bounds) {
    return Rect.fromLTRB(
      norm.left * bounds.width,
      norm.top * bounds.height,
      norm.right * bounds.width,
      norm.bottom * bounds.height,
    );
  }

  Rect _toNormalizedRect(Rect px, Size bounds) {
    if (bounds.width <= 0 || bounds.height <= 0) {
      return PhotoTransform.fullCropRect;
    }
    return PhotoTransform.clampCropRect(
      Rect.fromLTRB(
        px.left / bounds.width,
        px.top / bounds.height,
        px.right / bounds.width,
        px.bottom / bounds.height,
      ),
    );
  }

  Rect _computeUpdatedPixelRect(Offset delta, Size bounds) {
    final w = bounds.width;
    final h = bounds.height;
    final start = _dragStartPixelRect;
    final ar = widget.lockedAspectRatio;

    var minW = math.min(w, math.max(28.0, w * PhotoTransform.minCropExtent));
    var minH = math.min(h, math.max(28.0, h * PhotoTransform.minCropExtent));
    if (ar != null && ar > 0) {
      if (minW / minH < ar) {
        minW = math.min(w, minH * ar);
        minH = minW / ar;
      } else {
        minH = math.min(h, minW / ar);
        minW = minH * ar;
      }
    }

    switch (_activeZone) {
      case _CropDragZone.none:
        return start;

      case _CropDragZone.move:
        final nextLeft = (start.left + delta.dx).clamp(0.0, w - start.width);
        final nextTop = (start.top + delta.dy).clamp(0.0, h - start.height);
        return Rect.fromLTWH(nextLeft, nextTop, start.width, start.height);

      case _CropDragZone.bottomRight:
        if (ar == null) {
          final right = (start.right + delta.dx).clamp(start.left + minW, w);
          final bottom = (start.bottom + delta.dy).clamp(start.top + minH, h);
          return Rect.fromLTRB(start.left, start.top, right, bottom);
        }
        final ax = start.left;
        final ay = start.top;
        final rawW = start.width + delta.dx;
        final rawH = start.height + delta.dy;
        final maxW = math.min(w - ax, (h - ay) * ar);
        final nextW = ((rawW + rawH * ar) / 2.0)
            .clamp(math.min(minW, maxW), maxW)
            .toDouble();
        return Rect.fromLTWH(ax, ay, nextW, nextW / ar);

      case _CropDragZone.topLeft:
        if (ar == null) {
          final left = (start.left + delta.dx).clamp(0.0, start.right - minW);
          final top = (start.top + delta.dy).clamp(0.0, start.bottom - minH);
          return Rect.fromLTRB(left, top, start.right, start.bottom);
        }
        final ax = start.right;
        final ay = start.bottom;
        final rawW = start.width - delta.dx;
        final rawH = start.height - delta.dy;
        final maxW = math.min(ax, ay * ar);
        final nextW = ((rawW + rawH * ar) / 2.0)
            .clamp(math.min(minW, maxW), maxW)
            .toDouble();
        final nextH = nextW / ar;
        return Rect.fromLTWH(ax - nextW, ay - nextH, nextW, nextH);

      case _CropDragZone.topRight:
        if (ar == null) {
          final right = (start.right + delta.dx).clamp(start.left + minW, w);
          final top = (start.top + delta.dy).clamp(0.0, start.bottom - minH);
          return Rect.fromLTRB(start.left, top, right, start.bottom);
        }
        final ax = start.left;
        final ay = start.bottom;
        final rawW = start.width + delta.dx;
        final rawH = start.height - delta.dy;
        final maxW = math.min(w - ax, ay * ar);
        final nextW = ((rawW + rawH * ar) / 2.0)
            .clamp(math.min(minW, maxW), maxW)
            .toDouble();
        final nextH = nextW / ar;
        return Rect.fromLTWH(ax, ay - nextH, nextW, nextH);

      case _CropDragZone.bottomLeft:
        if (ar == null) {
          final left = (start.left + delta.dx).clamp(0.0, start.right - minW);
          final bottom = (start.bottom + delta.dy).clamp(start.top + minH, h);
          return Rect.fromLTRB(left, start.top, start.right, bottom);
        }
        final ax = start.right;
        final ay = start.top;
        final rawW = start.width - delta.dx;
        final rawH = start.height + delta.dy;
        final maxW = math.min(ax, (h - ay) * ar);
        final nextW = ((rawW + rawH * ar) / 2.0)
            .clamp(math.min(minW, maxW), maxW)
            .toDouble();
        final nextH = nextW / ar;
        return Rect.fromLTWH(ax - nextW, ay, nextW, nextH);

      case _CropDragZone.right:
        if (ar == null) {
          final right = (start.right + delta.dx).clamp(start.left + minW, w);
          return Rect.fromLTRB(start.left, start.top, right, start.bottom);
        }
        final maxW = math.min(w - start.left, h * ar);
        final nextW = (start.width + delta.dx)
            .clamp(math.min(minW, maxW), maxW)
            .toDouble();
        final nextH = nextW / ar;
        final nextTop = (start.center.dy - nextH / 2.0).clamp(0.0, h - nextH);
        return Rect.fromLTWH(start.left, nextTop, nextW, nextH);

      case _CropDragZone.left:
        if (ar == null) {
          final left = (start.left + delta.dx).clamp(0.0, start.right - minW);
          return Rect.fromLTRB(left, start.top, start.right, start.bottom);
        }
        final maxW = math.min(start.right, h * ar);
        final nextW = (start.width - delta.dx)
            .clamp(math.min(minW, maxW), maxW)
            .toDouble();
        final nextH = nextW / ar;
        final nextTop = (start.center.dy - nextH / 2.0).clamp(0.0, h - nextH);
        return Rect.fromLTWH(start.right - nextW, nextTop, nextW, nextH);

      case _CropDragZone.bottom:
        if (ar == null) {
          final bottom = (start.bottom + delta.dy).clamp(start.top + minH, h);
          return Rect.fromLTRB(start.left, start.top, start.right, bottom);
        }
        final maxH = math.min(h - start.top, w / ar);
        final nextH = (start.height + delta.dy)
            .clamp(math.min(minH, maxH), maxH)
            .toDouble();
        final nextW = nextH * ar;
        final nextLeft = (start.center.dx - nextW / 2.0).clamp(0.0, w - nextW);
        return Rect.fromLTWH(nextLeft, start.top, nextW, nextH);

      case _CropDragZone.top:
        if (ar == null) {
          final top = (start.top + delta.dy).clamp(0.0, start.bottom - minH);
          return Rect.fromLTRB(start.left, top, start.right, start.bottom);
        }
        final maxH = math.min(start.bottom, w / ar);
        final nextH = (start.height - delta.dy)
            .clamp(math.min(minH, maxH), maxH)
            .toDouble();
        final nextW = nextH * ar;
        final nextLeft = (start.center.dx - nextW / 2.0).clamp(0.0, w - nextW);
        return Rect.fromLTWH(nextLeft, start.bottom - nextH, nextW, nextH);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounds = Size(constraints.maxWidth, constraints.maxHeight);
        final pxRect = _toPixelRect(widget.cropRect, bounds);
        final outW = (widget.orientedImageSize.width * widget.cropRect.width)
            .round();
        final outH = (widget.orientedImageSize.height * widget.cropRect.height)
            .round();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            final zone = _hitTest(details.localPosition, pxRect);
            if (zone == _CropDragZone.none) {
              return;
            }
            _activeZone = zone;
            _dragStartPixelRect = pxRect;
            _dragStartLocal = details.localPosition;
            setState(() => _isDragging = true);
            widget.onInteractionStart?.call();
          },
          onPanUpdate: (details) {
            if (_activeZone == _CropDragZone.none) {
              return;
            }
            final delta = details.localPosition - _dragStartLocal;
            final updatedPx = _computeUpdatedPixelRect(delta, bounds);
            widget.onCropChanged(_toNormalizedRect(updatedPx, bounds));
          },
          onPanEnd: (_) {
            if (_activeZone != _CropDragZone.none) {
              _activeZone = _CropDragZone.none;
              setState(() => _isDragging = false);
              widget.onInteractionEnd?.call();
            }
          },
          onPanCancel: () {
            if (_activeZone != _CropDragZone.none) {
              _activeZone = _CropDragZone.none;
              setState(() => _isDragging = false);
              widget.onInteractionEnd?.call();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CustomPaint(
                painter: _CropOverlayPainter(
                  cropRect: pxRect,
                  gridColor: widget.theme.cropGridColor,
                  scrimColor: widget.theme.cropScrimColor,
                  accentColor: widget.theme.accentColor,
                  isDragging: _isDragging,
                ),
              ),
              if (_isDragging)
                Positioned(
                  left: (pxRect.center.dx - 52).clamp(
                    8.0,
                    math.max(8.0, bounds.width - 112),
                  ),
                  top: math.max(8.0, pxRect.top + 10.0),
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: StudioColors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: StudioColors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Text(
                        '$outW × $outH',
                        style: const TextStyle(
                          color: StudioColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter({
    required this.cropRect,
    required this.gridColor,
    required this.scrimColor,
    required this.accentColor,
    required this.isDragging,
  });

  final Rect cropRect;
  final Color gridColor;
  final Color scrimColor;
  final Color accentColor;
  final bool isDragging;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Exterior dimmed scrim using even-odd cutout.
    final scrimPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(cropRect);
    canvas.drawPath(scrimPath, Paint()..color = scrimColor);

    // 2. Rule-of-thirds grid lines.
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: isDragging ? 0.55 : 0.32)
      ..strokeWidth = 0.85
      ..style = PaintingStyle.stroke;

    final thirdW = cropRect.width / 3.0;
    final thirdH = cropRect.height / 3.0;
    for (var i = 1; i <= 2; i++) {
      canvas.drawLine(
        Offset(cropRect.left + thirdW * i, cropRect.top),
        Offset(cropRect.left + thirdW * i, cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + thirdH * i),
        Offset(cropRect.right, cropRect.top + thirdH * i),
        gridPaint,
      );
    }

    // 3. Outer crisp frame border.
    canvas.drawRect(
      cropRect,
      Paint()
        ..color = gridColor.withValues(alpha: 0.9)
        ..strokeWidth = 1.25
        ..style = PaintingStyle.stroke,
    );

    // 4. Bold L-shaped corner brackets.
    final bracketLen = math.min(
      22.0,
      math.min(cropRect.width, cropRect.height) * 0.28,
    );
    final handlePaint = Paint()
      ..color = isDragging ? accentColor : StudioColors.white
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void drawCorner(Offset corner, double dx, double dy) {
      canvas.drawLine(corner, corner + Offset(dx * bracketLen, 0), handlePaint);
      canvas.drawLine(corner, corner + Offset(0, dy * bracketLen), handlePaint);
    }

    drawCorner(cropRect.topLeft, 1, 1);
    drawCorner(cropRect.topRight, -1, 1);
    drawCorner(cropRect.bottomLeft, 1, -1);
    drawCorner(cropRect.bottomRight, -1, -1);

    // 5. Subtle midpoint edge pills.
    final edgeLen = math.min(
      18.0,
      math.min(cropRect.width, cropRect.height) * 0.2,
    );
    final edgePaint = Paint()
      ..color = StudioColors.white.withValues(alpha: 0.92)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cropRect.center.dx - edgeLen / 2, cropRect.top),
      Offset(cropRect.center.dx + edgeLen / 2, cropRect.top),
      edgePaint,
    );
    canvas.drawLine(
      Offset(cropRect.center.dx - edgeLen / 2, cropRect.bottom),
      Offset(cropRect.center.dx + edgeLen / 2, cropRect.bottom),
      edgePaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.center.dy - edgeLen / 2),
      Offset(cropRect.left, cropRect.center.dy + edgeLen / 2),
      edgePaint,
    );
    canvas.drawLine(
      Offset(cropRect.right, cropRect.center.dy - edgeLen / 2),
      Offset(cropRect.right, cropRect.center.dy + edgeLen / 2),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.scrimColor != scrimColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDragging != isDragging;
  }
}

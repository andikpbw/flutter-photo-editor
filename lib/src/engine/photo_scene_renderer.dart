import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/drawing_stroke.dart';
import '../models/overlay_layer.dart';
import '../models/photo_edit_state.dart';
import '../models/photo_transform.dart';
import 'color_matrix.dart';

/// Shared WYSIWYG rendering pipeline used by both the interactive canvas and
/// [PhotoExportEngine] so preview and exported pixels match identically.
abstract final class PhotoSceneRenderer {
  /// Paints the edited [image] with [state] into [outputSize] on [canvas].
  ///
  /// When [showFullUncropped] is `true` (used while inside the Crop tool), the
  /// full oriented image is painted without clipping to [PhotoTransform.cropRect].
  /// When [showOriginal] is `true`, all edits are bypassed for before/after
  /// comparison.
  /// When [activeStroke] is provided, it is painted live on top of committed
  /// strokes.
  static void paint({
    required Canvas canvas,
    required Size outputSize,
    required ui.Image image,
    required PhotoEditState state,
    bool showFullUncropped = false,
    bool showOriginal = false,
    DrawingStroke? activeStroke,
  }) {
    if (outputSize.width <= 0 || outputSize.height <= 0) {
      return;
    }

    final sourceSize = Size(image.width.toDouble(), image.height.toDouble());
    if (showOriginal) {
      canvas.save();
      canvas.clipRect(Offset.zero & outputSize);
      paintImage(
        canvas: canvas,
        rect: Offset.zero & outputSize,
        image: image,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
      canvas.restore();
      return;
    }

    final transform = state.transform;
    final orientedSize = transform.orientedSize(sourceSize);
    final visibleRect = showFullUncropped
        ? PhotoTransform.fullCropRect
        : transform.cropRect;

    final visiblePxX = visibleRect.left * orientedSize.width;
    final visiblePxY = visibleRect.top * orientedSize.height;
    final visiblePxW = math.max(1.0, visibleRect.width * orientedSize.width);
    final visiblePxH = math.max(1.0, visibleRect.height * orientedSize.height);
    final scaleX = outputSize.width / visiblePxW;
    final scaleY = outputSize.height / visiblePxH;

    canvas.save();
    canvas.clipRect(Offset.zero & outputSize);

    // Map oriented-image pixel space into outputSize.
    canvas.save();
    canvas.translate(-visiblePxX * scaleX, -visiblePxY * scaleY);
    canvas.scale(scaleX, scaleY);

    // 1. Base photo with rotation, auto-zoom straighten, flips, filter, adjustments, and blur.
    _paintTransformedPhoto(
      canvas: canvas,
      image: image,
      sourceSize: sourceSize,
      orientedSize: orientedSize,
      state: state,
    );

    canvas.restore();

    // 2. Radial vignette anchored to the visible composition frame.
    if (state.adjustments.vignette > 0.0) {
      _paintVignette(
        canvas: canvas,
        rect: Offset.zero & outputSize,
        strength: state.adjustments.vignette,
      );
    }

    // 3. Markup strokes and overlays in oriented-image coordinate space.
    canvas.save();
    canvas.translate(-visiblePxX * scaleX, -visiblePxY * scaleY);
    canvas.scale(scaleX, scaleY);

    final minDim = math.min(orientedSize.width, orientedSize.height);
    for (final stroke in state.strokes) {
      _paintStroke(canvas, stroke, orientedSize, minDim);
    }
    if (activeStroke != null) {
      _paintStroke(canvas, activeStroke, orientedSize, minDim);
    }

    for (final overlay in state.overlays) {
      paintOverlay(canvas, overlay, orientedSize);
    }

    canvas.restore();
    canvas.restore();
  }

  /// Paints a single [overlay] in oriented-image pixel coordinates of size
  /// [orientedSize].
  static void paintOverlay(
    Canvas canvas,
    PhotoOverlayLayer overlay,
    Size orientedSize,
  ) {
    final center = Offset(
      overlay.position.dx * orientedSize.width,
      overlay.position.dy * orientedSize.height,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(overlay.rotation);
    canvas.scale(overlay.scale);

    switch (overlay) {
      case TextOverlayLayer():
        _paintTextLayer(canvas, overlay, orientedSize);
      case StickerOverlayLayer():
        _paintStickerLayer(canvas, overlay, orientedSize);
    }

    canvas.restore();
  }

  /// Measures the unscaled, unrotated bounding size of [overlay] in
  /// oriented-image pixel coordinates.
  static Size measureOverlaySize(PhotoOverlayLayer overlay, Size orientedSize) {
    final minDim = math.min(orientedSize.width, orientedSize.height);
    switch (overlay) {
      case TextOverlayLayer():
        final painter = _buildTextPainter(overlay, orientedSize);
        final padX = minDim * 0.024;
        final padY = minDim * 0.014;
        return Size(painter.width + padX * 2, painter.height + padY * 2);
      case StickerOverlayLayer():
        final fontSize = (overlay.baseSize * minDim).clamp(12.0, 2000.0);
        final painter = TextPainter(
          text: TextSpan(
            text: overlay.content,
            style: TextStyle(fontSize: fontSize, height: 1.0),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final pad = fontSize * 0.14;
        return Size(painter.width + pad * 2, painter.height + pad * 2);
    }
  }

  static void _paintTransformedPhoto({
    required Canvas canvas,
    required ui.Image image,
    required Size sourceSize,
    required Size orientedSize,
    required PhotoEditState state,
  }) {
    final transform = state.transform;
    final composedMatrix = PhotoColorMatrix.compose(
      filter: state.filter,
      filterIntensity: state.filterIntensity,
      adjustments: state.adjustments,
    );

    final imagePaint = Paint()..filterQuality = FilterQuality.high;
    if (!PhotoColorMatrix.isIdentity(composedMatrix)) {
      imagePaint.colorFilter = ColorFilter.matrix(composedMatrix);
    }
    if (state.adjustments.blur > 0.0) {
      final minSourceDim = math.min(sourceSize.width, sourceSize.height);
      final sigma = state.adjustments.blur * 0.028 * minSourceDim;
      if (sigma > 0.05) {
        imagePaint.imageFilter = ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.clamp,
        );
      }
    }

    canvas.save();
    canvas.translate(orientedSize.width / 2.0, orientedSize.height / 2.0);
    if (transform.rotationAngle != 0.0) {
      final autoScale = transform.straightenAutoScale(orientedSize);
      canvas.rotate(transform.rotationAngle);
      canvas.scale(autoScale, autoScale);
    }
    if (transform.flipHorizontal || transform.flipVertical) {
      canvas.scale(
        transform.flipHorizontal ? -1.0 : 1.0,
        transform.flipVertical ? -1.0 : 1.0,
      );
    }
    if (transform.quarterTurns != 0) {
      canvas.rotate(transform.quarterTurns * math.pi / 2.0);
    }
    canvas.translate(-sourceSize.width / 2.0, -sourceSize.height / 2.0);
    canvas.drawImage(image, Offset.zero, imagePaint);
    canvas.restore();
  }

  static void _paintVignette({
    required Canvas canvas,
    required Rect rect,
    required double strength,
  }) {
    final clamped = strength.clamp(0.0, 1.0);
    final shader = RadialGradient(
      radius: 0.88,
      colors: <Color>[
        Colors.transparent,
        Colors.black.withValues(alpha: clamped * 0.25),
        Colors.black.withValues(alpha: clamped * 0.86),
      ],
      stops: const <double>[0.42, 0.76, 1.0],
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = shader);
  }

  static void _paintStroke(
    Canvas canvas,
    DrawingStroke stroke,
    Size orientedSize,
    double minDim,
  ) {
    if (stroke.points.isEmpty) {
      return;
    }

    final width = math.max(1.0, stroke.strokeWidth * minDim);
    final effectiveAlpha = stroke.tool == BrushTool.highlighter
        ? (stroke.opacity * 0.42).clamp(0.05, 1.0)
        : stroke.opacity;

    final paint = Paint()
      ..color = stroke.color.withValues(alpha: effectiveAlpha)
      ..strokeWidth = stroke.tool == BrushTool.highlighter ? width * 1.9 : width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    Offset toPx(Offset norm) =>
        Offset(norm.dx * orientedSize.width, norm.dy * orientedSize.height);

    switch (stroke.tool) {
      case BrushTool.pen:
      case BrushTool.highlighter:
        if (stroke.points.length == 1) {
          final p = toPx(stroke.points.first);
          canvas.drawCircle(
            p,
            paint.strokeWidth / 2.0,
            Paint()
              ..color = paint.color
              ..style = PaintingStyle.fill
              ..isAntiAlias = true,
          );
          return;
        }
        final path = Path();
        final first = toPx(stroke.points.first);
        path.moveTo(first.dx, first.dy);
        for (var i = 1; i < stroke.points.length - 1; i++) {
          final p0 = toPx(stroke.points[i]);
          final p1 = toPx(stroke.points[i + 1]);
          final mid = Offset((p0.dx + p1.dx) / 2.0, (p0.dy + p1.dy) / 2.0);
          path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
        }
        final last = toPx(stroke.points.last);
        path.lineTo(last.dx, last.dy);
        canvas.drawPath(path, paint);

      case BrushTool.arrow:
        final start = toPx(stroke.points.first);
        final end = toPx(stroke.points.last);
        canvas.drawLine(start, end, paint);
        final delta = end - start;
        final length = delta.distance;
        if (length > 1.0) {
          final angle = math.atan2(delta.dy, delta.dx);
          final headLength = math.min(
            length * 0.45,
            math.max(width * 3.2, 12.0),
          );
          const spread = 0.48;
          final wing1 = Offset(
            end.dx - headLength * math.cos(angle - spread),
            end.dy - headLength * math.sin(angle - spread),
          );
          final wing2 = Offset(
            end.dx - headLength * math.cos(angle + spread),
            end.dy - headLength * math.sin(angle + spread),
          );
          final arrowPath = Path()
            ..moveTo(wing1.dx, wing1.dy)
            ..lineTo(end.dx, end.dy)
            ..lineTo(wing2.dx, wing2.dy);
          canvas.drawPath(arrowPath, paint);
        }

      case BrushTool.rectangle:
        final start = toPx(stroke.points.first);
        final end = toPx(stroke.points.last);
        final rect = Rect.fromPoints(start, end);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(width * 0.4)),
          paint,
        );

      case BrushTool.oval:
        final start = toPx(stroke.points.first);
        final end = toPx(stroke.points.last);
        canvas.drawOval(Rect.fromPoints(start, end), paint);
    }
  }

  static TextPainter _buildTextPainter(
    TextOverlayLayer layer,
    Size orientedSize,
  ) {
    final minDim = math.min(orientedSize.width, orientedSize.height);
    final fontSize = (layer.fontSize * minDim).clamp(10.0, 1200.0);
    final shadows = layer.backgroundStyle == TextBackgroundStyle.none
        ? <Shadow>[
            Shadow(
              color: Colors.black.withValues(alpha: 0.72),
              blurRadius: fontSize * 0.16,
              offset: Offset(0, fontSize * 0.05),
            ),
          ]
        : null;

    final painter = TextPainter(
      text: TextSpan(
        text: layer.text.isEmpty ? ' ' : layer.text,
        style: TextStyle(
          color: layer.color,
          fontSize: fontSize,
          fontWeight: layer.fontWeight,
          fontStyle: layer.fontStyle,
          fontFamily: layer.fontFamily,
          height: 1.2,
          shadows: shadows,
        ),
      ),
      textAlign: layer.textAlign,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: orientedSize.width * 0.88);
    return painter;
  }

  static void _paintTextLayer(
    Canvas canvas,
    TextOverlayLayer layer,
    Size orientedSize,
  ) {
    final minDim = math.min(orientedSize.width, orientedSize.height);
    final painter = _buildTextPainter(layer, orientedSize);
    final padX = minDim * 0.024;
    final padY = minDim * 0.014;
    final bgRect = Rect.fromCenter(
      center: Offset.zero,
      width: painter.width + padX * 2,
      height: painter.height + padY * 2,
    );
    final radius = Radius.circular(minDim * 0.02);

    switch (layer.backgroundStyle) {
      case TextBackgroundStyle.none:
        break;
      case TextBackgroundStyle.solid:
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, radius),
          Paint()..color = layer.backgroundColor.withValues(alpha: 1.0),
        );
      case TextBackgroundStyle.translucent:
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, radius),
          Paint()..color = layer.backgroundColor.withValues(alpha: 0.68),
        );
      case TextBackgroundStyle.outline:
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, radius),
          Paint()..color = layer.backgroundColor.withValues(alpha: 0.25),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bgRect, radius),
          Paint()
            ..color = layer.color.withValues(alpha: 0.92)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.5, minDim * 0.005),
        );
    }

    painter.paint(canvas, Offset(-painter.width / 2.0, -painter.height / 2.0));
  }

  static void _paintStickerLayer(
    Canvas canvas,
    StickerOverlayLayer layer,
    Size orientedSize,
  ) {
    final minDim = math.min(orientedSize.width, orientedSize.height);
    final fontSize = (layer.baseSize * minDim).clamp(12.0, 2000.0);
    final painter = TextPainter(
      text: TextSpan(
        text: layer.content,
        style: TextStyle(fontSize: fontSize, height: 1.0),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(-painter.width / 2.0, -painter.height / 2.0));
  }
}

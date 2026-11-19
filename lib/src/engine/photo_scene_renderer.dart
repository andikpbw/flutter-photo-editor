import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../models/drawing_stroke.dart';
import '../models/overlay_layer.dart';
import '../models/photo_edit_state.dart';
import '../models/photo_frame.dart';
import '../models/photo_transform.dart';
import '../widgets/controls/studio_primitives.dart';
import 'color_matrix.dart';

/// Shared WYSIWYG rendering pipeline used by both the interactive canvas and
/// [PhotoExportEngine] so preview and exported pixels match identically.
abstract final class PhotoSceneRenderer {
  /// Paints the edited [image] with [state] into [outputSize] on [canvas].
  ///
  /// When [showFullUncropped] is `true` (used while inside the Crop tool), the
  /// full oriented image is painted without clipping to [PhotoTransform.cropRect]
  /// or framing borders.
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

    final frame = showFullUncropped ? PhotoFrame.none : state.frame;
    final outerRect = Offset.zero & outputSize;
    final contentRect = computeFramedContentRect(outputSize, frame);
    final cornerRadiusPx = computeCornerRadiusPx(contentRect, frame);

    canvas.save();
    canvas.clipRect(outerRect);

    // 0. Studio frame / mat backdrop fill (when frame or rounded card is active).
    if (!frame.isNone) {
      canvas.drawRect(outerRect, Paint()..color = frame.color);
    }

    // Clip the inner photo scene to contentRect (with optional rounded corners).
    canvas.save();
    if (cornerRadiusPx > 0.5) {
      canvas.clipRRect(
        RRect.fromRectAndRadius(contentRect, Radius.circular(cornerRadiusPx)),
      );
    } else {
      canvas.clipRect(contentRect);
    }
    canvas.translate(contentRect.left, contentRect.top);

    _paintSceneContent(
      canvas: canvas,
      contentSize: contentRect.size,
      image: image,
      state: state,
      showFullUncropped: showFullUncropped,
      activeStroke: activeStroke,
    );

    canvas.restore();

    // Optional subtle museum-mat inner hairline bezel for Gallery & Polaroid.
    if (frame.style == PhotoFrameStyle.gallery ||
        frame.style == PhotoFrameStyle.polaroid) {
      final isDarkFrame = frame.color.computeLuminance() < 0.4;
      final bevelPaint = Paint()
        ..color = (isDarkFrame ? StudioColors.white : StudioColors.black)
            .withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, outputSize.shortestSide * 0.002);
      if (cornerRadiusPx > 0.5) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(contentRect, Radius.circular(cornerRadiusPx)),
          bevelPaint,
        );
      } else {
        canvas.drawRect(contentRect, bevelPaint);
      }
    }

    canvas.restore();
  }

  /// Paints an interactive side-by-side split-screen comparison where the left
  /// side (`0..splitPosition`) shows the unmodified original image and the
  /// right side (`splitPosition..1`) shows the fully edited photo.
  static void paintSplitComparison({
    required Canvas canvas,
    required Size outputSize,
    required ui.Image image,
    required PhotoEditState state,
    required double splitPosition,
    DrawingStroke? activeStroke,
  }) {
    final splitX = (outputSize.width * splitPosition.clamp(0.0, 1.0));

    // Left: Before (original ungraded photo aligned to frame).
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, splitX, outputSize.height));
    paint(
      canvas: canvas,
      outputSize: outputSize,
      image: image,
      state: PhotoEditState(transform: state.transform, frame: state.frame),
    );
    canvas.restore();

    // Right: After (complete edited scene).
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(splitX, 0, outputSize.width - splitX, outputSize.height),
    );
    paint(
      canvas: canvas,
      outputSize: outputSize,
      image: image,
      state: state,
      activeStroke: activeStroke,
    );
    canvas.restore();
  }

  /// Computes the inner photo rectangle inside [outputSize] after applying
  /// [frame] insets.
  static Rect computeFramedContentRect(Size outputSize, PhotoFrame frame) {
    final minSide = outputSize.shortestSide;
    switch (frame.style) {
      case PhotoFrameStyle.none:
        return Offset.zero & outputSize;
      case PhotoFrameStyle.minimal:
        final inset = minSide * (0.015 + frame.thickness * 0.045);
        return Rect.fromLTRB(
          inset,
          inset,
          math.max(inset + 1, outputSize.width - inset),
          math.max(inset + 1, outputSize.height - inset),
        );
      case PhotoFrameStyle.gallery:
        final inset = minSide * (0.04 + frame.thickness * 0.09);
        return Rect.fromLTRB(
          inset,
          inset,
          math.max(inset + 1, outputSize.width - inset),
          math.max(inset + 1, outputSize.height - inset),
        );
      case PhotoFrameStyle.polaroid:
        final side = minSide * (0.035 + frame.thickness * 0.045);
        final bottom = side * 3.1;
        return Rect.fromLTRB(
          side,
          side,
          math.max(side + 1, outputSize.width - side),
          math.max(side + 1, outputSize.height - bottom),
        );
      case PhotoFrameStyle.cinema:
        final bar = outputSize.height * (0.04 + frame.thickness * 0.095);
        return Rect.fromLTRB(
          0,
          bar,
          outputSize.width,
          math.max(bar + 1, outputSize.height - bar),
        );
      case PhotoFrameStyle.rounded:
        final inset = minSide * (0.025 + frame.thickness * 0.055);
        return Rect.fromLTRB(
          inset,
          inset,
          math.max(inset + 1, outputSize.width - inset),
          math.max(inset + 1, outputSize.height - inset),
        );
    }
  }

  /// Computes the inner photo corner radius in pixels for [contentRect] and
  /// [frame].
  static double computeCornerRadiusPx(Rect contentRect, PhotoFrame frame) {
    final base = frame.style == PhotoFrameStyle.rounded
        ? math.max(0.28, frame.cornerRadius)
        : frame.cornerRadius;
    if (base <= 0.0) {
      return 0.0;
    }
    return contentRect.shortestSide * 0.16 * base;
  }

  static void _paintSceneContent({
    required Canvas canvas,
    required Size contentSize,
    required ui.Image image,
    required PhotoEditState state,
    required bool showFullUncropped,
    DrawingStroke? activeStroke,
  }) {
    final sourceSize = Size(image.width.toDouble(), image.height.toDouble());
    final transform = state.transform;
    final orientedSize = transform.orientedSize(sourceSize);
    final visibleRect = showFullUncropped
        ? PhotoTransform.fullCropRect
        : transform.cropRect;

    final visiblePxX = visibleRect.left * orientedSize.width;
    final visiblePxY = visibleRect.top * orientedSize.height;
    final visiblePxW = math.max(1.0, visibleRect.width * orientedSize.width);
    final visiblePxH = math.max(1.0, visibleRect.height * orientedSize.height);
    final scaleX = contentSize.width / visiblePxW;
    final scaleY = contentSize.height / visiblePxH;

    // 1. Base photo with rotation, auto-zoom straighten, flips, filter,
    // adjustments, shadows/highlights passes, and blur.
    canvas.save();
    canvas.translate(-visiblePxX * scaleX, -visiblePxY * scaleY);
    canvas.scale(scaleX, scaleY);

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
        rect: Offset.zero & contentSize,
        strength: state.adjustments.vignette,
      );
    }

    // 3. Organic analog film grain texture pass.
    if (state.adjustments.grain > 0.0) {
      _paintFilmGrain(
        canvas: canvas,
        size: contentSize,
        strength: state.adjustments.grain,
      );
    }

    // 4. Markup strokes (including non-destructive privacy blur) and overlays.
    canvas.save();
    canvas.translate(-visiblePxX * scaleX, -visiblePxY * scaleY);
    canvas.scale(scaleX, scaleY);

    final minDim = math.min(orientedSize.width, orientedSize.height);
    for (final stroke in state.strokes) {
      _paintStroke(
        canvas: canvas,
        stroke: stroke,
        image: image,
        sourceSize: sourceSize,
        orientedSize: orientedSize,
        state: state,
        minDim: minDim,
      );
    }
    if (activeStroke != null) {
      _paintStroke(
        canvas: canvas,
        stroke: activeStroke,
        image: image,
        sourceSize: sourceSize,
        orientedSize: orientedSize,
        state: state,
        minDim: minDim,
      );
    }

    for (final overlay in state.overlays) {
      if (overlay.isVisible) {
        paintOverlay(canvas, overlay, orientedSize);
      }
    }

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

    final needsOpacityLayer = overlay.opacity < 0.999;
    if (needsOpacityLayer) {
      canvas.saveLayer(
        null,
        Paint()..color = StudioColors.white.withValues(alpha: overlay.opacity),
      );
    }

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
    if (needsOpacityLayer) {
      canvas.restore();
    }
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
        if (overlay.isBadge) {
          final painter = _buildBadgePainter(overlay, orientedSize);
          final padX = minDim * 0.028;
          final padY = minDim * 0.014;
          return Size(painter.width + padX * 2, painter.height + padY * 2);
        }
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
    double? overrideBlurSigma,
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
    final sigma =
        overrideBlurSigma ??
        (state.adjustments.blur > 0.0
            ? state.adjustments.blur *
                  0.028 *
                  math.min(sourceSize.width, sourceSize.height)
            : 0.0);
    if (sigma > 0.05) {
      imagePaint.imageFilter = ui.ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.clamp,
      );
    }

    void drawOriented(Paint paint) {
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
      canvas.drawImage(image, Offset.zero, paint);
      canvas.restore();
    }

    drawOriented(imagePaint);

    // Non-linear GPU shadows lift/deepen pass (affects dark regions selectively).
    final shadows = state.adjustments.shadows;
    if (shadows.abs() > 1e-3 && overrideBlurSigma == null) {
      if (shadows > 0) {
        final liftAlpha = (shadows * 0.36).clamp(0.0, 0.42);
        // Inverted-luminance mask adds energy proportionally to darkness (1 - L).
        final shadowLiftMatrix = PhotoColorMatrix.multiply(<double>[
          -liftAlpha,
          0,
          0,
          0,
          255.0 * liftAlpha,
          0,
          -liftAlpha,
          0,
          0,
          255.0 * liftAlpha,
          0,
          0,
          -liftAlpha,
          0,
          255.0 * liftAlpha,
          0,
          0,
          0,
          1,
          0,
        ], composedMatrix);
        drawOriented(
          Paint()
            ..filterQuality = FilterQuality.low
            ..blendMode = BlendMode.plus
            ..colorFilter = ColorFilter.matrix(shadowLiftMatrix),
        );
      } else {
        final darkenStrength = (-shadows * 0.42).clamp(0.0, 0.48);
        drawOriented(
          Paint()
            ..filterQuality = FilterQuality.low
            ..blendMode = BlendMode.multiply
            ..color = StudioColors.white.withValues(alpha: darkenStrength)
            ..colorFilter = PhotoColorMatrix.isIdentity(composedMatrix)
                ? null
                : ColorFilter.matrix(composedMatrix),
        );
      }
    }

    // Non-linear GPU highlights boost/recovery pass (affects bright pixels > 128).
    final highlights = state.adjustments.highlights;
    if (highlights.abs() > 1e-3 && overrideBlurSigma == null) {
      if (highlights > 0) {
        final boost = (highlights * 0.38).clamp(0.0, 0.45);
        final hiMatrix = PhotoColorMatrix.multiply(<double>[
          2.0 * boost,
          0,
          0,
          0,
          -255.0 * boost,
          0,
          2.0 * boost,
          0,
          0,
          -255.0 * boost,
          0,
          0,
          2.0 * boost,
          0,
          -255.0 * boost,
          0,
          0,
          0,
          1,
          0,
        ], composedMatrix);
        drawOriented(
          Paint()
            ..filterQuality = FilterQuality.low
            ..blendMode = BlendMode.plus
            ..colorFilter = ColorFilter.matrix(hiMatrix),
        );
      } else {
        final recover = (-highlights * 0.34).clamp(0.0, 0.4);
        final recoverMatrix = PhotoColorMatrix.multiply(<double>[
          1.0 - recover * 0.55,
          0,
          0,
          0,
          0,
          0,
          1.0 - recover * 0.55,
          0,
          0,
          0,
          0,
          0,
          1.0 - recover * 0.55,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ], composedMatrix);
        drawOriented(
          Paint()
            ..filterQuality = FilterQuality.low
            ..blendMode = BlendMode.darken
            ..colorFilter = ColorFilter.matrix(recoverMatrix),
        );
      }
    }
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
        StudioColors.transparent,
        StudioColors.black.withValues(alpha: clamped * 0.25),
        StudioColors.black.withValues(alpha: clamped * 0.86),
      ],
      stops: const <double>[0.42, 0.76, 1.0],
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = shader);
  }

  static void _paintFilmGrain({
    required Canvas canvas,
    required Size size,
    required double strength,
  }) {
    final clamped = strength.clamp(0.0, 1.0);
    if (clamped <= 0.0) {
      return;
    }
    // Deterministic resolution-scaled silver-halide grain dots.
    const count = 2400;
    final dotSize = math.max(1.0, size.shortestSide * 0.0024);
    final lightPts = <Offset>[];
    final darkPts = <Offset>[];

    var seed = 0x5DEECE66;
    double nextRand() {
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
      return seed / 0x7FFFFFFF;
    }

    for (var i = 0; i < count; i++) {
      final pt = Offset(nextRand() * size.width, nextRand() * size.height);
      if (i.isEven) {
        lightPts.add(pt);
      } else {
        darkPts.add(pt);
      }
    }

    canvas.drawPoints(
      ui.PointMode.points,
      lightPts,
      Paint()
        ..color = StudioColors.white.withValues(alpha: clamped * 0.16)
        ..strokeWidth = dotSize
        ..strokeCap = StrokeCap.square,
    );
    canvas.drawPoints(
      ui.PointMode.points,
      darkPts,
      Paint()
        ..color = StudioColors.black.withValues(alpha: clamped * 0.18)
        ..strokeWidth = dotSize
        ..strokeCap = StrokeCap.square,
    );
  }

  static void _paintStroke({
    required Canvas canvas,
    required DrawingStroke stroke,
    required ui.Image image,
    required Size sourceSize,
    required Size orientedSize,
    required PhotoEditState state,
    required double minDim,
  }) {
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

      case BrushTool.line:
        final start = toPx(stroke.points.first);
        final end = toPx(stroke.points.last);
        canvas.drawLine(start, end, paint);

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

      case BrushTool.filledRectangle:
        final start = toPx(stroke.points.first);
        final end = toPx(stroke.points.last);
        final rect = Rect.fromPoints(start, end);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(width * 0.4)),
          Paint()
            ..color = stroke.color.withValues(alpha: stroke.opacity)
            ..style = PaintingStyle.fill
            ..isAntiAlias = true,
        );

      case BrushTool.oval:
        final start = toPx(stroke.points.first);
        final end = toPx(stroke.points.last);
        canvas.drawOval(Rect.fromPoints(start, end), paint);

      case BrushTool.blurRect:
        final start = toPx(stroke.points.first);
        final end = toPx(stroke.points.last);
        final rect = Rect.fromPoints(start, end);
        if (rect.width < 2 || rect.height < 2) {
          return;
        }
        final radius = Radius.circular(
          math.min(rect.shortestSide * 0.16, 18.0),
        );
        final rrect = RRect.fromRectAndRadius(rect, radius);
        canvas.save();
        canvas.clipRRect(rrect);
        _paintTransformedPhoto(
          canvas: canvas,
          image: image,
          sourceSize: sourceSize,
          orientedSize: orientedSize,
          state: state,
          overrideBlurSigma: math.max(
            12.0,
            math.min(sourceSize.width, sourceSize.height) * 0.032,
          ),
        );
        canvas.drawRRect(
          rrect,
          Paint()..color = StudioColors.white.withValues(alpha: 0.08),
        );
        canvas.restore();
    }
  }

  static TextPainter _buildTextPainter(
    TextOverlayLayer layer,
    Size orientedSize,
  ) {
    final minDim = math.min(orientedSize.width, orientedSize.height);
    final fontSize = (layer.fontSize * minDim).clamp(10.0, 1200.0);
    final shadows =
        layer.hasShadow && layer.backgroundStyle == TextBackgroundStyle.none
        ? <Shadow>[
            Shadow(
              color: StudioColors.black.withValues(alpha: 0.72),
              blurRadius: fontSize * 0.18,
              offset: Offset(0, fontSize * 0.06),
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
          letterSpacing: layer.letterSpacing * (fontSize / 32.0),
          height: layer.lineHeight,
          shadows: shadows,
        ),
      ),
      textAlign: layer.textAlign,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: orientedSize.width * 0.88);
    return painter;
  }

  static TextPainter _buildBadgePainter(
    StickerOverlayLayer layer,
    Size orientedSize,
  ) {
    final minDim = math.min(orientedSize.width, orientedSize.height);
    final fontSize = (layer.baseSize * minDim * 0.42).clamp(11.0, 600.0);
    return TextPainter(
      text: TextSpan(
        text: layer.content,
        style: TextStyle(
          color: StudioColors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          fontFamily: layer.fontFamily,
          letterSpacing: fontSize * 0.08,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
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
    if (layer.isBadge) {
      final painter = _buildBadgePainter(layer, orientedSize);
      final padX = minDim * 0.028;
      final padY = minDim * 0.014;
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: painter.width + padX * 2,
        height: painter.height + padY * 2,
      );
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(rect.height / 2.0),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              layer.badgeColor,
              Color.lerp(layer.badgeColor, StudioColors.black, 0.25)!,
            ],
          ).createShader(rect),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = StudioColors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, minDim * 0.003),
      );
      painter.paint(
        canvas,
        Offset(-painter.width / 2.0, -painter.height / 2.0),
      );
      return;
    }

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

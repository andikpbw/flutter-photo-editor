import 'package:flutter/widgets.dart';

import '../../engine/histogram_calculator.dart';
import '../../models/photo_editor_theme.dart';
import 'studio_primitives.dart';

/// Live Lightroom-style RGB & luminance histogram visualization widget.
class PhotoHistogramView extends StatelessWidget {
  /// Creates a [PhotoHistogramView].
  const PhotoHistogramView({
    super.key,
    required this.data,
    required this.theme,
    this.height = 68.0,
    this.label,
  });

  /// Precomputed per-channel tonal histogram buckets.
  final PhotoHistogramData data;

  /// Visual theme tokens.
  final PhotoEditorTheme theme;

  /// Chart height in logical pixels.
  final double height;

  /// Optional subtle corner caption.
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.elevatedSurfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(
            painter: _HistogramPainter(
              data: data,
              gridColor: theme.borderColor.withValues(alpha: 0.7),
              isDark: theme.brightness == Brightness.dark,
            ),
          ),
          if (label != null)
            Positioned(
              left: 8,
              top: 5,
              child: Text(
                label!,
                style: TextStyle(
                  color: theme.secondaryTextColor.withValues(alpha: 0.8),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  const _HistogramPainter({
    required this.data,
    required this.gridColor,
    required this.isDark,
  });

  final PhotoHistogramData data;
  final Color gridColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || data.binCount < 2) {
      return;
    }

    // Subtle quarter-tone vertical gridlines.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.7;
    for (var i = 1; i <= 3; i++) {
      final x = size.width * (i / 4.0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    _drawChannel(
      canvas,
      size,
      data.red,
      const Color(0xFFFF4D6A).withValues(alpha: 0.34),
      const Color(0xFFFF5E7E).withValues(alpha: 0.78),
    );
    _drawChannel(
      canvas,
      size,
      data.green,
      const Color(0xFF34D399).withValues(alpha: 0.30),
      const Color(0xFF34D399).withValues(alpha: 0.75),
    );
    _drawChannel(
      canvas,
      size,
      data.blue,
      const Color(0xFF4F8BFF).withValues(alpha: 0.34),
      const Color(0xFF60A5FA).withValues(alpha: 0.82),
    );
    _drawChannel(
      canvas,
      size,
      data.luminance,
      (isDark ? StudioColors.white : StudioColors.black).withValues(
        alpha: 0.14,
      ),
      (isDark ? StudioColors.white : StudioColors.black).withValues(
        alpha: 0.55,
      ),
    );
  }

  void _drawChannel(
    Canvas canvas,
    Size size,
    List<double> bins,
    Color fillColor,
    Color strokeColor,
  ) {
    final n = bins.length;
    final stepX = size.width / (n - 1);
    const padTop = 10.0;
    final usableH = size.height - padTop;

    final fillPath = Path()..moveTo(0, size.height);
    final linePath = Path();

    for (var i = 0; i < n; i++) {
      final x = i * stepX;
      final y = size.height - (bins[i].clamp(0.0, 1.0) * usableH);
      if (i == 0) {
        fillPath.lineTo(x, y);
        linePath.moveTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - (bins[i - 1].clamp(0.0, 1.0) * usableH);
        final midX = (prevX + x) / 2.0;
        fillPath.cubicTo(midX, prevY, midX, y, x, y);
        linePath.cubicTo(midX, prevY, midX, y, x, y);
      }
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = strokeColor
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_HistogramPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.isDark != isDark;
  }
}

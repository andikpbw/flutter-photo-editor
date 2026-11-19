import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Core color constants avoiding any Material package dependency.
abstract final class StudioColors {
  /// Pure opaque white (`#FFFFFFFF`).
  static const Color white = Color(0xFFFFFFFF);

  /// Pure opaque black (`#FF000000`).
  static const Color black = Color(0xFF000000);

  /// Fully transparent color (`#00000000`).
  static const Color transparent = Color(0x00000000);
}

/// Verified MaterialIcons codepoints accessible from pure `flutter/widgets.dart`
/// without importing deprecated `flutter/material.dart`.
abstract final class StudioIcons {
  /// Add icon.
  static const IconData add = IconData(0xf537, fontFamily: 'MaterialIcons');

  /// Downward arrow icon.
  static const IconData arrowDownward = IconData(
    0xf575,
    fontFamily: 'MaterialIcons',
  );

  /// Upward arrow icon.
  static const IconData arrowUpward = IconData(
    0xf57e,
    fontFamily: 'MaterialIcons',
  );

  /// Clarity sparkle icon.
  static const IconData autoAwesome = IconData(
    0xeea9,
    fontFamily: 'MaterialIcons',
  );

  /// Filters wand icon.
  static const IconData autoFixHigh = IconData(
    0xf598,
    fontFamily: 'MaterialIcons',
  );

  /// Block / none icon.
  static const IconData block = IconData(0xf5be, fontFamily: 'MaterialIcons');

  /// Privacy blur region icon.
  static const IconData blurCircular = IconData(
    0xf5c6,
    fontFamily: 'MaterialIcons',
  );

  /// Blur adjustment icon.
  static const IconData blurOn = IconData(0xf5c9, fontFamily: 'MaterialIcons');

  /// Border thickness icon.
  static const IconData borderOuter = IconData(
    0xf5da,
    fontFamily: 'MaterialIcons',
  );

  /// Shadows crescent icon.
  static const IconData brightness2 = IconData(
    0xeef5,
    fontFamily: 'MaterialIcons',
  );

  /// Highlights sun icon.
  static const IconData brightnessHigh = IconData(
    0xf5e9,
    fontFamily: 'MaterialIcons',
  );

  /// Broken image fallback icon.
  static const IconData brokenImage = IconData(
    0xeeff,
    fontFamily: 'MaterialIcons',
  );

  /// Highlighter brush icon.
  static const IconData brush = IconData(0xf5ef, fontFamily: 'MaterialIcons');

  /// Checkmark icon.
  static const IconData check = IconData(0xf636, fontFamily: 'MaterialIcons');

  /// Oval outline icon.
  static const IconData circleOutlined = IconData(
    0xef53,
    fontFamily: 'MaterialIcons',
  );

  /// Close icon.
  static const IconData close = IconData(0xe16a, fontFamily: 'MaterialIcons');

  /// Rounded close icon.
  static const IconData closeRounded = IconData(
    0xf647,
    fontFamily: 'MaterialIcons',
  );

  /// Vibrance color lens icon.
  static const IconData colorLens = IconData(
    0xef6b,
    fontFamily: 'MaterialIcons',
  );

  /// Split compare handle icon.
  static const IconData compareArrows = IconData(
    0xf65d,
    fontFamily: 'MaterialIcons',
  );

  /// Compare toggle icon.
  static const IconData compare = IconData(0xf65e, fontFamily: 'MaterialIcons');

  /// Contrast icon.
  static const IconData contrast = IconData(
    0xf02f1,
    fontFamily: 'MaterialIcons',
  );

  /// Duplicate/copy icon.
  static const IconData copy = IconData(0xf66c, fontFamily: 'MaterialIcons');

  /// Minimal frame icon.
  static const IconData cropDin = IconData(0xf683, fontFamily: 'MaterialIcons');

  /// Crop & rotate tool icon.
  static const IconData cropRotate = IconData(
    0xf688,
    fontFamily: 'MaterialIcons',
  );

  /// Rectangle outline icon.
  static const IconData cropSquare = IconData(
    0xf68a,
    fontFamily: 'MaterialIcons',
  );

  /// Delete icon.
  static const IconData deleteOutline = IconData(
    0xf696,
    fontFamily: 'MaterialIcons',
  );

  /// Draw tool icon.
  static const IconData draw = IconData(0xf030c, fontFamily: 'MaterialIcons');

  /// Edit text outlined icon.
  static const IconData editOutlined = IconData(
    0xf00d,
    fontFamily: 'MaterialIcons',
  );

  /// Pen tool icon.
  static const IconData editRounded = IconData(
    0xf6fb,
    fontFamily: 'MaterialIcons',
  );

  /// Stickers emoji icon.
  static const IconData emojiEmotions = IconData(
    0xf019,
    fontFamily: 'MaterialIcons',
  );

  /// Exposure icon.
  static const IconData exposure = IconData(
    0xf729,
    fontFamily: 'MaterialIcons',
  );

  /// Gallery frames icon.
  static const IconData filterFrames = IconData(
    0xf759,
    fontFamily: 'MaterialIcons',
  );

  /// Flip mirror icon.
  static const IconData flip = IconData(0xf776, fontFamily: 'MaterialIcons');

  /// Center align icon.
  static const IconData formatAlignCenter = IconData(
    0xf785,
    fontFamily: 'MaterialIcons',
  );

  /// Left align icon.
  static const IconData formatAlignLeft = IconData(
    0xf787,
    fontFamily: 'MaterialIcons',
  );

  /// Right align icon.
  static const IconData formatAlignRight = IconData(
    0xf788,
    fontFamily: 'MaterialIcons',
  );

  /// Bold typography icon.
  static const IconData formatBold = IconData(
    0xf789,
    fontFamily: 'MaterialIcons',
  );

  /// Italic typography icon.
  static const IconData formatItalic = IconData(
    0xf790,
    fontFamily: 'MaterialIcons',
  );

  /// Fade gradient icon.
  static const IconData gradient = IconData(
    0xf7ba,
    fontFamily: 'MaterialIcons',
  );

  /// Analog film grain icon.
  static const IconData grain = IconData(0xf7bc, fontFamily: 'MaterialIcons');

  /// Straight line tool icon.
  static const IconData horizontalRule = IconData(
    0xf7f8,
    fontFamily: 'MaterialIcons',
  );

  /// White-balance tint icon.
  static const IconData invertColors = IconData(
    0xf825,
    fontFamily: 'MaterialIcons',
  );

  /// Stroke width icon.
  static const IconData lineWeight = IconData(
    0xf857,
    fontFamily: 'MaterialIcons',
  );

  /// Vector arrow icon.
  static const IconData northEast = IconData(
    0xf0019,
    fontFamily: 'MaterialIcons',
  );

  /// Opacity droplet icon.
  static const IconData opacity = IconData(
    0xf0030,
    fontFamily: 'MaterialIcons',
  );

  /// Scale & rotate handle icon.
  static const IconData openInFull = IconData(
    0xe45b,
    fontFamily: 'MaterialIcons',
  );

  /// Saturation palette icon.
  static const IconData palette = IconData(0xf24f, fontFamily: 'MaterialIcons');

  /// Polaroid frame icon.
  static const IconData photoCameraFront = IconData(
    0xf29a,
    fontFamily: 'MaterialIcons',
  );

  /// Editor studio brand icon.
  static const IconData photoFilter = IconData(
    0xf008e,
    fontFamily: 'MaterialIcons',
  );

  /// Redo icon.
  static const IconData redo = IconData(
    0xf00e7,
    fontFamily: 'MaterialIcons',
    matchTextDirection: true,
  );

  /// Zoom out minus icon.
  static const IconData remove = IconData(0xf00f1, fontFamily: 'MaterialIcons');

  /// Reset all icon.
  static const IconData restartAlt = IconData(
    0xf0106,
    fontFamily: 'MaterialIcons',
  );

  /// Rotate 90° counter-clockwise icon.
  static const IconData rotate90Ccw = IconData(
    0xf0113,
    fontFamily: 'MaterialIcons',
  );

  /// Rotate 90° clockwise icon.
  static const IconData rotate90Cw = IconData(
    0xf0374,
    fontFamily: 'MaterialIcons',
  );

  /// Rotation slider icon.
  static const IconData rotateRight = IconData(
    0xf0115,
    fontFamily: 'MaterialIcons',
  );

  /// Corner radius icon.
  static const IconData roundedCorner = IconData(
    0xf0116,
    fontFamily: 'MaterialIcons',
  );

  /// Letter spacing icon.
  static const IconData spaceBar = IconData(
    0xf01ae,
    fontFamily: 'MaterialIcons',
  );

  /// Filled box icon.
  static const IconData square = IconData(0xf0385, fontFamily: 'MaterialIcons');

  /// Straighten ruler icon.
  static const IconData straighten = IconData(
    0xf01e3,
    fontFamily: 'MaterialIcons',
  );

  /// Cinema letterbox icon.
  static const IconData theaters = IconData(
    0xf022a,
    fontFamily: 'MaterialIcons',
  );

  /// Warmth thermometer icon.
  static const IconData thermostat = IconData(
    0xf022c,
    fontFamily: 'MaterialIcons',
  );

  /// Text tool icon.
  static const IconData title = IconData(0xf023d, fontFamily: 'MaterialIcons');

  /// Adjust sliders tool icon.
  static const IconData tune = IconData(0xf0258, fontFamily: 'MaterialIcons');

  /// Undo icon.
  static const IconData undo = IconData(
    0xf0261,
    fontFamily: 'MaterialIcons',
    matchTextDirection: true,
  );

  /// Vignette icon.
  static const IconData vignette = IconData(
    0xf0290,
    fontFamily: 'MaterialIcons',
  );

  /// Hidden layer eye-off icon.
  static const IconData visibilityOff = IconData(
    0xf4a0,
    fontFamily: 'MaterialIcons',
  );

  /// Visible layer eye icon.
  static const IconData visibility = IconData(
    0xf4a1,
    fontFamily: 'MaterialIcons',
  );

  /// Brightness sun icon.
  static const IconData wbSunny = IconData(0xf4bc, fontFamily: 'MaterialIcons');

  /// Scale arrows icon.
  static const IconData zoomOutMap = IconData(
    0xf02cf,
    fontFamily: 'MaterialIcons',
  );
}

/// Pure-widgets tactile pressable wrapper with desktop pointer cursor and
/// optional semantic tooltip label.
class StudioPressable extends StatefulWidget {
  /// Creates a [StudioPressable].
  const StudioPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.tooltip,
    this.borderRadius,
  });

  /// Child widget rendered inside the pressable target.
  final Widget child;

  /// Tap callback; when `null`, the control is treated as disabled.
  final VoidCallback? onTap;

  /// Optional double-tap callback.
  final VoidCallback? onDoubleTap;

  /// Optional accessible semantic label / tooltip description.
  final String? tooltip;

  /// Optional clip/visual radius.
  final BorderRadius? borderRadius;

  @override
  State<StudioPressable> createState() => _StudioPressableState();
}

class _StudioPressableState extends State<StudioPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onDoubleTap != null;
    Widget content = AnimatedOpacity(
      duration: const Duration(milliseconds: 90),
      opacity: _pressed ? 0.72 : 1.0,
      child: widget.child,
    );

    if (widget.borderRadius != null) {
      content = ClipRRect(borderRadius: widget.borderRadius!, child: content);
    }

    content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: content,
      ),
    );

    if (widget.tooltip != null) {
      content = Semantics(
        label: widget.tooltip,
        tooltip: widget.tooltip,
        button: true,
        enabled: enabled,
        child: content,
      );
    }
    return content;
  }
}

/// Sleek studio action button (filled, outlined, or text) built purely on
/// `flutter/widgets.dart`.
class StudioButton extends StatelessWidget {
  /// Creates a [StudioButton].
  const StudioButton({
    super.key,
    required this.label,
    required this.foregroundColor,
    required this.onPressed,
    this.backgroundColor,
    this.borderColor,
    this.icon,
    this.iconSize = 17,
    this.leading,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    this.borderRadius = 10.0,
    this.fontSize = 13.0,
    this.fontWeight = FontWeight.w600,
    this.expand = false,
  });

  /// Button text label.
  final String label;

  /// Text and icon color.
  final Color foregroundColor;

  /// Optional filled background color.
  final Color? backgroundColor;

  /// Optional outline border color.
  final Color? borderColor;

  /// Optional leading icon glyph.
  final IconData? icon;

  /// Leading icon size.
  final double iconSize;

  /// Optional custom leading widget (overrides [icon]).
  final Widget? leading;

  /// Internal padding.
  final EdgeInsetsGeometry padding;

  /// Corner radius in logical pixels.
  final double borderRadius;

  /// Label font size.
  final double fontSize;

  /// Label font weight.
  final FontWeight fontWeight;

  /// Whether the button stretches to fill horizontal width.
  final bool expand;

  /// Tap callback; `null` disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final effectiveFg = enabled
        ? foregroundColor
        : foregroundColor.withValues(alpha: 0.45);
    final effectiveBg = backgroundColor == null
        ? null
        : enabled
        ? backgroundColor
        : backgroundColor!.withValues(alpha: 0.45);

    return StudioPressable(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: expand ? double.infinity : null,
        padding: padding,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(borderRadius),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading!,
              const SizedBox(width: 7),
            ] else if (icon != null) ...<Widget>[
              Icon(icon, size: iconSize, color: effectiveFg),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: effectiveFg,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Precision darkroom slider built purely on `flutter/widgets.dart` with smooth
/// drag & tap-to-seek and center-anchored active fill for bipolar controls.
class StudioSlider extends StatefulWidget {
  /// Creates a [StudioSlider].
  const StudioSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.activeColor,
    required this.inactiveColor,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  });

  /// Current numeric value.
  final double value;

  /// Minimum bound.
  final double min;

  /// Maximum bound.
  final double max;

  /// Active track accent color.
  final Color activeColor;

  /// Inactive track background color.
  final Color inactiveColor;

  /// Called continuously during drag or tap.
  final ValueChanged<double> onChanged;

  /// Called when dragging or tap-to-seek begins.
  final ValueChanged<double>? onChangeStart;

  /// Called when dragging or tap-to-seek ends.
  final ValueChanged<double>? onChangeEnd;

  @override
  State<StudioSlider> createState() => _StudioSliderState();
}

class _StudioSliderState extends State<StudioSlider> {
  bool _isDragging = false;
  double _lastDragValue = 0.0;

  double _valueFromDx(double dx, double width) {
    const pad = 8.0;
    final usable = math.max(1.0, width - pad * 2);
    final t = ((dx - pad) / usable).clamp(0.0, 1.0);
    return widget.min + t * (widget.max - widget.min);
  }

  void _endDrag() {
    if (!_isDragging) {
      return;
    }
    _isDragging = false;
    widget.onChangeEnd?.call(_lastDragValue);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = math.max(24.0, constraints.maxWidth);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            if (_isDragging) {
              return;
            }
            final next = _valueFromDx(d.localPosition.dx, w);
            widget.onChangeStart?.call(widget.value);
            widget.onChanged(next);
            widget.onChangeEnd?.call(next);
          },
          onHorizontalDragStart: (d) {
            _isDragging = true;
            widget.onChangeStart?.call(widget.value);
            final next = _valueFromDx(d.localPosition.dx, w);
            _lastDragValue = next;
            widget.onChanged(next);
          },
          onHorizontalDragUpdate: (d) {
            final next = _valueFromDx(d.localPosition.dx, w);
            _lastDragValue = next;
            widget.onChanged(next);
          },
          onHorizontalDragEnd: (_) => _endDrag(),
          onHorizontalDragCancel: _endDrag,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: CustomPaint(
              size: Size(w, 28),
              painter: _StudioSliderPainter(
                value: widget.value.clamp(widget.min, widget.max),
                min: widget.min,
                max: widget.max,
                activeColor: widget.activeColor,
                inactiveColor: widget.inactiveColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StudioSliderPainter extends CustomPainter {
  const _StudioSliderPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double value;
  final double min;
  final double max;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 8.0;
    const trackH = 3.2;
    const thumbR = 7.0;
    final cy = size.height / 2.0;
    const left = pad;
    final right = math.max(left + 1.0, size.width - pad);
    final span = right - left;
    final range = math.max(1e-6, max - min);
    final t = ((value - min) / range).clamp(0.0, 1.0);
    final thumbX = left + t * span;

    // Inactive full track.
    final trackRect = RRect.fromLTRBR(
      left,
      cy - trackH / 2,
      right,
      cy + trackH / 2,
      const Radius.circular(trackH / 2),
    );
    canvas.drawRRect(trackRect, Paint()..color = inactiveColor);

    // Active highlight segment (anchored at zero for bipolar ranges).
    final isBipolar = min < 0 && max > 0;
    final anchorT = isBipolar ? ((0.0 - min) / range).clamp(0.0, 1.0) : 0.0;
    final anchorX = left + anchorT * span;
    final segLeft = math.min(anchorX, thumbX);
    final segRight = math.max(anchorX, thumbX);
    if (segRight - segLeft > 0.5) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          segLeft,
          cy - trackH / 2,
          segRight,
          cy + trackH / 2,
          const Radius.circular(trackH / 2),
        ),
        Paint()..color = activeColor,
      );
    }

    // Subtle zero center notch for bipolar sliders.
    if (isBipolar) {
      canvas.drawCircle(
        Offset(anchorX, cy),
        2.2,
        Paint()..color = activeColor.withValues(alpha: 0.55),
      );
    }

    // Subtle thumb drop shadow + crisp white circular thumb.
    canvas.drawCircle(
      Offset(thumbX, cy + 1.0),
      thumbR + 0.5,
      Paint()..color = StudioColors.black.withValues(alpha: 0.32),
    );
    canvas.drawCircle(
      Offset(thumbX, cy),
      thumbR,
      Paint()..color = StudioColors.white,
    );
    canvas.drawCircle(
      Offset(thumbX, cy),
      thumbR,
      Paint()
        ..color = activeColor.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_StudioSliderPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}

/// Smooth pure-widgets spinning arc indicator replacing `CircularProgressIndicator`.
class StudioSpinner extends StatefulWidget {
  /// Creates a [StudioSpinner].
  const StudioSpinner({
    super.key,
    required this.color,
    this.size = 24.0,
    this.strokeWidth = 2.4,
  });

  /// Arc stroke color.
  final Color color;

  /// Diameter in logical pixels.
  final double size;

  /// Arc thickness.
  final double strokeWidth;

  @override
  State<StudioSpinner> createState() => _StudioSpinnerState();
}

class _StudioSpinnerState extends State<StudioSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          return CustomPaint(
            painter: _SpinnerPainter(
              progress: _anim.value,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    canvas.drawArc(
      rect,
      progress * math.pi * 2,
      math.pi * 1.35,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

import 'package:flutter/material.dart';

/// Visual styling tokens for the `photo_editor_studio` UI.
@immutable
class PhotoEditorTheme {
  /// Creates a custom [PhotoEditorTheme].
  const PhotoEditorTheme({
    required this.brightness,
    required this.canvasBackground,
    required this.surfaceColor,
    required this.elevatedSurfaceColor,
    required this.borderColor,
    required this.accentColor,
    required this.onAccentColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.dangerColor,
    required this.cropGridColor,
    required this.cropScrimColor,
    this.panelBorderRadius = 14.0,
    this.desktopInspectorWidth = 316.0,
  });

  /// Modern darkroom studio theme optimized for color-accurate photo editing.
  factory PhotoEditorTheme.dark({Color accentColor = const Color(0xFF4F8BFF)}) {
    return PhotoEditorTheme(
      brightness: Brightness.dark,
      canvasBackground: const Color(0xFF0B0D12),
      surfaceColor: const Color(0xFF13161E),
      elevatedSurfaceColor: const Color(0xFF1C202B),
      borderColor: const Color(0xFF282E3D),
      accentColor: accentColor,
      onAccentColor: Colors.white,
      primaryTextColor: const Color(0xFFF3F6FC),
      secondaryTextColor: const Color(0xFF949EB2),
      dangerColor: const Color(0xFFFF5C6C),
      cropGridColor: const Color(0xCCFFFFFF),
      cropScrimColor: const Color(0xA607080B),
    );
  }

  /// Crisp light studio theme suitable for light-mode applications.
  factory PhotoEditorTheme.light({
    Color accentColor = const Color(0xFF2563EB),
  }) {
    return PhotoEditorTheme(
      brightness: Brightness.light,
      canvasBackground: const Color(0xFFE9EDF4),
      surfaceColor: const Color(0xFFFFFFFF),
      elevatedSurfaceColor: const Color(0xFFF3F5F9),
      borderColor: const Color(0xFFDDE3EE),
      accentColor: accentColor,
      onAccentColor: Colors.white,
      primaryTextColor: const Color(0xFF111827),
      secondaryTextColor: const Color(0xFF64748B),
      dangerColor: const Color(0xFFDC2626),
      cropGridColor: const Color(0xE6FFFFFF),
      cropScrimColor: const Color(0x8A0F172A),
    );
  }

  /// Overall UI brightness.
  final Brightness brightness;

  /// Background behind the photo canvas.
  final Color canvasBackground;

  /// Primary surface color for toolbars, rails, and sidebars.
  final Color surfaceColor;

  /// Secondary surface color for chips, cards, and active pill buttons.
  final Color elevatedSurfaceColor;

  /// Hairline divider and panel border color.
  final Color borderColor;

  /// Primary interactive accent color for selected tools, sliders, and CTAs.
  final Color accentColor;

  /// Foreground text/icon color displayed on top of [accentColor].
  final Color onAccentColor;

  /// High-emphasis text and icon color.
  final Color primaryTextColor;

  /// Secondary/muted label and inactive icon color.
  final Color secondaryTextColor;

  /// Destructive action color (delete layer / reset warning).
  final Color dangerColor;

  /// Color of crop border lines, handles, and rule-of-thirds grid.
  final Color cropGridColor;

  /// Translucent overlay color dimming areas outside the crop rectangle.
  final Color cropScrimColor;

  /// Standard corner radius for cards and buttons.
  final double panelBorderRadius;

  /// Width of the inspector sidebar in desktop layout mode.
  final double desktopInspectorWidth;

  /// Returns a copy with selectively overridden styling tokens.
  PhotoEditorTheme copyWith({
    Brightness? brightness,
    Color? canvasBackground,
    Color? surfaceColor,
    Color? elevatedSurfaceColor,
    Color? borderColor,
    Color? accentColor,
    Color? onAccentColor,
    Color? primaryTextColor,
    Color? secondaryTextColor,
    Color? dangerColor,
    Color? cropGridColor,
    Color? cropScrimColor,
    double? panelBorderRadius,
    double? desktopInspectorWidth,
  }) {
    return PhotoEditorTheme(
      brightness: brightness ?? this.brightness,
      canvasBackground: canvasBackground ?? this.canvasBackground,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      elevatedSurfaceColor: elevatedSurfaceColor ?? this.elevatedSurfaceColor,
      borderColor: borderColor ?? this.borderColor,
      accentColor: accentColor ?? this.accentColor,
      onAccentColor: onAccentColor ?? this.onAccentColor,
      primaryTextColor: primaryTextColor ?? this.primaryTextColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      dangerColor: dangerColor ?? this.dangerColor,
      cropGridColor: cropGridColor ?? this.cropGridColor,
      cropScrimColor: cropScrimColor ?? this.cropScrimColor,
      panelBorderRadius: panelBorderRadius ?? this.panelBorderRadius,
      desktopInspectorWidth:
          desktopInspectorWidth ?? this.desktopInspectorWidth,
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/photo_editor_theme.dart';

/// Crisp section header with an optional trailing action button.
class StudioSectionHeader extends StatelessWidget {
  /// Creates a [StudioSectionHeader].
  const StudioSectionHeader({
    super.key,
    required this.title,
    required this.theme,
    this.actionLabel,
    this.onAction,
  });

  /// Section title text.
  final String title;

  /// Visual theme tokens.
  final PhotoEditorTheme theme;

  /// Optional trailing action text (for example `Reset`).
  final String? actionLabel;

  /// Callback invoked when the trailing action is tapped.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: theme.secondaryTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: theme.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Precision studio slider with live value badge and double-tap reset.
class StudioSliderRow extends StatelessWidget {
  /// Creates a [StudioSliderRow].
  const StudioSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueText,
    required this.theme,
    required this.onChanged,
    this.icon,
    this.defaultValue = 0.0,
    this.onChangeStart,
    this.onChangeEnd,
    this.onReset,
    this.compact = false,
  });

  /// Slider label text.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Current numeric value.
  final double value;

  /// Minimum slider value.
  final double min;

  /// Maximum slider value.
  final double max;

  /// Neutral default value used to detect active highlights and double-tap reset.
  final double defaultValue;

  /// Formatted live value readout (e.g. `+24`, `85%`, `-3.5°`).
  final String valueText;

  /// Visual theme tokens.
  final PhotoEditorTheme theme;

  /// Called continuously while dragging the slider.
  final ValueChanged<double> onChanged;

  /// Called when dragging begins.
  final ValueChanged<double>? onChangeStart;

  /// Called when dragging completes.
  final ValueChanged<double>? onChangeEnd;

  /// Optional callback invoked on double-tap to reset to [defaultValue].
  final VoidCallback? onReset;

  /// Uses tighter vertical spacing for compact mobile sheets.
  final bool compact;

  bool get _isModified => (value - defaultValue).abs() > 1e-3;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onReset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 15,
                  color: _isModified
                      ? theme.accentColor
                      : theme.secondaryTextColor,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: _isModified
                        ? theme.primaryTextColor
                        : theme.secondaryTextColor,
                    fontSize: 12.5,
                    fontWeight: _isModified ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _isModified ? onReset : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _isModified
                        ? theme.accentColor.withValues(alpha: 0.16)
                        : theme.elevatedSurfaceColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    valueText,
                    style: TextStyle(
                      color: _isModified
                          ? theme.accentColor
                          : theme.secondaryTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: compact ? 28 : 30,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3.0,
                activeTrackColor: theme.accentColor,
                inactiveTrackColor: theme.borderColor,
                thumbColor: Colors.white,
                overlayColor: theme.accentColor.withValues(alpha: 0.18),
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 7.0,
                  elevation: 2,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 15),
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
                onChangeStart: onChangeStart,
                onChangeEnd: onChangeEnd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular color swatch picker supporting horizontal scrolling or wrap layout.
class StudioColorSwatches extends StatelessWidget {
  /// Creates a [StudioColorSwatches] selector.
  const StudioColorSwatches({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.theme,
    required this.onSelected,
    this.wrap = false,
  });

  /// Available color swatches.
  final List<Color> colors;

  /// Currently active color.
  final Color selectedColor;

  /// Visual theme tokens.
  final PhotoEditorTheme theme;

  /// Called when a color swatch is tapped.
  final ValueChanged<Color> onSelected;

  /// When `true`, lays swatches out in a wrapping grid (ideal for desktop).
  final bool wrap;

  Widget _buildSwatch(Color color) {
    final isSelected = color.toARGB32() == selectedColor.toARGB32();
    return GestureDetector(
      onTap: () => onSelected(color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 28,
        height: 28,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? theme.accentColor
                : theme.borderColor.withValues(alpha: 0.8),
            width: isSelected ? 2.2 : 1.0,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.18),
              width: 0.7,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (wrap) {
      return Wrap(
        spacing: 9,
        runSpacing: 9,
        children: colors.map(_buildSwatch).toList(),
      );
    }
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => _buildSwatch(colors[index]),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../controller/photo_editor_controller.dart';
import '../../engine/histogram_calculator.dart';
import '../../models/photo_adjustments.dart';
import '../../models/photo_editor_labels.dart';
import '../../models/photo_editor_theme.dart';
import 'histogram_widget.dart';
import 'studio_widgets.dart';

/// Tonal, color, optical, and texture adjustment controls paired with a live
/// RGB & luminance histogram on desktop viewports.
class AdjustPanel extends StatelessWidget {
  /// Creates an [AdjustPanel].
  const AdjustPanel({
    super.key,
    required this.controller,
    required this.adjustments,
    required this.theme,
    required this.labels,
    required this.isDesktop,
    this.histogramData,
  });

  /// Active editor controller.
  final PhotoEditorController controller;

  /// Enabled adjustment parameter types.
  final List<PhotoAdjustmentType> adjustments;

  /// Visual theme tokens.
  final PhotoEditorTheme theme;

  /// Localizable strings.
  final PhotoEditorLabels labels;

  /// Whether rendering in the vertical desktop inspector sidebar.
  final bool isDesktop;

  /// Optional live RGB histogram data rendered above desktop sliders.
  final PhotoHistogramData? histogramData;

  static IconData _iconFor(PhotoAdjustmentType type) {
    switch (type) {
      case PhotoAdjustmentType.exposure:
        return Icons.exposure_rounded;
      case PhotoAdjustmentType.brightness:
        return Icons.wb_sunny_outlined;
      case PhotoAdjustmentType.contrast:
        return Icons.contrast_rounded;
      case PhotoAdjustmentType.highlights:
        return Icons.brightness_high_rounded;
      case PhotoAdjustmentType.shadows:
        return Icons.brightness_2_outlined;
      case PhotoAdjustmentType.saturation:
        return Icons.palette_outlined;
      case PhotoAdjustmentType.vibrance:
        return Icons.color_lens_outlined;
      case PhotoAdjustmentType.warmth:
        return Icons.thermostat_rounded;
      case PhotoAdjustmentType.tint:
        return Icons.invert_colors_rounded;
      case PhotoAdjustmentType.clarity:
        return Icons.auto_awesome_outlined;
      case PhotoAdjustmentType.fade:
        return Icons.gradient_rounded;
      case PhotoAdjustmentType.vignette:
        return Icons.vignette_rounded;
      case PhotoAdjustmentType.grain:
        return Icons.grain_rounded;
      case PhotoAdjustmentType.blur:
        return Icons.blur_on_rounded;
    }
  }

  static String _formatValue(PhotoAdjustmentType type, double value) {
    final pct = (value * 100).round();
    if (PhotoAdjustments.minFor(type) < 0 && pct > 0) {
      return '+$pct';
    }
    return '$pct';
  }

  @override
  Widget build(BuildContext context) {
    final current = controller.state.adjustments;

    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: StudioSectionHeader(
              title: labels.adjustTab.toUpperCase(),
              theme: theme,
              actionLabel: !current.isDefault ? labels.resetAll : null,
              onAction: controller.resetAdjustments,
            ),
          ),
          if (histogramData != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: PhotoHistogramView(
                data: histogramData!,
                theme: theme,
                label: labels.histogram.toUpperCase(),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: adjustments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final type = adjustments[index];
                final value = current.valueFor(type);
                return StudioSliderRow(
                  label: labels.adjustmentLabel(type),
                  icon: _iconFor(type),
                  value: value,
                  min: PhotoAdjustments.minFor(type),
                  max: PhotoAdjustments.maxFor(type),
                  valueText: _formatValue(type, value),
                  theme: theme,
                  onChangeStart: (_) => controller.beginInteraction(),
                  onChanged: (v) =>
                      controller.setAdjustment(type, v, recordHistory: false),
                  onChangeEnd: (_) => controller.commitInteraction(),
                  onReset: () => controller.resetAdjustment(type),
                );
              },
            ),
          ),
        ],
      );
    }

    final activeType = adjustments.contains(controller.activeAdjustment)
        ? controller.activeAdjustment
        : adjustments.first;
    final activeValue = current.valueFor(activeType);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
          child: StudioSliderRow(
            label: labels.adjustmentLabel(activeType),
            icon: _iconFor(activeType),
            value: activeValue,
            min: PhotoAdjustments.minFor(activeType),
            max: PhotoAdjustments.maxFor(activeType),
            valueText: _formatValue(activeType, activeValue),
            theme: theme,
            compact: true,
            onChangeStart: (_) => controller.beginInteraction(),
            onChanged: (v) =>
                controller.setAdjustment(activeType, v, recordHistory: false),
            onChangeEnd: (_) => controller.commitInteraction(),
            onReset: () => controller.resetAdjustment(activeType),
          ),
        ),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            itemCount: adjustments.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final type = adjustments[index];
              final selected = type == activeType;
              final modified = current.valueFor(type).abs() > 1e-3;
              return GestureDetector(
                onTap: () => controller.setActiveAdjustment(type),
                onDoubleTap: () => controller.resetAdjustment(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 72,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.accentColor.withValues(alpha: 0.16)
                        : theme.elevatedSurfaceColor,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: selected ? theme.accentColor : theme.borderColor,
                      width: selected ? 1.4 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Icon(
                            _iconFor(type),
                            size: 19,
                            color: selected
                                ? theme.accentColor
                                : theme.primaryTextColor,
                          ),
                          if (modified)
                            Positioned(
                              right: -5,
                              top: -2,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: theme.accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels.adjustmentLabel(type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? theme.accentColor
                              : theme.secondaryTextColor,
                          fontSize: 10.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

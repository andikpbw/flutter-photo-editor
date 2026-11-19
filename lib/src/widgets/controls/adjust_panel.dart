import 'package:flutter/widgets.dart';

import '../../controller/photo_editor_controller.dart';
import '../../engine/histogram_calculator.dart';
import '../../models/photo_adjustments.dart';
import '../../models/photo_editor_labels.dart';
import '../../models/photo_editor_theme.dart';
import 'histogram_widget.dart';
import 'studio_primitives.dart';
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
        return StudioIcons.exposure;
      case PhotoAdjustmentType.brightness:
        return StudioIcons.wbSunny;
      case PhotoAdjustmentType.contrast:
        return StudioIcons.contrast;
      case PhotoAdjustmentType.highlights:
        return StudioIcons.brightnessHigh;
      case PhotoAdjustmentType.shadows:
        return StudioIcons.brightness2;
      case PhotoAdjustmentType.saturation:
        return StudioIcons.palette;
      case PhotoAdjustmentType.vibrance:
        return StudioIcons.colorLens;
      case PhotoAdjustmentType.warmth:
        return StudioIcons.thermostat;
      case PhotoAdjustmentType.tint:
        return StudioIcons.invertColors;
      case PhotoAdjustmentType.clarity:
        return StudioIcons.autoAwesome;
      case PhotoAdjustmentType.fade:
        return StudioIcons.gradient;
      case PhotoAdjustmentType.vignette:
        return StudioIcons.vignette;
      case PhotoAdjustmentType.grain:
        return StudioIcons.grain;
      case PhotoAdjustmentType.blur:
        return StudioIcons.blurOn;
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

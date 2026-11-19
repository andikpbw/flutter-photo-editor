import 'package:flutter/widgets.dart';

import '../../controller/photo_editor_controller.dart';
import '../../models/photo_editor_labels.dart';
import '../../models/photo_editor_theme.dart';
import '../../models/photo_frame.dart';
import 'studio_primitives.dart';
import 'studio_widgets.dart';

/// Studio frame, museum mat, Polaroid, cinema letterbox, and rounded-card
/// border selector panel.
class FramePanel extends StatelessWidget {
  /// Creates a [FramePanel].
  const FramePanel({
    super.key,
    required this.controller,
    required this.frameColors,
    required this.theme,
    required this.labels,
    required this.isDesktop,
  });

  /// Active editor controller.
  final PhotoEditorController controller;

  /// Available frame fill color swatches.
  final List<Color> frameColors;

  /// Visual theme tokens.
  final PhotoEditorTheme theme;

  /// Localizable strings.
  final PhotoEditorLabels labels;

  /// Whether rendering in the vertical desktop inspector sidebar.
  final bool isDesktop;

  static IconData _iconFor(PhotoFrameStyle style) {
    switch (style) {
      case PhotoFrameStyle.none:
        return StudioIcons.block;
      case PhotoFrameStyle.minimal:
        return StudioIcons.cropDin;
      case PhotoFrameStyle.gallery:
        return StudioIcons.filterFrames;
      case PhotoFrameStyle.polaroid:
        return StudioIcons.photoCameraFront;
      case PhotoFrameStyle.cinema:
        return StudioIcons.theaters;
      case PhotoFrameStyle.rounded:
        return StudioIcons.roundedCorner;
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = controller.state.frame;
    final hasFrame = frame.style != PhotoFrameStyle.none;

    final thicknessSlider = StudioSliderRow(
      label: labels.frameThickness,
      icon: StudioIcons.borderOuter,
      value: frame.thickness,
      min: 0.05,
      max: 1.0,
      defaultValue: 0.45,
      valueText: '${(frame.thickness * 100).round()}%',
      theme: theme,
      compact: !isDesktop,
      onChangeStart: (_) => controller.beginInteraction(),
      onChanged: (v) => controller.setFrameThickness(v, recordHistory: false),
      onChangeEnd: (_) => controller.commitInteraction(),
      onReset: () => controller.setFrameThickness(0.45),
    );

    final radiusSlider = StudioSliderRow(
      label: labels.frameCornerRadius,
      icon: StudioIcons.roundedCorner,
      value: frame.cornerRadius,
      min: 0.0,
      max: 1.0,
      valueText: '${(frame.cornerRadius * 100).round()}%',
      theme: theme,
      compact: !isDesktop,
      onChangeStart: (_) => controller.beginInteraction(),
      onChanged: (v) =>
          controller.setFrameCornerRadius(v, recordHistory: false),
      onChangeEnd: (_) => controller.commitInteraction(),
      onReset: () => controller.setFrameCornerRadius(0.0),
    );

    if (isDesktop) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: <Widget>[
          StudioSectionHeader(
            title: labels.framesTab.toUpperCase(),
            theme: theme,
            actionLabel: !frame.isNone ? labels.reset : null,
            onAction: controller.resetFrame,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.05,
            children: PhotoFrameStyle.values.map((style) {
              final selected = frame.style == style;
              return StudioPressable(
                onTap: () => controller.setFrameStyle(style),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.accentColor.withValues(alpha: 0.16)
                        : theme.elevatedSurfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? theme.accentColor : theme.borderColor,
                      width: selected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        _iconFor(style),
                        size: 20,
                        color: selected
                            ? theme.accentColor
                            : theme.primaryTextColor,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        labels.frameStyleLabel(style),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? theme.accentColor
                              : theme.secondaryTextColor,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (hasFrame) ...<Widget>[
            const SizedBox(height: 18),
            StudioSectionHeader(
              title: labels.frameColor.toUpperCase(),
              theme: theme,
            ),
            const SizedBox(height: 10),
            StudioColorSwatches(
              colors: frameColors,
              selectedColor: frame.color,
              theme: theme,
              wrap: true,
              onSelected: controller.setFrameColor,
            ),
            const SizedBox(height: 16),
            thicknessSlider,
          ],
          const SizedBox(height: 12),
          radiusSlider,
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (hasFrame) ...<Widget>[
            thicknessSlider,
            const SizedBox(height: 4),
            StudioColorSwatches(
              colors: frameColors,
              selectedColor: frame.color,
              theme: theme,
              onSelected: controller.setFrameColor,
            ),
            const SizedBox(height: 6),
          ],
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: PhotoFrameStyle.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final style = PhotoFrameStyle.values[index];
                final selected = frame.style == style;
                return StudioPressable(
                  onTap: () => controller.setFrameStyle(style),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 68,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.accentColor.withValues(alpha: 0.16)
                          : theme.elevatedSurfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? theme.accentColor : theme.borderColor,
                        width: selected ? 1.4 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          _iconFor(style),
                          size: 18,
                          color: selected
                              ? theme.accentColor
                              : theme.primaryTextColor,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          labels.frameStyleLabel(style),
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
      ),
    );
  }
}

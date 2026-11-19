import 'package:flutter/widgets.dart';

import '../../controller/photo_editor_controller.dart';
import '../../models/drawing_stroke.dart';
import '../../models/photo_editor_labels.dart';
import '../../models/photo_editor_theme.dart';
import 'studio_primitives.dart';
import 'studio_widgets.dart';

/// Drawing, vector shape markup, and non-destructive privacy-blur controls.
class DrawPanel extends StatelessWidget {
  /// Creates a [DrawPanel].
  const DrawPanel({
    super.key,
    required this.controller,
    required this.colors,
    required this.theme,
    required this.labels,
    required this.isDesktop,
  });

  /// Active editor controller.
  final PhotoEditorController controller;

  /// Available drawing colors.
  final List<Color> colors;

  /// Visual theme tokens.
  final PhotoEditorTheme theme;

  /// Localizable strings.
  final PhotoEditorLabels labels;

  /// Whether rendering in the vertical desktop inspector sidebar.
  final bool isDesktop;

  static IconData _iconFor(BrushTool tool) {
    switch (tool) {
      case BrushTool.pen:
        return StudioIcons.editRounded;
      case BrushTool.highlighter:
        return StudioIcons.brush;
      case BrushTool.line:
        return StudioIcons.horizontalRule;
      case BrushTool.arrow:
        return StudioIcons.northEast;
      case BrushTool.rectangle:
        return StudioIcons.cropSquare;
      case BrushTool.filledRectangle:
        return StudioIcons.square;
      case BrushTool.oval:
        return StudioIcons.circleOutlined;
      case BrushTool.blurRect:
        return StudioIcons.blurCircular;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasStrokes = controller.state.strokes.isNotEmpty;
    final isBlurTool = controller.brushTool == BrushTool.blurRect;

    final sizeSlider = StudioSliderRow(
      label: labels.brushSize,
      icon: StudioIcons.lineWeight,
      value: controller.brushWidth,
      min: 0.003,
      max: 0.05,
      defaultValue: 0.012,
      valueText: '${(controller.brushWidth * 1000).round()}',
      theme: theme,
      compact: !isDesktop,
      onChanged: controller.setBrushWidth,
      onReset: () => controller.setBrushWidth(0.012),
    );

    final opacitySlider = StudioSliderRow(
      label: labels.brushOpacity,
      icon: StudioIcons.opacity,
      value: controller.brushOpacity,
      min: 0.15,
      max: 1.0,
      defaultValue: 1.0,
      valueText: '${(controller.brushOpacity * 100).round()}%',
      theme: theme,
      compact: !isDesktop,
      onChanged: controller.setBrushOpacity,
      onReset: () => controller.setBrushOpacity(1.0),
    );

    if (isDesktop) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: <Widget>[
          StudioSectionHeader(
            title: labels.drawTab.toUpperCase(),
            theme: theme,
            actionLabel: hasStrokes ? labels.clearStrokes : null,
            onAction: controller.clearStrokes,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.05,
            children: BrushTool.values.map((tool) {
              final selected = controller.brushTool == tool;
              return StudioPressable(
                tooltip: labels.brushToolLabel(tool),
                onTap: () => controller.setBrushTool(tool),
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
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        _iconFor(tool),
                        size: 18,
                        color: selected
                            ? theme.accentColor
                            : theme.primaryTextColor,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        labels.brushToolLabel(tool),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? theme.accentColor
                              : theme.secondaryTextColor,
                          fontSize: 9.5,
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
          if (!isBlurTool) ...<Widget>[
            const SizedBox(height: 16),
            StudioColorSwatches(
              colors: colors,
              selectedColor: controller.brushColor,
              theme: theme,
              wrap: true,
              onSelected: controller.setBrushColor,
            ),
            const SizedBox(height: 18),
            sizeSlider,
            const SizedBox(height: 12),
            opacitySlider,
          ],
          if (hasStrokes) ...<Widget>[
            const SizedBox(height: 16),
            StudioButton(
              label: '${labels.undo} (${controller.state.strokes.length})',
              icon: StudioIcons.undo,
              iconSize: 16,
              foregroundColor: theme.primaryTextColor,
              borderColor: theme.borderColor,
              expand: true,
              onPressed: controller.undoLastStroke,
            ),
          ],
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!isBlurTool) sizeSlider,
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: BrushTool.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final tool = BrushTool.values[index];
                      final selected = controller.brushTool == tool;
                      return StudioPressable(
                        tooltip: labels.brushToolLabel(tool),
                        onTap: () => controller.setBrushTool(tool),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.accentColor.withValues(alpha: 0.16)
                                : theme.elevatedSurfaceColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? theme.accentColor
                                  : theme.borderColor,
                            ),
                          ),
                          child: Icon(
                            _iconFor(tool),
                            size: 18,
                            color: selected
                                ? theme.accentColor
                                : theme.primaryTextColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (hasStrokes) ...<Widget>[
                const SizedBox(width: 6),
                StudioPressable(
                  tooltip: labels.undo,
                  onTap: controller.undoLastStroke,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      StudioIcons.undo,
                      size: 18,
                      color: theme.primaryTextColor,
                    ),
                  ),
                ),
                StudioPressable(
                  tooltip: labels.clearStrokes,
                  onTap: controller.clearStrokes,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      StudioIcons.deleteOutline,
                      size: 18,
                      color: theme.dangerColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!isBlurTool) ...<Widget>[
            const SizedBox(height: 8),
            StudioColorSwatches(
              colors: colors,
              selectedColor: controller.brushColor,
              theme: theme,
              onSelected: controller.setBrushColor,
            ),
          ],
        ],
      ),
    );
  }
}

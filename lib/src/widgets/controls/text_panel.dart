import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../controller/photo_editor_controller.dart';
import '../../models/overlay_layer.dart';
import '../../models/photo_editor_labels.dart';
import '../../models/photo_editor_theme.dart';
import 'studio_primitives.dart';
import 'studio_widgets.dart';

/// Controls for creating, styling, aligning, spacing, scaling, rotating,
/// reordering, and toggling visibility on text overlay layers.
class TextPanel extends StatelessWidget {
  /// Creates a [TextPanel].
  const TextPanel({
    super.key,
    required this.controller,
    required this.colors,
    required this.theme,
    required this.labels,
    required this.isDesktop,
    required this.onAddText,
    required this.onEditText,
  });

  /// Active editor controller.
  final PhotoEditorController controller;

  /// Available text color swatches.
  final List<Color> colors;

  /// Visual theme tokens.
  final PhotoEditorTheme theme;

  /// Localizable strings.
  final PhotoEditorLabels labels;

  /// Whether rendering in the vertical desktop inspector sidebar.
  final bool isDesktop;

  /// Opens the dialog to create a new text layer.
  final VoidCallback onAddText;

  /// Opens the dialog to edit an existing [TextOverlayLayer].
  final ValueChanged<TextOverlayLayer> onEditText;

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedOverlay;
    final selectedText = selected is TextOverlayLayer ? selected : null;
    final textLayers = controller.state.overlays
        .whereType<TextOverlayLayer>()
        .toList();

    if (isDesktop) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: <Widget>[
          StudioSectionHeader(
            title: labels.textTab.toUpperCase(),
            theme: theme,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: StudioButton(
                  label: labels.addText,
                  icon: StudioIcons.add,
                  iconSize: 18,
                  backgroundColor: theme.accentColor,
                  foregroundColor: theme.onAccentColor,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  expand: true,
                  onPressed: onAddText,
                ),
              ),
              if (selectedText != null) ...<Widget>[
                const SizedBox(width: 8),
                StudioPressable(
                  tooltip: labels.editText,
                  onTap: () => onEditText(selectedText),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.elevatedSurfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: Icon(
                      StudioIcons.editOutlined,
                      size: 18,
                      color: theme.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (selectedText != null) ...<Widget>[
            const SizedBox(height: 16),
            StudioSectionHeader(
              title: labels.textStyle.toUpperCase(),
              theme: theme,
            ),
            const SizedBox(height: 8),
            _BackgroundStyleRow(
              layer: selectedText,
              controller: controller,
              theme: theme,
            ),
            const SizedBox(height: 10),
            _TypographyRow(
              layer: selectedText,
              controller: controller,
              theme: theme,
            ),
            const SizedBox(height: 14),
            StudioSectionHeader(
              title: labels.textColor.toUpperCase(),
              theme: theme,
            ),
            const SizedBox(height: 8),
            StudioColorSwatches(
              colors: colors,
              selectedColor: selectedText.color,
              theme: theme,
              wrap: true,
              onSelected: (c) =>
                  controller.updateOverlay(selectedText.copyWith(color: c)),
            ),
            const SizedBox(height: 14),
            StudioSliderRow(
              label: labels.textScale,
              icon: StudioIcons.zoomOutMap,
              value: selectedText.scale,
              min: 0.4,
              max: 3.0,
              defaultValue: 1.0,
              valueText: '${(selectedText.scale * 100).round()}%',
              theme: theme,
              onChangeStart: (_) => controller.beginInteraction(),
              onChanged: (v) => controller.updateOverlay(
                selectedText.copyWith(scale: v),
                recordHistory: false,
              ),
              onChangeEnd: (_) => controller.commitInteraction(),
              onReset: () =>
                  controller.updateOverlay(selectedText.copyWith(scale: 1.0)),
            ),
            const SizedBox(height: 8),
            StudioSliderRow(
              label: labels.textRotation,
              icon: StudioIcons.rotateRight,
              value: (selectedText.rotation * 180.0 / math.pi).clamp(
                -180.0,
                180.0,
              ),
              min: -180.0,
              max: 180.0,
              valueText:
                  '${(selectedText.rotation * 180.0 / math.pi).round()}°',
              theme: theme,
              onChangeStart: (_) => controller.beginInteraction(),
              onChanged: (deg) => controller.updateOverlay(
                selectedText.copyWith(rotation: deg * math.pi / 180.0),
                recordHistory: false,
              ),
              onChangeEnd: (_) => controller.commitInteraction(),
              onReset: () => controller.updateOverlay(
                selectedText.copyWith(rotation: 0.0),
              ),
            ),
            const SizedBox(height: 8),
            StudioSliderRow(
              label: labels.letterSpacing,
              icon: StudioIcons.spaceBar,
              value: selectedText.letterSpacing,
              min: -1.5,
              max: 10.0,
              valueText: selectedText.letterSpacing.toStringAsFixed(1),
              theme: theme,
              onChangeStart: (_) => controller.beginInteraction(),
              onChanged: (v) => controller.updateOverlay(
                selectedText.copyWith(letterSpacing: v),
                recordHistory: false,
              ),
              onChangeEnd: (_) => controller.commitInteraction(),
              onReset: () => controller.updateOverlay(
                selectedText.copyWith(letterSpacing: 0.0),
              ),
            ),
            const SizedBox(height: 8),
            StudioSliderRow(
              label: labels.layerOpacity,
              icon: StudioIcons.opacity,
              value: selectedText.opacity,
              min: 0.15,
              max: 1.0,
              defaultValue: 1.0,
              valueText: '${(selectedText.opacity * 100).round()}%',
              theme: theme,
              onChangeStart: (_) => controller.beginInteraction(),
              onChanged: (v) => controller.updateOverlay(
                selectedText.copyWith(opacity: v),
                recordHistory: false,
              ),
              onChangeEnd: (_) => controller.commitInteraction(),
              onReset: () =>
                  controller.updateOverlay(selectedText.copyWith(opacity: 1.0)),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: StudioButton(
                    label: labels.duplicateLayer,
                    icon: StudioIcons.copy,
                    iconSize: 15,
                    foregroundColor: theme.primaryTextColor,
                    borderColor: theme.borderColor,
                    expand: true,
                    onPressed: controller.duplicateSelectedOverlay,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StudioButton(
                    label: labels.deleteLayer,
                    icon: StudioIcons.deleteOutline,
                    iconSize: 16,
                    foregroundColor: theme.dangerColor,
                    borderColor: theme.dangerColor.withValues(alpha: 0.5),
                    expand: true,
                    onPressed: controller.deleteSelectedOverlay,
                  ),
                ),
              ],
            ),
          ] else if (textLayers.isEmpty) ...<Widget>[
            const SizedBox(height: 20),
            Text(
              labels.noLayersHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.secondaryTextColor, fontSize: 12.5),
            ),
          ],
          if (textLayers.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            StudioSectionHeader(
              title: labels.layersHeading.toUpperCase(),
              theme: theme,
            ),
            const SizedBox(height: 8),
            ...textLayers.reversed.map((layer) {
              final active = layer.id == selectedText?.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: StudioPressable(
                  onTap: () => controller.selectOverlay(layer.id),
                  onDoubleTap: () => onEditText(layer),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? theme.accentColor.withValues(alpha: 0.14)
                          : theme.elevatedSurfaceColor,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: active ? theme.accentColor : theme.borderColor,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        StudioPressable(
                          onTap: () =>
                              controller.toggleOverlayVisibility(layer.id),
                          child: Icon(
                            layer.isVisible
                                ? StudioIcons.visibility
                                : StudioIcons.visibilityOff,
                            size: 15,
                            color: layer.isVisible
                                ? theme.accentColor
                                : theme.secondaryTextColor.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            layer.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: layer.isVisible
                                  ? theme.primaryTextColor
                                  : theme.secondaryTextColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        StudioPressable(
                          onTap: () => controller.moveOverlayForward(layer.id),
                          child: Icon(
                            StudioIcons.arrowUpward,
                            size: 14,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        StudioPressable(
                          onTap: () => controller.moveOverlayBackward(layer.id),
                          child: Icon(
                            StudioIcons.arrowDownward,
                            size: 14,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        StudioPressable(
                          onTap: () => controller.deleteOverlay(layer.id),
                          child: Icon(
                            StudioIcons.closeRounded,
                            size: 15,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Flexible(
                child: StudioButton(
                  label: labels.addText,
                  icon: StudioIcons.add,
                  backgroundColor: theme.accentColor,
                  foregroundColor: theme.onAccentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  onPressed: onAddText,
                ),
              ),
              if (selectedText != null) ...<Widget>[
                const SizedBox(width: 8),
                StudioPressable(
                  tooltip: labels.editText,
                  onTap: () => onEditText(selectedText),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      StudioIcons.editOutlined,
                      size: 18,
                      color: theme.primaryTextColor,
                    ),
                  ),
                ),
                StudioPressable(
                  tooltip: labels.duplicateLayer,
                  onTap: controller.duplicateSelectedOverlay,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      StudioIcons.copy,
                      size: 17,
                      color: theme.primaryTextColor,
                    ),
                  ),
                ),
                StudioPressable(
                  tooltip: labels.deleteLayer,
                  onTap: controller.deleteSelectedOverlay,
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
          if (selectedText != null) ...<Widget>[
            const SizedBox(height: 8),
            _BackgroundStyleRow(
              layer: selectedText,
              controller: controller,
              theme: theme,
            ),
            const SizedBox(height: 8),
            StudioColorSwatches(
              colors: colors,
              selectedColor: selectedText.color,
              theme: theme,
              onSelected: (c) =>
                  controller.updateOverlay(selectedText.copyWith(color: c)),
            ),
          ],
        ],
      ),
    );
  }
}

class _BackgroundStyleRow extends StatelessWidget {
  const _BackgroundStyleRow({
    required this.layer,
    required this.controller,
    required this.theme,
  });

  final TextOverlayLayer layer;
  final PhotoEditorController controller;
  final PhotoEditorTheme theme;

  static String _labelFor(TextBackgroundStyle style) {
    switch (style) {
      case TextBackgroundStyle.none:
        return 'Plain';
      case TextBackgroundStyle.solid:
        return 'Solid';
      case TextBackgroundStyle.translucent:
        return 'Glass';
      case TextBackgroundStyle.outline:
        return 'Outline';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TextBackgroundStyle.values.map((style) {
        final selected = layer.backgroundStyle == style;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: StudioPressable(
              onTap: () => controller.updateOverlay(
                layer.copyWith(backgroundStyle: style),
              ),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.accentColor.withValues(alpha: 0.16)
                      : theme.elevatedSurfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? theme.accentColor : theme.borderColor,
                  ),
                ),
                child: Text(
                  _labelFor(style),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? theme.accentColor
                        : theme.secondaryTextColor,
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TypographyRow extends StatelessWidget {
  const _TypographyRow({
    required this.layer,
    required this.controller,
    required this.theme,
  });

  final TextOverlayLayer layer;
  final PhotoEditorController controller;
  final PhotoEditorTheme theme;

  @override
  Widget build(BuildContext context) {
    final isBold = layer.fontWeight.value >= FontWeight.w700.value;
    final isItalic = layer.fontStyle == FontStyle.italic;

    Widget pill({
      required IconData icon,
      required bool active,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.5),
          child: StudioPressable(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: active
                    ? theme.accentColor.withValues(alpha: 0.16)
                    : theme.elevatedSurfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: active ? theme.accentColor : theme.borderColor,
                ),
              ),
              child: Icon(
                icon,
                size: 16,
                color: active ? theme.accentColor : theme.primaryTextColor,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        pill(
          icon: StudioIcons.formatBold,
          active: isBold,
          onTap: () => controller.updateOverlay(
            layer.copyWith(
              fontWeight: isBold ? FontWeight.w500 : FontWeight.w800,
            ),
          ),
        ),
        pill(
          icon: StudioIcons.formatItalic,
          active: isItalic,
          onTap: () => controller.updateOverlay(
            layer.copyWith(
              fontStyle: isItalic ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
        pill(
          icon: StudioIcons.formatAlignLeft,
          active: layer.textAlign == TextAlign.left,
          onTap: () => controller.updateOverlay(
            layer.copyWith(textAlign: TextAlign.left),
          ),
        ),
        pill(
          icon: StudioIcons.formatAlignCenter,
          active: layer.textAlign == TextAlign.center,
          onTap: () => controller.updateOverlay(
            layer.copyWith(textAlign: TextAlign.center),
          ),
        ),
        pill(
          icon: StudioIcons.formatAlignRight,
          active: layer.textAlign == TextAlign.right,
          onTap: () => controller.updateOverlay(
            layer.copyWith(textAlign: TextAlign.right),
          ),
        ),
      ],
    );
  }
}

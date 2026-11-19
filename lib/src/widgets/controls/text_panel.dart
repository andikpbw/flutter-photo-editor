import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controller/photo_editor_controller.dart';
import '../../models/overlay_layer.dart';
import '../../models/photo_editor_labels.dart';
import '../../models/photo_editor_theme.dart';
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
                child: FilledButton.icon(
                  onPressed: onAddText,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(labels.addText),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.accentColor,
                    foregroundColor: theme.onAccentColor,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (selectedText != null) ...<Widget>[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => onEditText(selectedText),
                  tooltip: labels.editText,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.elevatedSurfaceColor,
                    foregroundColor: theme.primaryTextColor,
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
              icon: Icons.zoom_out_map_rounded,
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
              icon: Icons.rotate_right_rounded,
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
              icon: Icons.space_bar_rounded,
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
              icon: Icons.opacity_rounded,
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
                  child: OutlinedButton.icon(
                    onPressed: controller.duplicateSelectedOverlay,
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: Text(labels.duplicateLayer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryTextColor,
                      side: BorderSide(color: theme.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.deleteSelectedOverlay,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: Text(labels.deleteLayer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.dangerColor,
                      side: BorderSide(
                        color: theme.dangerColor.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
                child: InkWell(
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
                        InkWell(
                          onTap: () =>
                              controller.toggleOverlayVisibility(layer.id),
                          child: Icon(
                            layer.isVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
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
                        InkWell(
                          onTap: () => controller.moveOverlayForward(layer.id),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            size: 14,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => controller.moveOverlayBackward(layer.id),
                          child: Icon(
                            Icons.arrow_downward_rounded,
                            size: 14,
                            color: theme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => controller.deleteOverlay(layer.id),
                          child: Icon(
                            Icons.close_rounded,
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
                child: FilledButton.icon(
                  onPressed: onAddText,
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: Text(
                    labels.addText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.accentColor,
                    foregroundColor: theme.onAccentColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (selectedText != null) ...<Widget>[
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => onEditText(selectedText),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: labels.editText,
                  color: theme.primaryTextColor,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: controller.duplicateSelectedOverlay,
                  icon: const Icon(Icons.copy_rounded, size: 17),
                  tooltip: labels.duplicateLayer,
                  color: theme.primaryTextColor,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: controller.deleteSelectedOverlay,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  tooltip: labels.deleteLayer,
                  color: theme.dangerColor,
                  visualDensity: VisualDensity.compact,
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
            child: GestureDetector(
              onTap: () => controller.updateOverlay(
                layer.copyWith(backgroundStyle: style),
              ),
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
          child: GestureDetector(
            onTap: onTap,
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
          icon: Icons.format_bold_rounded,
          active: isBold,
          onTap: () => controller.updateOverlay(
            layer.copyWith(
              fontWeight: isBold ? FontWeight.w500 : FontWeight.w800,
            ),
          ),
        ),
        pill(
          icon: Icons.format_italic_rounded,
          active: isItalic,
          onTap: () => controller.updateOverlay(
            layer.copyWith(
              fontStyle: isItalic ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
        pill(
          icon: Icons.format_align_left_rounded,
          active: layer.textAlign == TextAlign.left,
          onTap: () => controller.updateOverlay(
            layer.copyWith(textAlign: TextAlign.left),
          ),
        ),
        pill(
          icon: Icons.format_align_center_rounded,
          active: layer.textAlign == TextAlign.center,
          onTap: () => controller.updateOverlay(
            layer.copyWith(textAlign: TextAlign.center),
          ),
        ),
        pill(
          icon: Icons.format_align_right_rounded,
          active: layer.textAlign == TextAlign.right,
          onTap: () => controller.updateOverlay(
            layer.copyWith(textAlign: TextAlign.right),
          ),
        ),
      ],
    );
  }
}

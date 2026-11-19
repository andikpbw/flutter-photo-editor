import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controller/photo_editor_controller.dart';
import '../../models/overlay_layer.dart';
import '../../models/photo_editor_labels.dart';
import '../../models/photo_editor_theme.dart';
import 'studio_widgets.dart';

/// Sticker & emoji gallery panel with active sticker transform controls.
class StickerPanel extends StatelessWidget {
  /// Creates a [StickerPanel].
  const StickerPanel({
    super.key,
    required this.controller,
    required this.stickers,
    required this.theme,
    required this.labels,
    required this.isDesktop,
  });

  /// Active editor controller.
  final PhotoEditorController controller;

  /// Available stickers/emojis.
  final List<String> stickers;

  /// Visual theme tokens.
  final PhotoEditorTheme theme;

  /// Localizable strings.
  final PhotoEditorLabels labels;

  /// Whether rendering in the vertical desktop inspector sidebar.
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedOverlay;
    final selectedSticker = selected is StickerOverlayLayer ? selected : null;

    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: StudioSectionHeader(
              title: labels.stickersTab.toUpperCase(),
              theme: theme,
            ),
          ),
          if (selectedSticker != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  StudioSliderRow(
                    label: labels.textScale,
                    icon: Icons.zoom_out_map_rounded,
                    value: selectedSticker.scale,
                    min: 0.4,
                    max: 3.0,
                    defaultValue: 1.0,
                    valueText: '${(selectedSticker.scale * 100).round()}%',
                    theme: theme,
                    onChangeStart: (_) => controller.beginInteraction(),
                    onChanged: (v) => controller.updateOverlay(
                      selectedSticker.copyWith(scale: v),
                      recordHistory: false,
                    ),
                    onChangeEnd: (_) => controller.commitInteraction(),
                    onReset: () => controller.updateOverlay(
                      selectedSticker.copyWith(scale: 1.0),
                    ),
                  ),
                  const SizedBox(height: 6),
                  StudioSliderRow(
                    label: labels.textRotation,
                    icon: Icons.rotate_right_rounded,
                    value: (selectedSticker.rotation * 180.0 / math.pi).clamp(
                      -180.0,
                      180.0,
                    ),
                    min: -180.0,
                    max: 180.0,
                    valueText:
                        '${(selectedSticker.rotation * 180.0 / math.pi).round()}°',
                    theme: theme,
                    onChangeStart: (_) => controller.beginInteraction(),
                    onChanged: (deg) => controller.updateOverlay(
                      selectedSticker.copyWith(rotation: deg * math.pi / 180.0),
                      recordHistory: false,
                    ),
                    onChangeEnd: (_) => controller.commitInteraction(),
                    onReset: () => controller.updateOverlay(
                      selectedSticker.copyWith(rotation: 0.0),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                          ),
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
                  const Divider(height: 20),
                ],
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: stickers.length,
              itemBuilder: (context, index) {
                final sticker = stickers[index];
                return InkWell(
                  onTap: () => controller.addStickerLayer(sticker),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.elevatedSurfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: Center(
                      child: Text(
                        sticker,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (selectedSticker != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: StudioSliderRow(
                    label: labels.textScale,
                    value: selectedSticker.scale,
                    min: 0.4,
                    max: 3.0,
                    defaultValue: 1.0,
                    valueText: '${(selectedSticker.scale * 100).round()}%',
                    theme: theme,
                    compact: true,
                    onChangeStart: (_) => controller.beginInteraction(),
                    onChanged: (v) => controller.updateOverlay(
                      selectedSticker.copyWith(scale: v),
                      recordHistory: false,
                    ),
                    onChangeEnd: (_) => controller.commitInteraction(),
                    onReset: () => controller.updateOverlay(
                      selectedSticker.copyWith(scale: 1.0),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: controller.deleteSelectedOverlay,
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                  color: theme.dangerColor,
                  tooltip: labels.deleteLayer,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            itemCount: stickers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final sticker = stickers[index];
              return GestureDetector(
                onTap: () => controller.addStickerLayer(sticker),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.elevatedSurfaceColor,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Center(
                    child: Text(sticker, style: const TextStyle(fontSize: 23)),
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

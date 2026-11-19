import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../controller/photo_editor_controller.dart';
import '../../models/overlay_layer.dart';
import '../../models/photo_editor_labels.dart';
import '../../models/photo_editor_theme.dart';
import 'studio_primitives.dart';
import 'studio_widgets.dart';

/// Sticker, emoji, and crisp cross-platform vector studio badge gallery panel.
class StickerPanel extends StatelessWidget {
  /// Creates a [StickerPanel].
  const StickerPanel({
    super.key,
    required this.controller,
    required this.stickers,
    required this.studioBadges,
    required this.theme,
    required this.labels,
    required this.isDesktop,
  });

  /// Active editor controller.
  final PhotoEditorController controller;

  /// Available stickers/emojis.
  final List<String> stickers;

  /// Available crisp vector studio pill badges (e.g. `RAW`, `PRO`, `4K`).
  final List<String> studioBadges;

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
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: <Widget>[
          StudioSectionHeader(
            title: labels.stickersTab.toUpperCase(),
            theme: theme,
          ),
          if (selectedSticker != null) ...<Widget>[
            const SizedBox(height: 10),
            StudioSliderRow(
              label: labels.textScale,
              icon: StudioIcons.zoomOutMap,
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
              icon: StudioIcons.rotateRight,
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
            const SizedBox(height: 6),
            StudioSliderRow(
              label: labels.layerOpacity,
              icon: StudioIcons.opacity,
              value: selectedSticker.opacity,
              min: 0.15,
              max: 1.0,
              defaultValue: 1.0,
              valueText: '${(selectedSticker.opacity * 100).round()}%',
              theme: theme,
              onChangeStart: (_) => controller.beginInteraction(),
              onChanged: (v) => controller.updateOverlay(
                selectedSticker.copyWith(opacity: v),
                recordHistory: false,
              ),
              onChangeEnd: (_) => controller.commitInteraction(),
              onReset: () => controller.updateOverlay(
                selectedSticker.copyWith(opacity: 1.0),
              ),
            ),
            const SizedBox(height: 8),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(height: 1, color: theme.borderColor),
            ),
          ],
          if (studioBadges.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            StudioSectionHeader(
              title: labels.badgesHeading.toUpperCase(),
              theme: theme,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: studioBadges.map((badge) {
                return StudioPressable(
                  onTap: () => controller.addBadgeLayer(
                    badge,
                    badgeColor: theme.accentColor,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          theme.accentColor,
                          theme.accentColor.withValues(alpha: 0.72),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: StudioColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: stickers.length,
            itemBuilder: (context, index) {
              final sticker = stickers[index];
              return StudioPressable(
                onTap: () => controller.addStickerLayer(sticker),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.elevatedSurfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Center(
                    child: Text(sticker, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              );
            },
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
                StudioPressable(
                  tooltip: labels.deleteLayer,
                  onTap: controller.deleteSelectedOverlay,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      StudioIcons.deleteOutline,
                      size: 19,
                      color: theme.dangerColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (studioBadges.isNotEmpty)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
              itemCount: studioBadges.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final badge = studioBadges[index];
                return StudioPressable(
                  onTap: () => controller.addBadgeLayer(
                    badge,
                    badgeColor: theme.accentColor,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.accentColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: StudioColors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            itemCount: stickers.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final sticker = stickers[index];
              return StudioPressable(
                onTap: () => controller.addStickerLayer(sticker),
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.elevatedSurfaceColor,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: Center(
                    child: Text(sticker, style: const TextStyle(fontSize: 22)),
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

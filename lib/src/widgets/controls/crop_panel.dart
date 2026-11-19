import 'package:flutter/material.dart';

import '../../controller/photo_editor_controller.dart';
import '../../models/crop_aspect_ratio.dart';
import '../../models/photo_editor_labels.dart';
import '../../models/photo_editor_theme.dart';
import 'studio_widgets.dart';

/// Controls for interactive crop aspect ratios, 90° rotation, mirroring, and
/// fine straightening.
class CropPanel extends StatelessWidget {
  /// Creates a [CropPanel].
  const CropPanel({
    super.key,
    required this.controller,
    required this.aspectRatios,
    required this.sourceImageSize,
    required this.theme,
    required this.labels,
    required this.isDesktop,
  });

  /// Active editor controller.
  final PhotoEditorController controller;

  /// Available crop aspect ratio presets.
  final List<CropAspectRatio> aspectRatios;

  /// Dimensions of the unmodified source image.
  final Size sourceImageSize;

  /// Visual theme tokens.
  final PhotoEditorTheme theme;

  /// Localizable strings.
  final PhotoEditorLabels labels;

  /// Whether rendering in the vertical desktop inspector sidebar.
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final transform = controller.state.transform;
    final degrees = transform.rotationDegrees;
    final formattedDeg =
        '${degrees > 0.05 ? '+' : ''}${degrees.toStringAsFixed(1)}°';

    final quickActions = Row(
      children: <Widget>[
        _TransformActionButton(
          icon: Icons.rotate_90_degrees_ccw_rounded,
          tooltip: labels.rotateLeft,
          theme: theme,
          onTap: controller.rotateLeft,
        ),
        const SizedBox(width: 8),
        _TransformActionButton(
          icon: Icons.rotate_90_degrees_cw_outlined,
          tooltip: labels.rotateRight,
          theme: theme,
          onTap: controller.rotateRight,
        ),
        const SizedBox(width: 8),
        _TransformActionButton(
          icon: Icons.flip_rounded,
          tooltip: labels.flipHorizontal,
          active: transform.flipHorizontal,
          theme: theme,
          onTap: controller.flipHorizontal,
        ),
        const SizedBox(width: 8),
        _TransformActionButton(
          icon: Icons.flip_rounded,
          quarterTurns: 1,
          tooltip: labels.flipVertical,
          active: transform.flipVertical,
          theme: theme,
          onTap: controller.flipVertical,
        ),
      ],
    );

    final straightenSlider = StudioSliderRow(
      label: labels.straighten,
      icon: Icons.straighten_rounded,
      value: degrees,
      min: -45.0,
      max: 45.0,
      valueText: formattedDeg,
      theme: theme,
      compact: !isDesktop,
      onChangeStart: (_) => controller.beginInteraction(),
      onChanged: (deg) =>
          controller.setStraightenDegrees(deg, recordHistory: false),
      onChangeEnd: (_) => controller.commitInteraction(),
      onReset: () => controller.setStraightenDegrees(0.0),
    );

    if (isDesktop) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: <Widget>[
          StudioSectionHeader(
            title: labels.cropTab.toUpperCase(),
            theme: theme,
            actionLabel: !transform.isIdentity ? labels.reset : null,
            onAction: controller.resetTransform,
          ),
          const SizedBox(height: 14),
          quickActions,
          const SizedBox(height: 18),
          straightenSlider,
          const SizedBox(height: 18),
          StudioSectionHeader(
            title: labels.aspectRatio.toUpperCase(),
            theme: theme,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: aspectRatios.map((preset) {
              final selected = controller.activeAspectRatio.id == preset.id;
              return _AspectRatioChip(
                preset: preset,
                selected: selected,
                theme: theme,
                onTap: () => controller.selectAspectRatio(
                  preset,
                  sourceImageSize: sourceImageSize,
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: straightenSlider,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
          child: Row(
            children: <Widget>[
              Expanded(child: quickActions),
              if (!transform.isIdentity) ...<Widget>[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: controller.resetTransform,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 34),
                  ),
                  child: Text(
                    labels.reset,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            itemCount: aspectRatios.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = aspectRatios[index];
              return _AspectRatioChip(
                preset: preset,
                selected: controller.activeAspectRatio.id == preset.id,
                theme: theme,
                onTap: () => controller.selectAspectRatio(
                  preset,
                  sourceImageSize: sourceImageSize,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TransformActionButton extends StatelessWidget {
  const _TransformActionButton({
    required this.icon,
    required this.tooltip,
    required this.theme,
    required this.onTap,
    this.active = false,
    this.quarterTurns = 0,
  });

  final IconData icon;
  final String tooltip;
  final PhotoEditorTheme theme;
  final VoidCallback onTap;
  final bool active;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: active
                  ? theme.accentColor.withValues(alpha: 0.16)
                  : theme.elevatedSurfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? theme.accentColor : theme.borderColor,
              ),
            ),
            child: Center(
              child: RotatedBox(
                quarterTurns: quarterTurns,
                child: Icon(
                  icon,
                  size: 18,
                  color: active ? theme.accentColor : theme.primaryTextColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AspectRatioChip extends StatelessWidget {
  const _AspectRatioChip({
    required this.preset,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final CropAspectRatio preset;
  final bool selected;
  final PhotoEditorTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? theme.accentColor : theme.elevatedSurfaceColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? theme.accentColor : theme.borderColor,
          ),
        ),
        child: Text(
          preset.label,
          style: TextStyle(
            color: selected ? theme.onAccentColor : theme.primaryTextColor,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

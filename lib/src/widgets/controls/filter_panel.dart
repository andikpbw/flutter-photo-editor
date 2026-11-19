import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../controller/photo_editor_controller.dart';
import '../../models/photo_editor_labels.dart';
import '../../models/photo_editor_theme.dart';
import '../../models/photo_filter.dart';
import 'studio_primitives.dart';
import 'studio_widgets.dart';

/// Color-grading filter selector panel with category tabs, live image
/// thumbnail previews, and adjustable filter intensity.
class FilterPanel extends StatelessWidget {
  /// Creates a [FilterPanel].
  const FilterPanel({
    super.key,
    required this.controller,
    required this.filters,
    required this.theme,
    required this.labels,
    required this.isDesktop,
    this.thumbnail,
  });

  /// Active editor controller.
  final PhotoEditorController controller;

  /// Ordered list of available color filters.
  final List<PhotoFilter> filters;

  /// Visual theme tokens.
  final PhotoEditorTheme theme;

  /// Localizable strings.
  final PhotoEditorLabels labels;

  /// Whether rendering in the vertical desktop inspector sidebar.
  final bool isDesktop;

  /// Lightweight downscaled source image used for smooth live thumbnails.
  final ui.Image? thumbnail;

  @override
  Widget build(BuildContext context) {
    final activeFilter = controller.state.filter;
    final intensity = controller.state.filterIntensity;
    final activeCategory = controller.activeFilterCategory;
    final visibleFilters = PhotoFilters.forCategory(filters, activeCategory);

    final categoryBar = SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 14),
        itemCount: PhotoFilterCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final cat = PhotoFilterCategory.values[index];
          final selected = cat == activeCategory;
          return GestureDetector(
            onTap: () => controller.setFilterCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? theme.accentColor.withValues(alpha: 0.18)
                    : theme.elevatedSurfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? theme.accentColor : theme.borderColor,
                ),
              ),
              child: Center(
                child: Text(
                  labels.filterCategoryLabel(cat),
                  style: TextStyle(
                    color: selected
                        ? theme.accentColor
                        : theme.secondaryTextColor,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    final intensityWidget = !activeFilter.isOriginal
        ? StudioSliderRow(
            label: labels.filterIntensity,
            icon: StudioIcons.opacity,
            value: intensity,
            min: 0.0,
            max: 1.0,
            defaultValue: 1.0,
            valueText: '${(intensity * 100).round()}%',
            theme: theme,
            compact: !isDesktop,
            onChangeStart: (_) => controller.beginInteraction(),
            onChanged: (v) =>
                controller.setFilterIntensity(v, recordHistory: false),
            onChangeEnd: (_) => controller.commitInteraction(),
            onReset: () => controller.setFilterIntensity(1.0),
          )
        : null;

    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: StudioSectionHeader(
              title: labels.filtersTab.toUpperCase(),
              theme: theme,
              actionLabel: !activeFilter.isOriginal ? labels.reset : null,
              onAction: () => controller.selectFilter(PhotoFilters.original),
            ),
          ),
          categoryBar,
          const SizedBox(height: 8),
          if (intensityWidget != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: intensityWidget,
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: visibleFilters.length,
              itemBuilder: (context, index) {
                final filter = visibleFilters[index];
                return _FilterThumbnailCard(
                  filter: filter,
                  thumbnail: thumbnail,
                  selected: activeFilter.id == filter.id,
                  theme: theme,
                  onTap: () => controller.selectFilter(filter),
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
        if (intensityWidget != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
            child: intensityWidget,
          ),
        const SizedBox(height: 4),
        categoryBar,
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            itemCount: visibleFilters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final filter = visibleFilters[index];
              return SizedBox(
                width: 64,
                child: _FilterThumbnailCard(
                  filter: filter,
                  thumbnail: thumbnail,
                  selected: activeFilter.id == filter.id,
                  theme: theme,
                  onTap: () => controller.selectFilter(filter),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterThumbnailCard extends StatelessWidget {
  const _FilterThumbnailCard({
    required this.filter,
    required this.thumbnail,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final PhotoFilter filter;
  final ui.Image? thumbnail;
  final bool selected;
  final PhotoEditorTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? theme.accentColor : theme.borderColor,
                  width: selected ? 2.2 : 1.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: thumbnail != null
                    ? CustomPaint(
                        painter: _FilterThumbPainter(
                          image: thumbnail!,
                          matrix: filter.isOriginal ? null : filter.matrix,
                        ),
                        child: const SizedBox.expand(),
                      )
                    : Container(color: theme.elevatedSurfaceColor),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            filter.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? theme.accentColor : theme.secondaryTextColor,
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterThumbPainter extends CustomPainter {
  const _FilterThumbPainter({required this.image, required this.matrix});

  final ui.Image image;
  final List<double>? matrix;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final srcSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.cover, srcSize, size);
    final srcRect = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & srcSize,
    );
    final dstRect = Alignment.center.inscribe(fitted.destination, rect);
    final paint = Paint()..filterQuality = FilterQuality.low;
    if (matrix != null) {
      paint.colorFilter = ColorFilter.matrix(matrix!);
    }
    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(_FilterThumbPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.matrix != matrix;
  }
}

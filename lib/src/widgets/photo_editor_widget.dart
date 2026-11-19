import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controller/photo_editor_controller.dart';
import '../engine/photo_export_engine.dart';
import '../models/overlay_layer.dart';
import '../models/photo_edit_state.dart';
import '../models/photo_editor_config.dart';
import '../models/photo_editor_labels.dart';
import '../models/photo_editor_result.dart';
import '../models/photo_editor_theme.dart';
import 'canvas/photo_editor_canvas.dart';
import 'controls/adjust_panel.dart';
import 'controls/crop_panel.dart';
import 'controls/draw_panel.dart';
import 'controls/filter_panel.dart';
import 'controls/sticker_panel.dart';
import 'controls/text_panel.dart';
import 'dialogs/text_editor_dialog.dart';

/// A modern, adaptive, studio-grade Flutter photo editor widget supporting
/// color-grading filters, precision adjustments, interactive cropping,
/// straightening, rotation, flipping, vector markup drawing, text overlays,
/// and stickers across mobile, desktop, and web platforms.
class PhotoEditor extends StatefulWidget {
  /// Creates a [PhotoEditor] from encoded image [bytes] (PNG, JPEG, WebP, etc.).
  PhotoEditor.memory(
    Uint8List bytes, {
    super.key,
    this.onComplete,
    this.onCancel,
    this.onError,
    this.controller,
    this.initialState = PhotoEditState.initial,
    PhotoEditorConfig? config,
  }) : _bytes = bytes,
       _imageProvider = null,
       _directImage = null,
       config = config ?? PhotoEditorConfig();

  /// Creates a [PhotoEditor] from any Flutter [ImageProvider] (such as
  /// `AssetImage`, `NetworkImage`, or `MemoryImage`).
  PhotoEditor.provider(
    ImageProvider imageProvider, {
    super.key,
    this.onComplete,
    this.onCancel,
    this.onError,
    this.controller,
    this.initialState = PhotoEditState.initial,
    PhotoEditorConfig? config,
  }) : _bytes = null,
       _imageProvider = imageProvider,
       _directImage = null,
       config = config ?? PhotoEditorConfig();

  /// Creates a [PhotoEditor] directly from an already decoded [ui.Image].
  ///
  /// The caller remains responsible for disposing [image].
  PhotoEditor.image(
    ui.Image image, {
    super.key,
    this.onComplete,
    this.onCancel,
    this.onError,
    this.controller,
    this.initialState = PhotoEditState.initial,
    PhotoEditorConfig? config,
  }) : _bytes = null,
       _imageProvider = null,
       _directImage = image,
       config = config ?? PhotoEditorConfig();

  final Uint8List? _bytes;
  final ImageProvider? _imageProvider;
  final ui.Image? _directImage;

  /// Callback invoked with the rendered [PhotoEditorResult] when the user taps
  /// Export/Done.
  final ValueChanged<PhotoEditorResult>? onComplete;

  /// Callback invoked when the user taps Cancel/Close.
  final VoidCallback? onCancel;

  /// Optional error callback invoked if loading or exporting fails.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Optional external [PhotoEditorController] for programmatic control.
  final PhotoEditorController? controller;

  /// Initial edit state applied when no external [controller] is provided.
  final PhotoEditState initialState;

  /// Editor feature, theme, label, layout, and export configuration.
  final PhotoEditorConfig config;

  /// Opens [PhotoEditor] as a full-screen route and returns the exported
  /// [PhotoEditorResult], or `null` if the user cancels.
  ///
  /// Exactly one of [bytes], [imageProvider], or [image] must be provided.
  static Future<PhotoEditorResult?> open(
    BuildContext context, {
    Uint8List? bytes,
    ImageProvider? imageProvider,
    ui.Image? image,
    PhotoEditorConfig? config,
    PhotoEditorController? controller,
    PhotoEditState initialState = PhotoEditState.initial,
  }) {
    final providedCount =
        (bytes != null ? 1 : 0) +
        (imageProvider != null ? 1 : 0) +
        (image != null ? 1 : 0);
    if (providedCount != 1) {
      throw ArgumentError(
        'Provide exactly one of bytes, imageProvider, or image.',
      );
    }

    return Navigator.of(context).push<PhotoEditorResult?>(
      MaterialPageRoute<PhotoEditorResult?>(
        builder: (routeContext) {
          void handleComplete(PhotoEditorResult result) {
            if (Navigator.of(routeContext).canPop()) {
              Navigator.of(routeContext).pop(result);
            }
          }

          void handleCancel() {
            if (Navigator.of(routeContext).canPop()) {
              Navigator.of(routeContext).pop();
            }
          }

          if (bytes != null) {
            return PhotoEditor.memory(
              bytes,
              config: config,
              controller: controller,
              initialState: initialState,
              onComplete: handleComplete,
              onCancel: handleCancel,
            );
          }
          if (imageProvider != null) {
            return PhotoEditor.provider(
              imageProvider,
              config: config,
              controller: controller,
              initialState: initialState,
              onComplete: handleComplete,
              onCancel: handleCancel,
            );
          }
          return PhotoEditor.image(
            image!,
            config: config,
            controller: controller,
            initialState: initialState,
            onComplete: handleComplete,
            onCancel: handleCancel,
          );
        },
      ),
    );
  }

  @override
  State<PhotoEditor> createState() => _PhotoEditorState();
}

class _PhotoEditorState extends State<PhotoEditor> {
  PhotoEditorController? _ownedController;
  final TransformationController _transformationController =
      TransformationController();

  ui.Image? _image;
  bool _ownsImage = false;
  ui.Image? _thumbnail;
  Object? _loadError;
  bool _isLoading = true;
  bool _isExporting = false;

  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  int _loadGeneration = 0;

  PhotoEditorController get _controller =>
      widget.controller ?? _ownedController!;

  PhotoEditorTheme get _theme => widget.config.theme;
  PhotoEditorLabels get _labels => widget.config.labels;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = PhotoEditorController(
        initialState: widget.initialState,
        initialTool: widget.config.resolvedInitialTool,
        maxHistoryLength: widget.config.maxHistoryLength,
        initialBrushColor: widget.config.brushColors.isNotEmpty
            ? widget.config.brushColors.first
            : Colors.white,
      );
    }
    unawaited(_loadSourceImage());
  }

  @override
  void didUpdateWidget(covariant PhotoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (widget.controller == null && _ownedController == null) {
        _ownedController = PhotoEditorController(
          initialState: widget.initialState,
          initialTool: widget.config.resolvedInitialTool,
          maxHistoryLength: widget.config.maxHistoryLength,
        );
      } else if (widget.controller != null && _ownedController != null) {
        _ownedController!.dispose();
        _ownedController = null;
      }
    }
    if (oldWidget._bytes != widget._bytes ||
        oldWidget._imageProvider != widget._imageProvider ||
        oldWidget._directImage != widget._directImage) {
      unawaited(_loadSourceImage());
    }
  }

  @override
  void dispose() {
    _detachImageStream();
    _disposeOwnedImage();
    _thumbnail?.dispose();
    _transformationController.dispose();
    _ownedController?.dispose();
    super.dispose();
  }

  void _detachImageStream() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  void _disposeOwnedImage() {
    if (_ownsImage) {
      _image?.dispose();
    }
    _image = null;
    _ownsImage = false;
  }

  Future<void> _loadSourceImage() async {
    final generation = ++_loadGeneration;
    _detachImageStream();
    _disposeOwnedImage();
    _thumbnail?.dispose();
    _thumbnail = null;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      if (widget._directImage != null) {
        await _onImageReady(
          widget._directImage!,
          ownsImage: false,
          generation: generation,
        );
        return;
      }

      if (widget._bytes != null) {
        final codec = await ui.instantiateImageCodec(widget._bytes!);
        final frame = await codec.getNextFrame();
        codec.dispose();
        if (generation != _loadGeneration || !mounted) {
          frame.image.dispose();
          return;
        }
        await _onImageReady(
          frame.image,
          ownsImage: true,
          generation: generation,
        );
        return;
      }

      if (widget._imageProvider != null) {
        final stream = widget._imageProvider!.resolve(ImageConfiguration.empty);
        _imageStream = stream;
        _imageStreamListener = ImageStreamListener(
          (info, _) {
            if (generation != _loadGeneration || !mounted) {
              return;
            }
            // Clone image handle so PhotoEditor safely owns its lifetime.
            final cloned = info.image.clone();
            unawaited(
              _onImageReady(cloned, ownsImage: true, generation: generation),
            );
          },
          onError: (error, stackTrace) {
            if (generation != _loadGeneration || !mounted) {
              return;
            }
            widget.onError?.call(error, stackTrace ?? StackTrace.current);
            setState(() {
              _isLoading = false;
              _loadError = error;
            });
          },
        );
        stream.addListener(_imageStreamListener!);
      }
    } catch (error, stackTrace) {
      if (generation != _loadGeneration || !mounted) {
        return;
      }
      widget.onError?.call(error, stackTrace);
      setState(() {
        _isLoading = false;
        _loadError = error;
      });
    }
  }

  Future<void> _onImageReady(
    ui.Image image, {
    required bool ownsImage,
    required int generation,
  }) async {
    _disposeOwnedImage();
    _image = image;
    _ownsImage = ownsImage;

    final thumb = await _buildThumbnail(image);
    if (generation != _loadGeneration || !mounted) {
      thumb?.dispose();
      return;
    }

    _thumbnail?.dispose();
    _thumbnail = thumb;

    setState(() {
      _isLoading = false;
      _loadError = null;
    });
  }

  Future<ui.Image?> _buildThumbnail(ui.Image source) async {
    try {
      const maxThumb = 144.0;
      final srcW = source.width.toDouble();
      final srcH = source.height.toDouble();
      final scale = math.min(1.0, maxThumb / math.max(srcW, srcH));
      final thumbW = math.max(1, (srcW * scale).round());
      final thumbH = math.max(1, (srcH * scale).round());

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        source,
        Rect.fromLTWH(0, 0, srcW, srcH),
        Rect.fromLTWH(0, 0, thumbW.toDouble(), thumbH.toDouble()),
        Paint()..filterQuality = FilterQuality.medium,
      );
      final picture = recorder.endRecording();
      try {
        return await picture.toImage(thumbW, thumbH);
      } finally {
        picture.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleExport() async {
    final image = _image;
    if (image == null || _isExporting) {
      return;
    }
    setState(() => _isExporting = true);
    try {
      final result = await PhotoExportEngine.export(
        image: image,
        state: _controller.state,
        options: widget.config.exportOptions,
      );
      if (!mounted) {
        return;
      }
      setState(() => _isExporting = false);
      widget.onComplete?.call(result);
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      setState(() => _isExporting = false);
      widget.onError?.call(error, stackTrace);
    }
  }

  Future<void> _handleAddText() async {
    final entered = await TextEditorDialog.show(
      context,
      theme: _theme,
      labels: _labels,
    );
    if (!mounted || entered == null) {
      return;
    }
    final defaultColor = widget.config.textColors.isNotEmpty
        ? widget.config.textColors.first
        : Colors.white;
    _controller.addTextLayer(text: entered, color: defaultColor);
  }

  Future<void> _handleEditText(TextOverlayLayer layer) async {
    final updated = await TextEditorDialog.show(
      context,
      theme: _theme,
      labels: _labels,
      initialText: layer.text,
      isEditing: true,
    );
    if (!mounted || updated == null) {
      return;
    }
    _controller.updateOverlay(layer.copyWith(text: updated));
  }

  void _setZoom(double targetScale) {
    final clamped = targetScale.clamp(1.0, 5.0);
    _transformationController.value = Matrix4.diagonal3Values(
      clamped,
      clamped,
      1.0,
    );
    _controller.setZoomScale(clamped);
  }

  bool _isDesktopForWidth(double width) {
    switch (widget.config.layoutMode) {
      case PhotoEditorLayoutMode.desktop:
        return true;
      case PhotoEditorLayoutMode.mobile:
        return false;
      case PhotoEditorLayoutMode.auto:
        return width >= widget.config.desktopBreakpoint;
    }
  }

  String _toolLabel(PhotoEditorTool tool) {
    switch (tool) {
      case PhotoEditorTool.crop:
        return _labels.cropTab;
      case PhotoEditorTool.filters:
        return _labels.filtersTab;
      case PhotoEditorTool.adjust:
        return _labels.adjustTab;
      case PhotoEditorTool.draw:
        return _labels.drawTab;
      case PhotoEditorTool.text:
        return _labels.textTab;
      case PhotoEditorTool.stickers:
        return _labels.stickersTab;
    }
  }

  IconData _toolIcon(PhotoEditorTool tool) {
    switch (tool) {
      case PhotoEditorTool.crop:
        return Icons.crop_rotate_rounded;
      case PhotoEditorTool.filters:
        return Icons.auto_fix_high_rounded;
      case PhotoEditorTool.adjust:
        return Icons.tune_rounded;
      case PhotoEditorTool.draw:
        return Icons.draw_rounded;
      case PhotoEditorTool.text:
        return Icons.title_rounded;
      case PhotoEditorTool.stickers:
        return Icons.emoji_emotions_outlined;
    }
  }

  Widget _buildActiveToolPanel({required bool isDesktop}) {
    final sourceSize = _image != null
        ? Size(_image!.width.toDouble(), _image!.height.toDouble())
        : const Size(1000, 1000);

    switch (_controller.activeTool) {
      case PhotoEditorTool.filters:
        return FilterPanel(
          controller: _controller,
          filters: widget.config.filters,
          theme: _theme,
          labels: _labels,
          isDesktop: isDesktop,
          thumbnail: _thumbnail,
        );
      case PhotoEditorTool.adjust:
        return AdjustPanel(
          controller: _controller,
          adjustments: widget.config.adjustments,
          theme: _theme,
          labels: _labels,
          isDesktop: isDesktop,
        );
      case PhotoEditorTool.crop:
        return CropPanel(
          controller: _controller,
          aspectRatios: widget.config.aspectRatios,
          sourceImageSize: sourceSize,
          theme: _theme,
          labels: _labels,
          isDesktop: isDesktop,
        );
      case PhotoEditorTool.draw:
        return DrawPanel(
          controller: _controller,
          colors: widget.config.brushColors,
          theme: _theme,
          labels: _labels,
          isDesktop: isDesktop,
        );
      case PhotoEditorTool.text:
        return TextPanel(
          controller: _controller,
          colors: widget.config.textColors,
          theme: _theme,
          labels: _labels,
          isDesktop: isDesktop,
          onAddText: _handleAddText,
          onEditText: _handleEditText,
        );
      case PhotoEditorTool.stickers:
        return StickerPanel(
          controller: _controller,
          stickers: widget.config.stickers,
          theme: _theme,
          labels: _labels,
          isDesktop: isDesktop,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: _theme.canvasBackground,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = _isDesktopForWidth(constraints.maxWidth);
              return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
            },
          );
        },
      ),
    );

    if (!widget.config.enableKeyboardShortcuts) {
      return content;
    }

    final isApple =
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: isApple,
          control: !isApple,
        ): _controller.undo,
        SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: isApple,
          control: !isApple,
          shift: true,
        ): _controller.redo,
        SingleActivator(
          LogicalKeyboardKey.keyY,
          meta: isApple,
          control: !isApple,
        ): _controller.redo,
        SingleActivator(
          LogicalKeyboardKey.digit0,
          meta: isApple,
          control: !isApple,
        ): () =>
            _setZoom(1.0),
        const SingleActivator(LogicalKeyboardKey.delete):
            _controller.deleteSelectedOverlay,
        const SingleActivator(LogicalKeyboardKey.backspace):
            _controller.deleteSelectedOverlay,
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            _controller.selectOverlay(null),
      },
      child: Focus(autofocus: true, child: content),
    );
  }

  Widget _buildCanvasArea() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: _theme.accentColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _labels.loading,
              style: TextStyle(color: _theme.secondaryTextColor, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_loadError != null || _image == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.broken_image_outlined,
                size: 42,
                color: _theme.secondaryTextColor,
              ),
              const SizedBox(height: 12),
              Text(
                _labels.loadError,
                textAlign: TextAlign.center,
                style: TextStyle(color: _theme.primaryTextColor, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        PhotoEditorCanvas(
          image: _image!,
          controller: _controller,
          theme: _theme,
          enableZoomPan: widget.config.enableZoomPan,
          originalBadgeLabel: _labels.originalBadge,
          transformationController: _transformationController,
          onEditTextLayer: _handleEditText,
        ),
        if (_isExporting)
          ColoredBox(
            color: Colors.black.withValues(alpha: 0.45),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _theme.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _theme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: _theme.accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _labels.exporting,
                      style: TextStyle(
                        color: _theme.primaryTextColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop 3-Pane Studio Layout
  // ---------------------------------------------------------------------------

  Widget _buildDesktopLayout() {
    final croppedSize = _image != null
        ? _controller.state.transform.croppedSize(
            Size(_image!.width.toDouble(), _image!.height.toDouble()),
          )
        : null;

    return Column(
      children: <Widget>[
        // Top desktop studio toolbar.
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _theme.surfaceColor,
            border: Border(bottom: BorderSide(color: _theme.borderColor)),
          ),
          child: Row(
            children: <Widget>[
              if (widget.config.showCloseButton) ...<Widget>[
                _ToolbarIconButton(
                  icon: Icons.close_rounded,
                  tooltip: _labels.cancel,
                  theme: _theme,
                  onPressed: widget.onCancel,
                ),
                const SizedBox(width: 8),
              ],
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      _theme.accentColor,
                      _theme.accentColor.withValues(alpha: 0.72),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_filter_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _labels.title,
                style: TextStyle(
                  color: _theme.primaryTextColor,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (croppedSize != null) ...<Widget>[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _theme.elevatedSurfaceColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _theme.borderColor),
                  ),
                  child: Text(
                    '${croppedSize.width.round()} × ${croppedSize.height.round()}',
                    style: TextStyle(
                      color: _theme.secondaryTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Zoom controls
              if (widget.config.enableZoomPan) ...<Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _theme.elevatedSurfaceColor,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _theme.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _CompactMiniButton(
                        icon: Icons.remove_rounded,
                        theme: _theme,
                        onPressed: _controller.zoomScale > 1.01
                            ? () => _setZoom(_controller.zoomScale - 0.25)
                            : null,
                      ),
                      GestureDetector(
                        onTap: () => _setZoom(1.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '${(_controller.zoomScale * 100).round()}%',
                            style: TextStyle(
                              color: _theme.primaryTextColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _CompactMiniButton(
                        icon: Icons.add_rounded,
                        theme: _theme,
                        onPressed: _controller.zoomScale < 4.99
                            ? () => _setZoom(_controller.zoomScale + 0.25)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Undo / Redo / Compare / Reset
              _ToolbarIconButton(
                icon: Icons.undo_rounded,
                tooltip: _labels.undo,
                theme: _theme,
                onPressed: _controller.canUndo ? _controller.undo : null,
              ),
              const SizedBox(width: 4),
              _ToolbarIconButton(
                icon: Icons.redo_rounded,
                tooltip: _labels.redo,
                theme: _theme,
                onPressed: _controller.canRedo ? _controller.redo : null,
              ),
              const SizedBox(width: 4),
              _ToolbarIconButton(
                icon: Icons.compare_rounded,
                tooltip: _labels.compare,
                active: _controller.isComparingOriginal,
                theme: _theme,
                onPressed: _image != null
                    ? () => _controller.setComparingOriginal(
                        !_controller.isComparingOriginal,
                      )
                    : null,
              ),
              if (_controller.hasChanges) ...<Widget>[
                const SizedBox(width: 4),
                _ToolbarIconButton(
                  icon: Icons.restart_alt_rounded,
                  tooltip: _labels.resetAll,
                  theme: _theme,
                  onPressed: _controller.resetAll,
                ),
              ],
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _image != null && !_isExporting
                    ? _handleExport
                    : null,
                icon: _isExporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 17),
                label: Text(
                  _labels.done,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _theme.accentColor,
                  foregroundColor: _theme.onAccentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3-pane workspace body.
        Expanded(
          child: Row(
            children: <Widget>[
              // Left tool navigation rail.
              Container(
                width: 74,
                decoration: BoxDecoration(
                  color: _theme.surfaceColor,
                  border: Border(right: BorderSide(color: _theme.borderColor)),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  children: widget.config.tools.map((tool) {
                    final selected = _controller.activeTool == tool;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () => _controller.setActiveTool(tool),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? _theme.accentColor.withValues(alpha: 0.16)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? _theme.accentColor.withValues(alpha: 0.55)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                _toolIcon(tool),
                                size: 20,
                                color: selected
                                    ? _theme.accentColor
                                    : _theme.secondaryTextColor,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _toolLabel(tool),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected
                                      ? _theme.accentColor
                                      : _theme.secondaryTextColor,
                                  fontSize: 10.5,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Center studio canvas.
              Expanded(child: _buildCanvasArea()),

              // Right inspector sidebar.
              Container(
                width: _theme.desktopInspectorWidth,
                decoration: BoxDecoration(
                  color: _theme.surfaceColor,
                  border: Border(left: BorderSide(color: _theme.borderColor)),
                ),
                child: _buildActiveToolPanel(isDesktop: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile Compact Studio Layout
  // ---------------------------------------------------------------------------

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Column(
        children: <Widget>[
          // Top compact studio action bar.
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _theme.surfaceColor,
              border: Border(bottom: BorderSide(color: _theme.borderColor)),
            ),
            child: Row(
              children: <Widget>[
                if (widget.config.showCloseButton)
                  _ToolbarIconButton(
                    icon: Icons.close_rounded,
                    tooltip: _labels.cancel,
                    theme: _theme,
                    onPressed: widget.onCancel,
                  ),
                const Spacer(),
                _ToolbarIconButton(
                  icon: Icons.undo_rounded,
                  tooltip: _labels.undo,
                  theme: _theme,
                  onPressed: _controller.canUndo ? _controller.undo : null,
                ),
                _ToolbarIconButton(
                  icon: Icons.redo_rounded,
                  tooltip: _labels.redo,
                  theme: _theme,
                  onPressed: _controller.canRedo ? _controller.redo : null,
                ),
                _ToolbarIconButton(
                  icon: Icons.compare_rounded,
                  tooltip: _labels.compare,
                  active: _controller.isComparingOriginal,
                  theme: _theme,
                  onPressed: _image != null
                      ? () => _controller.setComparingOriginal(
                          !_controller.isComparingOriginal,
                        )
                      : null,
                ),
                if (_controller.hasChanges)
                  _ToolbarIconButton(
                    icon: Icons.restart_alt_rounded,
                    tooltip: _labels.resetAll,
                    theme: _theme,
                    onPressed: _controller.resetAll,
                  ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: _image != null && !_isExporting
                      ? _handleExport
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _theme.accentColor,
                    foregroundColor: _theme.onAccentColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isExporting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _labels.done,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Main canvas.
          Expanded(child: _buildCanvasArea()),

          // Contextual tool control panel.
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _theme.surfaceColor,
              border: Border(top: BorderSide(color: _theme.borderColor)),
            ),
            child: _buildActiveToolPanel(isDesktop: false),
          ),

          // Bottom primary tool navigation rail.
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: _theme.surfaceColor,
              border: Border(
                top: BorderSide(
                  color: _theme.borderColor.withValues(alpha: 0.7),
                ),
              ),
            ),
            child: Row(
              children: widget.config.tools.map((tool) {
                final selected = _controller.activeTool == tool;
                return Expanded(
                  child: InkWell(
                    onTap: () => _controller.setActiveTool(tool),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? _theme.accentColor.withValues(alpha: 0.16)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _toolIcon(tool),
                            size: 19,
                            color: selected
                                ? _theme.accentColor
                                : _theme.secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _toolLabel(tool),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? _theme.accentColor
                                : _theme.secondaryTextColor,
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
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.theme,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final PhotoEditorTheme theme;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: active
                ? theme.accentColor.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: active ? Border.all(color: theme.accentColor) : null,
          ),
          child: Icon(
            icon,
            size: 19,
            color: !enabled
                ? theme.secondaryTextColor.withValues(alpha: 0.35)
                : active
                ? theme.accentColor
                : theme.primaryTextColor,
          ),
        ),
      ),
    );
  }
}

class _CompactMiniButton extends StatelessWidget {
  const _CompactMiniButton({
    required this.icon,
    required this.theme,
    required this.onPressed,
  });

  final IconData icon;
  final PhotoEditorTheme theme;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(
          icon,
          size: 15,
          color: onPressed != null
              ? theme.primaryTextColor
              : theme.secondaryTextColor.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

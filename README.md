<p align="center">
  <a href="https://pub.dev/packages/photo_editor_studio">
    <img src="doc/screenshots/badge_no1_gold.png" alt="#1 Flutter Library — photo_editor_studio Golden Award Badge" width="760" />
  </a>
</p>

<h1 align="center">photo_editor_studio</h1>

<p align="center">
  <strong>A modern &amp; professional studio-grade Flutter photo editor library</strong><br />
  24 categorized color filters, 14 precision adjustments with live RGB histogram, interactive split-screen before/after comparison, cropping, straightening, vector markup &amp; privacy blur, typography layers with magnetic snap guides, studio badges, and museum/Polaroid frames across <strong>Android, iOS, macOS, Windows, Linux &amp; Web (WASM)</strong> — with <strong>zero external runtime dependencies</strong>.
</p>

<p align="center">
  <a href="https://pub.dev/packages/photo_editor_studio"><img src="https://img.shields.io/pub/v/photo_editor_studio.svg?color=F5B82E&label=pub.dev&style=for-the-badge" alt="pub package" /></a>
  <a href="https://pub.dev/packages/photo_editor_studio/score"><img src="https://img.shields.io/pub/points/photo_editor_studio?color=4F8BFF&style=for-the-badge" alt="pub points 160/160" /></a>
  <a href="https://github.com/andikpbw/flutter-photo-editor/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-34D399.svg?style=for-the-badge" alt="License: MIT" /></a>
  <a href="https://humanize.id"><img src="https://img.shields.io/badge/Supported%20by-Humanize%20AI-F5B82E.svg?style=for-the-badge" alt="Supported by Humanize AI" /></a>
</p>

---

## Live Real-UI Studio Showcase

`photo_editor_studio` automatically adapts between a sleek **3-pane Desktop Studio** (left navigation rail, zoomable darkroom canvas with live split-screen curtain & magnetic snap guides, right precision inspector with live RGB histogram) and a thumb-friendly **Mobile Studio** layout, in both Dark and Light themes.

### Desktop Studio Frame

<p align="center">
  <img src="doc/screenshots/demo_desktop.gif" alt="photo_editor_studio running live in Desktop Studio frame" width="840" />
</p>

### Mobile Frame

<p align="center">
  <img src="doc/screenshots/demo_mobile.gif" alt="photo_editor_studio running live in Mobile frame" width="360" />
</p>

---

## Pro-Studio Feature Matrix

| Studio Module | Capabilities |
| --- | --- |
| **24 Categorized Color Filters** | Organized into `All`, `Vivid`, `Cinema`, `Film`, `B&W`, and `Moody` (`Vivid`, `Warm`, `Cool`, `Velvia`, `Cinematic`, `Teal Gold`, `Dramatic`, `Golden`, `Midnight`, `Portra`, `Gold 400`, `Fade`, `Vintage`, `Retro 70s`, `Nordic`, `Pastel`, `Dreamy`, `Forest`, `Cyber`, `Mono`, `Noir`, `Silver`, `Sepia`, `Original`) with live thumbnails, `0–100%` intensity blending, and custom 4×5 matrix filter support. |
| **14 Precision Adjustments + Live RGB Histogram** | Real-time **Exposure**, **Brightness**, **Contrast**, non-linear GPU **Highlights** & **Shadows**, **Saturation**, skin-tone-aware **Vibrance**, **Warmth**, **Tint**, **Clarity**, **Fade**, **Radial Vignette**, **Analog Film Grain**, and resolution-scaled **Gaussian Blur** — paired with a live 64-bin **RGB & Luminance Histogram** on desktop. |
| **Interactive Split-Screen Compare** | Draggable **Before / After Split Curtain** directly on the canvas with `BEFORE` / `AFTER` pills plus full-original preview toggle. |
| **Crop, Rotate, Flip & Straighten** | Interactive 8-handle + interior drag crop frame with rule-of-thirds grid, live pixel dimension badge, aspect ratios (`Free`, `Original`, `1:1`, `4:3`, `3:2`, `16:9`, `4:5`, `9:16`), 90° left/right rotation, horizontal/vertical mirror, and `-45°..+45°` fine straightening with exact automatic corner-fill zoom. |
| **8 Markup & Privacy Blur Tools** | Smooth quadratic Bézier **Pen**, translucent **Marker**, straight **Line**, vector **Arrow**, **Box**, solid **Fill Box**, **Oval**, and non-destructive **Privacy Blur** redaction regions stored in resolution-independent normalized coordinates. |
| **Typography, Layers & Smart Snap Guides** | Multi-line **Text** overlays (`Plain`, `Solid`, `Glass`, `Outline` pills, bold/italic, alignment, letter spacing/tracking, line height, opacity, shadow) plus **Stickers** & crisp cross-platform **Studio Vector Badges** (`RAW`, `PRO`, `4K`, `HDR`, `NEW`, `LIVE`, `35MM`, `100%`) with **magnetic center snap alignment guides**, visibility toggles, Z-order reordering, duplication, and arrow-key nudging. |
| **Studio Frames & Borders** | `Minimal`, museum `Gallery` mat, classic `Polaroid`, widescreen `Cinema` letterbox, and `Rounded Card` frames with customizable colors, border thickness, and inner corner radius rendered identically in preview and export. |
| **Zero-Dependency WYSIWYG Export** | Shared `PhotoSceneRenderer` pipeline guarantees pixel-identical output across **PNG**, built-in pure-Dart baseline **JPEG** (`quality: 1..100`), and **Raw RGBA**, with optional `maxWidth`/`maxHeight` bounds across all 6 Flutter platforms + **WebAssembly (WASM)**. |

---

## Installation

Add `photo_editor_studio` to your `pubspec.yaml`:

```yaml
dependencies:
  photo_editor_studio: ^1.0.1
```

Or install via CLI:

```bash
flutter pub add photo_editor_studio
```

---

## Quick Start

### 1. Open as a Full-Screen Route

The fastest way to integrate `photo_editor_studio` is `PhotoEditor.open`, which returns a `PhotoEditorResult?` (`null` if cancelled):

```dart
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:photo_editor_studio/photo_editor_studio.dart';

Future<void> editPhoto(BuildContext context, Uint8List imageBytes) async {
  final PhotoEditorResult? result = await PhotoEditor.open(
    context,
    bytes: imageBytes,
    config: PhotoEditorConfig(
      theme: PhotoEditorTheme.dark(accentColor: const Color(0xFF4F8BFF)),
      exportOptions: const PhotoExportOptions(
        format: PhotoExportFormat.jpeg,
        jpegQuality: 92,
        maxWidth: 2048,
      ),
    ),
  );

  if (result != null) {
    // result.bytes  -> Uint8List (PNG / JPEG / Raw RGBA)
    // result.width  -> Exported pixel width
    // result.height -> Exported pixel height
    // result.state  -> Non-destructive PhotoEditState (serializable via toJson())
  }
}
```

### 2. Embed Directly in Your Widget Tree

Edit from memory bytes, any Flutter `ImageProvider` (`AssetImage`, `NetworkImage`, `MemoryImage`), or a pre-decoded `ui.Image`:

```dart
PhotoEditor.provider(
  const AssetImage('assets/sample.jpg'),
  config: PhotoEditorConfig(
    theme: PhotoEditorTheme.light(),
    enableSplitCompare: true,
    enableSnapGuides: true,
    showHistogram: true,
  ),
  onComplete: (PhotoEditorResult result) {
    // Handle exported bytes & edit state
  },
  onCancel: () => Navigator.of(context).pop(),
)
```

### 3. Headless / Programmatic Editing & JSON State Persistence

Save drafts, build batch processors, or create custom UIs around `PhotoEditorController` and `PhotoExportEngine`:

```dart
final controller = PhotoEditorController()
  ..selectFilter(PhotoFilters.tealOrange)
  ..setFilterIntensity(0.85)
  ..setAdjustment(PhotoAdjustmentType.contrast, 0.20)
  ..setAdjustment(PhotoAdjustmentType.shadows, 0.18)
  ..setAdjustment(PhotoAdjustmentType.vignette, 0.35)
  ..setFrameStyle(PhotoFrameStyle.polaroid)
  ..addTextLayer(text: 'MORNING LIGHT', letterSpacing: 2.0)
  ..addBadgeLayer('RAW 4K');

// Persist non-destructive edit state as JSON
final Map<String, dynamic> savedDraft = controller.state.toJson();

// Restore later
final restoredState = PhotoEditState.fromJson(savedDraft);

// Export headless at full resolution
final PhotoEditorResult exported = await PhotoExportEngine.export(
  image: decodedUiImage,
  state: restoredState,
  options: const PhotoExportOptions(
    format: PhotoExportFormat.png,
  ),
);
```

### 4. Custom Color Filters & Custom Labels / Localization

```dart
const customFilter = PhotoFilter(
  id: 'emerald_film',
  name: 'Emerald',
  category: PhotoFilterCategory.film,
  matrix: <double>[
    0.92, 0.04, 0.00, 0, -4,
    0.00, 1.12, 0.02, 0,  4,
    0.00, 0.06, 1.04, 0,  6,
    0.00, 0.00, 0.00, 1,  0,
  ],
);

final config = PhotoEditorConfig(
  filters: <PhotoFilter>[...PhotoFilters.presets, customFilter],
  labels: const PhotoEditorLabels(
    title: 'Studio Editor',
    done: 'Save Photo',
    cancel: 'Discard',
    cropTab: 'Crop',
    filtersTab: 'Presets',
    adjustTab: 'Tone',
    drawTab: 'Markup',
    textTab: 'Type',
    stickersTab: 'Badges',
    framesTab: 'Borders',
  ),
);
```

---

## Desktop & Web Keyboard Shortcuts

| Shortcut | Action |
| --- | --- |
| `Cmd / Ctrl + Z` | Undo |
| `Cmd / Ctrl + Shift + Z` or `Ctrl + Y` | Redo |
| `Cmd / Ctrl + 0` | Reset zoom to 100% (Fit) |
| `\` | Toggle Split-Screen Before / After Comparison |
| `Arrow Keys` | Fine-nudge selected text, sticker, or badge layer |
| `Delete` / `Backspace` | Delete selected overlay layer |
| `Escape` | Clear overlay selection |

---

## Support

This library is proudly supported by **[Humanize AI](https://humanize.id)**.

If `photo_editor_studio` powers your Flutter apps, please star the repository on [GitHub](https://github.com/andikpbw/flutter-photo-editor), open issues or feature requests in the [issue tracker](https://github.com/andikpbw/flutter-photo-editor/issues), and visit **[Humanize AI](https://humanize.id)**.

---

## License

Released under the [MIT License](https://github.com/andikpbw/flutter-photo-editor/blob/main/LICENSE).

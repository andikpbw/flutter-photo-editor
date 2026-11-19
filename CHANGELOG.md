## 1.0.0

* Initial production release of `photo_editor_studio` — a pro-studio Flutter photo editor engineered with zero external runtime dependencies.
* **Adaptive Studio UI**: Responsive 3-pane Desktop Studio and Mobile Studio layouts with Dark and Light themes plus full `PhotoEditorTheme` and `PhotoEditorLabels` localization support.
* **24 Categorized Studio Filters**: Organized into `All`, `Vivid`, `Cinema`, `Film`, `B&W`, and `Moody` with live thumbnail previews, adjustable intensity (`0–100%`), and custom 4×5 matrix filter support.
* **14 Precision Adjustments + Live RGB Histogram**: Real-time Exposure, Brightness, Contrast, GPU Highlights & Shadows, Saturation, Vibrance, Warmth, Tint, Clarity, Fade, Radial Vignette, Organic Film Grain, and Gaussian Blur paired with a live 64-bin RGB & Luminance Histogram.
* **Interactive Split-Screen Compare**: Draggable Before / After curtain slider directly on the photo canvas alongside full-original comparison.
* **Interactive Crop & Transform**: 8-handle freeform and locked aspect-ratio cropping (`Original`, `1:1`, `4:3`, `3:2`, `16:9`, `4:5`, `9:16`), 90° left/right rotation, horizontal/vertical flip, and fine `-45°` to `+45°` straightening with automatic corner-fill zoom.
* **8 Markup & Privacy Blur Tools**: Smooth Bézier Pen, Marker Highlighter, Line, Vector Arrow, Box, Filled Box, Oval, and non-destructive Privacy Blur regions in resolution-independent coordinates.
* **Typography, Layers, Smart Snap Guides & Studio Badges**: Multi-line styled text (tracking, opacity, alignment, pill styles, visibility toggles, Z-order reordering, arrow-key nudging), magnetic center snap guides, stickers, and crisp cross-platform vector badges (`RAW`, `PRO`, `4K`, `HDR`).
* **Studio Frames & Borders**: `Minimal`, `Gallery`, `Polaroid`, `Cinema`, and `Rounded Card` frames with customizable colors, border thickness, and inner corner radius.
* **Non-Destructive Engine & Full-Resolution Export**: Full Undo/Redo with gesture coalescing, JSON state serialization (`toJson`/`fromJson`), and pixel-identical WYSIWYG export to PNG, pure-Dart baseline JPEG, and raw RGBA across Android, iOS, macOS, Windows, Linux, and Web (WASM-ready).

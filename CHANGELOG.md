## 1.0.0

* Initial production release of `photo_editor`.
* **Adaptive Studio UI**: Responsive mobile and desktop/tablet studio layouts with dark and light themes plus full `PhotoEditorTheme` and `PhotoEditorLabels` localization support.
* **Curated Color Filters**: 16 built-in studio color-grading presets (`Vivid`, `Cinematic`, `Dramatic`, `Noir`, `Golden Hour`, `Vintage`, `Nordic`, `Pastel`, `Sepia`, `Cyber`, and more) with live thumbnails, intensity slider, and custom filter support.
* **Precision Adjustments**: Real-time Brightness, Contrast, Saturation, Exposure, Warmth, Tint, Fade, Clarity, Radial Vignette, and Gaussian Blur.
* **Interactive Crop & Transform**: Freeform and aspect-ratio locked cropping (`Original`, `1:1`, `4:3`, `3:2`, `16:9`, `4:5`, `9:16`), 90° left/right rotation, horizontal/vertical flip, and fine `-45°` to `+45°` straightening with automatic corner-fill scaling.
* **Markup & Drawing**: Smooth Bézier pen, semi-transparent highlighter, vector arrows, rectangles, and ovals with customizable stroke colors and widths in resolution-independent normalized coordinates.
* **Text & Sticker Overlays**: Drag, scale, rotate, align, style (plain, solid pill, translucent pill, outline), and edit multi-line text and sticker layers.
* **Non-Destructive Engine & Full-Resolution Export**: Full Undo/Redo history, Compare Original preview, JSON state serialization (`toJson`/`fromJson`), and zero-dependency full-resolution export to PNG, pure-Dart baseline JPEG, and raw RGBA across Android, iOS, macOS, Windows, Linux, and Web (WASM compatible).

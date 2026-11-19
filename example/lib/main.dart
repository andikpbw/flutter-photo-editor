import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:photo_editor/photo_editor.dart';

void main() {
  runApp(const PhotoEditorExampleApp());
}

/// Interactive showcase app for `photo_editor`.
class PhotoEditorExampleApp extends StatelessWidget {
  const PhotoEditorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Editor Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  Uint8List? _sampleBytes;
  PhotoEditorResult? _lastResult;
  bool _darkTheme = true;
  PhotoExportFormat _exportFormat = PhotoExportFormat.png;

  @override
  void initState() {
    super.initState();
    _generateSampleImage();
  }

  Future<void> _generateSampleImage() async {
    final bytes = await _createScenicSamplePng(1200, 900);
    if (mounted) {
      setState(() => _sampleBytes = bytes);
    }
  }

  Future<void> _openEditor() async {
    final bytes = _sampleBytes;
    if (bytes == null) {
      return;
    }

    final result = await PhotoEditor.open(
      context,
      bytes: bytes,
      initialState: _lastResult?.state ?? PhotoEditState.initial,
      config: PhotoEditorConfig(
        theme: _darkTheme ? PhotoEditorTheme.dark() : PhotoEditorTheme.light(),
        exportOptions: PhotoExportOptions(
          format: _exportFormat,
          jpegQuality: 92,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => _lastResult = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewBytes = _lastResult?.bytes ?? _sampleBytes;
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141822),
        title: const Text('photo_editor Demo'),
        actions: <Widget>[
          TextButton.icon(
            onPressed: () => setState(() => _darkTheme = !_darkTheme),
            icon: Icon(_darkTheme ? Icons.dark_mode : Icons.light_mode),
            label: Text(_darkTheme ? 'Dark' : 'Light'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141822),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF262D3D)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: previewBytes != null
                        ? Image.memory(previewBytes, fit: BoxFit.contain)
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),
                const SizedBox(height: 18),
                if (_lastResult != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      'Exported ${_lastResult!.width} × ${_lastResult!.height} '
                      '(${_lastResult!.fileExtension.toUpperCase()}, '
                      '${(_lastResult!.bytes.length / 1024).toStringAsFixed(1)} KB)',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    SegmentedButton<PhotoExportFormat>(
                      segments: const <ButtonSegment<PhotoExportFormat>>[
                        ButtonSegment<PhotoExportFormat>(
                          value: PhotoExportFormat.png,
                          label: Text('PNG'),
                        ),
                        ButtonSegment<PhotoExportFormat>(
                          value: PhotoExportFormat.jpeg,
                          label: Text('JPEG'),
                        ),
                      ],
                      selected: <PhotoExportFormat>{_exportFormat},
                      onSelectionChanged: (set) =>
                          setState(() => _exportFormat = set.first),
                    ),
                    FilledButton.icon(
                      onPressed: _sampleBytes != null ? _openEditor : null,
                      icon: const Icon(Icons.auto_fix_high_rounded),
                      label: const Text('Open Photo Editor'),
                    ),
                    if (_lastResult != null)
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _lastResult = null),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Reset Preview'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Generates a rich procedural sunset mountain lake illustration as PNG bytes
/// so the example works offline on all platforms without bundled assets.
Future<Uint8List> _createScenicSamplePng(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(width.toDouble(), height.toDouble());
  final rect = Offset.zero & size;

  // Sunset sky gradient
  canvas.drawRect(
    rect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF1A2A5E),
          Color(0xFF6B4C8C),
          Color(0xFFE07A5F),
          Color(0xFFF6BD60),
        ],
        stops: <double>[0.0, 0.32, 0.56, 0.72],
      ).createShader(rect),
  );

  // Glowing sun
  final sunCenter = Offset(size.width * 0.52, size.height * 0.44);
  canvas.drawCircle(
    sunCenter,
    size.height * 0.22,
    Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              const Color(0xFFFFF3C4),
              const Color(0xFFFFB703).withValues(alpha: 0.45),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: sunCenter, radius: size.height * 0.22),
          ),
  );

  // Distant mountain range
  final backMountains = Path()
    ..moveTo(0, size.height * 0.64)
    ..lineTo(size.width * 0.16, size.height * 0.42)
    ..lineTo(size.width * 0.34, size.height * 0.54)
    ..lineTo(size.width * 0.54, size.height * 0.34)
    ..lineTo(size.width * 0.74, size.height * 0.50)
    ..lineTo(size.width * 0.90, size.height * 0.38)
    ..lineTo(size.width, size.height * 0.50)
    ..lineTo(size.width, size.height * 0.68)
    ..lineTo(0, size.height * 0.68)
    ..close();
  canvas.drawPath(backMountains, Paint()..color = const Color(0xFF33416B));

  // Foreground mountain silhouette
  final frontMountains = Path()
    ..moveTo(0, size.height * 0.68)
    ..lineTo(size.width * 0.22, size.height * 0.50)
    ..lineTo(size.width * 0.44, size.height * 0.62)
    ..lineTo(size.width * 0.68, size.height * 0.46)
    ..lineTo(size.width * 0.88, size.height * 0.58)
    ..lineTo(size.width, size.height * 0.54)
    ..lineTo(size.width, size.height * 0.70)
    ..lineTo(0, size.height * 0.70)
    ..close();
  canvas.drawPath(frontMountains, Paint()..color = const Color(0xFF1D2744));

  // Calm reflective lake
  final lakeRect = Rect.fromLTWH(
    0,
    size.height * 0.66,
    size.width,
    size.height * 0.34,
  );
  canvas.drawRect(
    lakeRect,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF476C9B),
          Color(0xFF1B3A5C),
          Color(0xFF0E1D33),
        ],
      ).createShader(lakeRect),
  );

  // Golden water shimmer lines
  final shimmerPaint = Paint()
    ..color = const Color(0x88FFD166)
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 16; i++) {
    final t = i / 16.0;
    final y = size.height * (0.69 + t * 0.26);
    final halfW = (1.0 - t * 0.55) * size.width * 0.14;
    shimmerPaint.strokeWidth = 2.0 + t * 3.0;
    canvas.drawLine(
      Offset(sunCenter.dx - halfW + math.sin(i * 1.7) * 14, y),
      Offset(sunCenter.dx + halfW + math.cos(i * 1.3) * 14, y),
      shimmerPaint,
    );
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

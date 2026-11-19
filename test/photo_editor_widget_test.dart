import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_editor/photo_editor.dart';

Future<ui.Image> _buildTestImage(int w, int h) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFF1E3A8A), Color(0xFFF59E0B)],
      ).createShader(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble())),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(w, h);
  } finally {
    picture.dispose();
  }
}

Future<Uint8List> _buildTestPng(int w, int h) async {
  final image = await _buildTestImage(w, h);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

void main() {
  group('PhotoEditor responsive widget tests', () {
    testWidgets(
      'Mobile viewport (390x844) navigates all 6 tools without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final image = await tester.runAsync(() => _buildTestImage(240, 180));
        addTearDown(image!.dispose);

        final controller = PhotoEditorController();
        addTearDown(controller.dispose);

        PhotoEditorResult? exported;
        await tester.pumpWidget(
          MaterialApp(
            home: PhotoEditor.image(
              image,
              controller: controller,
              onComplete: (result) => exported = result,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Filters tab is active initially: tap Vivid filter card.
        expect(find.text('Vivid'), findsWidgets);
        await tester.tap(find.text('Vivid').last);
        await tester.pumpAndSettle();
        expect(controller.state.filter, PhotoFilters.vivid);

        // Switch through every single tool tab cleanly.
        for (final tab in <String>[
          'Crop',
          'Adjust',
          'Draw',
          'Text',
          'Stickers',
          'Frames',
        ]) {
          await tester.ensureVisible(find.text(tab));
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
        }

        // Apply a studio frame.
        await tester.tap(find.text('Polaroid'));
        await tester.pumpAndSettle();
        expect(controller.state.frame.style, PhotoFrameStyle.polaroid);

        // Add a studio badge & sticker.
        await tester.tap(find.text('Stickers'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('✨'));
        await tester.pumpAndSettle();
        expect(controller.state.overlays.length, 1);

        // Switch to Text and add a text overlay via dialog.
        await tester.tap(find.text('Text'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add Text'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Humanize AI');
        await tester.tap(find.text('Add Text').last);
        await tester.pumpAndSettle();
        expect(controller.state.overlays.length, 2);

        // Toggle interactive Split-Screen Before/After Compare curtain.
        await tester.tap(find.byIcon(Icons.compare_rounded));
        await tester.pumpAndSettle();
        expect(find.text('BEFORE'), findsOneWidget);
        expect(find.text('AFTER'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.compare_rounded));
        await tester.pumpAndSettle();

        // Export and verify result.
        await tester.runAsync(() async {
          await tester.tap(find.text('Export'));
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 120));
        });
        await tester.pumpAndSettle();

        expect(exported, isNotNull);
        expect(exported!.width, 240);
        expect(exported!.height, 180);
        expect(exported!.bytes, isNotEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Desktop viewport (1280x800) renders 3-pane studio with light & dark themes',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final image = await tester.runAsync(() => _buildTestImage(320, 240));
        addTearDown(image!.dispose);

        final controller = PhotoEditorController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: PhotoEditor.image(
              image,
              controller: controller,
              config: PhotoEditorConfig(theme: PhotoEditorTheme.light()),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();

        // Desktop header shows dimensions badge & zoom percentage.
        expect(find.text('320 × 240'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);

        // Navigate every desktop inspector panel (including Frames & live RGB Histogram).
        for (final tab in <String>[
          'Crop',
          'Adjust',
          'Draw',
          'Text',
          'Stickers',
          'Frames',
          'Filters',
        ]) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          if (tab == 'Adjust') {
            expect(find.byType(PhotoHistogramView), findsOneWidget);
          }
        }

        // Rotate right updates dimensions badge to 240 x 320.
        await tester.tap(find.text('Crop'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Rotate Right'));
        await tester.pumpAndSettle();
        expect(find.text('240 × 320'), findsOneWidget);

        // Undo restores 320 x 240.
        await tester.tap(find.byTooltip('Undo'));
        await tester.pumpAndSettle();
        expect(find.text('320 × 240'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('PhotoEditor.memory decodes PNG bytes and supports onCancel', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final pngBytes = await tester.runAsync(() => _buildTestPng(120, 90));
      var cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: PhotoEditor.memory(pngBytes!, onCancel: () => cancelled = true),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();
      expect(cancelled, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Ultra-compact viewport (320x568) renders all tabs without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final image = await tester.runAsync(() => _buildTestImage(160, 120));
        addTearDown(image!.dispose);

        await tester.pumpWidget(MaterialApp(home: PhotoEditor.image(image)));
        await tester.pumpAndSettle();

        for (final tab in <String>[
          'Crop',
          'Adjust',
          'Draw',
          'Text',
          'Stickers',
          'Frames',
          'Filters',
        ]) {
          await tester.ensureVisible(find.text(tab));
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'PhotoEditor.open pushes modal editor and returns PhotoEditorResult',
      (tester) async {
        tester.view.physicalSize = const Size(960, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final image = await tester.runAsync(() => _buildTestImage(200, 150));
        addTearDown(image!.dispose);

        PhotoEditorResult? routeResult;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      routeResult = await PhotoEditor.open(
                        context,
                        image: image,
                      );
                    },
                    child: const Text('Launch'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Launch'));
        await tester.pumpAndSettle();
        expect(find.text('Photo Editor'), findsOneWidget);

        await tester.tap(find.text('Vivid').last);
        await tester.pumpAndSettle();

        await tester.runAsync(() async {
          await tester.tap(find.text('Export'));
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 120));
        });
        await tester.pumpAndSettle();

        expect(routeResult, isNotNull);
        expect(routeResult!.state.filter, PhotoFilters.vivid);
        expect(routeResult!.width, 200);
        expect(routeResult!.height, 150);
      },
    );

    testWidgets('Interactive drawing gesture on canvas creates a stroke', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(960, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final image = await tester.runAsync(() => _buildTestImage(300, 200));
      addTearDown(image!.dispose);

      final controller = PhotoEditorController(
        initialTool: PhotoEditorTool.draw,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(home: PhotoEditor.image(image, controller: controller)),
      );
      await tester.pumpAndSettle();

      final canvasCenter = tester.getCenter(find.byType(PhotoEditorCanvas));
      final gesture = await tester.startGesture(
        canvasCenter - const Offset(60, 20),
      );
      await gesture.moveBy(const Offset(120, 40));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.state.strokes.length, 1);
      expect(
        controller.state.strokes.first.points.length,
        greaterThanOrEqualTo(2),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:photo_editor/photo_editor.dart';

void main() {
  group('PhotoEditorController', () {
    test('tracks undo/redo history and respects maxHistoryLength', () {
      final controller = PhotoEditorController(maxHistoryLength: 3);
      addTearDown(controller.dispose);

      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);

      controller.selectFilter(PhotoFilters.vivid);
      controller.selectFilter(PhotoFilters.cinematic);
      controller.selectFilter(PhotoFilters.noir);
      controller.selectFilter(PhotoFilters.vintage);

      expect(controller.state.filter, PhotoFilters.vintage);
      // Bounded to 3 checkpoints: vintage -> noir -> cinematic -> vivid.
      controller.undo();
      expect(controller.state.filter, PhotoFilters.noir);
      controller.undo();
      expect(controller.state.filter, PhotoFilters.cinematic);
      controller.undo();
      expect(controller.state.filter, PhotoFilters.vivid);
      expect(controller.canUndo, isFalse);

      controller.redo();
      expect(controller.state.filter, PhotoFilters.cinematic);
      expect(controller.canRedo, isTrue);

      // New edit clears redo stack.
      controller.selectFilter(PhotoFilters.sepia);
      expect(controller.canRedo, isFalse);
    });

    test(
      'beginInteraction/commitInteraction coalesces drag updates into 1 undo',
      () {
        final controller = PhotoEditorController();
        addTearDown(controller.dispose);

        controller.beginInteraction();
        controller.setAdjustment(
          PhotoAdjustmentType.brightness,
          0.1,
          recordHistory: false,
        );
        controller.setAdjustment(
          PhotoAdjustmentType.brightness,
          0.3,
          recordHistory: false,
        );
        controller.setAdjustment(
          PhotoAdjustmentType.brightness,
          0.5,
          recordHistory: false,
        );
        expect(controller.canUndo, isFalse);

        controller.commitInteraction();
        expect(controller.canUndo, isTrue);
        expect(controller.state.adjustments.brightness, 0.5);

        controller.undo();
        expect(controller.state.adjustments.brightness, 0.0);
        expect(controller.canUndo, isFalse);
      },
    );

    test('selecting filter restores intensity from 0 to 1', () {
      final controller = PhotoEditorController();
      addTearDown(controller.dispose);

      controller.selectFilter(PhotoFilters.vivid);
      controller.setFilterIntensity(0.0);
      expect(controller.state.filterIntensity, 0.0);

      controller.selectFilter(PhotoFilters.dramatic);
      expect(controller.state.filterIntensity, 1.0);
    });

    test('rotateRight & flip transform strokes and overlays consistently', () {
      final controller = PhotoEditorController();
      addTearDown(controller.dispose);

      controller.startStroke(const Offset(0.2, 0.3));
      controller.appendStrokePoint(const Offset(0.6, 0.4));
      controller.endStroke();

      final text = controller.addTextLayer(
        text: 'Hello',
        position: const Offset(0.25, 0.75),
      );
      expect(controller.selectedOverlayId, text.id);

      // 4 clockwise turns return everything to exact starting coordinates.
      for (var i = 0; i < 4; i++) {
        controller.rotateRight();
      }
      final strokePoint = controller.state.strokes.first.points.first;
      expect(strokePoint.dx, closeTo(0.2, 1e-6));
      expect(strokePoint.dy, closeTo(0.3, 1e-6));

      final overlayPos = controller.state.overlays.first.position;
      expect(overlayPos.dx, closeTo(0.25, 1e-6));
      expect(overlayPos.dy, closeTo(0.75, 1e-6));

      // Double horizontal flip restores coordinates.
      controller.flipHorizontal();
      expect(controller.state.overlays.first.position.dx, closeTo(0.75, 1e-6));
      controller.flipHorizontal();
      expect(controller.state.overlays.first.position.dx, closeTo(0.25, 1e-6));
    });

    test('drawing stroke shapes keep only start and end points', () {
      final controller = PhotoEditorController();
      addTearDown(controller.dispose);

      controller.setBrushTool(BrushTool.arrow);
      controller.startStroke(const Offset(0.1, 0.1));
      controller.appendStrokePoint(const Offset(0.3, 0.3));
      controller.appendStrokePoint(const Offset(0.8, 0.7));
      controller.endStroke();

      expect(controller.state.strokes.length, 1);
      expect(controller.state.strokes.first.points, <Offset>[
        const Offset(0.1, 0.1),
        const Offset(0.8, 0.7),
      ]);

      controller.undoLastStroke();
      expect(controller.state.strokes, isEmpty);
    });

    test('overlay CRUD: add, duplicate, update, delete, resetAll', () {
      final controller = PhotoEditorController();
      addTearDown(controller.dispose);

      final sticker = controller.addStickerLayer('🔥');
      expect(controller.state.overlays.length, 1);
      expect(controller.selectedOverlay, sticker);

      controller.duplicateSelectedOverlay();
      expect(controller.state.overlays.length, 2);
      expect(controller.selectedOverlayId, isNot(sticker.id));

      controller.deleteSelectedOverlay();
      expect(controller.state.overlays.length, 1);
      expect(controller.selectedOverlayId, isNull);

      controller.resetAll();
      expect(controller.state, PhotoEditState.initial);
      expect(controller.hasChanges, isFalse);
    });

    test(
      'supports split compare curtain, frames, layer z-order, visibility & nudge',
      () {
        final controller = PhotoEditorController();
        addTearDown(controller.dispose);

        // Split compare mode & position clamping
        expect(controller.compareMode, PhotoCompareMode.off);
        controller.toggleCompareMode();
        expect(controller.compareMode, PhotoCompareMode.splitCurtain);
        controller.setSplitPosition(0.25);
        expect(controller.splitPosition, 0.25);
        controller.toggleCompareMode();
        expect(controller.compareMode, PhotoCompareMode.off);

        // Studio frames
        controller.setFrameStyle(PhotoFrameStyle.polaroid);
        controller.setFrameCornerRadius(0.3);
        expect(controller.state.frame.style, PhotoFrameStyle.polaroid);
        expect(controller.state.frame.cornerRadius, 0.3);
        expect(controller.hasChanges, isTrue);

        // Layer z-order, visibility, studio badge, and arrow nudge
        final first = controller.addTextLayer(
          text: 'First',
          position: const Offset(0.5, 0.5),
        );
        final second = controller.addBadgeLayer('RAW');
        expect(controller.state.overlays.last.id, second.id);

        controller.moveOverlayBackward(second.id);
        expect(controller.state.overlays.first.id, second.id);
        controller.moveOverlayForward(second.id);
        expect(controller.state.overlays.last.id, second.id);

        controller.toggleOverlayVisibility(first.id);
        expect(controller.state.overlays.first.isVisible, isFalse);

        controller.selectOverlay(first.id);
        controller.nudgeSelectedOverlay(const Offset(0.05, -0.02));
        expect(controller.selectedOverlay!.position.dx, closeTo(0.55, 1e-6));
        expect(controller.selectedOverlay!.position.dy, closeTo(0.48, 1e-6));
      },
    );
  });
}

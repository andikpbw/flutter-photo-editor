import 'package:flutter/widgets.dart';

import '../../models/photo_editor_labels.dart';
import '../../models/photo_editor_theme.dart';
import '../controls/studio_primitives.dart';

/// Modal studio dialog for entering or editing multi-line overlay text, built
/// purely on `flutter/widgets.dart`.
class TextEditorDialog extends StatefulWidget {
  /// Creates a [TextEditorDialog].
  const TextEditorDialog({
    super.key,
    required this.theme,
    required this.labels,
    this.initialText = '',
    this.isEditing = false,
  });

  /// Visual theme tokens.
  final PhotoEditorTheme theme;

  /// Localizable labels.
  final PhotoEditorLabels labels;

  /// Pre-filled text when editing an existing text overlay.
  final String initialText;

  /// Whether editing an existing overlay (`true`) or adding a new one (`false`).
  final bool isEditing;

  /// Opens the dialog and resolves to the trimmed entered string, or `null` if
  /// cancelled or empty.
  static Future<String?> show(
    BuildContext context, {
    required PhotoEditorTheme theme,
    required PhotoEditorLabels labels,
    String initialText = '',
    bool isEditing = false,
  }) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: labels.cancel,
      barrierColor: StudioColors.black.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (dialogContext, _, _) => TextEditorDialog(
        theme: theme,
        labels: labels,
        initialText: initialText,
        isEditing: isEditing,
      ),
      transitionBuilder: (_, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<TextEditorDialog> createState() => _TextEditorDialogState();
}

class _TextEditorDialogState extends State<TextEditorDialog> {
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _textController.addListener(_handleTextChanged);
    _focusNode.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_handleTextChanged);
    _focusNode.removeListener(_handleTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _textController.text.trim();
    Navigator.of(context).pop(trimmed.isEmpty ? null : trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return DefaultTextStyle(
      style: TextStyle(
        color: theme.primaryTextColor,
        fontSize: 14,
        decoration: TextDecoration.none,
      ),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + viewInsets.bottom),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.borderColor),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: StudioColors.black.withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      widget.isEditing
                          ? widget.labels.editText
                          : widget.labels.addText,
                      style: TextStyle(
                        color: theme.primaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _focusNode.requestFocus,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 72),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.elevatedSurfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _focusNode.hasFocus
                                ? theme.accentColor
                                : theme.borderColor,
                            width: _focusNode.hasFocus ? 1.5 : 1.0,
                          ),
                        ),
                        child: Stack(
                          children: <Widget>[
                            if (_textController.text.isEmpty)
                              IgnorePointer(
                                child: Text(
                                  widget.labels.textPlaceholder,
                                  style: TextStyle(
                                    color: theme.secondaryTextColor,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            EditableText(
                              controller: _textController,
                              focusNode: _focusNode,
                              autofocus: true,
                              maxLines: 4,
                              minLines: 2,
                              style: TextStyle(
                                color: theme.primaryTextColor,
                                fontSize: 15,
                                height: 1.35,
                              ),
                              cursorColor: theme.accentColor,
                              backgroundCursorColor: theme.elevatedSurfaceColor,
                              selectionColor: theme.accentColor.withValues(
                                alpha: 0.35,
                              ),
                              onSubmitted: (_) => _submit(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        StudioButton(
                          label: widget.labels.cancel,
                          foregroundColor: theme.secondaryTextColor,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        StudioButton(
                          label: widget.isEditing
                              ? widget.labels.done
                              : widget.labels.addText,
                          backgroundColor: theme.accentColor,
                          foregroundColor: theme.onAccentColor,
                          fontWeight: FontWeight.w700,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

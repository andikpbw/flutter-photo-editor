import 'package:flutter/material.dart';

import '../../models/photo_editor_labels.dart';
import '../../models/photo_editor_theme.dart';

/// Modal studio dialog for entering or editing multi-line overlay text.
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
    return showDialog<String>(
      context: context,
      builder: (context) => TextEditorDialog(
        theme: theme,
        labels: labels,
        initialText: initialText,
        isEditing: isEditing,
      ),
    );
  }

  @override
  State<TextEditorDialog> createState() => _TextEditorDialogState();
}

class _TextEditorDialogState extends State<TextEditorDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _textController.text.trim();
    Navigator.of(context).pop(trimmed.isEmpty ? null : trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Dialog(
      backgroundColor: theme.surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
              TextField(
                controller: _textController,
                autofocus: true,
                maxLines: 4,
                minLines: 2,
                style: TextStyle(color: theme.primaryTextColor, fontSize: 15),
                cursorColor: theme.accentColor,
                decoration: InputDecoration(
                  hintText: widget.labels.textPlaceholder,
                  hintStyle: TextStyle(color: theme.secondaryTextColor),
                  filled: true,
                  fillColor: theme.elevatedSurfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: theme.accentColor,
                      width: 1.5,
                    ),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.secondaryTextColor,
                    ),
                    child: Text(widget.labels.cancel),
                  ),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.accentColor,
                      foregroundColor: theme.onAccentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      widget.isEditing ? 'Save' : widget.labels.addText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../app_controller.dart';
import '../bible_api.dart';
import '../marks.dart';
import '../theme.dart';
import 'share_verse_screen.dart';

/// Bottom sheet shown when a verse is tapped: highlight, note, share, copy.
Future<void> showVerseActions(BuildContext context, AppController controller, BibleVerse verse) {
  final reference = '${controller.reference}:${verse.number}';
  final quote = '“${verse.text}” — $reference (${controller.language.edition})';

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => ListenableBuilder(
      listenable: controller,
      builder: (_, __) {
        final mark = controller.markFor(verse.number);
        final hasNote = mark?.note != null && mark!.note!.isNotEmpty;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reference, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Text(verse.text, style: const TextStyle(fontFamily: scriptureFont, fontSize: 19, height: 1.45)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    for (final color in HighlightColor.values) ...[
                      _ColorDot(
                        color: color.color,
                        selected: mark?.color == color,
                        label: color.label,
                        onTap: () => controller.setHighlight(verse.number, mark?.color == color ? null : color),
                      ),
                      const SizedBox(width: 10),
                    ],
                    const Spacer(),
                    if (mark?.color != null)
                      TextButton(onPressed: () => controller.setHighlight(verse.number, null), child: const Text('Clear')),
                  ],
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(hasNote ? Icons.sticky_note_2_rounded : Icons.sticky_note_2_outlined, color: hasNote ? Brand.gold : null),
                  title: Text(hasNote ? 'Edit note' : 'Add note'),
                  subtitle: hasNote ? Text(mark!.note!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                  onTap: () => editNote(sheetContext, controller, verse.number, reference),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Share as image'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ShareVerseScreen(text: verse.text, reference: reference, edition: controller.language.edition),
                    ));
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Share text'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Share.share(quote, subject: reference);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.content_copy_rounded),
                  title: const Text('Copy verse'),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: quote));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verse copied')));
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Dialog for writing or changing the note on a verse.
Future<void> editNote(BuildContext context, AppController controller, int verse, String reference) async {
  final existing = controller.markFor(verse)?.note ?? '';
  final field = TextEditingController(text: existing);
  final result = await showDialog<String?>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Note on $reference'),
      content: TextField(
        controller: field,
        autofocus: true,
        minLines: 3,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'What does this verse say to you?', border: OutlineInputBorder()),
      ),
      actions: [
        if (existing.isNotEmpty)
          TextButton(onPressed: () => Navigator.pop(dialogContext, ''), child: const Text('Delete')),
        TextButton(onPressed: () => Navigator.pop(dialogContext, null), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, field.text), child: const Text('Save')),
      ],
    ),
  );
  field.dispose();
  if (result == null) return;
  controller.setNote(verse, result);
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.selected, required this.label, required this.onTap});
  final Color color;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: selected ? Brand.ink : Colors.black12, width: selected ? 2.5 : 1),
            ),
            child: selected ? const Icon(Icons.check_rounded, size: 20, color: Brand.ink) : null,
          ),
        ),
      );
}

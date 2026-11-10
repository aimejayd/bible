import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../bible_api.dart';
import '../language.dart';
import '../theme.dart';
import 'book_picker.dart';
import 'sheets.dart';

class ReadScreen extends StatefulWidget {
  const ReadScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  final _scroll = ScrollController();
  Future<BibleChapter?>? _chapter;
  String? _loadedKey;

  AppController get c => widget.controller;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _ensureLoaded() {
    if (_loadedKey == c.key) return;
    _loadedKey = c.key;
    _chapter = c.loadChapter(c.language, c.book, c.chapter);
  }

  @override
  Widget build(BuildContext context) {
    _ensureLoaded();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => pickPassage(context, c),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(c.reference,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: scriptureFont, fontSize: 24, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.expand_more_rounded),
              ],
            ),
          ),
        ),
        actions: [
          _LanguageChip(controller: c),
          IconButton(tooltip: 'Text size', icon: const Icon(Icons.text_fields_rounded), onPressed: () => showTextSizeSheet(context, c)),
          IconButton(
            tooltip: c.isSaved ? 'Remove from saved' : 'Save chapter',
            icon: Icon(c.isSaved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined),
            color: c.isSaved ? Brand.gold : null,
            onPressed: () {
              c.toggleSaved();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(c.isSaved ? '${c.reference} saved' : '${c.reference} removed from saved')));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<BibleChapter?>(
        future: _chapter,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final chapter = snapshot.data;
          if (chapter == null) return _Unavailable(language: c.language);
          return ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            children: [
              Text(c.language.bookName(c.book).toUpperCase(),
                  style: TextStyle(letterSpacing: 2.2, fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurfaceVariant)),
              Text('${c.chapter}',
                  style: TextStyle(fontFamily: scriptureFont, fontSize: 72, height: 1.1, color: theme.brightness == Brightness.dark ? Brand.gold : Brand.green)),
              const SizedBox(height: 4),
              const SizedBox(width: 40, child: Divider(color: Brand.gold, thickness: 2, height: 2)),
              const SizedBox(height: 20),
              if (c.language == BibleLanguage.kinyarwanda) const _PreviewNotice(),
              ...chapter.verses.map((v) => _VerseView(verse: v, controller: c)),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (c.hasPrevious)
                    OutlinedButton.icon(onPressed: c.previous, icon: const Icon(Icons.arrow_back_rounded), label: const Text('Previous')),
                  const Spacer(),
                  if (c.hasNext)
                    FilledButton.icon(onPressed: c.next, icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Next')),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  c.language == BibleLanguage.kinyarwanda ? '${c.language.edition} · Preview' : '${c.language.edition} · Public domain',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VerseView extends StatelessWidget {
  const _VerseView({required this.verse, required this.controller});
  final BibleVerse verse;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = 21 * controller.textScale;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onLongPress: () => _actions(context),
      onTap: () => _actions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
              text: '${verse.number}  ',
              style: TextStyle(fontSize: size * .58, fontWeight: FontWeight.w700, color: theme.brightness == Brightness.dark ? Brand.gold : Brand.goldInk),
            ),
            TextSpan(text: verse.text),
          ]),
          style: TextStyle(fontFamily: scriptureFont, fontSize: size, height: 1.55, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }

  void _actions(BuildContext context) {
    final reference = '${controller.reference}:${verse.number}';
    final quote = '“${verse.text}” — $reference (${controller.language.edition})';
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reference, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 10),
              Text(verse.text, style: const TextStyle(fontFamily: scriptureFont, fontSize: 19, height: 1.45)),
              const SizedBox(height: 16),
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
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: ActionChip(
          tooltip: 'Reading language',
          label: Text(controller.language.short, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
          avatar: const Icon(Icons.translate_rounded, size: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onPressed: () => showLanguageSheet(context, controller),
        ),
      );
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Brand.gold.withValues(alpha: .15), borderRadius: BorderRadius.circular(14)),
        child: const Text('Kinyarwanda preview: Genesis 1 only. The full Bibiliya Yera is coming once licensing with the Bible Society of Rwanda is in place.'),
      );
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.language});
  final BibleLanguage language;

  @override
  Widget build(BuildContext context) {
    final kin = language == BibleLanguage.kinyarwanda;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(kin ? Icons.hourglass_top_rounded : Icons.cloud_off_rounded, size: 52, color: Brand.gold),
            const SizedBox(height: 16),
            Text(kin ? 'Coming soon in Kinyarwanda' : 'Chapter not available',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              kin
                  ? 'Only Genesis 1 is available as a preview for now. Switch to English or Français to read the whole Bible.'
                  : 'This chapter could not be loaded. Check your connection and try again.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

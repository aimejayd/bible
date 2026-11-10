import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../bible_api.dart';
import '../language.dart';
import '../theme.dart';
import 'book_picker.dart';
import 'search_screen.dart';
import 'sheets.dart';
import 'verse_actions.dart';

class ReadScreen extends StatefulWidget {
  const ReadScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  final _scroll = ScrollController();
  final _verseKeys = <int, GlobalKey>{};
  Future<BibleChapter?>? _chapter;
  String? _loadedKey;
  int? _flashVerse;

  AppController get c => widget.controller;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _ensureLoaded() {
    if (_loadedKey == c.key) return;
    _loadedKey = c.key;
    _verseKeys.clear();
    _chapter = c.loadChapter(c.language, c.book, c.chapter);
  }

  /// After a chapter from search or the library is shown, scroll to its verse and flash it.
  void _scrollToPending() {
    final verse = c.pendingVerse;
    if (verse == null) return;
    c.pendingVerse = null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final target = _verseKeys[verse]?.currentContext;
      if (target == null || !mounted) return;
      await Scrollable.ensureVisible(target, alignment: .2, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
      if (!mounted) return;
      setState(() => _flashVerse = verse);
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (mounted) setState(() => _flashVerse = null);
    });
  }

  void _swipe(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v < -400 && c.hasNext) {
      c.next();
    } else if (v > 400 && c.hasPrevious) {
      c.previous();
    }
  }

  void _openSearch() => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SearchScreen(controller: c, onOpen: () {}),
      ));

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
          IconButton(tooltip: 'Search', icon: const Icon(Icons.search_rounded), onPressed: _openSearch),
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
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              if (value == 'size') showTextSizeSheet(context, c);
              if (value == 'top') _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'size', child: ListTile(leading: Icon(Icons.text_fields_rounded), title: Text('Text size'))),
              PopupMenuItem(value: 'top', child: ListTile(leading: Icon(Icons.vertical_align_top_rounded), title: Text('Back to top'))),
            ],
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: _swipe,
        child: FutureBuilder<BibleChapter?>(
          future: _chapter,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final chapter = snapshot.data;
            if (chapter == null) return _Unavailable(language: c.language);
            for (final v in chapter.verses) {
              _verseKeys.putIfAbsent(v.number, GlobalKey.new);
            }
            _scrollToPending();
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
                ...chapter.verses.map((v) => _VerseView(key: _verseKeys[v.number], verse: v, controller: c, flash: _flashVerse == v.number)),
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
      ),
    );
  }
}

class _VerseView extends StatelessWidget {
  const _VerseView({super.key, required this.verse, required this.controller, required this.flash});
  final BibleVerse verse;
  final AppController controller;
  final bool flash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final size = 21 * controller.textScale;
    final mark = controller.markFor(verse.number);
    final hasNote = mark?.note != null && mark.note!.isNotEmpty;
    final highlight = mark?.color == null ? null : (dark ? mark!.color!.dim : mark!.color!.color);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: flash ? Brand.gold.withValues(alpha: .3) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showVerseActions(context, controller, verse),
        onLongPress: () => showVerseActions(context, controller, verse),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: '${verse.number}  ',
                style: TextStyle(fontSize: size * .58, fontWeight: FontWeight.w700, color: dark ? Brand.gold : Brand.goldInk),
              ),
              TextSpan(text: verse.text, style: highlight == null ? null : TextStyle(backgroundColor: highlight)),
              if (hasNote)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.sticky_note_2_rounded, size: size * .7, color: dark ? Brand.gold : Brand.goldInk),
                  ),
                ),
            ]),
            style: TextStyle(fontFamily: scriptureFont, fontSize: size, height: 1.55, color: theme.colorScheme.onSurface),
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

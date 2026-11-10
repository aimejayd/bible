import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../bible_catalog.dart';
import '../language.dart';
import '../theme.dart';

/// Opens the book and chapter picker. Returns true if the reader moved to a new passage.
Future<bool> pickPassage(BuildContext context, AppController controller, {BibleBook? startBook}) async {
  final result = await Navigator.of(context).push<(BibleBook, int)>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BookPickerPage(
        language: controller.language,
        current: controller.book,
        currentChapter: controller.chapter,
        startBook: startBook ?? controller.book,
      ),
    ),
  );
  if (result == null) return false;
  controller.openPassage(result.$1, result.$2);
  return true;
}

class BookPickerPage extends StatefulWidget {
  const BookPickerPage({super.key, required this.language, required this.current, required this.currentChapter, required this.startBook});
  final BibleLanguage language;
  final BibleBook current;
  final int currentChapter;
  final BibleBook startBook;

  @override
  State<BookPickerPage> createState() => _BookPickerPageState();
}

class _BookPickerPageState extends State<BookPickerPage> {
  final _startKey = GlobalKey();
  String _query = '';
  late BibleBook? _open = widget.startBook;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _startKey.currentContext;
      if (target != null) Scrollable.ensureVisible(target, alignment: .1);
    });
  }

  bool _matches(BibleBook book) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return widget.language.bookName(book).toLowerCase().contains(q) || book.name.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final oldTestament = bibleBooks.take(39).where(_matches).toList();
    final newTestament = bibleBooks.skip(39).where(_matches).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a passage', style: TextStyle(fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() {
                _query = value.trim();
                final hits = bibleBooks.where(_matches).toList();
                _open = hits.length == 1 ? hits.first : (_query.isEmpty ? widget.startBook : null);
              }),
              decoration: InputDecoration(
                hintText: 'Search books',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (oldTestament.isNotEmpty) ...[const SectionLabel('Old Testament'), ...oldTestament.map(_bookRow), const SizedBox(height: 20)],
          if (newTestament.isNotEmpty) ...[const SectionLabel('New Testament'), ...newTestament.map(_bookRow)],
          if (oldTestament.isEmpty && newTestament.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: Text('No book matches your search.'))),
        ],
      ),
    );
  }

  Widget _bookRow(BibleBook book) {
    final theme = Theme.of(context);
    final open = _open == book;
    final isCurrent = book == widget.current;
    final chapters = widget.language.chapterCount(book);
    return Padding(
      key: book == widget.startBook ? _startKey : null,
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
              title: Text(widget.language.bookName(book),
                  style: TextStyle(fontWeight: FontWeight.w700, color: isCurrent ? theme.colorScheme.primary : null)),
              subtitle: Text('$chapters ${chapters == 1 ? 'chapter' : 'chapters'}'),
              trailing: AnimatedRotation(turns: open ? .5 : 0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.expand_more_rounded)),
              onTap: () => setState(() => _open = open ? null : book),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: !open
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(chapters, (i) {
                          final n = i + 1;
                          final selected = isCurrent && n == widget.currentChapter;
                          return SizedBox(
                            width: 48,
                            height: 44,
                            child: FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: selected ? Brand.green : null,
                                foregroundColor: selected ? Colors.white : null,
                              ),
                              onPressed: () => Navigator.of(context).pop((book, n)),
                              child: Text('$n', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          );
                        }),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

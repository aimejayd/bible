import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../bible_catalog.dart';
import '../language.dart';
import '../theme.dart';

/// Saved chapters, highlights and notes.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.controller, required this.onOpen});
  final AppController controller;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Library', style: TextStyle(fontFamily: scriptureFont, fontSize: 28, fontWeight: FontWeight.w700)),
            bottom: const TabBar(
              tabs: [Tab(text: 'Chapters'), Tab(text: 'Highlights'), Tab(text: 'Notes')],
              indicatorColor: Brand.gold,
            ),
          ),
          body: TabBarView(
            children: [
              _Chapters(controller: controller, onOpen: onOpen),
              _Marks(controller: controller, onOpen: onOpen, notes: false),
              _Marks(controller: controller, onOpen: onOpen, notes: true),
            ],
          ),
        ),
      );
}

class _Chapters extends StatelessWidget {
  const _Chapters({required this.controller, required this.onOpen});
  final AppController controller;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final items = controller.saved.map(_parse).whereType<_SavedItem>().toList()
      ..sort((a, b) => a.book.number != b.book.number ? a.book.number - b.book.number : a.chapter - b.chapter);
    if (items.isEmpty) {
      return const _Empty(icon: Icons.bookmarks_outlined, title: 'No saved chapters yet', text: 'Tap the bookmark while reading to keep a chapter here.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = items[i];
        return _Swipe(
          id: item.key,
          onRemove: () => controller.removeSaved(item.key),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              leading: const Icon(Icons.bookmark_rounded, color: Brand.gold),
              title: Text('${item.language.bookName(item.book)} ${item.chapter}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              subtitle: Text('${item.language.label} · ${item.language.edition}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                controller.openPassage(item.book, item.chapter, inLanguage: item.language);
                onOpen();
              },
            ),
          ),
        );
      },
    );
  }

  static _SavedItem? _parse(String key) {
    final parts = key.split('_');
    if (parts.length != 3) return null;
    final language = BibleLanguage.values.where((l) => l.name == parts[0]);
    final number = int.tryParse(parts[1]);
    final chapter = int.tryParse(parts[2]);
    if (language.isEmpty || number == null || chapter == null || number < 1 || number > bibleBooks.length) return null;
    return _SavedItem(key, language.first, bibleBooks[number - 1], chapter);
  }
}

class _SavedItem {
  const _SavedItem(this.key, this.language, this.book, this.chapter);
  final String key;
  final BibleLanguage language;
  final BibleBook book;
  final int chapter;
}

class _Marks extends StatelessWidget {
  const _Marks({required this.controller, required this.onOpen, required this.notes});
  final AppController controller;
  final VoidCallback onOpen;

  /// True for the Notes tab, false for Highlights.
  final bool notes;

  @override
  Widget build(BuildContext context) {
    final items = controller.marks.values.where((m) => notes ? (m.note != null && m.note!.isNotEmpty) : m.color != null).toList()
      ..sort((a, b) => b.updated.compareTo(a.updated));
    if (items.isEmpty) {
      return notes
          ? const _Empty(icon: Icons.sticky_note_2_outlined, title: 'No notes yet', text: 'Tap a verse while reading and choose "Add note".')
          : const _Empty(icon: Icons.format_color_fill_rounded, title: 'No highlights yet', text: 'Tap a verse while reading and pick a colour.');
    }
    final language = controller.language;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final mark = items[i];
        final book = bibleBooks[mark.book - 1];
        final reference = '${language.bookName(book)} ${mark.chapter}:${mark.verse}';
        return _Swipe(
          id: mark.key,
          onRemove: () => controller.removeMark(mark.key),
          child: Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                controller.openPassage(book, mark.chapter, verse: mark.verse);
                onOpen();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (mark.color != null)
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(color: mark.color!.color, shape: BoxShape.circle),
                          ),
                        Expanded(child: Text(reference, style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary))),
                        Text(_when(mark.updated), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    if (notes) ...[
                      const SizedBox(height: 6),
                      Text(mark.note!, style: const TextStyle(fontSize: 16, height: 1.4)),
                    ],
                    const SizedBox(height: 6),
                    FutureBuilder<String?>(
                      future: controller.verseText(language.code == null ? BibleLanguage.english : language, mark.book, mark.chapter, mark.verse),
                      builder: (context, snapshot) => Text(
                        snapshot.data ?? '',
                        maxLines: notes ? 2 : 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: scriptureFont,
                          fontSize: notes ? 15 : 18,
                          height: 1.4,
                          color: notes ? Theme.of(context).colorScheme.onSurfaceVariant : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _when(DateTime time) {
    final days = DateTime.now().difference(time).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 30) return '$days days ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}

class _Swipe extends StatelessWidget {
  const _Swipe({required this.id, required this.onRemove, required this.child});
  final String id;
  final VoidCallback onRemove;
  final Widget child;

  @override
  Widget build(BuildContext context) => Dismissible(
        key: ValueKey(id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        onDismissed: (_) => onRemove(),
        child: child,
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title, text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Brand.gold),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(text, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
}

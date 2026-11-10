import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../bible_catalog.dart';
import '../language.dart';
import '../theme.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key, required this.controller, required this.onOpen});
  final AppController controller;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final items = controller.saved.map(_parse).whereType<_SavedItem>().toList()
      ..sort((a, b) => a.book.number != b.book.number ? a.book.number - b.book.number : a.chapter - b.chapter);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved', style: TextStyle(fontFamily: scriptureFont, fontSize: 28, fontWeight: FontWeight.w700))),
      body: items.isEmpty
          ? const _Empty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = items[i];
                return Dismissible(
                  key: ValueKey(item.key),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) => controller.removeSaved(item.key),
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
            ),
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

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bookmarks_outlined, size: 56, color: Brand.gold),
              const SizedBox(height: 16),
              const Text('No saved chapters yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Tap the bookmark while reading to keep a chapter here.',
                  textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
}

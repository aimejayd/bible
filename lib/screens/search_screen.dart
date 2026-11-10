import 'dart:async';

import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../bible_catalog.dart';
import '../language.dart';
import '../search.dart';
import '../theme.dart';

/// Searches the whole Bible in the current reading language.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.controller, required this.onOpen});
  final AppController controller;

  /// Called after a result is opened in the reader.
  final VoidCallback onOpen;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _field = TextEditingController();
  Timer? _debounce;
  int _testament = 0;
  String _query = '';
  List<SearchHit>? _hits;

  AppController get c => widget.controller;

  // Kinyarwanda has no full text yet, so its searches run on English.
  BibleLanguage get _language => c.language.code == null ? BibleLanguage.english : c.language;

  @override
  void dispose() {
    _debounce?.cancel();
    _field.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(value));
  }

  Future<void> _run(String value) async {
    final query = value.trim();
    setState(() {
      _query = query;
      _hits = null;
    });
    if (query.length < 2) return;
    final index = await c.searchIndex(_language);
    if (index == null || !mounted || _query != query) return;
    setState(() => _hits = index.search(query, testament: _testament));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _field,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: _run,
          decoration: InputDecoration(
            hintText: 'Search the Bible in ${_language.label}',
            border: InputBorder.none,
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _field.clear();
                      _run('');
                    },
                  ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                for (final (i, label) in ['Whole Bible', 'Old Testament', 'New Testament'].indexed) ...[
                  ChoiceChip(
                    label: Text(label),
                    selected: _testament == i,
                    onSelected: (_) {
                      setState(() => _testament = i);
                      _run(_field.text);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ),
      body: _body(theme),
    );
  }

  Widget _body(ThemeData theme) {
    if (_query.length < 2) {
      return _Hint(
        icon: Icons.search_rounded,
        title: 'Search every verse',
        text: 'Type a word or a phrase, for example "shepherd", "berger" or "do not fear". Accents do not matter.',
      );
    }
    final hits = _hits;
    if (hits == null) return const Center(child: CircularProgressIndicator());
    if (hits.isEmpty) return _Hint(icon: Icons.search_off_rounded, title: 'No verses found', text: 'Try fewer words or a different spelling.');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: hits.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Text(
              hits.length >= 300 ? 'First 300 verses' : '${hits.length} ${hits.length == 1 ? 'verse' : 'verses'}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          );
        }
        final hit = hits[i - 1];
        final book = bibleBooks[hit.entry.book - 1];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              c.openPassage(book, hit.entry.chapter, inLanguage: _language, verse: hit.entry.verse);
              Navigator.of(context).pop();
              widget.onOpen();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_language.bookName(book)} ${hit.entry.chapter}:${hit.entry.verse}',
                      style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(children: _highlighted(hit, theme)),
                    style: const TextStyle(fontFamily: scriptureFont, fontSize: 18, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<InlineSpan> _highlighted(SearchHit hit, ThemeData theme) {
    final text = hit.entry.text;
    final spans = <InlineSpan>[];
    var at = 0;
    final mark = TextStyle(
      backgroundColor: Brand.gold.withValues(alpha: theme.brightness == Brightness.dark ? .45 : .35),
      fontWeight: FontWeight.w700,
    );
    for (final (start, end) in hit.ranges) {
      if (start > at) spans.add(TextSpan(text: text.substring(at, start)));
      spans.add(TextSpan(text: text.substring(start, end), style: mark));
      at = end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return spans;
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title, text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: Brand.gold),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(text, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
}

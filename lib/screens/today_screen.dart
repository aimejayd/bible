import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../bible_catalog.dart';
import '../daily_verse.dart';
import '../language.dart';
import '../theme.dart';
import 'book_picker.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.controller, required this.onRead});
  final AppController controller;
  final VoidCallback onRead;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: Brand.green, borderRadius: BorderRadius.circular(13)),
                child: Image.asset('assets/brand/mark.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text('Ijambo Bible', style: theme.textTheme.headlineSmall?.copyWith(fontFamily: scriptureFont, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _VerseOfTheDay(controller: controller, onRead: onRead),
          const SizedBox(height: 28),
          const SectionLabel('Continue reading'),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              leading: const _IconBadge(icon: Icons.menu_book_rounded),
              title: Text(controller.reference, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              subtitle: Text('${controller.language.edition} · ${controller.language.label}'),
              trailing: const Icon(Icons.arrow_forward_rounded),
              onTap: onRead,
            ),
          ),
          const SizedBox(height: 28),
          const SectionLabel('Explore'),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  icon: Icons.history_edu_rounded,
                  title: 'Old Testament',
                  subtitle: '39 books',
                  onTap: () => _browse(context, testament: 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(
                  icon: Icons.auto_stories_rounded,
                  title: 'New Testament',
                  subtitle: '27 books',
                  onTap: () => _browse(context, testament: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Center(
            child: Text('English · Français · Kinyarwanda',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: .4)),
          ),
        ],
      ),
    );
  }

  Future<void> _browse(BuildContext context, {required int testament}) async {
    final picked = await pickPassage(context, controller, startBook: testament == 0 ? bibleBooks.first : bibleBooks[39]);
    if (picked) onRead();
  }
}

class _VerseOfTheDay extends StatefulWidget {
  const _VerseOfTheDay({required this.controller, required this.onRead});
  final AppController controller;
  final VoidCallback onRead;

  @override
  State<_VerseOfTheDay> createState() => _VerseOfTheDayState();
}

class _VerseOfTheDayState extends State<_VerseOfTheDay> {
  final (int, int, int) _ref = verseForToday();
  Future<String?>? _text;
  BibleLanguage? _loadedFor;

  // Kinyarwanda has no licensed full text yet, so it shows its own Psalm 23:1.
  static const _kinyarwandaVerse = 'Uwiteka ni we mwungeri wanjye, sinzakena.';

  BibleLanguage get _language => widget.controller.language;

  @override
  Widget build(BuildContext context) {
    if (_loadedFor != _language) {
      _loadedFor = _language;
      _text = _language == BibleLanguage.kinyarwanda
          ? Future.value(_kinyarwandaVerse)
          : widget.controller.verseText(_language, _ref.$1, _ref.$2, _ref.$3);
    }
    final kin = _language == BibleLanguage.kinyarwanda;
    final book = bibleBooks[(kin ? 19 : _ref.$1) - 1];
    final reference = '${_language.bookName(book)} ${kin ? 23 : _ref.$2}:${kin ? 1 : _ref.$3}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A6556), Brand.green, Brand.greenDeep]),
        boxShadow: [BoxShadow(color: Brand.green.withValues(alpha: .25), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_sunny_rounded, color: Brand.gold, size: 16),
              SizedBox(width: 8),
              Text('VERSE OF THE DAY', style: TextStyle(color: Brand.gold, letterSpacing: 1.4, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<String?>(
            future: _text,
            builder: (context, snapshot) {
              final text = snapshot.data == null ? null : tidyVerse(snapshot.data!);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: text == null
                      ? const SizedBox(height: 64, key: ValueKey('loading'))
                      : Text('“$text”',
                          key: ValueKey(text),
                          style: const TextStyle(color: Colors.white, fontFamily: scriptureFont, fontSize: 24, height: 1.35)),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(reference, style: const TextStyle(color: Color(0xFFDCEBE5), fontWeight: FontWeight.w700))),
              IconButton(
                tooltip: 'Copy',
                color: Colors.white,
                icon: const Icon(Icons.content_copy_rounded, size: 20),
                onPressed: () async {
                  final text = await _text;
                  if (text == null || !context.mounted) return;
                  await Clipboard.setData(ClipboardData(text: '“${tidyVerse(text)}” — $reference (${_language.edition})'));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verse copied')));
                  }
                },
              ),
              if (!kin)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () {
                    widget.controller.openPassage(book, _ref.$2);
                    widget.onRead();
                  },
                  child: const Text('Read chapter'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBadge(icon: icon),
                const SizedBox(height: 14),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: dark ? Brand.green : const Color(0xFFE3EEE9), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: dark ? Brand.gold : Brand.green, size: 22),
    );
  }
}

import 'package:flutter/material.dart';

import 'bible_api.dart';
import 'bible_catalog.dart';
import 'bible_storage.dart';
import 'bundled_bible.dart';

void main() => runApp(const IjamboApp());

class IjamboApp extends StatefulWidget {
  const IjamboApp({super.key});
  @override
  State<IjamboApp> createState() => _IjamboAppState();
}

class _IjamboAppState extends State<IjamboApp> {
  final _storage = BibleStorage();
  bool _dark = false;
  @override
  void initState() { super.initState(); _restore(); }
  Future<void> _restore() async { final dark = await _storage.darkMode(); if (mounted) setState(() => _dark = dark); }
  Future<void> _setDark(bool value) async { setState(() => _dark = value); await _storage.setDarkMode(value); }
  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF255D50);
    final theme = ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: _dark ? Brightness.dark : Brightness.light, surface: _dark ? const Color(0xFF16211E) : const Color(0xFFFFFCF6)), scaffoldBackgroundColor: _dark ? const Color(0xFF16211E) : const Color(0xFFFFFCF6), appBarTheme: AppBarTheme(backgroundColor: _dark ? const Color(0xFF16211E) : const Color(0xFFFFFCF6), elevation: 0, scrolledUnderElevation: 0), cardTheme: CardThemeData(elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))));
    return MaterialApp(title: 'Ijambo Bible', debugShowCheckedModeBanner: false, theme: theme, home: BibleHome(storage: _storage, darkMode: _dark, onDarkMode: _setDark));
  }
}

enum BibleLanguage { english, french, kinyarwanda }
extension BibleLanguageDetails on BibleLanguage {
  String get label => switch (this) { BibleLanguage.english => 'English', BibleLanguage.french => 'Français', BibleLanguage.kinyarwanda => 'Kinyarwanda' };
  String get edition => switch (this) { BibleLanguage.english => 'World English Bible', BibleLanguage.french => 'Bible Darby', BibleLanguage.kinyarwanda => 'Bibiliya Yera' };
  String? get code => switch (this) { BibleLanguage.english => 'web', BibleLanguage.french => 'darby', BibleLanguage.kinyarwanda => null };
  String bookName(BibleBook book) => this == BibleLanguage.french ? frenchBookNames[book.number - 1] : book.name;
  int chapterCount(BibleBook book) => this == BibleLanguage.french ? frenchChapterCounts[book.number] ?? book.chapters : book.chapters;
}

class BibleHome extends StatefulWidget {
  const BibleHome({super.key, required this.storage, required this.darkMode, required this.onDarkMode});
  final BibleStorage storage; final bool darkMode; final ValueChanged<bool> onDarkMode;
  @override
  State<BibleHome> createState() => _BibleHomeState();
}

class _BibleHomeState extends State<BibleHome> {
  final _api = BibleApi();
  final _bundle = BundledBible();
  BibleLanguage _language = BibleLanguage.english;
  BibleBook _book = bibleBooks.first;
  int _chapterNumber = 1, _page = 0;
  BibleChapter? _chapter;
  bool _loading = true;
  String? _notice;
  Set<String> _saved = {};
  String get _key => '${_language.name}_${_book.number}_$_chapterNumber';
  bool get _isSaved => _saved.contains(_key);

  @override
  void initState() { super.initState(); _restoreSaved(); _load(); }
  Future<void> _restoreSaved() async { final saved = await widget.storage.savedChapters(); if (mounted) setState(() => _saved = saved); }
  Future<void> _load() async {
    final key = _key;
    if (_language == BibleLanguage.kinyarwanda) {
      setState(() { _loading = false; _chapter = _book.number == 1 && _chapterNumber == 1 ? _kinyarwandaSample : null; _notice = 'Kinyarwanda is ready for its approved Bible Society of Rwanda / DBL connection. Genesis 1 is a local preview.'; });
      return;
    }
    setState(() { _loading = true; _notice = null; });
    final bundled = await _bundle.chapter(edition: _language.code!, bookNumber: _book.number, chapterNumber: _chapterNumber, bookName: _language.bookName(_book));
    if (bundled != null) {
      if (mounted && key == _key) setState(() { _chapter = bundled; _loading = false; });
      return;
    }
    final cached = await widget.storage.chapter(key);
    if (cached != null && mounted && key == _key) setState(() { _chapter = cached; _loading = false; _notice = 'Available offline'; });
    try {
      final chapter = await _api.fetchChapter(translationCode: _language.code!, bookNumber: _book.number, chapterNumber: _chapterNumber);
      await widget.storage.saveChapter(key, chapter);
      if (mounted && key == _key) setState(() { _chapter = chapter; _loading = false; _notice = 'Downloaded for offline reading'; });
    } catch (_) {
      if (mounted && key == _key) setState(() { _loading = false; _notice = cached == null ? 'Connect to the internet to load this chapter.' : 'Offline copy shown.'; });
    }
  }

  Future<void> _pickLanguage() async {
    final picked = await showModalBottomSheet<BibleLanguage>(context: context, showDragHandle: true, builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), child: Column(mainAxisSize: MainAxisSize.min, children: [const Align(alignment: Alignment.centerLeft, child: Text('Reading language', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800))), const SizedBox(height: 8), ...BibleLanguage.values.map((language) => RadioListTile(value: language, groupValue: _language, contentPadding: EdgeInsets.zero, title: Text(language.label), subtitle: Text(language.edition), onChanged: (value) => Navigator.pop(context, value)))]))));
    if (picked != null && picked != _language) { setState(() { _language = picked; _chapterNumber = _chapterNumber.clamp(1, picked.chapterCount(_book)); }); _load(); }
  }

  Future<void> _pickPassage([BibleBook? chosen]) async {
    final book = chosen ?? await showModalBottomSheet<BibleBook>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => _BookPicker(language: _language, selected: _book));
    if (book == null || !mounted) return;
    final chapter = await showModalBottomSheet<int>(context: context, showDragHandle: true, builder: (_) => _ChapterPicker(language: _language, book: book, selected: book == _book ? _chapterNumber : 1));
    if (chapter == null) return;
    setState(() { _book = book; _chapterNumber = chapter; _page = 0; }); _load();
  }
  Future<void> _toggleSaved() async { final next = !_isSaved; setState(() { next ? _saved.add(_key) : _saved.remove(_key); }); await widget.storage.setSaved(_key, next); }
  void _next() {
    if (_chapterNumber < _language.chapterCount(_book)) {
      setState(() => _chapterNumber++);
    } else if (_book.number < bibleBooks.length) {
      setState(() { _book = bibleBooks[_book.number]; _chapterNumber = 1; });
    } else {
      return;
    }
    _load();
  }
  void _search() => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => _ChapterSearch(chapter: _chapter));

  @override
  Widget build(BuildContext context) {
    final pages = [_Reader(language: _language, book: _book, chapterNumber: _chapterNumber, chapter: _chapter, loading: _loading, notice: _notice, saved: _isSaved, onLanguage: _pickLanguage, onPassage: _pickPassage, onSave: _toggleSaved, onNext: _next), _Books(language: _language, onPick: _pickPassage), _Saved(saved: _saved, onPick: _pickPassage), _Settings(language: _language, dark: widget.darkMode, onLanguage: _pickLanguage, onDark: widget.onDarkMode)];
    return Scaffold(appBar: AppBar(title: const _Brand(), actions: [IconButton(onPressed: _search, icon: const Icon(Icons.search_rounded), tooltip: 'Search this chapter'), const SizedBox(width: 4)]), body: SafeArea(top: false, child: IndexedStack(index: _page, children: pages)), bottomNavigationBar: NavigationBar(selectedIndex: _page, onDestinationSelected: (value) => setState(() => _page = value), destinations: const [NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Read'), NavigationDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books), label: 'Books'), NavigationDestination(icon: Icon(Icons.bookmark_outline), selectedIcon: Icon(Icons.bookmark), label: 'Saved'), NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: 'Settings')]));
  }
}

class _Reader extends StatelessWidget {
  const _Reader({required this.language, required this.book, required this.chapterNumber, required this.chapter, required this.loading, required this.notice, required this.saved, required this.onLanguage, required this.onPassage, required this.onSave, required this.onNext});
  final BibleLanguage language; final BibleBook book; final int chapterNumber; final BibleChapter? chapter; final bool loading, saved; final String? notice; final VoidCallback onLanguage, onPassage, onSave, onNext;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 32), children: [_DailyVerse(language: language), const SizedBox(height: 24), Row(children: [Expanded(child: _SelectButton(label: language.label, icon: Icons.translate_rounded, onTap: onLanguage)), const SizedBox(width: 10), Expanded(child: _SelectButton(label: '${language.bookName(book)} $chapterNumber', icon: Icons.keyboard_arrow_down_rounded, onTap: onPassage))]), const SizedBox(height: 26), Row(children: [Expanded(child: Text(chapter?.bookName ?? language.bookName(book), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontFamily: 'serif', fontWeight: FontWeight.w700))), IconButton(onPressed: onSave, icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded), color: const Color(0xFFC7752E))]), Text('CHAPTER $chapterNumber  •  ${language.edition.toUpperCase()}', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w800)), const SizedBox(height: 16), if (loading) const LinearProgressIndicator(), if (notice != null) Padding(padding: const EdgeInsets.only(top: 12, bottom: 6), child: Text(notice!, style: Theme.of(context).textTheme.bodySmall)), const SizedBox(height: 14), if (!loading && chapter == null) const _EmptyReader(), ...?chapter?.verses.map((verse) => _Verse(number: verse.number, text: verse.text)), if (chapter != null) const SizedBox(height: 8), if (chapter != null) if (chapterNumber < language.chapterCount(book) || book.number < bibleBooks.length) FilledButton.icon(onPressed: onNext, icon: const Icon(Icons.arrow_forward_rounded), label: Text(chapterNumber < language.chapterCount(book) ? 'Next chapter' : 'Next book'))]);
}

class _Verse extends StatelessWidget { const _Verse({required this.number, required this.text}); final int number; final String text; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 19), child: RichText(text: TextSpan(style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: 'serif', height: 1.48), children: [TextSpan(text: '$number ', style: const TextStyle(color: Color(0xFFC7752E), fontFamily: 'sans-serif', fontWeight: FontWeight.w800, fontSize: 13)), TextSpan(text: text)]))); }
class _DailyVerse extends StatelessWidget { const _DailyVerse({required this.language}); final BibleLanguage language; @override Widget build(BuildContext context) { final text = switch (language) { BibleLanguage.english => '“The Lord is my shepherd; I shall not want.”', BibleLanguage.french => '“L’Éternel est mon berger: je ne manquerai de rien.”', BibleLanguage.kinyarwanda => '“Uwiteka ni we mwungeri wanjye, sinzakena.”' }; return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF255D50), borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('VERSE OF THE DAY', style: TextStyle(color: Color(0xFFDDEBE5), letterSpacing: 1.1, fontSize: 11, fontWeight: FontWeight.w700)), const SizedBox(height: 9), Text(text, style: const TextStyle(color: Colors.white, fontFamily: 'serif', fontSize: 23, height: 1.25)), const SizedBox(height: 12), const Text('Psalm 23:1', style: TextStyle(color: Color(0xFFDDEBE5), fontWeight: FontWeight.w700))])); } }

class _Books extends StatelessWidget { const _Books({required this.language, required this.onPick}); final BibleLanguage language; final ValueChanged<BibleBook> onPick; @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [Text('Books', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontFamily: 'serif', fontWeight: FontWeight.w700)), const SizedBox(height: 4), const Text('Choose a book and chapter'), const SizedBox(height: 20), _BookSection(title: 'OLD TESTAMENT', language: language, books: bibleBooks.take(39), onPick: onPick), const SizedBox(height: 24), _BookSection(title: 'NEW TESTAMENT', language: language, books: bibleBooks.skip(39), onPick: onPick)]); }
class _BookSection extends StatelessWidget {
  const _BookSection({required this.title, required this.language, required this.books, required this.onPick});
  final String title;
  final BibleLanguage language;
  final Iterable<BibleBook> books;
  final ValueChanged<BibleBook> onPick;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w800, color: const Color(0xFF255D50))),
          const SizedBox(height: 8),
          ...books.map((book) => Card(child: ListTile(title: Text(language.bookName(book), style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${language.chapterCount(book)} chapters'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => onPick(book)))),
        ],
      );
}

class _Saved extends StatelessWidget { const _Saved({required this.saved, required this.onPick}); final Set<String> saved; final ValueChanged<BibleBook> onPick; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Saved', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontFamily: 'serif', fontWeight: FontWeight.w700)), const SizedBox(height: 20), if (saved.isEmpty) const Expanded(child: _EmptySaved()) else Expanded(child: ListView.separated(itemCount: saved.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, index) { final parts = saved.elementAt(index).split('_'); final book = bibleBooks.firstWhere((item) => item.number == int.parse(parts[1])); return Card(child: ListTile(leading: const Icon(Icons.bookmark_rounded, color: Color(0xFFC7752E)), title: Text('${book.name} ${parts[2]}'), subtitle: Text(parts[0]), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => onPick(book))); }))])); }

class _Settings extends StatelessWidget { const _Settings({required this.language, required this.dark, required this.onLanguage, required this.onDark}); final BibleLanguage language; final bool dark; final VoidCallback onLanguage; final ValueChanged<bool> onDark; @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [Text('Settings', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontFamily: 'serif', fontWeight: FontWeight.w700)), const SizedBox(height: 22), Card(child: ListTile(leading: const Icon(Icons.translate_rounded), title: const Text('Reading language'), subtitle: Text(language.label), trailing: const Icon(Icons.chevron_right_rounded), onTap: onLanguage)), const SizedBox(height: 10), Card(child: SwitchListTile(secondary: const Icon(Icons.dark_mode_outlined), title: const Text('Dark appearance'), subtitle: Text(dark ? 'Easy on your eyes at night' : 'Bright reading experience'), value: dark, onChanged: onDark)), const SizedBox(height: 10), const Card(child: ListTile(leading: Icon(Icons.download_done_outlined), title: Text('Works offline'), subtitle: Text('The full English and French Bibles are on your phone'))), const SizedBox(height: 24), Text('ABOUT', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w800, color: const Color(0xFF255D50))), const SizedBox(height: 6), const Card(child: ListTile(title: Text('Ijambo Bible'), subtitle: Text('English · Français · Kinyarwanda'))), const SizedBox(height: 10), const Card(child: ListTile(title: Text('Bible texts'), subtitle: Text('World English Bible and Bible Darby (1885) are in the public domain.')))]); }

class _BookPicker extends StatelessWidget { const _BookPicker({required this.language, required this.selected}); final BibleLanguage language; final BibleBook selected; @override Widget build(BuildContext context) => SafeArea(child: SizedBox(height: MediaQuery.sizeOf(context).height * .72, child: Column(children: [const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 12), child: Align(alignment: Alignment.centerLeft, child: Text('Choose a book', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)))), Expanded(child: GridView.builder(padding: const EdgeInsets.all(20), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3.1, crossAxisSpacing: 10, mainAxisSpacing: 10), itemCount: bibleBooks.length, itemBuilder: (_, index) { final book = bibleBooks[index]; return FilledButton.tonal(onPressed: () => Navigator.pop(context, book), style: FilledButton.styleFrom(backgroundColor: book == selected ? const Color(0xFF255D50) : null, foregroundColor: book == selected ? Colors.white : null), child: Text(language.bookName(book), overflow: TextOverflow.ellipsis)); }))]))); }
class _ChapterPicker extends StatelessWidget {
  const _ChapterPicker({required this.language, required this.book, required this.selected});
  final BibleLanguage language;
  final BibleBook book;
  final int selected;
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${language.bookName(book)} chapters', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              SizedBox(
                height: 310,
                child: GridView.count(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: List.generate(language.chapterCount(book), (index) {
                    final number = index + 1;
                    return FilledButton.tonal(
                      onPressed: () => Navigator.pop(context, number),
                      style: FilledButton.styleFrom(padding: EdgeInsets.zero, backgroundColor: number == selected ? const Color(0xFF255D50) : null, foregroundColor: number == selected ? Colors.white : null),
                      child: Text('$number'),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ChapterSearch extends StatefulWidget { const _ChapterSearch({required this.chapter}); final BibleChapter? chapter; @override State<_ChapterSearch> createState() => _ChapterSearchState(); }
class _ChapterSearchState extends State<_ChapterSearch> { String _query = ''; @override Widget build(BuildContext context) { final matches = widget.chapter?.verses.where((verse) => verse.text.toLowerCase().contains(_query.toLowerCase())).toList() ?? []; return SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24), child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(autofocus: true, onChanged: (value) => setState(() => _query = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search this chapter', border: OutlineInputBorder())), const SizedBox(height: 14), SizedBox(height: 280, child: _query.isEmpty ? const Center(child: Text('Search the chapter currently open.')) : matches.isEmpty ? const Center(child: Text('No verses found.')) : ListView.separated(itemCount: matches.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (_, index) => ListTile(title: Text('${matches[index].number}', style: const TextStyle(color: Color(0xFFC7752E), fontWeight: FontWeight.w800)), subtitle: Text(matches[index].text))))]))); } }

class _SelectButton extends StatelessWidget { const _SelectButton({required this.label, required this.icon, required this.onTap}); final String label; final IconData icon; final VoidCallback onTap; @override Widget build(BuildContext context) => OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 18), label: Text(label, overflow: TextOverflow.ellipsis), style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15))); }
class _Brand extends StatelessWidget { const _Brand(); @override Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_rounded, color: Color(0xFFC7752E)), SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('IJAMBO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.6, fontSize: 17)), Text('Holy Bible', style: TextStyle(fontSize: 11))])]); }
class _EmptyReader extends StatelessWidget { const _EmptyReader(); @override Widget build(BuildContext context) => const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Center(child: Text('This chapter will be available when the Kinyarwanda edition is connected.', textAlign: TextAlign.center))); }
class _EmptySaved extends StatelessWidget { const _EmptySaved(); @override Widget build(BuildContext context) => const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bookmark_border_rounded, size: 54, color: Color(0xFF9AA7A2)), SizedBox(height: 14), Text('No saved chapters yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)), SizedBox(height: 6), Text('Save a chapter from the reader for quick return.', textAlign: TextAlign.center)])); }
const _kinyarwandaSample = BibleChapter(bookName: 'Itangiriro', chapter: 1, verses: [BibleVerse(number: 1, text: 'Mu ntangiriro Imana yaremye ijuru n’isi.'), BibleVerse(number: 2, text: 'Isi yari itagira ishusho kandi irimo ubusa, umwijima wari hejuru y’amazi maremare; Umwuka w’Imana yagendagendaga hejuru y’amazi.'), BibleVerse(number: 3, text: 'Imana iravuga iti: Habe umucyo; umucyo ubaho.'), BibleVerse(number: 4, text: 'Imana ibona umucyo ko ari mwiza, Imana itandukanya umucyo n’umwijima.'), BibleVerse(number: 5, text: 'Imana yita umucyo Amanywa, umwijima iwita Ijoro. Buragoroba buracya, uwo ni umunsi wa mbere.')]);

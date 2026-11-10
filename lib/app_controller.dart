import 'package:flutter/material.dart';

import 'bible_api.dart';
import 'bible_catalog.dart';
import 'bible_storage.dart';
import 'bundled_bible.dart';
import 'language.dart';

/// App-wide state: settings, where the reader is, and saved chapters.
class AppController extends ChangeNotifier {
  AppController(this.storage);

  final BibleStorage storage;
  final _bundle = BundledBible();
  final _api = BibleApi();

  ThemeMode themeMode = ThemeMode.system;
  double textScale = 1.0;
  BibleLanguage language = BibleLanguage.english;
  BibleBook book = bibleBooks.first;
  int chapter = 1;
  Set<String> saved = {};

  String get key => keyFor(language, book, chapter);
  static String keyFor(BibleLanguage language, BibleBook book, int chapter) =>
      '${language.name}_${book.number}_$chapter';

  bool get isSaved => saved.contains(key);
  String get reference => '${language.bookName(book)} $chapter';
  bool get hasNext => chapter < language.chapterCount(book) || book.number < bibleBooks.length;
  bool get hasPrevious => chapter > 1 || book.number > 1;

  Future<void> load() async {
    themeMode = switch (await storage.themeMode()) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    textScale = await storage.textScale();
    saved = await storage.savedChapters();
    final parts = (await storage.position())?.split('|');
    if (parts != null && parts.length == 3) {
      final lang = BibleLanguage.values.where((l) => l.name == parts[0]);
      final number = int.tryParse(parts[1]) ?? 1;
      if (lang.isNotEmpty) language = lang.first;
      book = bibleBooks[(number - 1).clamp(0, bibleBooks.length - 1)];
      chapter = (int.tryParse(parts[2]) ?? 1).clamp(1, language.chapterCount(book));
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
    storage.setThemeMode(mode.name);
  }

  void setTextScale(double value) {
    textScale = value;
    notifyListeners();
    storage.setTextScale(value);
  }

  void setLanguage(BibleLanguage value) {
    if (value == language) return;
    language = value;
    chapter = chapter.clamp(1, language.chapterCount(book));
    _changed();
  }

  void openPassage(BibleBook newBook, int newChapter, {BibleLanguage? inLanguage}) {
    if (inLanguage != null) language = inLanguage;
    book = newBook;
    chapter = newChapter.clamp(1, language.chapterCount(newBook));
    _changed();
  }

  void next() {
    if (chapter < language.chapterCount(book)) {
      openPassage(book, chapter + 1);
    } else if (book.number < bibleBooks.length) {
      openPassage(bibleBooks[book.number], 1);
    }
  }

  void previous() {
    if (chapter > 1) {
      openPassage(book, chapter - 1);
    } else if (book.number > 1) {
      final before = bibleBooks[book.number - 2];
      openPassage(before, language.chapterCount(before));
    }
  }

  void toggleSaved() {
    saved = {...saved};
    saved.contains(key) ? saved.remove(key) : saved.add(key);
    notifyListeners();
    storage.setSavedChapters(saved);
  }

  void removeSaved(String savedKey) {
    saved = {...saved}..remove(savedKey);
    notifyListeners();
    storage.setSavedChapters(saved);
  }

  void _changed() {
    notifyListeners();
    storage.setPosition('${language.name}|${book.number}|$chapter');
  }

  /// Loads a chapter: bundled text first, then a previously downloaded copy, then GetBible.
  Future<BibleChapter?> loadChapter(BibleLanguage lang, BibleBook b, int c) async {
    final code = lang.code;
    if (code == null) return b.number == 1 && c == 1 ? kinyarwandaGenesis1 : null;
    final bundled = await _bundle.chapter(edition: code, bookNumber: b.number, chapterNumber: c, bookName: lang.bookName(b));
    if (bundled != null) return bundled;
    final cacheKey = keyFor(lang, b, c);
    final cached = await storage.chapter(cacheKey);
    if (cached != null) return cached;
    try {
      final fetched = await _api.fetchChapter(translationCode: code, bookNumber: b.number, chapterNumber: c);
      await storage.saveChapter(cacheKey, fetched);
      return fetched;
    } catch (_) {
      return null;
    }
  }

  /// Text of one verse, or null if it is not available.
  Future<String?> verseText(BibleLanguage lang, int bookNumber, int chapterNumber, int verse) async {
    final loaded = await loadChapter(lang, bibleBooks[bookNumber - 1], chapterNumber);
    for (final v in loaded?.verses ?? const <BibleVerse>[]) {
      if (v.number == verse) return v.text;
    }
    return null;
  }
}

/// Kinyarwanda preview until the Bible Society of Rwanda text is licensed.
const kinyarwandaGenesis1 = BibleChapter(bookName: 'Itangiriro', chapter: 1, verses: [
  BibleVerse(number: 1, text: 'Mu ntangiriro Imana yaremye ijuru n’isi.'),
  BibleVerse(number: 2, text: 'Isi yari itagira ishusho kandi irimo ubusa, umwijima wari hejuru y’amazi maremare; Umwuka w’Imana yagendagendaga hejuru y’amazi.'),
  BibleVerse(number: 3, text: 'Imana iravuga iti: Habe umucyo; umucyo ubaho.'),
  BibleVerse(number: 4, text: 'Imana ibona umucyo ko ari mwiza, Imana itandukanya umucyo n’umwijima.'),
  BibleVerse(number: 5, text: 'Imana yita umucyo Amanywa, umwijima iwita Ijoro. Buragoroba buracya, uwo ni umunsi wa mbere.'),
]);

import 'package:flutter/material.dart';

import 'bible_api.dart';
import 'bible_catalog.dart';
import 'bible_storage.dart';
import 'bundled_bible.dart';
import 'daily_verse.dart';
import 'language.dart';
import 'marks.dart';
import 'notifications.dart';
import 'search.dart';

/// App-wide state: settings, where the reader is, and saved chapters.
class AppController extends ChangeNotifier {
  AppController(this.storage);

  final BibleStorage storage;
  final _bundle = BundledBible();
  final _api = BibleApi();
  final _notifications = VerseNotifications();

  ThemeMode themeMode = ThemeMode.system;
  double textScale = 1.0;
  BibleLanguage language = BibleLanguage.english;
  BibleBook book = bibleBooks.first;
  int chapter = 1;
  Set<String> saved = {};
  DailyVerses dailyVerses = DailyVerses.empty;
  bool reminderEnabled = false;
  TimeOfDay reminderTime = const TimeOfDay(hour: 7, minute: 0);
  Map<String, VerseMark> marks = {};
  bool keepScreenOn = true;

  /// Verse the reader should scroll to after opening a chapter (from search or notes).
  int? pendingVerse;

  final _searchIndexes = <String, Future<SearchIndex>>{};

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
    dailyVerses = await DailyVerses.load();
    reminderEnabled = await storage.reminderEnabled();
    final minutes = await storage.reminderMinutes();
    reminderTime = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    marks = VerseMark.decodeAll(await storage.marks());
    keepScreenOn = await storage.keepScreenOn();
    final parts = (await storage.position())?.split('|');
    if (parts != null && parts.length == 3) {
      final lang = BibleLanguage.values.where((l) => l.name == parts[0]);
      final number = int.tryParse(parts[1]) ?? 1;
      if (lang.isNotEmpty) language = lang.first;
      book = bibleBooks[(number - 1).clamp(0, bibleBooks.length - 1)];
      chapter = (int.tryParse(parts[2]) ?? 1).clamp(1, language.chapterCount(book));
    }
    notifyListeners();
    if (reminderEnabled) _scheduleReminders();
  }

  /// Turns the morning verse notification on or off. Returns false if the phone refused permission.
  Future<bool> setReminderEnabled(bool value) async {
    if (value && !await _notifications.requestPermission()) return false;
    reminderEnabled = value;
    notifyListeners();
    await storage.setReminderEnabled(value);
    value ? await _scheduleReminders() : await _notifications.cancelAll();
    return true;
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    reminderTime = time;
    notifyListeners();
    await storage.setReminderMinutes(time.hour * 60 + time.minute);
    if (reminderEnabled) await _scheduleReminders();
  }

  /// Schedules the next two weeks of morning verses in the reading language.
  Future<void> _scheduleReminders() async {
    try {
      // Kinyarwanda has no full text yet, so its reminders use English.
      final lang = language.code == null ? BibleLanguage.english : language;
      final now = DateTime.now();
      final reminders = <VerseReminder>[];
      for (var day = 0; reminders.length < 14 && day < 15; day++) {
        final date = DateTime(now.year, now.month, now.day + day, reminderTime.hour, reminderTime.minute);
        if (!date.isAfter(now)) continue;
        final ref = dailyVerses.forDate(date);
        final text = await verseText(lang, ref.$1, ref.$2, ref.$3);
        if (text == null) continue;
        final reference = '${lang.bookName(bibleBooks[ref.$1 - 1])} ${ref.$2}:${ref.$3}';
        final feast = dailyVerses.feastName(date);
        reminders.add(VerseReminder(when: date, title: feast == null ? reference : '$feast · $reference', body: tidyVerse(text)));
      }
      await _notifications.schedule(reminders);
    } catch (e) {
      debugPrint('Could not schedule verse reminders: $e');
    }
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
    if (reminderEnabled) _scheduleReminders();
  }

  void openPassage(BibleBook newBook, int newChapter, {BibleLanguage? inLanguage, int? verse}) {
    if (inLanguage != null) language = inLanguage;
    book = newBook;
    chapter = newChapter.clamp(1, language.chapterCount(newBook));
    pendingVerse = verse;
    _changed();
  }

  void setKeepScreenOn(bool value) {
    keepScreenOn = value;
    notifyListeners();
    storage.setKeepScreenOn(value);
  }

  // Highlights and notes -----------------------------------------------------

  VerseMark? markFor(int verse) => marks[VerseMark.keyFor(book.number, chapter, verse)];

  void setHighlight(int verse, HighlightColor? color) {
    final key = VerseMark.keyFor(book.number, chapter, verse);
    final current = marks[key] ?? VerseMark(book: book.number, chapter: chapter, verse: verse, updated: DateTime.now());
    _putMark(key, current.copyWith(color: color, clearColor: color == null));
  }

  void setNote(int verse, String? note) {
    final key = VerseMark.keyFor(book.number, chapter, verse);
    final current = marks[key] ?? VerseMark(book: book.number, chapter: chapter, verse: verse, updated: DateTime.now());
    final trimmed = note?.trim();
    _putMark(key, current.copyWith(note: trimmed, clearNote: trimmed == null || trimmed.isEmpty));
  }

  void removeMark(String key) => _putMark(key, null);

  void _putMark(String key, VerseMark? mark) {
    marks = {...marks};
    if (mark == null || mark.isEmpty) {
      marks.remove(key);
    } else {
      marks[key] = mark;
    }
    notifyListeners();
    storage.setMarks(VerseMark.encodeAll(marks));
  }

  // Search -------------------------------------------------------------------

  /// The search index for [lang], built once per language and kept in memory.
  Future<SearchIndex>? searchIndex(BibleLanguage lang) {
    final code = lang.code;
    if (code == null) return null;
    return _searchIndexes.putIfAbsent(code, () => SearchIndex.load(code));
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

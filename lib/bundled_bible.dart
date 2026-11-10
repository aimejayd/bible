import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'bible_api.dart';

/// Reads the Bible texts shipped inside the app (assets/bibles/<edition>/<book>.json).
///
/// Each book file is `{"c": [[[verse, "text"], ...], ...]}`: one list per
/// chapter, in order, each holding `[verseNumber, text]` pairs. Books are
/// loaded on first use and the most recent few are kept in memory.
class BundledBible {
  static const _keepBooks = 4;
  final _books = <String, List<dynamic>>{};

  Future<BibleChapter?> chapter({
    required String edition,
    required int bookNumber,
    required int chapterNumber,
    required String bookName,
  }) async {
    final key = '$edition/$bookNumber';
    var chapters = _books.remove(key);
    if (chapters == null) {
      try {
        final raw = await rootBundle.loadString('assets/bibles/$key.json');
        chapters = (jsonDecode(raw) as Map<String, dynamic>)['c'] as List<dynamic>;
      } catch (_) {
        return null;
      }
    }
    _books[key] = chapters;
    if (_books.length > _keepBooks) _books.remove(_books.keys.first);

    if (chapterNumber < 1 || chapterNumber > chapters.length) return null;
    final verses = (chapters[chapterNumber - 1] as List<dynamic>).map((item) {
      final pair = item as List<dynamic>;
      return BibleVerse(number: pair[0] as int, text: pair[1] as String);
    }).toList(growable: false);
    return BibleChapter(bookName: bookName, chapter: chapterNumber, verses: verses);
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'bible_catalog.dart';

/// One verse in the search index.
class SearchEntry {
  const SearchEntry(this.book, this.chapter, this.verse, this.text, this.folded);
  final int book, chapter, verse;
  final String text;

  /// Lower-case, accents removed, same length as [text] so match positions line up.
  final String folded;
}

/// A verse that matched, with the character ranges to highlight.
class SearchHit {
  const SearchHit(this.entry, this.ranges, this.exact);
  final SearchEntry entry;
  final List<(int, int)> ranges;

  /// True when the whole query appears as one phrase.
  final bool exact;
}

/// Whole-Bible search over the bundled text of one edition.
class SearchIndex {
  SearchIndex(this.entries);
  final List<SearchEntry> entries;

  /// Loads every book of [edition] from the app's assets.
  static Future<SearchIndex> load(String edition) async {
    final entries = <SearchEntry>[];
    for (final book in bibleBooks) {
      final raw = await rootBundle.loadString('assets/bibles/$edition/${book.number}.json');
      entries.addAll(await compute(_parseBook, (book.number, raw)));
    }
    return SearchIndex(entries);
  }

  static List<SearchEntry> _parseBook((int, String) input) {
    final chapters = (jsonDecode(input.$2) as Map<String, dynamic>)['c'] as List<dynamic>;
    final out = <SearchEntry>[];
    for (var c = 0; c < chapters.length; c++) {
      for (final item in chapters[c] as List<dynamic>) {
        final pair = item as List<dynamic>;
        final text = pair[1] as String;
        out.add(SearchEntry(input.$1, c + 1, pair[0] as int, text, fold(text)));
      }
    }
    return out;
  }

  /// Finds verses containing every word of [query]. Phrase matches come first.
  /// [testament] 0 = whole Bible, 1 = Old Testament, 2 = New Testament.
  List<SearchHit> search(String query, {int testament = 0, int limit = 300}) {
    final folded = fold(query).trim();
    final words = folded.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return const [];
    final exactHits = <SearchHit>[];
    final otherHits = <SearchHit>[];
    for (final e in entries) {
      if (testament == 1 && e.book > 39) break;
      if (testament == 2 && e.book <= 39) continue;
      final ranges = <(int, int)>[];
      var all = true;
      for (final w in words) {
        var at = e.folded.indexOf(w);
        if (at < 0) {
          all = false;
          break;
        }
        while (at >= 0) {
          ranges.add((at, at + w.length));
          at = e.folded.indexOf(w, at + w.length);
        }
      }
      if (!all) continue;
      final exact = words.length == 1 || e.folded.contains(folded);
      ranges.sort((a, b) => a.$1 - b.$1);
      (exact ? exactHits : otherHits).add(SearchHit(e, _merge(ranges), exact));
      if (exactHits.length >= limit) break;
    }
    return [...exactHits, ...otherHits].take(limit).toList();
  }

  static List<(int, int)> _merge(List<(int, int)> ranges) {
    final out = <(int, int)>[];
    for (final r in ranges) {
      if (out.isNotEmpty && r.$1 <= out.last.$2) {
        out[out.length - 1] = (out.last.$1, r.$2 > out.last.$2 ? r.$2 : out.last.$2);
      } else {
        out.add(r);
      }
    }
    return out;
  }
}

const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n', 'ÿ': 'y', 'ý': 'y',
  '’': "'", '‘': "'", '“': '"', '”': '"', ' ': ' ', ' ': ' ',
};

/// Lower-cases and strips accents, keeping the string the same length.
String fold(String text) {
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_accents[ch] ?? ch);
  }
  return buffer.toString();
}

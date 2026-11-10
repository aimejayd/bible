import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'bible_catalog.dart';

/// (book number, chapter, verse)
typedef VerseRef = (int, int, int);

/// Picks the verse of the day from assets/verses/daily_verses.json.
///
/// * Feast days around Easter and fixed dates (Christmas, New Year) use the
///   verses listed under "special".
/// * Every other day uses "daily" in order: 1 January is the first entry.
///   The list has 366 entries, so no verse repeats within a year.
class DailyVerses {
  const DailyVerses(this.daily, this.special);

  final List<VerseRef> daily;
  final Map<String, VerseRef> special;

  static const fallback = (19, 23, 1);
  static const empty = DailyVerses([], {});

  static Future<DailyVerses> load() async {
    try {
      final json = jsonDecode(await rootBundle.loadString('assets/verses/daily_verses.json')) as Map<String, dynamic>;
      final daily = (json['daily'] as List<dynamic>).map((e) => parseReference(e as String)).whereType<VerseRef>().toList();
      final special = <String, VerseRef>{};
      (json['special'] as Map<String, dynamic>? ?? {}).forEach((key, value) {
        final ref = parseReference(value as String);
        if (ref != null) special[key] = ref;
      });
      return DailyVerses(daily, special);
    } catch (_) {
      return empty;
    }
  }

  VerseRef forDate(DateTime date) {
    final key = specialKey(date);
    if (key != null && special.containsKey(key)) return special[key]!;
    final mmdd = '${_two(date.month)}-${_two(date.day)}';
    if (special.containsKey(mmdd)) return special[mmdd]!;
    if (daily.isEmpty) return fallback;
    final dayOfYear = DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(date.year)).inDays;
    return daily[dayOfYear % daily.length];
  }

  /// Name of the feast on [date], if it is one the list has a verse for.
  String? feastName(DateTime date) {
    final key = specialKey(date);
    if (key != null && special.containsKey(key)) return easterFeasts[key];
    final mmdd = '${_two(date.month)}-${_two(date.day)}';
    return special.containsKey(mmdd) ? fixedFeasts[mmdd] : null;
  }

  /// 'easter+0', 'easter-2', … relative to Easter Sunday of that year.
  static String? specialKey(DateTime date) {
    final offset = DateTime.utc(date.year, date.month, date.day).difference(easterSunday(date.year)).inDays;
    return offset >= 0 ? 'easter+$offset' : 'easter$offset';
  }

  static const easterFeasts = {
    'easter-7': 'Palm Sunday',
    'easter-2': 'Good Friday',
    'easter-1': 'Holy Saturday',
    'easter+0': 'Easter Sunday',
    'easter+1': 'Easter Monday',
    'easter+39': 'Ascension',
    'easter+49': 'Pentecost',
  };

  static const fixedFeasts = {
    '01-01': 'New Year',
    '12-24': 'Christmas Eve',
    '12-25': 'Christmas',
    '12-26': 'Christmas',
    '12-31': 'Last day of the year',
  };
}

/// Western (Gregorian) Easter Sunday, as a UTC date.
DateTime easterSunday(int year) {
  final a = year % 19, b = year ~/ 100, c = year % 100;
  final d = b ~/ 4, e = b % 4, f = (b + 8) ~/ 25, g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4, k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = (h + l - 7 * m + 114) % 31 + 1;
  return DateTime.utc(year, month, day);
}

/// Parses an English reference like "John 3:16" or "1 Peter 5:7".
VerseRef? parseReference(String text) {
  final match = RegExp(r'^(.+?)\s+(\d+):(\d+)$').firstMatch(text.trim());
  if (match == null) return null;
  final name = match.group(1)!.toLowerCase();
  final books = bibleBooks.where((b) => b.name.toLowerCase() == name || (name == 'psalm' && b.number == 19));
  if (books.isEmpty) return null;
  final book = books.first;
  final chapter = int.parse(match.group(2)!), verse = int.parse(match.group(3)!);
  if (chapter < 1 || chapter > book.chapters || verse < 1) return null;
  return (book.number, chapter, verse);
}

String _two(int n) => n.toString().padLeft(2, '0');

/// Capitalises the first letter and drops a leading dash, so a verse that
/// starts mid-sentence reads well on its own.
String tidyVerse(String text) {
  var t = text.trim();
  if (t.startsWith('–') || t.startsWith('-')) t = t.substring(1).trim();
  return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

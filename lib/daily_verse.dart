/// Verses shown as the verse of the day, one per day in turn.
/// Each is (book number, chapter, verse) and is the same verse in English and French.
const dailyVerses = [
  (19, 23, 1), (43, 3, 16), (50, 4, 13), (20, 3, 5), (23, 41, 10), (24, 29, 11), (45, 8, 28), (40, 11, 28),
  (6, 1, 9), (19, 119, 105), (55, 1, 7), (58, 11, 1), (46, 13, 4), (19, 27, 1), (25, 3, 22), (40, 6, 33),
  (45, 12, 2), (48, 5, 22), (49, 2, 8), (19, 37, 4), (23, 40, 31), (43, 14, 6), (62, 4, 19), (19, 121, 1),
  (45, 15, 13), (51, 3, 23), (19, 91, 1), (33, 6, 8), (59, 1, 5), (20, 16, 3),
];

(int, int, int) verseForToday([DateTime? now]) {
  final today = now ?? DateTime.now();
  final dayOfYear = today.difference(DateTime(today.year)).inDays;
  return dailyVerses[(today.year * 366 + dayOfYear) % dailyVerses.length];
}

/// Capitalises the first letter and drops a leading dash, so a verse that
/// starts mid-sentence reads well on its own.
String tidyVerse(String text) {
  var t = text.trim();
  if (t.startsWith('–') || t.startsWith('-')) t = t.substring(1).trim();
  return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

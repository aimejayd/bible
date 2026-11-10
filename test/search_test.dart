import 'package:flutter_test/flutter_test.dart';

import 'package:ijambo/marks.dart';
import 'package:ijambo/search.dart';

void main() {
  SearchEntry e(int book, int chapter, int verse, String text) => SearchEntry(book, chapter, verse, text, fold(text));

  final index = SearchIndex([
    e(19, 23, 1, 'The LORD is my shepherd; I shall lack nothing.'),
    e(43, 10, 11, 'I am the good shepherd. The good shepherd lays down his life for the sheep.'),
    e(19, 23, 1, 'L’Éternel est mon berger : je ne manquerai de rien.'),
    e(40, 14, 27, 'Cheer up! It is I! Don’t be afraid.'),
    e(43, 14, 27, 'Peace I leave with you. Don’t let your heart be troubled, neither let it be fearful.'),
  ]);

  test('fold removes accents and keeps length', () {
    expect(fold('L’Éternel est mon berger'), "l'eternel est mon berger");
    expect(fold('Éléphant à Noël').length, 'Éléphant à Noël'.length);
  });

  test('search ignores case and accents', () {
    expect(index.search('eternel berger').map((h) => h.entry.book), [19]);
    expect(index.search('SHEPHERD').length, 2);
  });

  test('phrase matches come before scattered word matches', () {
    final hits = index.search('good shepherd');
    expect(hits.first.entry.book, 43);
    expect(hits.first.exact, isTrue);
    expect(hits.first.ranges, [(9, 22), (28, 41)]);
  });

  test('all words must be present', () {
    expect(index.search('shepherd nothing').length, 1);
    expect(index.search('shepherd banana'), isEmpty);
  });

  test('testament filter', () {
    expect(index.search('shepherd', testament: 1).length, 1);
    expect(index.search('shepherd', testament: 2).length, 1);
  });

  test('marks survive a round trip', () {
    final mark = VerseMark(book: 43, chapter: 3, verse: 16, color: HighlightColor.green, note: 'For God so loved', updated: DateTime(2026, 1, 2));
    final decoded = VerseMark.decodeAll(VerseMark.encodeAll({mark.key: mark}));
    expect(decoded[mark.key]!.color, HighlightColor.green);
    expect(decoded[mark.key]!.note, 'For God so loved');
    expect(decoded[mark.key]!.updated, DateTime(2026, 1, 2));
    expect(VerseMark.decodeAll('garbage'), isEmpty);
    expect(mark.copyWith(clearColor: true, clearNote: true).isEmpty, isTrue);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ijambo/daily_verse.dart';
import 'package:ijambo/main.dart';

void main() {
  testWidgets('Splash shows, then the app opens on Today', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const IjamboApp(splashDuration: Duration(milliseconds: 300)));
    await tester.pump();
    expect(find.text('IJAMBO'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('VERSE OF THE DAY'), findsOneWidget);
  });

  group('Verse of the day', () {
    final file = jsonDecode(File('assets/verses/daily_verses.json').readAsStringSync()) as Map<String, dynamic>;
    final verses = DailyVerses(
      (file['daily'] as List).map((e) => parseReference(e as String)!).toList(),
      (file['special'] as Map<String, dynamic>).map((k, v) => MapEntry(k, parseReference(v as String)!)),
    );

    test('every reference in the list is valid and there is one per day', () {
      expect(verses.daily.length, greaterThanOrEqualTo(366));
      expect(verses.daily.toSet().length, verses.daily.length, reason: 'no verse repeats within a year');
    });

    test('Easter dates are right', () {
      expect(easterSunday(2026), DateTime.utc(2026, 4, 5));
      expect(easterSunday(2027), DateTime.utc(2027, 3, 28));
      expect(easterSunday(2030), DateTime.utc(2030, 4, 21));
    });

    test('feast days use their own verse', () {
      expect(verses.forDate(DateTime(2026, 4, 5)), parseReference('Matthew 28:6'));
      expect(verses.feastName(DateTime(2026, 4, 5)), 'Easter Sunday');
      expect(verses.forDate(DateTime(2026, 4, 3)), parseReference('Isaiah 53:5'));
      expect(verses.forDate(DateTime(2026, 12, 25)), parseReference('Luke 2:11'));
      expect(verses.forDate(DateTime(2026, 5, 24)), parseReference('Acts 2:4'));
      expect(verses.feastName(DateTime(2026, 3, 10)), isNull);
    });

    test('ordinary days follow the list and change every day', () {
      expect(verses.forDate(DateTime(2026, 1, 2)), verses.daily[1]);
      expect(verses.forDate(DateTime(2026, 3, 10)), isNot(verses.forDate(DateTime(2026, 3, 11))));
    });

    test('references are parsed', () {
      expect(parseReference('John 3:16'), (43, 3, 16));
      expect(parseReference('1 Peter 5:7'), (60, 5, 7));
      expect(parseReference('Psalm 23:1'), (19, 23, 1));
      expect(parseReference('Nowhere 1:1'), isNull);
    });

    test('verse text is tidied', () {
      expect(tidyVerse('– mais nous savons'), 'Mais nous savons');
    });
  });
}

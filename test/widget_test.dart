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

  test('Verse of the day text is tidied', () {
    expect(tidyVerse('– mais nous savons'), 'Mais nous savons');
    expect(verseForToday(DateTime(2026, 1, 1)), isA<(int, int, int)>());
  });
}

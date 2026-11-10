import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ijambo/main.dart';

void main() {
  testWidgets('App opens on the reader', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const IjamboApp());
    await tester.pump();

    expect(find.text('IJAMBO'), findsOneWidget);
    expect(find.text('VERSE OF THE DAY'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
  });
}

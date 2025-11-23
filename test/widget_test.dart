// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ootech/views/home_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('HomePage renders quick actions', (WidgetTester tester) async {
    // Build our app and trigger a frame wrapped in MaterialApp for theme/directionality.
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );

    // Home page must show the "Atalhos rápidos" header and at least one menu option.
    expect(find.text('Atalhos rápidos'), findsOneWidget);
    // Layout uses Wrap for responsive shortcuts instead of GridView.
    expect(find.byType(Wrap), findsWidgets);
  });
}

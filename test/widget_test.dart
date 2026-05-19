
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cash_in_out/main.dart';

void main() {
  testWidgets('Cash In/Out app loads', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Cash In/Out'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.byIcon(Icons.delete_sweep_outlined), findsOneWidget);
  });
}

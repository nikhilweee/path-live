import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathlive/main.dart';

void main() {
  testWidgets('PATH Live app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('PATH Live'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
  });
}

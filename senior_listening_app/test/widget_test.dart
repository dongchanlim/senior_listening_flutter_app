import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:senior_listening_app/main.dart';

void main() {
  testWidgets('App smoke test - renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const SeniorListeningApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

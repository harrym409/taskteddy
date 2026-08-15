import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:taskteddy_customer/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskTeddyCustomerApp());
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:veltra/core/theme/veltra_theme.dart';

void main() {
  testWidgets('Veltra theme renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VeltraTheme.light,
        home: const Scaffold(
          body: Center(child: Text('Veltra')),
        ),
      ),
    );
    expect(find.text('Veltra'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veltra/core/theme/veltra_theme.dart';
import 'package:veltra/features/checkin/widgets/worker_profile_card.dart';
import 'package:veltra/models/worker.dart';

void main() {
  testWidgets('a worker profile shows height and weight', (tester) async {
    final worker = Worker(
      id: 'avery',
      userId: 'demo',
      name: 'Avery',
      employeeId: 'A-101',
      age: 29,
      heightCm: 168,
      weightKg: 62,
      bmi: 21.97,
      createdAt: DateTime.utc(2026, 11, 23),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: VeltraTheme.light,
        home: Scaffold(body: WorkerProfileCard(worker: worker)),
      ),
    );

    expect(find.text('A-101'), findsOneWidget);
    expect(find.text('29'), findsOneWidget);
    expect(find.text('168 cm'), findsOneWidget);
    expect(find.text('62.0 kg'), findsOneWidget);
    expect(find.textContaining('Normal'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);
  });
}

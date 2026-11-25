import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veltra/core/theme/veltra_theme.dart';
import 'package:veltra/features/checkin/widgets/checkin_saved_view.dart';
import 'package:veltra/models/check_in.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('a cool saved check-in is green', (tester) async {
    final checkIn = CheckIn(
      id: 'check-1',
      attemptId: 'attempt-1',
      crewId: 'crew',
      workerId: 'worker',
      windowId: 'window',
      capturedAt: DateTime.utc(2026, 11, 23, 18, 5),
      source: CheckInSources.simulated,
      foreheadTempC: 36.8,
      stripVolumeUl: 8,
      conductivityUsCm: 640,
      foreheadTempAvailable: true,
      stripVolumeAvailable: true,
      conductivityAvailable: true,
      sweatRateAvailable: false,
    );

    _phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: VeltraTheme.light,
        home: Scaffold(
          body: CheckInSavedView(
            checkIn: checkIn,
            workerName: 'Avery',
            trend: (_) => const Text('Not enough data'),
            onDone: () {},
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('GREEN'), findsOneWidget);
    expect(find.text('Avery'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Continue work'), findsOneWidget);
    expect(find.textContaining('Simulated'), findsOneWidget);
    expect(find.text('Forehead'), findsOneWidget);
    expect(find.text('Strip volume'), findsOneWidget);
    expect(find.text('Conductivity'), findsOneWidget);
    expect(find.text('Sweat rate'), findsOneWidget);
    expect(find.text('36.8 °C'), findsOneWidget);
    expect(find.text('8.0 µL'), findsOneWidget);
    expect(find.text('640 µS/cm'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('Trend'), findsOneWidget);
    expect(find.text('Not enough data'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Check-in saved'), findsNothing);
  });

  testWidgets('a blank strip still has a volume tile', (tester) async {
    final checkIn = CheckIn(
      id: 'check-2',
      attemptId: 'attempt-2',
      crewId: 'crew',
      workerId: 'worker',
      windowId: 'window',
      capturedAt: DateTime.utc(2026, 11, 23, 18, 6),
      source: CheckInSources.simulated,
      foreheadTempC: 36.8,
      foreheadTempAvailable: true,
      stripVolumeAvailable: false,
      conductivityUsCm: 640,
      conductivityAvailable: true,
      sweatRateAvailable: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: VeltraTheme.light,
        home: Scaffold(
          body: CheckInSavedView(
            checkIn: checkIn,
            workerName: 'Avery',
            trend: (_) => const Text('Not enough data'),
            onDone: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Strip volume'), findsOneWidget);
    expect(find.text('Unavailable'), findsNWidgets(2));
    expect(find.text('WBGT'), findsNothing);
  });
}

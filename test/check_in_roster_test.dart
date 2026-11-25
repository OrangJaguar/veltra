import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:veltra/core/demo_crew.dart';
import 'package:veltra/core/demo_mode.dart';
import 'package:veltra/features/checkin/simulated_reading.dart';
import 'package:veltra/models/check_in.dart';
import 'package:veltra/repositories/check_in_repository.dart';
import 'package:veltra/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('veltra_roster_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('one check-in marks only that worker, a timeout does not', () async {
    final service = await DatabaseService.openPath('${tempDir.path}/roster.db');
    final repo = CheckInRepository(service);
    await repo.seedDemoCrew(demoUserId);

    final avery = DemoCrew.workers[0].id;
    final blake = DemoCrew.workers[1].id;

    await repo.saveCheckIn(
      SaveCheckInRequest(
        attemptId: 'avery-1',
        crewId: DemoCrew.crewId,
        workerId: avery,
        windowId: DemoCrew.windowId,
        capturedAt: DateTime.utc(2026, 11, 23, 18),
        source: CheckInSources.simulated,
        foreheadTempC: SimulatedReading.foreheadTempC,
        stripVolumeUl: SimulatedReading.stripVolumeUl,
        conductivityUsCm: SimulatedReading.conductivityUsCm,
      ),
    );
    await repo.recordFailedAttempt(
      attemptId: 'blake-timeout',
      crewId: DemoCrew.crewId,
      workerId: blake,
      windowId: DemoCrew.windowId,
      error: SimulatedReading.timeoutError,
    );

    final roster = await repo.roster(
      crewId: DemoCrew.crewId,
      windowId: DemoCrew.windowId,
    );
    final averyRow = roster.firstWhere((row) => row.worker.id == avery);
    final blakeRow = roster.firstWhere((row) => row.worker.id == blake);

    expect(roster, hasLength(3));
    expect(averyRow.isCheckedIn, isTrue);
    expect(averyRow.latestCheckIn?.source, CheckInSources.simulated);
    expect(blakeRow.isCheckedIn, isFalse);
    expect(await repo.checkInsForWorker(blake), isEmpty);

    await repo.saveCheckIn(
      SaveCheckInRequest(
        attemptId: 'avery-2',
        crewId: DemoCrew.crewId,
        workerId: avery,
        windowId: DemoCrew.windowId,
        capturedAt: DateTime.utc(2026, 11, 23, 19),
        source: CheckInSources.simulated,
        foreheadTempC: SimulatedReading.foreheadTempC,
        stripVolumeUl: SimulatedReading.stripVolumeUl,
        conductivityUsCm: SimulatedReading.conductivityUsCm,
      ),
    );

    final averyHistory = await repo.checkInsForWorker(avery);
    final again = await repo.roster(
      crewId: DemoCrew.crewId,
      windowId: DemoCrew.windowId,
    );
    expect(averyHistory, hasLength(2));
    expect(
      again.where((row) => row.isCheckedIn).length,
      1,
    );
    expect(await service.db.query('sync_queue'), isEmpty);
    await service.db.close();
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:veltra/core/demo_crew.dart';
import 'package:veltra/core/demo_mode.dart';
import 'package:veltra/features/checkin/checkin_scenario.dart';
import 'package:veltra/features/checkin/sweat_rate.dart';
import 'package:veltra/models/roster_entry.dart';
import 'package:veltra/repositories/check_in_repository.dart';
import 'package:veltra/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('veltra_admin_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('scenarios save or fail without erasing a real check-in', () async {
    final service = await DatabaseService.openPath('${tempDir.path}/scenarios.db');
    final repo = CheckInRepository(service);
    await repo.seedDemoCrew(demoUserId);
    final avery = DemoCrew.workers.first.id;

    final temperature = await repo.applyScenario(
      attemptId: 'temp-only',
      crewId: DemoCrew.crewId,
      workerId: avery,
      windowId: DemoCrew.windowId,
      capturedAt: DateTime.utc(2026, 11, 23, 18),
      assignedPodId: null,
      presentedPodId: null,
      scenario: CheckInScenario.temperatureOnly,
    );
    expect(temperature.saved, isTrue);
    expect(temperature.checkIn?.foreheadTempC, 36.8);
    expect(temperature.checkIn?.stripVolumeUl, isNull);
    expect(temperature.checkIn?.conductivityUsCm, isNull);
    expect(temperature.checkIn?.sweatRateUlMin, isNull);

    for (final scenario in [
      CheckInScenario.dryStrip,
      CheckInScenario.poorContact,
      CheckInScenario.timeout,
    ]) {
      final failed = await repo.applyScenario(
        attemptId: scenario.id,
        crewId: DemoCrew.crewId,
        workerId: avery,
        windowId: DemoCrew.windowId,
        capturedAt: DateTime.utc(2026, 11, 23, 18, 5),
        assignedPodId: null,
        presentedPodId: null,
        scenario: scenario,
      );
      expect(failed.saved, isFalse);
      expect(failed.message, scenario.failureMessage);
    }

    final roster = await repo.roster(
      crewId: DemoCrew.crewId,
      windowId: DemoCrew.windowId,
    );
    expect(
      roster.firstWhere((row) => row.worker.id == avery).isCheckedIn,
      isTrue,
    );
    expect(await repo.checkInsForWorker(avery), hasLength(1));
    await service.db.close();
  });

  test('closing a window marks the rest missed, and a new window starts waiting', () async {
    final service = await DatabaseService.openPath('${tempDir.path}/windows.db');
    final repo = CheckInRepository(service);
    await repo.seedDemoCrew(demoUserId);
    final avery = DemoCrew.workers[0].id;
    final blake = DemoCrew.workers[1].id;

    await repo.applyScenario(
      attemptId: 'avery-saved',
      crewId: DemoCrew.crewId,
      workerId: avery,
      windowId: DemoCrew.windowId,
      capturedAt: DateTime.utc(2026, 11, 23, 18),
      assignedPodId: null,
      presentedPodId: null,
      scenario: CheckInScenario.complete,
    );
    await repo.closeWindow(DemoCrew.windowId);

    final closed = await repo.roster(
      crewId: DemoCrew.crewId,
      windowId: DemoCrew.windowId,
    );
    expect(
      closed.firstWhere((row) => row.worker.id == avery).status,
      RosterStatus.checkedIn,
    );
    expect(
      closed.firstWhere((row) => row.worker.id == blake).status,
      RosterStatus.missed,
    );

    final opened = await repo.openWindow(DemoCrew.crewId);
    expect(opened.created, isTrue);
    final fresh = await repo.roster(
      crewId: DemoCrew.crewId,
      windowId: opened.window.id,
    );
    expect(
      fresh.firstWhere((row) => row.worker.id == avery).status,
      RosterStatus.waiting,
    );
    expect(fresh.every((row) => !row.isCheckedIn), isTrue);
    await service.db.close();
  });

  test('a different presented pod does not save, and clearing it does', () async {
    final service = await DatabaseService.openPath('${tempDir.path}/pods.db');
    final repo = CheckInRepository(service);
    await repo.seedDemoCrew(demoUserId);
    final avery = DemoCrew.workers.first.id;
    await repo.setWorkerPod(workerId: avery, podId: 'TAG01');

    final mismatch = await repo.applyScenario(
      attemptId: 'wrong-pod',
      crewId: DemoCrew.crewId,
      workerId: avery,
      windowId: DemoCrew.windowId,
      capturedAt: DateTime.utc(2026, 11, 23, 18),
      assignedPodId: 'TAG01',
      presentedPodId: 'TAG02',
      scenario: CheckInScenario.complete,
    );
    expect(mismatch.saved, isFalse);
    expect(mismatch.message, wrongPodMessage);
    expect(await repo.checkInsForWorker(avery), isEmpty);

    final saved = await repo.applyScenario(
      attemptId: 'cleared-pod',
      crewId: DemoCrew.crewId,
      workerId: avery,
      windowId: DemoCrew.windowId,
      capturedAt: DateTime.utc(2026, 11, 23, 18, 1),
      assignedPodId: 'TAG01',
      presentedPodId: null,
      scenario: CheckInScenario.complete,
    );
    expect(saved.saved, isTrue);
    expect(saved.checkIn?.podId, 'TAG01');
    await service.db.close();
  });

  test('sweat rate waits for a second volume on the same pod and window', () async {
    expect(
      sweatRateUlPerMin(
        previousVolumeUl: null,
        volumeUl: 8,
        previousAt: DateTime.utc(2026, 11, 23, 18),
        capturedAt: DateTime.utc(2026, 11, 23, 18, 2),
      ),
      isNull,
    );
    expect(
      sweatRateUlPerMin(
        previousVolumeUl: 8,
        volumeUl: 25,
        previousAt: DateTime.utc(2026, 11, 23, 18),
        capturedAt: DateTime.utc(2026, 11, 23, 18, 2),
      ),
      isNull,
    );

    final service = await DatabaseService.openPath('${tempDir.path}/rate.db');
    final repo = CheckInRepository(service);
    await repo.seedDemoCrew(demoUserId);
    final avery = DemoCrew.workers.first.id;
    final first = await repo.applyScenario(
      attemptId: 'rate-1',
      crewId: DemoCrew.crewId,
      workerId: avery,
      windowId: DemoCrew.windowId,
      capturedAt: DateTime.utc(2026, 11, 23, 18),
      assignedPodId: 'TAG01',
      presentedPodId: null,
      scenario: CheckInScenario.complete,
    );
    expect(first.checkIn?.sweatRateUlMin, isNull);

    final second = await repo.applyScenario(
      attemptId: 'rate-2',
      crewId: DemoCrew.crewId,
      workerId: avery,
      windowId: DemoCrew.windowId,
      capturedAt: DateTime.utc(2026, 11, 23, 18, 2),
      assignedPodId: 'TAG01',
      presentedPodId: null,
      scenario: CheckInScenario.complete,
    );
    expect(second.checkIn?.sweatRateUlMin, 0);
    await service.db.close();
  });

  test('reset restores the demo crew and leaves the other crew and old scans', () async {
    final service = await DatabaseService.openPath('${tempDir.path}/reset.db');
    final repo = CheckInRepository(service);
    await repo.seedDemoCrew(demoUserId);
    await service.db.insert('workers', {
      'id': 'worker-old',
      'user_id': 'foreman-old',
      'name': 'Jordan',
      'created_at': 1,
      'synced': 0,
    });
    await service.db.insert('scans', {
      'id': 'scan-old',
      'worker_id': 'worker-old',
      'user_id': 'foreman-old',
      'timestamp': 2,
      'skin_temp': 36.5,
      'sweat_rate': 0.4,
      'salinity': 40,
      'status': 'green',
      'synced': 0,
    });

    final other = await repo.createEmptyCrew(name: 'Night crew');
    await repo.addCrewWorker(
      userId: demoUserId,
      crewId: DemoCrew.crewId,
      name: 'Quinn',
    );
    await repo.renameCrew(
      crewId: DemoCrew.crewId,
      name: 'Renamed',
      siteLabel: 'Other site',
    );
    await repo.applyScenario(
      attemptId: 'before-reset',
      crewId: DemoCrew.crewId,
      workerId: DemoCrew.workers.first.id,
      windowId: DemoCrew.windowId,
      capturedAt: DateTime.utc(2026, 11, 23, 18),
      assignedPodId: null,
      presentedPodId: null,
      scenario: CheckInScenario.complete,
    );
    final queueBefore = await service.db.query('sync_queue');

    await repo.resetDemoCrew(demoUserId);

    final demo = await repo.getCrew(DemoCrew.crewId);
    final workers = await repo.workersInCrew(DemoCrew.crewId);
    final window = await repo.getOpenWindow(DemoCrew.crewId);
    final crews = await repo.listCrews();
    final scans = await service.db.query('scans');
    final queueAfter = await service.db.query('sync_queue');

    expect(demo?.name, DemoCrew.crewName);
    expect(demo?.siteLabel, DemoCrew.siteLabel);
    expect(workers.map((worker) => worker.name).toList(), ['Avery', 'Blake', 'Casey']);
    expect(workers.every((worker) => !worker.archived && worker.podId == null), isTrue);
    expect(window?.id, DemoCrew.windowId);
    expect(await repo.checkInsForWorker(DemoCrew.workers.first.id), isEmpty);
    expect(crews.any((crew) => crew.id == other.id), isTrue);
    expect(scans.single['id'], 'scan-old');
    expect(queueBefore, isEmpty);
    expect(queueAfter, isEmpty);
    await service.db.close();
  });

  test('a recheck stays visible and still counts as checked in', () async {
    final service = await DatabaseService.openPath('${tempDir.path}/recheck.db');
    final repo = CheckInRepository(service);
    await repo.seedDemoCrew(demoUserId);
    final avery = DemoCrew.workers.first.id;
    await repo.applyScenario(
      attemptId: 'saved',
      crewId: DemoCrew.crewId,
      workerId: avery,
      windowId: DemoCrew.windowId,
      capturedAt: DateTime.utc(2026, 11, 23, 18),
      assignedPodId: null,
      presentedPodId: null,
      scenario: CheckInScenario.complete,
    );
    final followUp = await repo.requestRecheck(
      workerId: avery,
      windowId: DemoCrew.windowId,
    );
    final again = await repo.requestRecheck(
      workerId: avery,
      windowId: DemoCrew.windowId,
    );
    expect(again.id, followUp.id);

    final roster = await repo.roster(
      crewId: DemoCrew.crewId,
      windowId: DemoCrew.windowId,
    );
    final row = roster.firstWhere((entry) => entry.worker.id == avery);
    expect(row.status, RosterStatus.retryRequested);
    expect(row.isCheckedIn, isTrue);
    expect(
      await repo.openFollowUp(workerId: avery, windowId: DemoCrew.windowId),
      isNotNull,
    );
    await service.db.close();
  });

  test('editing a profile keeps the new height and skips the sync queue', () async {
    final service = await DatabaseService.openPath('${tempDir.path}/profile.db');
    final repo = CheckInRepository(service);
    await repo.seedDemoCrew(demoUserId);
    final before = (await repo.workersInCrew(DemoCrew.crewId))
        .firstWhere((worker) => worker.id == DemoCrew.workers.first.id);
    expect(before.heightCm, 168);
    expect(before.weightKg, 62);
    expect(before.employeeId, 'A-101');

    await repo.saveWorkerProfile(
      workerId: before.id,
      name: 'Avery',
      employeeId: 'A-101',
      age: 30,
      heightCm: 170,
      weightKg: 63,
    );

    final after = (await repo.workersInCrew(DemoCrew.crewId))
        .firstWhere((worker) => worker.id == before.id);
    expect(after.age, 30);
    expect(after.heightCm, 170);
    expect(after.weightKg, 63);
    expect(after.bmi, isNotNull);
    expect(await service.db.query('sync_queue'), isEmpty);
    await service.db.close();
  });
}

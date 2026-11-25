import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:veltra/core/demo_crew.dart';
import 'package:veltra/core/demo_mode.dart';
import 'package:veltra/models/check_in.dart';
import 'package:veltra/repositories/check_in_repository.dart';
import 'package:veltra/services/database_schema.dart';
import 'package:veltra/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('veltra_check_in_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('v4 database keeps workers, scans, and the sync queue', () async {
    final path = '${tempDir.path}/legacy.db';
    final legacy = await openDatabase(
      path,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute(DatabaseSchema.legacyV4Workers);
        await db.execute(DatabaseSchema.createBaselines);
        await db.execute(DatabaseSchema.createScans);
        await db.execute(DatabaseSchema.createSyncQueue);
        await db.execute(DatabaseSchema.createWorkersUserIndex);
        await db.execute(DatabaseSchema.createShiftMeta);
        await db.execute(DatabaseSchema.createWeatherCache);
      },
    );
    await legacy.insert('workers', {
      'id': 'worker-old',
      'user_id': 'foreman-old',
      'name': 'Jordan',
      'created_at': 1,
      'synced': 0,
    });
    await legacy.insert('scans', {
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
    await legacy.insert('sync_queue', {
      'operation': 'scan_create',
      'user_id': 'foreman-old',
      'document_path': 'users/foreman-old/scans/scan-old',
      'created_at': 3,
    });
    await legacy.close();

    final service = await DatabaseService.openPath(path);
    final workers = await service.db.query('workers');
    final scans = await service.db.query('scans');
    final queue = await service.db.query('sync_queue');

    expect(workers, hasLength(1));
    expect(workers.single['name'], 'Jordan');
    expect(workers.single['crew_id'], isNull);
    expect(workers.single['archived'], 0);
    expect(scans.single['id'], 'scan-old');
    expect(queue, hasLength(1));

    final tables = await service.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'check_ins'",
    );
    expect(tables, isNotEmpty);
    await service.db.close();
  });

  test('seed is stable and an empty crew has no workers', () async {
    final service = await DatabaseService.openPath('${tempDir.path}/seed.db');
    final repo = CheckInRepository(service);

    await repo.seedDemoCrew(demoUserId);
    await service.db.update(
      'crews',
      {'name': 'Renamed Yard'},
      where: 'id = ?',
      whereArgs: [DemoCrew.crewId],
    );
    await service.db.update(
      'workers',
      {'archived': 1},
      where: 'id = ?',
      whereArgs: [DemoCrew.workers.first.id],
    );
    await repo.seedDemoCrew(demoUserId);

    final crew = await repo.getCrew(DemoCrew.crewId);
    final workers = await repo.workersForCrew(DemoCrew.crewId);
    final openWindows = await repo.countOpenWindows(DemoCrew.crewId);
    final config = await repo.getDemoConfig();

    expect(crew?.name, 'Renamed Yard');
    expect(workers, hasLength(3));
    expect(workers.map((row) => row['name']), containsAll(['Avery', 'Blake', 'Casey']));
    expect(
      workers.firstWhere((row) => row['id'] == DemoCrew.workers.first.id)['archived'],
      1,
    );
    expect(openWindows, 1);
    expect(config?.role, 'worker');
    expect(config?.workerId, DemoCrew.workers.first.id);

    final empty = await repo.createEmptyCrew(name: 'Bench');
    expect(await repo.workersForCrew(empty.id), isEmpty);
    await service.db.close();
  });

  test('a crew can have only one open window', () async {
    final service = await DatabaseService.openPath('${tempDir.path}/window.db');
    final repo = CheckInRepository(service);
    final crew = await repo.createEmptyCrew(name: 'Window Crew');

    final first = await repo.openWindow(crew.id);
    final second = await repo.openWindow(crew.id);

    expect(first.created, isTrue);
    expect(second.created, isFalse);
    expect(second.window.id, first.window.id);
    expect(await repo.countOpenWindows(crew.id), 1);

    await repo.closeWindow(first.window.id);
    final third = await repo.openWindow(crew.id);
    expect(third.created, isTrue);
    expect(await repo.countOpenWindows(crew.id), 1);
    final all = await service.db.query(
      'checkin_windows',
      where: 'crew_id = ?',
      whereArgs: [crew.id],
    );
    expect(all, hasLength(2));
    await service.db.close();
  });

  test('temperature-only check-in saves once and skips baseline and sync', () async {
    final service = await DatabaseService.openPath('${tempDir.path}/save.db');
    final repo = CheckInRepository(service);
    await repo.seedDemoCrew(demoUserId);

    final baselineBefore = await service.db.query(
      'baselines',
      where: 'worker_id = ?',
      whereArgs: [DemoCrew.workers.first.id],
    );
    final queueBefore = await service.db.query('sync_queue');

    final request = SaveCheckInRequest(
      attemptId: 'attempt-1',
      crewId: DemoCrew.crewId,
      workerId: DemoCrew.workers.first.id,
      windowId: DemoCrew.windowId,
      capturedAt: DateTime.utc(2026, 11, 23, 18, 0),
      source: CheckInSources.simulated,
      foreheadTempC: 34.2,
    );

    final first = await repo.saveCheckIn(request);
    final second = await repo.saveCheckIn(
      SaveCheckInRequest(
        attemptId: request.attemptId,
        crewId: request.crewId,
        workerId: request.workerId,
        windowId: request.windowId,
        capturedAt: DateTime.utc(2026, 11, 23, 19, 0),
        source: CheckInSources.nfcTestTag,
        foreheadTempC: 40,
        stripVolumeUl: 12.5,
        conductivityUsCm: 820,
      ),
    );

    expect(first.created, isTrue);
    expect(second.created, isFalse);
    expect(second.checkIn.id, first.checkIn.id);
    expect(second.checkIn.foreheadTempC, 34.2);
    expect(second.checkIn.stripVolumeUl, isNull);
    expect(second.checkIn.conductivityUsCm, isNull);
    expect(second.checkIn.foreheadTempAvailable, isTrue);
    expect(second.checkIn.stripVolumeAvailable, isFalse);
    expect(second.checkIn.conductivityAvailable, isFalse);
    expect(second.checkIn.source, CheckInSources.simulated);
    expect(second.checkIn.capturedAt.isUtc, isTrue);

    final saved = await service.db.query('check_ins');
    final attempts = await service.db.query('checkin_attempts');
    final baselineAfter = await service.db.query(
      'baselines',
      where: 'worker_id = ?',
      whereArgs: [DemoCrew.workers.first.id],
    );
    final queueAfter = await service.db.query('sync_queue');

    expect(saved, hasLength(1));
    expect(saved.single['forehead_temp_c'], 34.2);
    expect(saved.single['strip_volume_ul'], isNull);
    expect(saved.single['conductivity_us_cm'], isNull);
    expect(attempts, hasLength(1));
    expect(baselineAfter.single['mu_temp'], baselineBefore.single['mu_temp']);
    expect(baselineAfter.single['shift_count'], baselineBefore.single['shift_count']);
    expect(queueBefore, isEmpty);
    expect(queueAfter, isEmpty);
    await service.db.close();
  });
}

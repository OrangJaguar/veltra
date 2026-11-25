import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/demo_crew.dart';
import '../core/utils/body_metrics.dart';
import '../features/checkin/checkin_scenario.dart';
import '../features/checkin/sweat_rate.dart';
import '../models/baseline.dart';
import '../models/check_in.dart';
import '../models/check_in_window.dart';
import '../models/crew.dart';
import '../models/demo_config.dart';
import '../models/follow_up.dart';
import '../models/roster_entry.dart';
import '../models/worker.dart';
import '../services/database_service.dart';

class CheckInRepository {
  CheckInRepository(this._databaseService);

  final DatabaseService _databaseService;
  final _uuid = const Uuid();

  Future<Crew> createEmptyCrew({
    required String name,
    String? siteLabel,
  }) async {
    final crew = Crew(
      id: _uuid.v4(),
      name: name.trim(),
      siteLabel: _emptyToNull(siteLabel),
      createdAt: DateTime.now().toUtc(),
    );
    await _databaseService.db.insert('crews', crew.toMap());
    return crew;
  }

  Future<Crew?> getCrew(String crewId) async {
    final rows = await _databaseService.db.query(
      'crews',
      where: 'id = ?',
      whereArgs: [crewId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Crew.fromMap(rows.first);
  }

  Future<List<Map<String, Object?>>> workersForCrew(String crewId) {
    return _databaseService.db.query(
      'workers',
      where: 'crew_id = ?',
      whereArgs: [crewId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
  }

  /// Inserts the stable demo crew, three workers, and one open window.
  /// A later call leaves an existing crew name, archived flag, and closed
  /// window alone.
  Future<void> seedDemoCrew(String userId) async {
    final db = _databaseService.db;
    await db.transaction((txn) async {
      final crews = await txn.query(
        'crews',
        where: 'id = ?',
        whereArgs: [DemoCrew.crewId],
        limit: 1,
      );
      if (crews.isEmpty) {
        await txn.insert('crews', {
          'id': DemoCrew.crewId,
          'name': DemoCrew.crewName,
          'site_label': DemoCrew.siteLabel,
          'created_at': DateTime.now().toUtc().millisecondsSinceEpoch,
        });
      }

      for (final worker in DemoCrew.workers) {
        final existing = await txn.query(
          'workers',
          where: 'id = ?',
          whereArgs: [worker.id],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          final row = existing.first;
          final untouched = row['age'] == null &&
              row['height_cm'] == null &&
              row['weight_kg'] == null;
          if (untouched) {
            await txn.update(
              'workers',
              _profileColumns(worker),
              where: 'id = ?',
              whereArgs: [worker.id],
            );
          }
          continue;
        }

        final createdAt = DateTime.now().toUtc().millisecondsSinceEpoch;
        await txn.insert('workers', {
          'id': worker.id,
          'user_id': userId,
          'name': worker.name,
          'created_at': createdAt,
          'crew_id': DemoCrew.crewId,
          'archived': 0,
          'synced': 0,
          ..._profileColumns(worker),
        });
        await txn.insert(
          'baselines',
          WorkerBaseline(workerId: worker.id).toMap(),
        );
      }

      final windows = await txn.query(
        'checkin_windows',
        where: 'crew_id = ?',
        whereArgs: [DemoCrew.crewId],
        limit: 1,
      );
      if (windows.isEmpty) {
        await txn.insert('checkin_windows', {
          'id': DemoCrew.windowId,
          'crew_id': DemoCrew.crewId,
          'opened_at': DateTime.now().toUtc().millisecondsSinceEpoch,
        });
      }

      final config = await txn.query(
        'demo_config',
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );
      if (config.isEmpty) {
        await txn.insert('demo_config', {
          'id': 1,
          'crew_id': DemoCrew.crewId,
          'role': DemoRoles.worker,
          'worker_id': DemoCrew.workers.first.id,
          'scan_source': CheckInSources.simulated,
        });
      }
    });
  }

  Future<OpenWindowResult> openWindow(String crewId) async {
    final existing = await getOpenWindow(crewId);
    if (existing != null) {
      return OpenWindowResult(window: existing, created: false);
    }

    final window = CheckInWindow(
      id: _uuid.v4(),
      crewId: crewId,
      openedAt: DateTime.now().toUtc(),
    );
    try {
      await _databaseService.db.insert('checkin_windows', window.toMap());
    } on DatabaseException catch (error) {
      if (!error.isUniqueConstraintError()) rethrow;
      final raced = await getOpenWindow(crewId);
      if (raced == null) rethrow;
      return OpenWindowResult(window: raced, created: false);
    }
    return OpenWindowResult(window: window, created: true);
  }

  Future<CheckInWindow?> getOpenWindow(String crewId) async {
    final rows = await _databaseService.db.query(
      'checkin_windows',
      where: 'crew_id = ? AND closed_at IS NULL',
      whereArgs: [crewId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CheckInWindow.fromMap(rows.first);
  }

  Future<int> countOpenWindows(String crewId) async {
    final result = await _databaseService.db.rawQuery(
      'SELECT COUNT(*) AS count FROM checkin_windows WHERE crew_id = ? AND closed_at IS NULL',
      [crewId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<CheckInWindow> closeWindow(String windowId) async {
    final closedAt = DateTime.now().toUtc();
    await _databaseService.db.update(
      'checkin_windows',
      {'closed_at': closedAt.millisecondsSinceEpoch},
      where: 'id = ? AND closed_at IS NULL',
      whereArgs: [windowId],
    );
    final rows = await _databaseService.db.query(
      'checkin_windows',
      where: 'id = ?',
      whereArgs: [windowId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Window $windowId was not found');
    }
    return CheckInWindow.fromMap(rows.first);
  }

  /// Writes one check-in. The same [SaveCheckInRequest.attemptId] returns the
  /// original row and does not touch baselines or the sync queue.
  Future<CheckInSaveResult> saveCheckIn(SaveCheckInRequest request) async {
    final db = _databaseService.db;
    return db.transaction((txn) async {
      final existing = await txn.query(
        'check_ins',
        where: 'attempt_id = ?',
        whereArgs: [request.attemptId],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return CheckInSaveResult(
          checkIn: CheckIn.fromMap(existing.first),
          created: false,
        );
      }

      final capturedAt = request.capturedAt.toUtc();
      final rate = request.source == CheckInSources.simulated
          ? (request.sweatRateUlMin ??
              await _derivedRate(
                txn,
                workerId: request.workerId,
                podId: _emptyToNull(request.podId),
                cartridgeSessionId: _emptyToNull(request.cartridgeSessionId),
                volumeUl: request.stripVolumeUl,
                capturedAt: capturedAt,
              ))
          : request.sweatRateUlMin;
      final checkIn = CheckIn(
        id: _uuid.v4(),
        attemptId: request.attemptId,
        crewId: request.crewId,
        workerId: request.workerId,
        windowId: request.windowId,
        capturedAt: capturedAt,
        source: request.source,
        podId: _emptyToNull(request.podId),
        cartridgeSessionId: _emptyToNull(request.cartridgeSessionId),
        foreheadTempC: request.foreheadTempC,
        stripVolumeUl: request.stripVolumeUl,
        conductivityUsCm: request.conductivityUsCm,
        sweatRateUlMin: rate,
        foreheadTempAvailable: request.foreheadTempC != null,
        stripVolumeAvailable: request.stripVolumeUl != null,
        conductivityAvailable: request.conductivityUsCm != null,
        sweatRateAvailable: rate != null,
        readQuality: _emptyToNull(request.readQuality),
        weather: request.weather,
      );

      try {
        await txn.insert('checkin_attempts', {
          'id': request.attemptId,
          'crew_id': request.crewId,
          'worker_id': request.workerId,
          'window_id': request.windowId,
          'outcome': 'saved',
          'created_at': capturedAt.millisecondsSinceEpoch,
        });
        await txn.insert('check_ins', checkIn.toMap());
      } on DatabaseException catch (error) {
        if (!error.isUniqueConstraintError()) rethrow;
        final raced = await txn.query(
          'check_ins',
          where: 'attempt_id = ?',
          whereArgs: [request.attemptId],
          limit: 1,
        );
        if (raced.isEmpty) rethrow;
        return CheckInSaveResult(
          checkIn: CheckIn.fromMap(raced.first),
          created: false,
        );
      }
      return CheckInSaveResult(checkIn: checkIn, created: true);
    });
  }

  Future<FollowUp> createFollowUp({
    required String workerId,
    required String windowId,
    String? note,
  }) async {
    final followUp = FollowUp(
      id: _uuid.v4(),
      workerId: workerId,
      windowId: windowId,
      requestedAt: DateTime.now().toUtc(),
      note: _emptyToNull(note),
    );
    await _databaseService.db.insert('follow_ups', followUp.toMap());
    return followUp;
  }

  Future<DemoConfig?> getDemoConfig() async {
    final rows = await _databaseService.db.query(
      'demo_config',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DemoConfig.fromMap(rows.first);
  }

  Future<void> saveDemoConfig(DemoConfig config) async {
    await _databaseService.db.insert(
      'demo_config',
      config.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Worker>> activeWorkers(String crewId) async {
    final rows = await _databaseService.db.query(
      'workers',
      where: 'crew_id = ? AND archived = 0',
      whereArgs: [crewId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Worker.fromMap).toList();
  }

  Future<CheckIn?> getCheckIn(String id) async {
    final rows = await _databaseService.db.query(
      'check_ins',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CheckIn.fromMap(rows.first);
  }

  Future<List<CheckIn>> checkInsForWorker(String workerId) async {
    final rows = await _databaseService.db.query(
      'check_ins',
      where: 'worker_id = ?',
      whereArgs: [workerId],
      orderBy: 'captured_at DESC',
    );
    return rows.map(CheckIn.fromMap).toList();
  }

  Future<CheckIn?> latestCheckInInWindow({
    required String workerId,
    required String windowId,
  }) async {
    final rows = await _databaseService.db.query(
      'check_ins',
      where: 'worker_id = ? AND window_id = ?',
      whereArgs: [workerId, windowId],
      orderBy: 'captured_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CheckIn.fromMap(rows.first);
  }

  Future<List<RosterEntry>> roster({
    required String crewId,
    required String windowId,
  }) async {
    final window = await getWindow(windowId);
    final workers = await activeWorkers(crewId);
    final entries = <RosterEntry>[];
    for (final worker in workers) {
      final latest = await latestCheckInInWindow(
        workerId: worker.id,
        windowId: windowId,
      );
      final followUp = await openFollowUp(
        workerId: worker.id,
        windowId: windowId,
      );
      entries.add(
        RosterEntry(
          worker: worker,
          latestCheckIn: latest,
          status: rosterStatus(
            windowOpen: window?.isOpen ?? false,
            hasCheckIn: latest != null,
            recheckRequested: followUp != null,
          ),
        ),
      );
    }
    return entries;
  }

  Future<CheckInWindow?> getWindow(String windowId) async {
    final rows = await _databaseService.db.query(
      'checkin_windows',
      where: 'id = ?',
      whereArgs: [windowId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CheckInWindow.fromMap(rows.first);
  }

  Future<CheckInWindow?> latestWindow(String crewId) async {
    final rows = await _databaseService.db.query(
      'checkin_windows',
      where: 'crew_id = ?',
      whereArgs: [crewId],
      orderBy: 'opened_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CheckInWindow.fromMap(rows.first);
  }

  Future<List<Crew>> listCrews() async {
    final rows = await _databaseService.db.query(
      'crews',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Crew.fromMap).toList();
  }

  Future<List<Worker>> workersInCrew(String crewId) async {
    final rows = await _databaseService.db.query(
      'workers',
      where: 'crew_id = ?',
      whereArgs: [crewId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Worker.fromMap).toList();
  }

  Future<void> renameCrew({
    required String crewId,
    required String name,
    String? siteLabel,
  }) async {
    await _databaseService.db.update(
      'crews',
      {
        'name': name.trim(),
        'site_label': _emptyToNull(siteLabel),
      },
      where: 'id = ?',
      whereArgs: [crewId],
    );
  }

  Future<Worker> addCrewWorker({
    required String userId,
    required String crewId,
    required String name,
  }) async {
    final worker = Worker(
      id: _uuid.v4(),
      userId: userId,
      name: name.trim(),
      createdAt: DateTime.now().toUtc(),
      crewId: crewId,
    );
    final db = _databaseService.db;
    await db.transaction((txn) async {
      await txn.insert('workers', worker.toMap());
      await txn.insert('baselines', WorkerBaseline(workerId: worker.id).toMap());
    });
    return worker;
  }

  Future<void> saveWorkerProfile({
    required String workerId,
    required String name,
    String? employeeId,
    int? age,
    double? heightCm,
    double? weightKg,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _databaseService.db.update(
      'workers',
      {
        'name': trimmed,
        'employee_id': _emptyToNull(employeeId),
        'age': age,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'bmi': BodyMetrics.calculateBmi(heightCm: heightCm, weightKg: weightKg),
      },
      where: 'id = ?',
      whereArgs: [workerId],
    );
  }

  Future<void> renameWorker({
    required String workerId,
    required String name,
  }) async {
    await _databaseService.db.update(
      'workers',
      {'name': name.trim()},
      where: 'id = ?',
      whereArgs: [workerId],
    );
  }

  Future<void> setWorkerPod({
    required String workerId,
    String? podId,
  }) async {
    await _databaseService.db.update(
      'workers',
      {'pod_id': _emptyToNull(podId)},
      where: 'id = ?',
      whereArgs: [workerId],
    );
  }

  Future<void> setWorkerArchived({
    required String workerId,
    required bool archived,
  }) async {
    await _databaseService.db.update(
      'workers',
      {'archived': archived ? 1 : 0},
      where: 'id = ?',
      whereArgs: [workerId],
    );
  }

  Future<FollowUp?> openFollowUp({
    required String workerId,
    required String windowId,
  }) async {
    final rows = await _databaseService.db.query(
      'follow_ups',
      where: 'worker_id = ? AND window_id = ? AND completed_at IS NULL',
      whereArgs: [workerId, windowId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return FollowUp.fromMap(rows.first);
  }

  Future<FollowUp> requestRecheck({
    required String workerId,
    required String windowId,
  }) async {
    final existing = await openFollowUp(workerId: workerId, windowId: windowId);
    if (existing != null) return existing;
    return createFollowUp(workerId: workerId, windowId: windowId);
  }

  /// Runs one simulated scenario. A failure records an attempt and does not
  /// insert a check-in. A mismatch does the same.
  Future<ScenarioOutcome> applyScenario({
    required String attemptId,
    required String crewId,
    required String workerId,
    required String windowId,
    required DateTime capturedAt,
    required String? assignedPodId,
    required String? presentedPodId,
    required CheckInScenario scenario,
    CheckInWeather? weather,
  }) async {
    final assigned = _emptyToNull(assignedPodId);
    final presented = _emptyToNull(presentedPodId);
    if (presented != null && assigned != null && presented != assigned) {
      await recordFailedAttempt(
        attemptId: attemptId,
        crewId: crewId,
        workerId: workerId,
        windowId: windowId,
        error: wrongPodMessage,
      );
      return const ScenarioOutcome(message: wrongPodMessage);
    }

    if (!scenario.saves) {
      final message = scenario.failureMessage ?? "Couldn't save";
      await recordFailedAttempt(
        attemptId: attemptId,
        crewId: crewId,
        workerId: workerId,
        windowId: windowId,
        error: message,
      );
      return ScenarioOutcome(message: message);
    }

    final saved = await saveCheckIn(
      SaveCheckInRequest(
        attemptId: attemptId,
        crewId: crewId,
        workerId: workerId,
        windowId: windowId,
        capturedAt: capturedAt,
        source: CheckInSources.simulated,
        podId: presented ?? assigned,
        cartridgeSessionId: windowId,
        foreheadTempC: scenario.foreheadTempC,
        stripVolumeUl: scenario.stripVolumeUl,
        conductivityUsCm: scenario.conductivityUsCm,
        weather: weather,
      ),
    );
    return ScenarioOutcome(checkIn: saved.checkIn);
  }

  /// Saves one decoded test-tag line. The line's pod id is what was presented.
  /// A mismatch records an attempt and does not insert a check-in.
  Future<ScenarioOutcome> saveTestTag({
    required String attemptId,
    required String crewId,
    required String workerId,
    required String windowId,
    required DateTime capturedAt,
    required String? assignedPodId,
    required String podId,
    required double foreheadTempC,
    double? stripVolumeUl,
    double? conductivityUsCm,
    CheckInWeather? weather,
  }) async {
    final assigned = _emptyToNull(assignedPodId);
    final presented = _emptyToNull(podId);
    if (presented != null && assigned != null && presented != assigned) {
      await recordFailedAttempt(
        attemptId: attemptId,
        crewId: crewId,
        workerId: workerId,
        windowId: windowId,
        error: wrongPodMessage,
      );
      return const ScenarioOutcome(message: wrongPodMessage);
    }

    final saved = await saveCheckIn(
      SaveCheckInRequest(
        attemptId: attemptId,
        crewId: crewId,
        workerId: workerId,
        windowId: windowId,
        capturedAt: capturedAt,
        source: CheckInSources.nfcTestTag,
        podId: presented ?? assigned,
        cartridgeSessionId: windowId,
        foreheadTempC: foreheadTempC,
        stripVolumeUl: stripVolumeUl,
        conductivityUsCm: conductivityUsCm,
        weather: weather,
      ),
    );
    return ScenarioOutcome(checkIn: saved.checkIn);
  }

  Future<void> recordUnpairedBench({
    required String attemptId,
    required String crewId,
    required String workerId,
    required String windowId,
  }) async {
    await _databaseService.db.insert(
      'checkin_attempts',
      {
        'id': attemptId,
        'crew_id': crewId,
        'worker_id': workerId,
        'window_id': windowId,
        'outcome': 'unpaired',
        'error': 'Unpaired bench read',
        'created_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Clears the seeded demo crew's check-ins and puts Avery, Blake, and Casey
  /// back. Other crews and the old scan table stay.
  Future<void> resetDemoCrew(String userId) async {
    final db = _databaseService.db;
    final seedIds = DemoCrew.workers.map((worker) => worker.id).toSet();
    await db.transaction((txn) async {
      final windows = await txn.query(
        'checkin_windows',
        columns: ['id'],
        where: 'crew_id = ?',
        whereArgs: [DemoCrew.crewId],
      );
      for (final window in windows) {
        final windowId = window['id'] as String;
        await txn.delete(
          'check_ins',
          where: 'window_id = ?',
          whereArgs: [windowId],
        );
        await txn.delete(
          'checkin_attempts',
          where: 'window_id = ?',
          whereArgs: [windowId],
        );
        await txn.delete(
          'follow_ups',
          where: 'window_id = ?',
          whereArgs: [windowId],
        );
      }
      await txn.delete(
        'checkin_windows',
        where: 'crew_id = ?',
        whereArgs: [DemoCrew.crewId],
      );
      final extras = await txn.query(
        'workers',
        columns: ['id'],
        where: 'crew_id = ?',
        whereArgs: [DemoCrew.crewId],
      );
      for (final row in extras) {
        final id = row['id'] as String;
        if (seedIds.contains(id)) continue;
        await txn.delete('workers', where: 'id = ?', whereArgs: [id]);
      }
      await txn.update(
        'crews',
        {
          'name': DemoCrew.crewName,
          'site_label': DemoCrew.siteLabel,
        },
        where: 'id = ?',
        whereArgs: [DemoCrew.crewId],
      );
      for (final worker in DemoCrew.workers) {
        final existing = await txn.query(
          'workers',
          where: 'id = ?',
          whereArgs: [worker.id],
          limit: 1,
        );
        if (existing.isEmpty) {
          await txn.insert('workers', {
            'id': worker.id,
            'user_id': userId,
            'name': worker.name,
            'created_at': DateTime.now().toUtc().millisecondsSinceEpoch,
            'crew_id': DemoCrew.crewId,
            'archived': 0,
            'synced': 0,
            ..._profileColumns(worker),
          });
          await txn.insert(
            'baselines',
            WorkerBaseline(workerId: worker.id).toMap(),
          );
        } else {
          await txn.update(
            'workers',
            {
              'name': worker.name,
              'archived': 0,
              'pod_id': null,
              'crew_id': DemoCrew.crewId,
              ..._profileColumns(worker),
            },
            where: 'id = ?',
            whereArgs: [worker.id],
          );
        }
      }
      await txn.insert('checkin_windows', {
        'id': DemoCrew.windowId,
        'crew_id': DemoCrew.crewId,
        'opened_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      });
      final config = await txn.query(
        'demo_config',
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );
      final role = config.isEmpty
          ? DemoRoles.worker
          : config.first['role'] as String;
      await txn.insert(
        'demo_config',
        {
          'id': 1,
          'crew_id': DemoCrew.crewId,
          'role': role,
          'worker_id': DemoCrew.workers.first.id,
          'scan_source': CheckInSources.simulated,
          'scenario': CheckInScenario.complete.id,
          'presented_pod_id': null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<double?> _derivedRate(
    Transaction txn, {
    required String workerId,
    required String? podId,
    required String? cartridgeSessionId,
    required double? volumeUl,
    required DateTime capturedAt,
  }) async {
    if (volumeUl == null || cartridgeSessionId == null) return null;
    final capturedMs = capturedAt.millisecondsSinceEpoch;
    final rows = await txn.query(
      'check_ins',
      where: podId == null
          ? 'worker_id = ? AND cartridge_session_id = ? AND pod_id IS NULL AND strip_volume_ul IS NOT NULL AND captured_at < ?'
          : 'worker_id = ? AND cartridge_session_id = ? AND pod_id = ? AND strip_volume_ul IS NOT NULL AND captured_at < ?',
      whereArgs: podId == null
          ? [workerId, cartridgeSessionId, capturedMs]
          : [workerId, cartridgeSessionId, podId, capturedMs],
      orderBy: 'captured_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final previous = CheckIn.fromMap(rows.first);
    return sweatRateUlPerMin(
      previousVolumeUl: previous.stripVolumeUl,
      volumeUl: volumeUl,
      previousAt: previous.capturedAt,
      capturedAt: capturedAt,
    );
  }

  /// A failed read. Does not insert a check-in and does not touch baselines
  /// or the sync queue.
  Future<void> recordFailedAttempt({
    required String attemptId,
    required String crewId,
    required String workerId,
    required String windowId,
    required String error,
  }) async {
    await _databaseService.db.insert(
      'checkin_attempts',
      {
        'id': attemptId,
        'crew_id': crewId,
        'worker_id': workerId,
        'window_id': windowId,
        'outcome': 'failed',
        'error': error,
        'created_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Map<String, Object?> _profileColumns(DemoWorkerSeed worker) {
    return {
      'employee_id': worker.employeeId,
      'age': worker.age,
      'height_cm': worker.heightCm,
      'weight_kg': worker.weightKg,
      'bmi': BodyMetrics.calculateBmi(
        heightCm: worker.heightCm,
        weightKg: worker.weightKg,
      ),
    };
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

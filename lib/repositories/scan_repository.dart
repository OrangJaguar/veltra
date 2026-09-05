import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/baseline.dart';
import '../models/scan_record.dart';
import '../models/sync_status.dart';
import '../models/worker.dart';
import '../services/database_service.dart';

class ScanRepository {
  ScanRepository(this._databaseService, this._firestore);

  final DatabaseService _databaseService;
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  Future<List<ScanRecord>> getScansForWorker(
    String workerId, {
    int limit = 20,
  }) async {
    final rows = await _databaseService.db.query(
      'scans',
      where: 'worker_id = ?',
      whereArgs: [workerId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map(ScanRecord.fromMap).toList();
  }

  Future<ScanRecord?> getLatestScanForWorker(String workerId) async {
    final rows = await _databaseService.db.query(
      'scans',
      where: 'worker_id = ?',
      whereArgs: [workerId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ScanRecord.fromMap(rows.first);
  }

  Future<ScanRecord> saveScan({
    required String userId,
    required Worker worker,
    required WorkerBaseline baseline,
    required ScanRecord scan,
  }) async {
    final db = _databaseService.db;
    await db.transaction((txn) async {
      await txn.insert('scans', scan.toMap());
      await txn.update(
        'workers',
        {
          'last_status': scan.status.name,
          'last_scan_at': scan.timestamp.millisecondsSinceEpoch,
          'synced': 0,
        },
        where: 'id = ?',
        whereArgs: [worker.id],
      );
      await txn.update(
        'baselines',
        baseline.toMap(),
        where: 'worker_id = ?',
        whereArgs: [worker.id],
      );
      await txn.insert('sync_queue', {
        'operation': 'scan_create',
        'user_id': userId,
        'document_path': 'users/$userId/scans/${scan.id}',
        'payload': jsonEncode({
          'scanId': scan.id,
          'workerId': worker.id,
        }),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
      await txn.insert('sync_queue', {
        'operation': 'baseline_update',
        'user_id': userId,
        'document_path':
            'users/$userId/workers/${worker.id}/baselines/current',
        'payload': jsonEncode({
          'workerId': worker.id,
        }),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    });

    return scan;
  }

  ScanRecord buildScanRecord({
    required String userId,
    required String workerId,
    required double skinTemp,
    required double sweatRate,
    required double salinity,
    required double? sweatVolume,
    required double wbgt,
    required WorkerStatus status,
    required String recommendation,
    required double zScore,
    required double tempRate,
    required double elapsedHours,
  }) {
    return ScanRecord(
      id: _uuid.v4(),
      workerId: workerId,
      userId: userId,
      timestamp: DateTime.now(),
      skinTemp: skinTemp,
      sweatRate: sweatRate,
      salinity: salinity,
      sweatVolume: sweatVolume,
      wbgt: wbgt,
      status: status,
      recommendation: recommendation,
      zScore: zScore,
      tempRate: tempRate,
      elapsedHours: elapsedHours,
      synced: false,
    );
  }

  Future<void> pushScanToFirestore({
    required String userId,
    required ScanRecord scan,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('scans')
        .doc(scan.id)
        .set({
      'workerId': scan.workerId,
      'timestamp': scan.timestamp.toUtc().toIso8601String(),
      'skinTemp': scan.skinTemp,
      'sweatRate': scan.sweatRate,
      'salinity': scan.salinity,
      if (scan.sweatVolume != null) 'sweatVolume': scan.sweatVolume,
      if (scan.wbgt != null) 'wbgt': scan.wbgt,
      'status': scan.status.name.toUpperCase(),
      if (scan.recommendation != null) 'recommendation': scan.recommendation,
      if (scan.zScore != null) 'zScore': scan.zScore,
      if (scan.tempRate != null) 'tempRate': scan.tempRate,
      if (scan.elapsedHours != null) 'elapsedHours': scan.elapsedHours,
    });

    await _databaseService.db.update(
      'scans',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [scan.id],
    );
  }

  Future<ScanRecord?> getScan(String scanId) async {
    final rows = await _databaseService.db.query(
      'scans',
      where: 'id = ?',
      whereArgs: [scanId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ScanRecord.fromMap(rows.first);
  }
}

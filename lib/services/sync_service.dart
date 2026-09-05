import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../models/baseline.dart';
import '../repositories/baseline_repository.dart';
import '../repositories/scan_repository.dart';
import '../repositories/worker_repository.dart';
import 'database_service.dart';

class SyncService {
  SyncService(
    this._databaseService,
    this._workerRepository,
    this._baselineRepository,
    this._scanRepository,
    this._firestore,
    this._connectivity,
  );

  final DatabaseService _databaseService;
  final WorkerRepository _workerRepository;
  final BaselineRepository _baselineRepository;
  final ScanRepository _scanRepository;
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;

  Stream<ConnectivityResult> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<int> pendingCount(String userId) async {
    final result = await _databaseService.db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> flushQueue(String userId) async {
    if (!await isOnline) return;

    final rows = await _databaseService.db.query(
      'sync_queue',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );

    for (final row in rows) {
      final id = row['id'] as int;
      final operation = row['operation'] as String;
      final documentPath = row['document_path'] as String;
      final payloadRaw = row['payload'] as String?;

      try {
        switch (operation) {
          case 'worker_create':
            if (payloadRaw == null) break;
            final payload = jsonDecode(payloadRaw) as Map<String, dynamic>;
            final workerId = payload['workerId'] as String;
            final worker = await _workerRepository.getWorker(workerId);
            if (worker == null) break;
            final baseline = await _baselineRepository.getBaseline(workerId) ??
                WorkerBaseline(workerId: workerId);
            await _workerRepository.pushWorkerToFirestore(
              userId: userId,
              worker: worker,
              baseline: baseline,
            );
          case 'worker_update':
            if (payloadRaw == null) break;
            final payload = jsonDecode(payloadRaw) as Map<String, dynamic>;
            final workerId = payload['workerId'] as String;
            final worker = await _workerRepository.getWorker(workerId);
            if (worker == null) break;
            final baseline = await _baselineRepository.getBaseline(workerId) ??
                WorkerBaseline(workerId: workerId);
            await _workerRepository.pushWorkerToFirestore(
              userId: userId,
              worker: worker,
              baseline: baseline,
            );
          case 'worker_delete':
            final workerId = documentPath.split('/').last;
            await _workerRepository.deleteWorkerFromFirestore(
              userId: userId,
              workerId: workerId,
            );
          case 'scan_create':
            if (payloadRaw == null) break;
            final payload = jsonDecode(payloadRaw) as Map<String, dynamic>;
            final scanId = payload['scanId'] as String;
            final scan = await _scanRepository.getScan(scanId);
            if (scan == null) break;
            await _scanRepository.pushScanToFirestore(
              userId: userId,
              scan: scan,
            );
          case 'baseline_update':
            if (payloadRaw == null) break;
            final payload = jsonDecode(payloadRaw) as Map<String, dynamic>;
            final workerId = payload['workerId'] as String;
            final baseline = await _baselineRepository.getBaseline(workerId);
            if (baseline == null) break;
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('workers')
                .doc(workerId)
                .collection('baselines')
                .doc('current')
                .set(baseline.toFirestore());
            await _databaseService.db.update(
              'baselines',
              {'synced': 1},
              where: 'worker_id = ?',
              whereArgs: [workerId],
            );
          case 'shift_update':
            if (payloadRaw == null) break;
            final payload = jsonDecode(payloadRaw) as Map<String, dynamic>;
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('meta')
                .doc('shift')
                .set(payload);
        }

        await _databaseService.db.delete(
          'sync_queue',
          where: 'id = ?',
          whereArgs: [id],
        );
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') break;
      } catch (_) {
        break;
      }
    }
  }
}

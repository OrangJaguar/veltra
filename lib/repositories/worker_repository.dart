import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/body_metrics.dart';
import '../models/baseline.dart';
import '../models/worker.dart';
import '../services/database_service.dart';

class WorkerRepository {
  WorkerRepository(this._databaseService, this._firestore);

  final DatabaseService _databaseService;
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();
  final _random = Random();

  Future<List<Worker>> getWorkers(String userId) async {
    final rows = await _databaseService.db.query(
      'workers',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Worker.fromMap).toList();
  }

  Future<Worker?> getWorker(String workerId) async {
    final rows = await _databaseService.db.query(
      'workers',
      where: 'id = ?',
      whereArgs: [workerId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Worker.fromMap(rows.first);
  }

  Future<Worker> addWorker({
    required String userId,
    required String name,
    String? employeeId,
    String? role,
    String? nfcId,
    int? age,
    double? heightCm,
    double? weightKg,
    String? photoPath,
  }) async {
    final bmi = BodyMetrics.calculateBmi(
      heightCm: heightCm,
      weightKg: weightKg,
    );

    final worker = Worker(
      id: _uuid.v4(),
      userId: userId,
      name: name.trim(),
      employeeId: _emptyToNull(employeeId),
      role: _emptyToNull(role),
      nfcId: _emptyToNull(nfcId),
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      bmi: bmi,
      photoPath: photoPath,
      createdAt: DateTime.now(),
      synced: false,
    );
    final baseline = WorkerBaseline(workerId: worker.id);

    final db = _databaseService.db;
    await db.transaction((txn) async {
      await txn.insert('workers', worker.toMap());
      await txn.insert('baselines', baseline.toMap());
      await txn.insert('sync_queue', {
        'operation': 'worker_create',
        'user_id': userId,
        'document_path': 'users/$userId/workers/${worker.id}',
        'payload': jsonEncode({
          'worker': worker.toFirestore(),
          'baseline': baseline.toFirestore(),
          'workerId': worker.id,
        }),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    });

    return worker;
  }

  Future<Worker> addDemoWorker({
    required String userId,
    required String name,
  }) async {
    final heightCm = 165 + _random.nextDouble() * 30;
    final weightKg = 62 + _random.nextDouble() * 35;
    final age = 22 + _random.nextInt(28);

    return addWorker(
      userId: userId,
      name: name,
      age: age,
      heightCm: double.parse(heightCm.toStringAsFixed(1)),
      weightKg: double.parse(weightKg.toStringAsFixed(1)),
    );
  }

  Future<void> updateWorkerPhoto({
    required Worker worker,
    required String photoPath,
  }) async {
    await _databaseService.db.update(
      'workers',
      {'photo_path': photoPath, 'synced': 0},
      where: 'id = ?',
      whereArgs: [worker.id],
    );
  }

  Future<Worker> updateWorker({
    required Worker worker,
    required String name,
    String? employeeId,
    String? role,
    String? nfcId,
    int? age,
    double? heightCm,
    double? weightKg,
    String? photoPath,
  }) async {
    final bmi = BodyMetrics.calculateBmi(
      heightCm: heightCm,
      weightKg: weightKg,
    );

    final updated = worker.copyWith(
      name: name.trim(),
      employeeId: _emptyToNull(employeeId),
      role: _emptyToNull(role),
      nfcId: _emptyToNull(nfcId),
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      bmi: bmi,
      photoPath: photoPath ?? worker.photoPath,
      synced: false,
    );

    final db = _databaseService.db;
    await db.transaction((txn) async {
      await txn.update(
        'workers',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [worker.id],
      );
      await txn.insert('sync_queue', {
        'operation': 'worker_update',
        'user_id': worker.userId,
        'document_path': 'users/${worker.userId}/workers/${worker.id}',
        'payload': jsonEncode({'workerId': worker.id}),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    });

    return updated;
  }

  Future<void> deleteWorker(Worker worker) async {
    final db = _databaseService.db;
    await db.transaction((txn) async {
      await txn.delete('baselines', where: 'worker_id = ?', whereArgs: [worker.id]);
      await txn.delete('scans', where: 'worker_id = ?', whereArgs: [worker.id]);
      await txn.delete('workers', where: 'id = ?', whereArgs: [worker.id]);
      await txn.insert('sync_queue', {
        'operation': 'worker_delete',
        'user_id': worker.userId,
        'document_path': 'users/${worker.userId}/workers/${worker.id}',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  Future<void> markWorkerSynced(String workerId) async {
    await _databaseService.db.update(
      'workers',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [workerId],
    );
  }

  Future<void> pushWorkerToFirestore({
    required String userId,
    required Worker worker,
    required WorkerBaseline baseline,
  }) async {
    final workerRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('workers')
        .doc(worker.id);

    await workerRef.set(worker.toFirestore());
    await workerRef.collection('baselines').doc('current').set(baseline.toFirestore());
    await markWorkerSynced(worker.id);
    await _databaseService.db.update(
      'baselines',
      {'synced': 1},
      where: 'worker_id = ?',
      whereArgs: [worker.id],
    );
  }

  Future<void> deleteWorkerFromFirestore({
    required String userId,
    required String workerId,
  }) async {
    final workerRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('workers')
        .doc(workerId);

    final baselineSnap = await workerRef.collection('baselines').get();
    for (final doc in baselineSnap.docs) {
      await doc.reference.delete();
    }
    await workerRef.delete();
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

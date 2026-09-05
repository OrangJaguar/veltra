import 'dart:convert';

import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../models/shift_status.dart';
import 'database_service.dart';

class ShiftService {
  ShiftService(this._databaseService);

  final DatabaseService _databaseService;

  Future<ShiftStatus> getStatus(String userId) async {
    final rows = await _databaseService.db.query(
      'shift_meta',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return const ShiftStatus();
    }

    final startedAt = DateTime.fromMillisecondsSinceEpoch(
      rows.first['current_shift_started_at'] as int,
    );
    final elapsed = DateTime.now().difference(startedAt).inSeconds / 3600.0;
    return ShiftStatus(
      startedAt: startedAt,
      elapsedHours: elapsed.clamp(0, 24),
    );
  }

  /// Auto-start shift on first scan of the calendar day.
  Future<ShiftStatus> ensureShiftForScan(String userId) async {
    final now = DateTime.now();
    final today = _dateKey(now);
    final rows = await _databaseService.db.query(
      'shift_meta',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (rows.isEmpty || rows.first['last_scan_date'] != today) {
      final startedAt = now;
      await _databaseService.db.insert(
        'shift_meta',
        {
          'user_id': userId,
          'current_shift_started_at': startedAt.millisecondsSinceEpoch,
          'last_scan_date': today,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _enqueueShiftSync(userId, startedAt, today);
      return ShiftStatus(startedAt: startedAt, elapsedHours: 0);
    }

    final startedAt = DateTime.fromMillisecondsSinceEpoch(
      rows.first['current_shift_started_at'] as int,
    );
    final elapsed = now.difference(startedAt).inSeconds / 3600.0;
    return ShiftStatus(
      startedAt: startedAt,
      elapsedHours: elapsed.clamp(0, 24),
    );
  }

  Future<void> _enqueueShiftSync(
    String userId,
    DateTime startedAt,
    String lastScanDate,
  ) async {
    await _databaseService.db.insert('sync_queue', {
      'operation': 'shift_update',
      'user_id': userId,
      'document_path': 'users/$userId/meta/shift',
      'payload': jsonEncode({
        'currentShiftStartedAt': startedAt.toUtc().toIso8601String(),
        'lastScanDate': lastScanDate,
      }),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> endShift(String userId) async {
    await _databaseService.db.delete(
      'shift_meta',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  String _dateKey(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}

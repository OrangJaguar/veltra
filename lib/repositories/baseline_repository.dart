import '../models/baseline.dart';
import '../services/database_service.dart';

class BaselineRepository {
  BaselineRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<WorkerBaseline?> getBaseline(String workerId) async {
    final rows = await _databaseService.db.query(
      'baselines',
      where: 'worker_id = ?',
      whereArgs: [workerId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkerBaseline.fromMap(rows.first);
  }

  Future<void> updateBaseline(WorkerBaseline baseline) async {
    await _databaseService.db.update(
      'baselines',
      baseline.toMap(),
      where: 'worker_id = ?',
      whereArgs: [baseline.workerId],
    );
  }
}

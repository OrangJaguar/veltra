import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_schema.dart';

class DatabaseService {
  DatabaseService._(this._db);

  final Database _db;

  Database get db => _db;

  static Future<DatabaseService> open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'veltra.db');
    final db = await openDatabase(
      path,
      version: DatabaseSchema.version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute(DatabaseSchema.createWorkers);
        await db.execute(DatabaseSchema.createBaselines);
        await db.execute(DatabaseSchema.createScans);
        await db.execute(DatabaseSchema.createSyncQueue);
        await db.execute(DatabaseSchema.createWorkersUserIndex);
        await db.execute(DatabaseSchema.createShiftMeta);
        await db.execute(DatabaseSchema.createWeatherCache);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          for (final statement in DatabaseSchema.migrateV2) {
            try {
              await db.execute(statement);
            } catch (_) {
              // Column may already exist from a partial migration.
            }
          }
        }
        if (oldVersion < 3) {
          for (final statement in DatabaseSchema.migrateV3) {
            await db.execute(statement);
          }
        }
        if (oldVersion < 4) {
          for (final statement in DatabaseSchema.migrateV4) {
            try {
              await db.execute(statement);
            } catch (_) {
              // Column may already exist from a partial migration.
            }
          }
          // Drop stale weather rows that predate air-temp caching.
          await db.delete('weather_cache');
        }
      },
    );
    return DatabaseService._(db);
  }

  Future<void> clearUserData(String userId) async {
    final batch = _db.batch();
    final workers = await _db.query(
      'workers',
      columns: ['id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    for (final row in workers) {
      batch.delete('baselines', where: 'worker_id = ?', whereArgs: [row['id']]);
      batch.delete('scans', where: 'worker_id = ?', whereArgs: [row['id']]);
    }
    batch.delete('workers', where: 'user_id = ?', whereArgs: [userId]);
    batch.delete('sync_queue', where: 'user_id = ?', whereArgs: [userId]);
    batch.delete('shift_meta', where: 'user_id = ?', whereArgs: [userId]);
    batch.delete('weather_cache', where: 'user_id = ?', whereArgs: [userId]);
    await batch.commit(noResult: true);
  }
}

abstract final class DatabaseSchema {
  static const version = 4;

  static const createWorkers = '''
    CREATE TABLE workers (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      name TEXT NOT NULL,
      employee_id TEXT,
      role TEXT,
      nfc_id TEXT,
      age INTEGER,
      height_cm REAL,
      weight_kg REAL,
      bmi REAL,
      photo_path TEXT,
      created_at INTEGER NOT NULL,
      last_status TEXT,
      last_scan_at INTEGER,
      synced INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const createBaselines = '''
    CREATE TABLE baselines (
      worker_id TEXT PRIMARY KEY,
      mu_salinity REAL NOT NULL,
      sigma_salinity REAL NOT NULL,
      mu_temp REAL NOT NULL,
      sigma_temp REAL NOT NULL,
      shift_count INTEGER NOT NULL,
      acclimatization REAL NOT NULL,
      synced INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY(worker_id) REFERENCES workers(id) ON DELETE CASCADE
    )
  ''';

  static const createScans = '''
    CREATE TABLE scans (
      id TEXT PRIMARY KEY,
      worker_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      skin_temp REAL NOT NULL,
      sweat_rate REAL NOT NULL,
      salinity REAL NOT NULL,
      sweat_volume REAL,
      wbgt REAL,
      status TEXT NOT NULL,
      recommendation TEXT,
      z_score REAL,
      temp_rate REAL,
      elapsed_hours REAL,
      synced INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY(worker_id) REFERENCES workers(id) ON DELETE CASCADE
    )
  ''';

  static const createSyncQueue = '''
    CREATE TABLE sync_queue (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      operation TEXT NOT NULL,
      user_id TEXT NOT NULL,
      document_path TEXT NOT NULL,
      payload TEXT,
      created_at INTEGER NOT NULL
    )
  ''';

  static const createWorkersUserIndex =
      'CREATE INDEX idx_workers_user ON workers(user_id)';

  static const createShiftMeta = '''
    CREATE TABLE IF NOT EXISTS shift_meta (
      user_id TEXT PRIMARY KEY,
      current_shift_started_at INTEGER NOT NULL,
      last_scan_date TEXT NOT NULL
    )
  ''';

  static const createWeatherCache = '''
    CREATE TABLE IF NOT EXISTS weather_cache (
      user_id TEXT PRIMARY KEY,
      wbgt REAL NOT NULL,
      air_temp_c REAL,
      relative_humidity REAL,
      latitude REAL,
      longitude REAL,
      fetched_at INTEGER NOT NULL
    )
  ''';

  static const migrateV2 = [
    'ALTER TABLE workers ADD COLUMN age INTEGER',
    'ALTER TABLE workers ADD COLUMN height_cm REAL',
    'ALTER TABLE workers ADD COLUMN weight_kg REAL',
    'ALTER TABLE workers ADD COLUMN bmi REAL',
    'ALTER TABLE workers ADD COLUMN photo_path TEXT',
  ];

  static const migrateV3 = [
    createShiftMeta,
    createWeatherCache,
  ];

  static const migrateV4 = [
    'ALTER TABLE weather_cache ADD COLUMN air_temp_c REAL',
    'ALTER TABLE weather_cache ADD COLUMN relative_humidity REAL',
  ];
}

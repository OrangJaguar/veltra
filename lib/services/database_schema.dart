abstract final class DatabaseSchema {
  static const version = 6;

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
      synced INTEGER NOT NULL DEFAULT 0,
      crew_id TEXT,
      archived INTEGER NOT NULL DEFAULT 0,
      pod_id TEXT
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

  static const createWorkersCrewIndex =
      'CREATE INDEX IF NOT EXISTS idx_workers_crew ON workers(crew_id)';

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

  static const createCrews = '''
    CREATE TABLE IF NOT EXISTS crews (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      site_label TEXT,
      created_at INTEGER NOT NULL
    )
  ''';

  static const createWindows = '''
    CREATE TABLE IF NOT EXISTS checkin_windows (
      id TEXT PRIMARY KEY,
      crew_id TEXT NOT NULL,
      opened_at INTEGER NOT NULL,
      closed_at INTEGER,
      FOREIGN KEY(crew_id) REFERENCES crews(id) ON DELETE CASCADE
    )
  ''';

  static const createWindowsOneOpenIndex = '''
    CREATE UNIQUE INDEX IF NOT EXISTS idx_windows_one_open
    ON checkin_windows(crew_id)
    WHERE closed_at IS NULL
  ''';

  static const createAttempts = '''
    CREATE TABLE IF NOT EXISTS checkin_attempts (
      id TEXT PRIMARY KEY,
      crew_id TEXT NOT NULL,
      worker_id TEXT NOT NULL,
      window_id TEXT NOT NULL,
      outcome TEXT NOT NULL,
      error TEXT,
      created_at INTEGER NOT NULL,
      FOREIGN KEY(crew_id) REFERENCES crews(id) ON DELETE CASCADE,
      FOREIGN KEY(worker_id) REFERENCES workers(id) ON DELETE CASCADE,
      FOREIGN KEY(window_id) REFERENCES checkin_windows(id) ON DELETE CASCADE
    )
  ''';

  static const createCheckIns = '''
    CREATE TABLE IF NOT EXISTS check_ins (
      id TEXT PRIMARY KEY,
      attempt_id TEXT NOT NULL UNIQUE,
      crew_id TEXT NOT NULL,
      worker_id TEXT NOT NULL,
      window_id TEXT NOT NULL,
      captured_at INTEGER NOT NULL,
      source TEXT NOT NULL,
      pod_id TEXT,
      cartridge_session_id TEXT,
      forehead_temp_c REAL,
      strip_volume_ul REAL,
      conductivity_us_cm REAL,
      sweat_rate_ul_min REAL,
      forehead_temp_available INTEGER NOT NULL DEFAULT 0,
      strip_volume_available INTEGER NOT NULL DEFAULT 0,
      conductivity_available INTEGER NOT NULL DEFAULT 0,
      sweat_rate_available INTEGER NOT NULL DEFAULT 0,
      read_quality TEXT,
      weather_air_temp_c REAL,
      weather_humidity REAL,
      weather_wbgt REAL,
      weather_source TEXT,
      weather_fetched_at INTEGER,
      FOREIGN KEY(attempt_id) REFERENCES checkin_attempts(id) ON DELETE CASCADE,
      FOREIGN KEY(crew_id) REFERENCES crews(id) ON DELETE CASCADE,
      FOREIGN KEY(worker_id) REFERENCES workers(id) ON DELETE CASCADE,
      FOREIGN KEY(window_id) REFERENCES checkin_windows(id) ON DELETE CASCADE
    )
  ''';

  static const createCheckInsWindowIndex =
      'CREATE INDEX IF NOT EXISTS idx_check_ins_window ON check_ins(window_id, worker_id)';

  static const createFollowUps = '''
    CREATE TABLE IF NOT EXISTS follow_ups (
      id TEXT PRIMARY KEY,
      worker_id TEXT NOT NULL,
      window_id TEXT NOT NULL,
      requested_at INTEGER NOT NULL,
      note TEXT,
      completed_at INTEGER,
      FOREIGN KEY(worker_id) REFERENCES workers(id) ON DELETE CASCADE,
      FOREIGN KEY(window_id) REFERENCES checkin_windows(id) ON DELETE CASCADE
    )
  ''';

  static const createDemoConfig = '''
    CREATE TABLE IF NOT EXISTS demo_config (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      crew_id TEXT,
      role TEXT NOT NULL,
      worker_id TEXT,
      scan_source TEXT NOT NULL,
      scenario TEXT,
      presented_pod_id TEXT
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

  static const migrateV5 = [
    createCrews,
    createWindows,
    createWindowsOneOpenIndex,
    createAttempts,
    createCheckIns,
    createCheckInsWindowIndex,
    createFollowUps,
    createDemoConfig,
    'ALTER TABLE workers ADD COLUMN crew_id TEXT',
    'ALTER TABLE workers ADD COLUMN archived INTEGER NOT NULL DEFAULT 0',
    'ALTER TABLE workers ADD COLUMN pod_id TEXT',
    createWorkersCrewIndex,
  ];

  static const migrateV6 = [
    'ALTER TABLE demo_config ADD COLUMN presented_pod_id TEXT',
  ];

  /// Schema written by app versions that stored v4. Used to prove an upgrade
  /// keeps old workers and scans.
  static const legacyV4Workers = '''
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
}

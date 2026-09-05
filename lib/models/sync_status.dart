enum SyncStatus {
  synced,
  pending,
  offline,
}

enum WorkerStatus {
  none,
  green,
  amber,
  red;

  static WorkerStatus? fromString(String? value) {
    if (value == null) return null;
    return WorkerStatus.values.firstWhere(
      (s) => s.name.toUpperCase() == value.toUpperCase(),
      orElse: () => WorkerStatus.none,
    );
  }

  String? get label {
    switch (this) {
      case WorkerStatus.none:
        return null;
      case WorkerStatus.green:
        return 'GREEN';
      case WorkerStatus.amber:
        return 'AMBER';
      case WorkerStatus.red:
        return 'RED';
    }
  }
}

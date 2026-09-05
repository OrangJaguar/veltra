import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scan_record.dart';
import '../models/sync_status.dart';
import '../models/worker.dart';
import 'worker_providers.dart';

final workerScansProvider =
    FutureProvider.autoDispose.family<List<ScanRecord>, String>((ref, workerId) {
  return ref.read(scanRepositoryProvider).getScansForWorker(workerId);
});

final crewStatusFilterProvider = StateProvider<WorkerStatus?>((ref) => null);

final filteredWorkersProvider = Provider.autoDispose<List<Worker>>((ref) {
  final workers = ref.watch(workersListProvider).valueOrNull ?? [];
  final filter = ref.watch(crewStatusFilterProvider);
  if (filter == null) return workers;
  return workers.where((w) => w.lastStatus == filter).toList();
});

enum TrendMetric {
  skinTemp('Skin temp', '°C'),
  zScore('Z-score', ''),
  salinity('Salinity', 'mmol/L'),
  sweatRate('Sweat rate', 'L/hr');

  const TrendMetric(this.label, this.unit);
  final String label;
  final String unit;

  double? valueFrom(ScanRecord scan) {
    switch (this) {
      case TrendMetric.skinTemp:
        return scan.skinTemp;
      case TrendMetric.zScore:
        return scan.zScore;
      case TrendMetric.salinity:
        return scan.salinity;
      case TrendMetric.sweatRate:
        return scan.sweatRate;
    }
  }
}

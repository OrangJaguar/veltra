import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/demo_mode.dart';
import '../features/auth/providers/auth_providers.dart';
import '../models/sync_status.dart';
import '../models/worker.dart';
import '../repositories/baseline_repository.dart';
import '../repositories/scan_repository.dart';
import '../repositories/worker_repository.dart';
import '../services/database_service.dart';
import '../services/demo_data_service.dart';
import '../services/photo_service.dart';
import '../services/sync_service.dart';
import 'settings_providers.dart';

/// Set in main() before runApp.
late DatabaseService appDatabase;

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return appDatabase;
});

final workerRepositoryProvider = Provider<WorkerRepository>((ref) {
  return WorkerRepository(
    ref.watch(databaseServiceProvider),
    ref.watch(firestoreProvider),
  );
});

final baselineRepositoryProvider = Provider<BaselineRepository>((ref) {
  return BaselineRepository(ref.watch(databaseServiceProvider));
});

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepository(
    ref.watch(databaseServiceProvider),
    ref.watch(firestoreProvider),
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(databaseServiceProvider),
    ref.watch(workerRepositoryProvider),
    ref.watch(baselineRepositoryProvider),
    ref.watch(scanRepositoryProvider),
    ref.watch(firestoreProvider),
    Connectivity(),
  );
});

final demoDataServiceProvider = Provider<DemoDataService>((ref) {
  return DemoDataService(ref.watch(workerRepositoryProvider));
});

final photoServiceProvider = Provider<PhotoService>((ref) => PhotoService());

final workersListProvider =
    FutureProvider.autoDispose<List<Worker>>((ref) async {
  final userId = ref.watch(activeUserIdProvider);
  if (userId == null) return [];

  return ref.read(workerRepositoryProvider).getWorkers(userId);
});

final syncStatusProvider = StreamProvider.autoDispose<SyncStatus>((ref) async* {
  final userId = ref.watch(activeUserIdProvider);
  if (userId == null) {
    yield SyncStatus.offline;
    return;
  }

  final syncService = ref.watch(syncServiceProvider);

  Future<SyncStatus> compute() async {
    final online = await syncService.isOnline;
    if (!online) return SyncStatus.offline;
    final pending = await syncService.pendingCount(userId);
    return pending > 0 ? SyncStatus.pending : SyncStatus.synced;
  }

  yield await compute();

  await for (final _ in syncService.connectivityStream) {
    await _flushSyncQueue(ref, silent: true);
    yield await compute();
  }
});

/// Called from ConsumerWidget screens.
void refreshWorkers(WidgetRef ref) {
  ref.invalidate(workersListProvider);
  ref.invalidate(syncStatusProvider);
}

/// Called from ConsumerWidget screens.
Future<void> syncNow(WidgetRef ref, {bool silent = false}) async {
  final userId = ref.read(activeUserIdProvider);
  if (userId == null) return;

  try {
    await ref.read(syncServiceProvider).flushQueue(userId);
    await recordLastSyncTime();
    ref.invalidate(lastSyncTimeProvider);
    refreshWorkers(ref);
  } catch (e) {
    if (!silent) rethrow;
  }
}

/// Internal helper for provider callbacks (uses Ref, not WidgetRef).
Future<void> _flushSyncQueue(Ref ref, {bool silent = false}) async {
  final userId = ref.read(activeUserIdProvider);
  if (userId == null) return;

  try {
    await ref.read(syncServiceProvider).flushQueue(userId);
    await recordLastSyncTime();
    ref.invalidate(lastSyncTimeProvider);
    ref.invalidate(workersListProvider);
    ref.invalidate(syncStatusProvider);
  } catch (e) {
    if (!silent) rethrow;
  }
}

final syncBootstrapProvider = Provider<void>((ref) {
  ref.listen(authStateProvider, (_, next) async {
    final user = next.valueOrNull;
    if (user == null) return;
    await _flushSyncQueue(ref, silent: true);
  });
});

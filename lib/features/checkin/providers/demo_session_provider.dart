import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo_mode.dart';
import '../../../models/check_in.dart';
import '../../../models/check_in_window.dart';
import '../../../models/crew.dart';
import '../../../models/demo_config.dart';
import '../../../models/follow_up.dart';
import '../../../models/roster_entry.dart';
import '../../../models/worker.dart';
import '../../../providers/worker_providers.dart';
import '../../scan/providers/scan_flow_provider.dart';

final checkInRevisionProvider = StateProvider<int>((ref) => 0);

final demoSessionProvider =
    AsyncNotifierProvider<DemoSession, DemoConfig>(DemoSession.new);

class DemoSession extends AsyncNotifier<DemoConfig> {
  @override
  Future<DemoConfig> build() async {
    await ref.read(demoDataServiceProvider).seedCheckInDemo(demoUserId);
    final existing = await ref.watch(checkInRepositoryProvider).getDemoConfig();
    if (existing != null) return existing;
    return const DemoConfig(
      role: DemoRoles.worker,
      scanSource: CheckInSources.simulated,
    );
  }

  Future<void> setRole(String role) async {
    final current = state.valueOrNull;
    if (current == null || current.role == role) return;
    final next = current.copyWith(role: role);
    await ref.read(checkInRepositoryProvider).saveDemoConfig(next);
    state = AsyncData(next);
  }

  Future<void> setWorker(String workerId) async {
    final current = state.valueOrNull;
    if (current == null || current.workerId == workerId) return;
    final next = current.copyWith(workerId: workerId);
    await ref.read(checkInRepositoryProvider).saveDemoConfig(next);
    state = AsyncData(next);
  }

  Future<void> saveConfig(DemoConfig Function(DemoConfig current) change) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = change(current);
    await ref.read(checkInRepositoryProvider).saveDemoConfig(next);
    state = AsyncData(next);
  }
}

final checkInCrewProvider = FutureProvider<Crew?>((ref) async {
  ref.watch(checkInRevisionProvider);
  final config = await ref.watch(demoSessionProvider.future);
  final crewId = config.crewId;
  if (crewId == null) return null;
  return ref.read(checkInRepositoryProvider).getCrew(crewId);
});

final openCheckInWindowProvider = FutureProvider<CheckInWindow?>((ref) async {
  ref.watch(checkInRevisionProvider);
  final config = await ref.watch(demoSessionProvider.future);
  final crewId = config.crewId;
  if (crewId == null) return null;
  return ref.read(checkInRepositoryProvider).getOpenWindow(crewId);
});

final latestWindowProvider = FutureProvider<CheckInWindow?>((ref) async {
  ref.watch(checkInRevisionProvider);
  final config = await ref.watch(demoSessionProvider.future);
  final crewId = config.crewId;
  if (crewId == null) return null;
  return ref.read(checkInRepositoryProvider).latestWindow(crewId);
});

final crewsProvider = FutureProvider<List<Crew>>((ref) async {
  ref.watch(checkInRevisionProvider);
  return ref.read(checkInRepositoryProvider).listCrews();
});

final crewWorkersProvider = FutureProvider<List<Worker>>((ref) async {
  ref.watch(checkInRevisionProvider);
  final config = await ref.watch(demoSessionProvider.future);
  final crewId = config.crewId;
  if (crewId == null) return [];
  return ref.read(checkInRepositoryProvider).workersInCrew(crewId);
});

final activeCrewWorkersProvider = FutureProvider<List<Worker>>((ref) async {
  ref.watch(checkInRevisionProvider);
  final config = await ref.watch(demoSessionProvider.future);
  final crewId = config.crewId;
  if (crewId == null) return [];
  return ref.read(checkInRepositoryProvider).activeWorkers(crewId);
});

final workerByIdProvider =
    FutureProvider.family<Worker?, String>((ref, workerId) {
  ref.watch(checkInRevisionProvider);
  return ref.read(workerRepositoryProvider).getWorker(workerId);
});

final selectedWorkerProvider = FutureProvider<Worker?>((ref) async {
  ref.watch(checkInRevisionProvider);
  final config = await ref.watch(demoSessionProvider.future);
  final workerId = config.workerId;
  if (workerId == null) return null;
  return ref.read(workerRepositoryProvider).getWorker(workerId);
});

final rosterProvider = FutureProvider<List<RosterEntry>>((ref) async {
  ref.watch(checkInRevisionProvider);
  final config = await ref.watch(demoSessionProvider.future);
  final crewId = config.crewId;
  if (crewId == null) return [];
  final window = await ref.watch(latestWindowProvider.future);
  if (window == null) return [];
  return ref.read(checkInRepositoryProvider).roster(
        crewId: crewId,
        windowId: window.id,
      );
});

final latestSelectedCheckInProvider = FutureProvider<CheckIn?>((ref) async {
  final worker = await ref.watch(selectedWorkerProvider.future);
  if (worker == null) return null;
  final rows = await ref.watch(workerCheckInsProvider(worker.id).future);
  if (rows.isEmpty) return null;
  return rows.first;
});

final workerCheckInsProvider =
    FutureProvider.family<List<CheckIn>, String>((ref, workerId) async {
  ref.watch(checkInRevisionProvider);
  return ref.read(checkInRepositoryProvider).checkInsForWorker(workerId);
});

final workerFollowUpProvider =
    FutureProvider.family<FollowUp?, String>((ref, workerId) async {
  ref.watch(checkInRevisionProvider);
  final window = await ref.watch(latestWindowProvider.future);
  if (window == null) return null;
  return ref.read(checkInRepositoryProvider).openFollowUp(
        workerId: workerId,
        windowId: window.id,
      );
});

final selectedFollowUpProvider = FutureProvider<FollowUp?>((ref) async {
  final worker = await ref.watch(selectedWorkerProvider.future);
  if (worker == null) return null;
  return ref.watch(workerFollowUpProvider(worker.id).future);
});

final optionalWeatherProvider = FutureProvider<CheckInWeather?>((ref) async {
  final userId = ref.watch(activeUserIdProvider);
  if (userId == null) return null;
  final labeled =
      await ref.read(weatherServiceProvider).readOptionalContext(userId);
  if (labeled == null) return null;
  return CheckInWeather(
    airTempC: labeled.reading.airTempC,
    relativeHumidity: labeled.reading.relativeHumidity,
    wbgt: labeled.reading.wbgt,
    source: labeled.source,
    fetchedAt: DateTime.now().toUtc(),
  );
});

void bumpCheckIns(WidgetRef ref) {
  ref.read(checkInRevisionProvider.notifier).state++;
}

import '../repositories/check_in_repository.dart';
import '../repositories/worker_repository.dart';

class DemoDataService {
  DemoDataService(this._workerRepository, this._checkInRepository);

  final WorkerRepository _workerRepository;
  final CheckInRepository _checkInRepository;

  static const demoNames = ['Jake', 'Maria', 'Dev', 'Chris', 'Sam'];

  /// Old foreman roster. Settings still calls this. It is not the check-in crew.
  Future<int> seedDemoCrew(String userId) async {
    var count = 0;
    for (final name in demoNames) {
      await _workerRepository.addDemoWorker(userId: userId, name: name);
      count++;
    }
    return count;
  }

  /// Three stable workers, one crew, one open window. Safe to call again.
  Future<void> seedCheckInDemo(String userId) {
    return _checkInRepository.seedDemoCrew(userId);
  }
}

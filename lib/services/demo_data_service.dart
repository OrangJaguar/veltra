import '../repositories/worker_repository.dart';

class DemoDataService {
  DemoDataService(this._workerRepository);

  final WorkerRepository _workerRepository;

  static const demoNames = ['Jake', 'Maria', 'Dev', 'Chris', 'Sam'];

  Future<int> seedDemoCrew(String userId) async {
    var count = 0;
    for (final name in demoNames) {
      await _workerRepository.addDemoWorker(userId: userId, name: name);
      count++;
    }
    return count;
  }
}

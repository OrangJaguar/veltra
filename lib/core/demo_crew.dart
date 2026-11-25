/// Stable local ids for the check-in demo. A second launch must not
/// create another crew, worker, or window.
abstract final class DemoCrew {
  static const crewId = 'veltra-demo-crew';
  static const windowId = 'veltra-demo-window';
  static const crewName = 'Demo Crew';
  static const siteLabel = 'Test Site';

  static const workers = <DemoWorkerSeed>[
    DemoWorkerSeed(
      id: 'veltra-demo-worker-avery',
      name: 'Avery',
      employeeId: 'A-101',
      age: 29,
      heightCm: 168,
      weightKg: 62,
    ),
    DemoWorkerSeed(
      id: 'veltra-demo-worker-blake',
      name: 'Blake',
      employeeId: 'B-102',
      age: 34,
      heightCm: 180,
      weightKg: 82,
    ),
    DemoWorkerSeed(
      id: 'veltra-demo-worker-casey',
      name: 'Casey',
      employeeId: 'C-103',
      age: 26,
      heightCm: 163,
      weightKg: 58,
    ),
  ];
}

class DemoWorkerSeed {
  const DemoWorkerSeed({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.age,
    required this.heightCm,
    required this.weightKg,
  });

  final String id;
  final String name;
  final String employeeId;
  final int age;
  final double heightCm;
  final double weightKg;
}

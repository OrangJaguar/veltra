abstract final class DemoRoles {
  static const worker = 'worker';
  static const supervisor = 'supervisor';
  static const demoAdmin = 'demoAdmin';
}

class DemoConfig {
  const DemoConfig({
    this.crewId,
    required this.role,
    this.workerId,
    required this.scanSource,
    this.scenario,
    this.presentedPodId,
  });

  final String? crewId;
  final String role;
  final String? workerId;
  final String scanSource;
  final String? scenario;
  final String? presentedPodId;

  DemoConfig copyWith({
    String? crewId,
    String? role,
    String? workerId,
    String? scanSource,
    String? scenario,
    String? presentedPodId,
    bool clearPresentedPod = false,
    bool clearWorker = false,
  }) {
    return DemoConfig(
      crewId: crewId ?? this.crewId,
      role: role ?? this.role,
      workerId: clearWorker ? null : (workerId ?? this.workerId),
      scanSource: scanSource ?? this.scanSource,
      scenario: scenario ?? this.scenario,
      presentedPodId:
          clearPresentedPod ? null : (presentedPodId ?? this.presentedPodId),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'crew_id': crewId,
      'role': role,
      'worker_id': workerId,
      'scan_source': scanSource,
      'scenario': scenario,
      'presented_pod_id': presentedPodId,
    };
  }

  factory DemoConfig.fromMap(Map<String, dynamic> map) {
    return DemoConfig(
      crewId: map['crew_id'] as String?,
      role: map['role'] as String,
      workerId: map['worker_id'] as String?,
      scanSource: map['scan_source'] as String,
      scenario: map['scenario'] as String?,
      presentedPodId: map['presented_pod_id'] as String?,
    );
  }
}

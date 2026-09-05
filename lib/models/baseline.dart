class WorkerBaseline {
  const WorkerBaseline({
    required this.workerId,
    this.muSalinity = 45.0,
    this.sigmaSalinity = 10.0,
    this.muTemp = 36.8,
    this.sigmaTemp = 0.4,
    this.shiftCount = 0,
    this.acclimatization = 1.0,
    this.synced = false,
  });

  final String workerId;
  final double muSalinity;
  final double sigmaSalinity;
  final double muTemp;
  final double sigmaTemp;
  final int shiftCount;
  final double acclimatization;
  final bool synced;

  Map<String, dynamic> toMap() {
    return {
      'worker_id': workerId,
      'mu_salinity': muSalinity,
      'sigma_salinity': sigmaSalinity,
      'mu_temp': muTemp,
      'sigma_temp': sigmaTemp,
      'shift_count': shiftCount,
      'acclimatization': acclimatization,
      'synced': synced ? 1 : 0,
    };
  }

  factory WorkerBaseline.fromMap(Map<String, dynamic> map) {
    return WorkerBaseline(
      workerId: map['worker_id'] as String,
      muSalinity: (map['mu_salinity'] as num?)?.toDouble() ?? 45.0,
      sigmaSalinity: (map['sigma_salinity'] as num?)?.toDouble() ?? 10.0,
      muTemp: (map['mu_temp'] as num?)?.toDouble() ?? 36.8,
      sigmaTemp: (map['sigma_temp'] as num?)?.toDouble() ?? 0.4,
      shiftCount: map['shift_count'] as int? ?? 0,
      acclimatization: (map['acclimatization'] as num?)?.toDouble() ?? 1.0,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'muSalinity': muSalinity,
      'sigmaSalinity': sigmaSalinity,
      'muTemp': muTemp,
      'sigmaTemp': sigmaTemp,
      'shiftCount': shiftCount,
      'acclimatization': acclimatization,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

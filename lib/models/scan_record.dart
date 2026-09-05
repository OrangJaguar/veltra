import 'sync_status.dart';

class ScanRecord {
  const ScanRecord({
    required this.id,
    required this.workerId,
    required this.userId,
    required this.timestamp,
    required this.skinTemp,
    required this.sweatRate,
    required this.salinity,
    this.sweatVolume,
    this.wbgt,
    required this.status,
    this.recommendation,
    this.zScore,
    this.tempRate,
    this.elapsedHours,
    this.synced = false,
  });

  final String id;
  final String workerId;
  final String userId;
  final DateTime timestamp;
  final double skinTemp;
  final double sweatRate;
  final double salinity;
  final double? sweatVolume;
  final double? wbgt;
  final WorkerStatus status;
  final String? recommendation;
  final double? zScore;
  final double? tempRate;
  final double? elapsedHours;
  final bool synced;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'user_id': userId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'skin_temp': skinTemp,
      'sweat_rate': sweatRate,
      'salinity': salinity,
      'sweat_volume': sweatVolume,
      'wbgt': wbgt,
      'status': status.name,
      'recommendation': recommendation,
      'z_score': zScore,
      'temp_rate': tempRate,
      'elapsed_hours': elapsedHours,
      'synced': synced ? 1 : 0,
    };
  }

  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      id: map['id'] as String,
      workerId: map['worker_id'] as String,
      userId: map['user_id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      skinTemp: (map['skin_temp'] as num).toDouble(),
      sweatRate: (map['sweat_rate'] as num).toDouble(),
      salinity: (map['salinity'] as num).toDouble(),
      sweatVolume: (map['sweat_volume'] as num?)?.toDouble(),
      wbgt: (map['wbgt'] as num?)?.toDouble(),
      status: WorkerStatus.fromString(map['status'] as String?) ??
          WorkerStatus.none,
      recommendation: map['recommendation'] as String?,
      zScore: (map['z_score'] as num?)?.toDouble(),
      tempRate: (map['temp_rate'] as num?)?.toDouble(),
      elapsedHours: (map['elapsed_hours'] as num?)?.toDouble(),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}

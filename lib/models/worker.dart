import 'sync_status.dart';

class Worker {
  const Worker({
    required this.id,
    required this.userId,
    required this.name,
    this.employeeId,
    this.role,
    this.nfcId,
    this.age,
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.photoPath,
    required this.createdAt,
    this.lastStatus,
    this.lastScanAt,
    this.synced = false,
  });

  final String id;
  final String userId;
  final String name;
  final String? employeeId;
  final String? role;
  final String? nfcId;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final String? photoPath;
  final DateTime createdAt;
  final WorkerStatus? lastStatus;
  final DateTime? lastScanAt;
  final bool synced;

  Worker copyWith({
    String? name,
    String? employeeId,
    String? role,
    String? nfcId,
    int? age,
    double? heightCm,
    double? weightKg,
    double? bmi,
    String? photoPath,
    WorkerStatus? lastStatus,
    DateTime? lastScanAt,
    bool? synced,
  }) {
    return Worker(
      id: id,
      userId: userId,
      name: name ?? this.name,
      employeeId: employeeId ?? this.employeeId,
      role: role ?? this.role,
      nfcId: nfcId ?? this.nfcId,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bmi: bmi ?? this.bmi,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt,
      lastStatus: lastStatus ?? this.lastStatus,
      lastScanAt: lastScanAt ?? this.lastScanAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'employee_id': employeeId,
      'role': role,
      'nfc_id': nfcId,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'bmi': bmi,
      'photo_path': photoPath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_status': lastStatus?.name,
      'last_scan_at': lastScanAt?.millisecondsSinceEpoch,
      'synced': synced ? 1 : 0,
    };
  }

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      employeeId: map['employee_id'] as String?,
      role: map['role'] as String?,
      nfcId: map['nfc_id'] as String?,
      age: map['age'] as int?,
      heightCm: (map['height_cm'] as num?)?.toDouble(),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      bmi: (map['bmi'] as num?)?.toDouble(),
      photoPath: map['photo_path'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      lastStatus: WorkerStatus.fromString(map['last_status'] as String?),
      lastScanAt: map['last_scan_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_scan_at'] as int)
          : null,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (employeeId != null && employeeId!.isNotEmpty) 'employeeId': employeeId,
      if (role != null && role!.isNotEmpty) 'role': role,
      if (nfcId != null && nfcId!.isNotEmpty) 'nfcId': nfcId,
      if (age != null) 'age': age,
      if (heightCm != null) 'heightCm': heightCm,
      if (weightKg != null) 'weightKg': weightKg,
      if (bmi != null) 'bmi': bmi,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
}

class CheckInAttempt {
  const CheckInAttempt({
    required this.id,
    required this.crewId,
    required this.workerId,
    required this.windowId,
    required this.outcome,
    this.error,
    required this.createdAt,
  });

  final String id;
  final String crewId;
  final String workerId;
  final String windowId;
  final String outcome;
  final String? error;
  final DateTime createdAt;

  factory CheckInAttempt.fromMap(Map<String, dynamic> map) {
    return CheckInAttempt(
      id: map['id'] as String,
      crewId: map['crew_id'] as String,
      workerId: map['worker_id'] as String,
      windowId: map['window_id'] as String,
      outcome: map['outcome'] as String,
      error: map['error'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
        isUtc: true,
      ),
    );
  }
}

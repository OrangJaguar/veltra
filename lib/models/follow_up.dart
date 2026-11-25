class FollowUp {
  const FollowUp({
    required this.id,
    required this.workerId,
    required this.windowId,
    required this.requestedAt,
    this.note,
    this.completedAt,
  });

  final String id;
  final String workerId;
  final String windowId;
  final DateTime requestedAt;
  final String? note;
  final DateTime? completedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'window_id': windowId,
      'requested_at': requestedAt.toUtc().millisecondsSinceEpoch,
      'note': note,
      'completed_at': completedAt?.toUtc().millisecondsSinceEpoch,
    };
  }

  factory FollowUp.fromMap(Map<String, dynamic> map) {
    return FollowUp(
      id: map['id'] as String,
      workerId: map['worker_id'] as String,
      windowId: map['window_id'] as String,
      requestedAt: DateTime.fromMillisecondsSinceEpoch(
        map['requested_at'] as int,
        isUtc: true,
      ),
      note: map['note'] as String?,
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              map['completed_at'] as int,
              isUtc: true,
            ),
    );
  }
}

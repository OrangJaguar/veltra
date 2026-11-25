class CheckInWindow {
  const CheckInWindow({
    required this.id,
    required this.crewId,
    required this.openedAt,
    this.closedAt,
  });

  final String id;
  final String crewId;
  final DateTime openedAt;
  final DateTime? closedAt;

  bool get isOpen => closedAt == null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'crew_id': crewId,
      'opened_at': openedAt.toUtc().millisecondsSinceEpoch,
      'closed_at': closedAt?.toUtc().millisecondsSinceEpoch,
    };
  }

  factory CheckInWindow.fromMap(Map<String, dynamic> map) {
    return CheckInWindow(
      id: map['id'] as String,
      crewId: map['crew_id'] as String,
      openedAt: DateTime.fromMillisecondsSinceEpoch(
        map['opened_at'] as int,
        isUtc: true,
      ),
      closedAt: map['closed_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              map['closed_at'] as int,
              isUtc: true,
            ),
    );
  }
}

class OpenWindowResult {
  const OpenWindowResult({required this.window, required this.created});

  final CheckInWindow window;
  final bool created;
}

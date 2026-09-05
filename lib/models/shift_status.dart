class ShiftStatus {
  const ShiftStatus({
    this.startedAt,
    this.elapsedHours = 0,
  });

  final DateTime? startedAt;
  final double elapsedHours;

  bool get isActive => startedAt != null;

  String get chipLabel {
    if (!isActive) return 'Shift · starts on scan';
    final totalMinutes = (elapsedHours * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return 'Shift · ${minutes}m';
    if (minutes == 0) return 'Shift · ${hours}h';
    return 'Shift · ${hours}h ${minutes}m';
  }
}

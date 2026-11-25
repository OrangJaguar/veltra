import 'check_in.dart';
import 'worker.dart';

enum RosterStatus {
  waiting,
  checkedIn,
  retryRequested,
  missed;

  String get label {
    switch (this) {
      case RosterStatus.waiting:
        return 'Waiting';
      case RosterStatus.checkedIn:
        return 'Checked in';
      case RosterStatus.retryRequested:
        return 'Retry requested';
      case RosterStatus.missed:
        return 'Missed';
    }
  }
}

/// A closed window with no save is Missed. An open recheck does not erase a
/// saved check-in, and it outranks Checked in on the row.
RosterStatus rosterStatus({
  required bool windowOpen,
  required bool hasCheckIn,
  required bool recheckRequested,
}) {
  if (!windowOpen && !hasCheckIn) return RosterStatus.missed;
  if (recheckRequested) return RosterStatus.retryRequested;
  if (hasCheckIn) return RosterStatus.checkedIn;
  return RosterStatus.waiting;
}

class RosterEntry {
  const RosterEntry({
    required this.worker,
    this.latestCheckIn,
    this.status = RosterStatus.waiting,
  });

  final Worker worker;
  final CheckIn? latestCheckIn;
  final RosterStatus status;

  bool get isCheckedIn => latestCheckIn != null;
}

Map<RosterStatus, int> tallyRoster(Iterable<RosterEntry> entries) {
  final counts = {for (final status in RosterStatus.values) status: 0};
  for (final entry in entries) {
    counts[entry.status] = counts[entry.status]! + 1;
  }
  return counts;
}

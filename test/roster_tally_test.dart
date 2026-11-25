import 'package:flutter_test/flutter_test.dart';
import 'package:veltra/models/roster_entry.dart';
import 'package:veltra/models/worker.dart';

Worker _worker(String name) {
  return Worker(
    id: name,
    userId: 'user',
    name: name,
    createdAt: DateTime.utc(2026, 11, 24),
  );
}

void main() {
  test('dashboard counts keep a retry separate from checked in', () {
    final entries = [
      RosterEntry(worker: _worker('Avery'), status: RosterStatus.checkedIn),
      RosterEntry(worker: _worker('Blake'), status: RosterStatus.retryRequested),
      RosterEntry(worker: _worker('Casey'), status: RosterStatus.missed),
    ];

    final counts = tallyRoster(entries);

    expect(counts[RosterStatus.waiting], 0);
    expect(counts[RosterStatus.checkedIn], 1);
    expect(counts[RosterStatus.retryRequested], 1);
    expect(counts[RosterStatus.missed], 1);
    expect(
      entries.where((entry) => entry.status != RosterStatus.checkedIn).length,
      2,
    );
  });
}

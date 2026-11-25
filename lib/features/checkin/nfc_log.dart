import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/nfc_tag_session.dart';

class NfcLogEntry {
  const NfcLogEntry({
    required this.at,
    required this.kind,
    required this.result,
    required this.elapsed,
    this.technologies = const [],
    this.identifier,
    this.payload,
  });

  final DateTime at;
  final String kind;
  final String result;
  final Duration elapsed;
  final List<String> technologies;
  final String? identifier;
  final String? payload;
}

final tagSessionProvider = Provider<NfcTagSession>((ref) => NfcTagSession());

final nfcEnabledProvider = FutureProvider<bool>((ref) {
  return ref.read(tagSessionProvider).isEnabled();
});

final nfcLogProvider = StateProvider<List<NfcLogEntry>>((ref) => const []);

void addNfcLog(WidgetRef ref, NfcLogEntry entry) {
  final current = ref.read(nfcLogProvider);
  ref.read(nfcLogProvider.notifier).state = [entry, ...current].take(8).toList();
}

String formatReadDuration(Duration elapsed) {
  if (elapsed.inMilliseconds >= 1000) {
    return '${(elapsed.inMilliseconds / 1000).toStringAsFixed(1)} s';
  }
  return '${elapsed.inMilliseconds} ms';
}

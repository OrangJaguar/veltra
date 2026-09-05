import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ttsEnabledKey = 'veltra_tts_enabled';
const _lastSyncKey = 'veltra_last_sync_ms';

final ttsEnabledProvider =
    StateNotifierProvider<TtsEnabledNotifier, bool>((ref) {
  return TtsEnabledNotifier();
});

class TtsEnabledNotifier extends StateNotifier<bool> {
  TtsEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_ttsEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ttsEnabledKey, value);
  }
}

final devSectionExpandedProvider = StateProvider<bool>((ref) => false);

Future<void> recordLastSyncTime() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
}

final lastSyncTimeProvider = FutureProvider<DateTime?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final ms = prefs.getInt(_lastSyncKey);
  if (ms == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(ms);
});

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
});

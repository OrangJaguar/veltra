import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MockScanPreset {
  random,
  forceGreen,
  forceAmber,
  forceRed,
}

const _mockPresetKey = 'veltra_mock_scan_preset';

final mockScanPresetProvider =
    StateNotifierProvider<MockScanPresetNotifier, MockScanPreset>((ref) {
  return MockScanPresetNotifier();
});

class MockScanPresetNotifier extends StateNotifier<MockScanPreset> {
  MockScanPresetNotifier() : super(MockScanPreset.random) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_mockPresetKey);
    if (index != null && index >= 0 && index < MockScanPreset.values.length) {
      state = MockScanPreset.values[index];
    }
  }

  Future<void> setPreset(MockScanPreset preset) async {
    state = preset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mockPresetKey, preset.index);
  }
}

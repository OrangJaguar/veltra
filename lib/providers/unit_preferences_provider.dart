import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/unit_preferences.dart';

final unitPreferencesStoreProvider =
    Provider<UnitPreferencesStore>((ref) => UnitPreferencesStore());

final unitPreferencesProvider =
    StateNotifierProvider<UnitPreferencesNotifier, UnitPreferences>((ref) {
  return UnitPreferencesNotifier(ref.watch(unitPreferencesStoreProvider));
});

class UnitPreferencesNotifier extends StateNotifier<UnitPreferences> {
  UnitPreferencesNotifier(this._store) : super(const UnitPreferences()) {
    _load();
  }

  final UnitPreferencesStore _store;

  Future<void> _load() async {
    state = await _store.load();
  }

  Future<void> setHeightUnit(MeasureUnit unit) async {
    state = state.copyWith(heightUnit: unit);
    await _store.save(state);
  }

  Future<void> setWeightUnit(MeasureUnit unit) async {
    state = state.copyWith(weightUnit: unit);
    await _store.save(state);
  }
}

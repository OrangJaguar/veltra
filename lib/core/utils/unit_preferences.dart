import 'package:shared_preferences/shared_preferences.dart';

enum MeasureUnit { metric, imperial }

class UnitPreferences {
  const UnitPreferences({
    this.heightUnit = MeasureUnit.metric,
    this.weightUnit = MeasureUnit.metric,
  });

  final MeasureUnit heightUnit;
  final MeasureUnit weightUnit;

  UnitPreferences copyWith({
    MeasureUnit? heightUnit,
    MeasureUnit? weightUnit,
  }) {
    return UnitPreferences(
      heightUnit: heightUnit ?? this.heightUnit,
      weightUnit: weightUnit ?? this.weightUnit,
    );
  }
}

class UnitPreferencesStore {
  static const _heightKey = 'veltra_height_unit';
  static const _weightKey = 'veltra_weight_unit';

  Future<UnitPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return UnitPreferences(
      heightUnit: _fromString(prefs.getString(_heightKey)),
      weightUnit: _fromString(prefs.getString(_weightKey)),
    );
  }

  Future<void> save(UnitPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_heightKey, preferences.heightUnit.name);
    await prefs.setString(_weightKey, preferences.weightUnit.name);
  }

  MeasureUnit _fromString(String? value) {
    if (value == MeasureUnit.imperial.name) return MeasureUnit.imperial;
    return MeasureUnit.metric;
  }
}

import '../../models/check_in.dart';
import '../../models/risk_result.dart';
import '../../services/risk_engine.dart';

/// Display verdict for a saved check-in. Missing forehead temperature has no color.
RiskResult? scoreCheckIn(CheckIn checkIn) {
  final forehead = checkIn.foreheadTempC;
  if (!checkIn.foreheadTempAvailable || forehead == null) return null;

  final microlitersPerMinute = checkIn.sweatRateAvailable
      ? checkIn.sweatRateUlMin
      : null;
  final litersPerHour = microlitersPerMinute == null
      ? 0.0
      : microlitersPerMinute * 60 / 1000000;

  final weather = checkIn.weather;
  final wbgt = weather == null ||
          weather.wbgt == null ||
          weather.source == WeatherContextSources.unavailable
      ? 0.0
      : weather.wbgt!;

  return const RiskEngine().evaluate(
    RiskInput(
      skinTemp: forehead,
      sweatRate: litersPerHour,
      salinity: 0,
      wbgt: wbgt,
      elapsedHours: 0,
      zScore: 0,
      tempRate: 0,
      acclimatization: 1.3,
    ),
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:veltra/features/checkin/checkin_risk.dart';
import 'package:veltra/features/checkin/manual_entry.dart';
import 'package:veltra/models/check_in.dart';
import 'package:veltra/models/sync_status.dart';

CheckIn _checkIn({
  double? forehead = 36.8,
  bool foreheadAvailable = true,
  double? rate,
  bool rateAvailable = false,
  CheckInWeather? weather,
}) {
  return CheckIn(
    id: 'check-1',
    attemptId: 'attempt-1',
    crewId: 'crew',
    workerId: 'worker',
    windowId: 'window',
    capturedAt: DateTime.utc(2026, 11, 23, 18, 5),
    source: CheckInSources.simulated,
    foreheadTempC: forehead,
    foreheadTempAvailable: foreheadAvailable,
    stripVolumeUl: 8,
    stripVolumeAvailable: true,
    conductivityUsCm: 640,
    conductivityAvailable: true,
    sweatRateUlMin: rate,
    sweatRateAvailable: rateAvailable,
    weather: weather,
  );
}

void main() {
  test('a cool forehead with no rate is green', () {
    final result = scoreCheckIn(_checkIn());
    expect(result!.status, WorkerStatus.green);
    expect(result.recommendation, 'Continue work');
    expect(result.riskScore, 0);
  });

  test('a hot forehead in heat is amber', () {
    final result = scoreCheckIn(
      _checkIn(
        forehead: 38.6,
        weather: const CheckInWeather(wbgt: 29, source: WeatherContextSources.estimated),
      ),
    );
    expect(result!.status, WorkerStatus.amber);
    expect(result.riskScore, 4);
  });

  test('extreme heat and a high rate is red', () {
    final result = scoreCheckIn(
      _checkIn(
        forehead: 39,
        rate: 1.6 * 1000000 / 60,
        rateAvailable: true,
        weather: const CheckInWeather(wbgt: 33, source: WeatherContextSources.estimated),
      ),
    );
    expect(result!.status, WorkerStatus.red);
  });

  test('a missing forehead has no verdict', () {
    expect(
      scoreCheckIn(_checkIn(forehead: null, foreheadAvailable: false)),
      isNull,
    );
  });

  test('manual entry keeps blank channels empty', () {
    final parsed = parseManualEntry(
      temperature: '36.8',
      volume: '',
      conductivity: ' 640 ',
    );
    expect(parsed.error, isNull);
    expect(parsed.reading!.foreheadTempC, 36.8);
    expect(parsed.reading!.stripVolumeUl, isNull);
    expect(parsed.reading!.conductivityUsCm, 640);
  });

  test('manual entry rejects an empty or out-of-range temperature', () {
    expect(
      parseManualEntry(temperature: ' ', volume: '', conductivity: '').error,
      'Enter a forehead temperature.',
    );
    expect(
      parseManualEntry(temperature: '29.9', volume: '', conductivity: '').error,
      'Temperature out of range.',
    );
    expect(
      parseManualEntry(temperature: '36', volume: '-1', conductivity: '').error,
      'Volume out of range.',
    );
  });
}

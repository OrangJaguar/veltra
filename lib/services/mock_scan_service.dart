import 'dart:math';

import '../models/sensor_reading.dart';
import '../providers/dev_settings_provider.dart';

class MockScanService {
  MockScanService(this._random);

  final Random _random;

  SensorReading generate({MockScanPreset preset = MockScanPreset.random}) {
    switch (preset) {
      case MockScanPreset.forceGreen:
        return _preset(
          skinTemp: 36.8,
          sweatRate: 0.5,
          salinity: 42,
          sweatVolume: 1.2,
        );
      case MockScanPreset.forceAmber:
        return _preset(
          skinTemp: 37.6,
          sweatRate: 1.2,
          salinity: 58,
          sweatVolume: 2.4,
        );
      case MockScanPreset.forceRed:
        return _preset(
          skinTemp: 38.7,
          sweatRate: 1.8,
          salinity: 75,
          sweatVolume: 3.8,
        );
      case MockScanPreset.random:
        return SensorReading(
          skinTemp: _range(36.0, 39.0),
          sweatRate: _range(0.1, 2.0),
          salinity: _range(20, 80),
          sweatVolume: _range(0.5, 5.0),
          mockNfcId: _randomNfcId(),
        );
    }
  }

  SensorReading _preset({
    required double skinTemp,
    required double sweatRate,
    required double salinity,
    required double sweatVolume,
  }) {
    return SensorReading(
      skinTemp: skinTemp,
      sweatRate: sweatRate,
      salinity: salinity,
      sweatVolume: sweatVolume,
      mockNfcId: _randomNfcId(),
    );
  }

  double _range(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  String _randomNfcId() {
    final bytes = List<int>.generate(4, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
  }
}

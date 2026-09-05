class SensorReading {
  const SensorReading({
    required this.skinTemp,
    required this.sweatRate,
    required this.salinity,
    required this.sweatVolume,
    required this.mockNfcId,
  });

  final double skinTemp;
  final double sweatRate;
  final double salinity;
  final double sweatVolume;
  final String mockNfcId;
}

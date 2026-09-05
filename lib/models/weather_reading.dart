class WeatherReading {
  const WeatherReading({
    required this.airTempC,
    required this.wbgt,
    required this.relativeHumidity,
    required this.latitude,
    required this.longitude,
  });

  final double airTempC;
  final double wbgt;
  final double relativeHumidity;
  final double latitude;
  final double longitude;
}

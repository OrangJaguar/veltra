import 'dart:convert';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;

import '../models/weather_reading.dart';
import 'database_service.dart';

class WeatherService {
  WeatherService(this._databaseService);

  final DatabaseService _databaseService;

  /// Dublin, OH — used when location permission is denied.
  static const defaultLatitude = 40.0992;
  static const defaultLongitude = -83.1141;

  static const fallbackWbgt = 26.0;
  static const fallbackAirTempC = 30.0;
  static const cacheDuration = Duration(minutes: 15);

  static const fallbackReading = WeatherReading(
    airTempC: fallbackAirTempC,
    wbgt: fallbackWbgt,
    relativeHumidity: 55,
    latitude: defaultLatitude,
    longitude: defaultLongitude,
  );

  Future<double> getWbgt(String userId) async {
    final reading = await getReading(userId);
    return reading.wbgt;
  }

  Future<WeatherReading> getReading(String userId) async {
    final coords = await _resolveCoordinates();
    final cached = await _readCache(userId, coords);
    if (cached != null) return cached;

    final reading = await _fetchReading(coords.latitude, coords.longitude);
    await _writeCache(userId: userId, reading: reading);
    return reading;
  }

  Future<void> clearCache(String userId) async {
    await _databaseService.db.delete(
      'weather_cache',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<WeatherReading?> _readCache(
    String userId,
    ({double latitude, double longitude}) coords,
  ) async {
    final rows = await _databaseService.db.query(
      'weather_cache',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final fetchedAt = DateTime.fromMillisecondsSinceEpoch(
      row['fetched_at'] as int,
    );
    if (DateTime.now().difference(fetchedAt) > cacheDuration) return null;

    final airTemp = (row['air_temp_c'] as num?)?.toDouble();
    final wbgt = (row['wbgt'] as num?)?.toDouble();
    if (airTemp == null || wbgt == null) {
      await clearCache(userId);
      return null;
    }

    final cachedLat = (row['latitude'] as num?)?.toDouble();
    final cachedLon = (row['longitude'] as num?)?.toDouble();
    if (cachedLat == null ||
        cachedLon == null ||
        _distanceDegrees(cachedLat, cachedLon, coords.latitude, coords.longitude) >
            0.25) {
      await clearCache(userId);
      return null;
    }

    return WeatherReading(
      airTempC: airTemp,
      wbgt: wbgt,
      relativeHumidity: (row['relative_humidity'] as num?)?.toDouble() ?? 50,
      latitude: cachedLat,
      longitude: cachedLon,
    );
  }

  Future<void> _writeCache({
    required String userId,
    required WeatherReading reading,
  }) async {
    await _databaseService.db.insert(
      'weather_cache',
      {
        'user_id': userId,
        'wbgt': reading.wbgt,
        'air_temp_c': reading.airTempC,
        'relative_humidity': reading.relativeHumidity,
        'latitude': reading.latitude,
        'longitude': reading.longitude,
        'fetched_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<({double latitude, double longitude})> _resolveCoordinates() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (latitude: defaultLatitude, longitude: defaultLongitude);
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
        return (latitude: position.latitude, longitude: position.longitude);
      } catch (_) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return (
            latitude: lastKnown.latitude,
            longitude: lastKnown.longitude,
          );
        }
      }

      return (latitude: defaultLatitude, longitude: defaultLongitude);
    } catch (_) {
      return (latitude: defaultLatitude, longitude: defaultLongitude);
    }
  }

  Future<WeatherReading> _fetchReading(double latitude, double longitude) async {
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': latitude.toStringAsFixed(4),
        'longitude': longitude.toStringAsFixed(4),
        'current': 'temperature_2m,relative_humidity_2m',
        'temperature_unit': 'celsius',
        'timezone': 'auto',
      });

      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return fallbackReading;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return fallbackReading;

      final tempC = (current['temperature_2m'] as num?)?.toDouble();
      final rh = (current['relative_humidity_2m'] as num?)?.toDouble();
      if (tempC == null || rh == null) return fallbackReading;

      final apiLat = (data['latitude'] as num?)?.toDouble() ?? latitude;
      final apiLon = (data['longitude'] as num?)?.toDouble() ?? longitude;

      return WeatherReading(
        airTempC: tempC,
        wbgt: estimateWbgt(tempC, rh),
        relativeHumidity: rh,
        latitude: apiLat,
        longitude: apiLon,
      );
    } catch (_) {
      return fallbackReading;
    }
  }

  /// Outdoor WBGT estimate from air temperature and relative humidity.
  static double estimateWbgt(double tempC, double relativeHumidity) {
    final tw = _wetBulbApprox(tempC, relativeHumidity);
    return 0.7 * tw + 0.3 * tempC;
  }

  static double _wetBulbApprox(double tempC, double relativeHumidity) {
    final rh = relativeHumidity.clamp(0, 100);
    return tempC *
            atan(0.151977 * sqrt(rh + 8.313659)) +
        atan(tempC + rh) -
        atan(rh - 1.676331) +
        0.00391838 * pow(rh, 1.5) * atan(0.023101 * rh) -
        4.686035;
  }

  static double _distanceDegrees(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = lat1 - lat2;
    final dLon = lon1 - lon2;
    return sqrt(dLat * dLat + dLon * dLon);
  }
}

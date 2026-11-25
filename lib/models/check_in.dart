abstract final class CheckInSources {
  static const simulated = 'simulated';
  static const nfcTestTag = 'nfc_test_tag';
  static const sensorPod = 'sensor_pod';
}

abstract final class WeatherContextSources {
  static const estimated = 'estimated';
  static const cached = 'cached';
  static const unavailable = 'unavailable';
  static const simulated = 'simulated';
}

class CheckInWeather {
  const CheckInWeather({
    this.airTempC,
    this.relativeHumidity,
    this.wbgt,
    required this.source,
    this.fetchedAt,
  });

  final double? airTempC;
  final double? relativeHumidity;
  final double? wbgt;
  final String source;
  final DateTime? fetchedAt;
}

class CheckIn {
  const CheckIn({
    required this.id,
    required this.attemptId,
    required this.crewId,
    required this.workerId,
    required this.windowId,
    required this.capturedAt,
    required this.source,
    this.podId,
    this.cartridgeSessionId,
    this.foreheadTempC,
    this.stripVolumeUl,
    this.conductivityUsCm,
    this.sweatRateUlMin,
    required this.foreheadTempAvailable,
    required this.stripVolumeAvailable,
    required this.conductivityAvailable,
    required this.sweatRateAvailable,
    this.readQuality,
    this.weather,
  });

  final String id;
  final String attemptId;
  final String crewId;
  final String workerId;
  final String windowId;

  /// Phone capture time, stored in UTC.
  final DateTime capturedAt;
  final String source;
  final String? podId;
  final String? cartridgeSessionId;
  final double? foreheadTempC;
  final double? stripVolumeUl;
  final double? conductivityUsCm;
  final double? sweatRateUlMin;
  final bool foreheadTempAvailable;
  final bool stripVolumeAvailable;
  final bool conductivityAvailable;
  final bool sweatRateAvailable;
  final String? readQuality;
  final CheckInWeather? weather;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'attempt_id': attemptId,
      'crew_id': crewId,
      'worker_id': workerId,
      'window_id': windowId,
      'captured_at': capturedAt.toUtc().millisecondsSinceEpoch,
      'source': source,
      'pod_id': podId,
      'cartridge_session_id': cartridgeSessionId,
      'forehead_temp_c': foreheadTempC,
      'strip_volume_ul': stripVolumeUl,
      'conductivity_us_cm': conductivityUsCm,
      'sweat_rate_ul_min': sweatRateUlMin,
      'forehead_temp_available': foreheadTempAvailable ? 1 : 0,
      'strip_volume_available': stripVolumeAvailable ? 1 : 0,
      'conductivity_available': conductivityAvailable ? 1 : 0,
      'sweat_rate_available': sweatRateAvailable ? 1 : 0,
      'read_quality': readQuality,
      'weather_air_temp_c': weather?.airTempC,
      'weather_humidity': weather?.relativeHumidity,
      'weather_wbgt': weather?.wbgt,
      'weather_source': weather?.source,
      'weather_fetched_at': weather?.fetchedAt?.toUtc().millisecondsSinceEpoch,
    };
  }

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    final weatherSource = map['weather_source'] as String?;
    return CheckIn(
      id: map['id'] as String,
      attemptId: map['attempt_id'] as String,
      crewId: map['crew_id'] as String,
      workerId: map['worker_id'] as String,
      windowId: map['window_id'] as String,
      capturedAt: DateTime.fromMillisecondsSinceEpoch(
        map['captured_at'] as int,
        isUtc: true,
      ),
      source: map['source'] as String,
      podId: map['pod_id'] as String?,
      cartridgeSessionId: map['cartridge_session_id'] as String?,
      foreheadTempC: (map['forehead_temp_c'] as num?)?.toDouble(),
      stripVolumeUl: (map['strip_volume_ul'] as num?)?.toDouble(),
      conductivityUsCm: (map['conductivity_us_cm'] as num?)?.toDouble(),
      sweatRateUlMin: (map['sweat_rate_ul_min'] as num?)?.toDouble(),
      foreheadTempAvailable: (map['forehead_temp_available'] as int? ?? 0) == 1,
      stripVolumeAvailable: (map['strip_volume_available'] as int? ?? 0) == 1,
      conductivityAvailable: (map['conductivity_available'] as int? ?? 0) == 1,
      sweatRateAvailable: (map['sweat_rate_available'] as int? ?? 0) == 1,
      readQuality: map['read_quality'] as String?,
      weather: weatherSource == null
          ? null
          : CheckInWeather(
              airTempC: (map['weather_air_temp_c'] as num?)?.toDouble(),
              relativeHumidity: (map['weather_humidity'] as num?)?.toDouble(),
              wbgt: (map['weather_wbgt'] as num?)?.toDouble(),
              source: weatherSource,
              fetchedAt: map['weather_fetched_at'] == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(
                      map['weather_fetched_at'] as int,
                      isUtc: true,
                    ),
            ),
    );
  }
}

class SaveCheckInRequest {
  const SaveCheckInRequest({
    required this.attemptId,
    required this.crewId,
    required this.workerId,
    required this.windowId,
    required this.capturedAt,
    required this.source,
    this.podId,
    this.cartridgeSessionId,
    this.foreheadTempC,
    this.stripVolumeUl,
    this.conductivityUsCm,
    this.sweatRateUlMin,
    this.readQuality,
    this.weather,
  });

  final String attemptId;
  final String crewId;
  final String workerId;
  final String windowId;
  final DateTime capturedAt;
  final String source;
  final String? podId;
  final String? cartridgeSessionId;
  final double? foreheadTempC;
  final double? stripVolumeUl;
  final double? conductivityUsCm;
  final double? sweatRateUlMin;
  final String? readQuality;
  final CheckInWeather? weather;
}

class CheckInSaveResult {
  const CheckInSaveResult({required this.checkIn, required this.created});

  final CheckIn checkIn;
  final bool created;
}

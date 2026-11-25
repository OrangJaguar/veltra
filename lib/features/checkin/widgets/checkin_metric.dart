import '../../../models/check_in.dart';

enum CheckInMetric {
  forehead('Forehead temperature', '°C'),
  volume('Strip volume', 'µL'),
  conductivity('Conductivity', 'µS/cm'),
  rate('Sweat rate', 'µL/min');

  const CheckInMetric(this.label, this.unit);

  final String label;
  final String unit;

  double? valueFrom(CheckIn checkIn) {
    switch (this) {
      case CheckInMetric.forehead:
        return checkIn.foreheadTempAvailable ? checkIn.foreheadTempC : null;
      case CheckInMetric.volume:
        return checkIn.stripVolumeAvailable ? checkIn.stripVolumeUl : null;
      case CheckInMetric.conductivity:
        return checkIn.conductivityAvailable ? checkIn.conductivityUsCm : null;
      case CheckInMetric.rate:
        return checkIn.sweatRateAvailable ? checkIn.sweatRateUlMin : null;
    }
  }
}

/// Local strip trend. The first point has no rate. 25 µL is the bench
/// saturation mark until the cartridge calibration is confirmed.
double? sweatRateUlPerMin({
  required double? previousVolumeUl,
  required double volumeUl,
  required DateTime previousAt,
  required DateTime capturedAt,
}) {
  if (previousVolumeUl == null) return null;
  if (previousVolumeUl >= 25 || volumeUl >= 25) return null;
  if (volumeUl < previousVolumeUl) return null;
  final minutes = capturedAt.difference(previousAt).inSeconds / 60;
  if (minutes <= 0 || minutes > 240) return null;
  return (volumeUl - previousVolumeUl) / minutes;
}

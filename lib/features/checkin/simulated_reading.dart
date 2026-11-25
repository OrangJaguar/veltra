/// The one happy-path fixture for plan 2. Rate stays empty on a single read.
abstract final class SimulatedReading {
  static const foreheadTempC = 36.8;
  static const stripVolumeUl = 8.0;
  static const conductivityUsCm = 640.0;
  static const timeoutError = 'Timed out';
}

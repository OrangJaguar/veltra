import 'package:intl/intl.dart';

import '../../models/check_in.dart';
import '../../models/check_in_window.dart';

String checkInSourceLabel(String source) {
  switch (source) {
    case CheckInSources.simulated:
      return 'Simulated';
    case CheckInSources.nfcTestTag:
      return 'Test tag';
    case CheckInSources.sensorPod:
      return 'Sensor pod';
    default:
      return source;
  }
}

String formatCheckInTime(DateTime capturedAt) {
  return DateFormat('h:mm a').format(capturedAt.toLocal());
}

String windowLabel(CheckInWindow? window) {
  if (window == null) return 'No open window';
  final when = formatCheckInTime(window.openedAt);
  if (!window.isOpen) return 'Window closed · $when';
  return 'Window open · $when';
}

String formatMeasurement(double? value, {int decimals = 1}) {
  if (value == null) return 'Unavailable';
  if (decimals == 0) return value.round().toString();
  return value.toStringAsFixed(decimals);
}

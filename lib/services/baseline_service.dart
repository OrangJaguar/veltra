import 'dart:math';

import '../models/baseline.dart';
import '../models/sensor_reading.dart';
import '../repositories/baseline_repository.dart';

class BaselineService {
  BaselineService(this._baselineRepository);

  final BaselineRepository _baselineRepository;

  double computeZScore({
    required WorkerBaseline baseline,
    required double salinity,
  }) {
    final sigma = baseline.sigmaSalinity.abs() < 0.001 ? 1.0 : baseline.sigmaSalinity;
    return (salinity - baseline.muSalinity) / sigma;
  }

  double computeTempRate({
    required double skinTemp,
    required double? previousSkinTemp,
    required DateTime? previousScanAt,
    required double elapsedHours,
  }) {
    if (previousSkinTemp == null || previousScanAt == null) {
      return (skinTemp - 36.5) / (elapsedHours + 0.1);
    }

    final hoursSince = DateTime.now().difference(previousScanAt).inSeconds / 3600.0;
    if (hoursSince <= 0.05) {
      return (skinTemp - 36.5) / (elapsedHours + 0.1);
    }
    return (skinTemp - previousSkinTemp) / hoursSince;
  }

  Future<WorkerBaseline> updateAfterScan({
    required WorkerBaseline baseline,
    required SensorReading reading,
  }) async {
    final newCount = baseline.shiftCount + 1;
    final newMuSalinity = _rollingMean(
      baseline.muSalinity,
      reading.salinity,
      newCount,
    );
    final newMuTemp = _rollingMean(
      baseline.muTemp,
      reading.skinTemp,
      newCount,
    );
    final newSigmaSalinity = _rollingStd(
      baseline.sigmaSalinity,
      baseline.muSalinity,
      newMuSalinity,
      reading.salinity,
      newCount,
    );
    final newSigmaTemp = _rollingStd(
      baseline.sigmaTemp,
      baseline.muTemp,
      newMuTemp,
      reading.skinTemp,
      newCount,
    );
    final acclimatization = min(2.0, 1.0 + newCount * 0.08);

    final updated = WorkerBaseline(
      workerId: baseline.workerId,
      muSalinity: newMuSalinity,
      sigmaSalinity: max(newSigmaSalinity, 1.0),
      muTemp: newMuTemp,
      sigmaTemp: max(newSigmaTemp, 0.1),
      shiftCount: newCount,
      acclimatization: acclimatization,
      synced: false,
    );

    await _baselineRepository.updateBaseline(updated);
    return updated;
  }

  double _rollingMean(double oldMean, double value, int count) {
    return oldMean + (value - oldMean) / count;
  }

  double _rollingStd(
    double oldSigma,
    double oldMean,
    double newMean,
    double value,
    int count,
  ) {
    if (count <= 1) return oldSigma.abs() < 0.001 ? 10.0 : oldSigma;
    final oldVariance = oldSigma * oldSigma;
    final delta = value - oldMean;
    final delta2 = value - newMean;
    final newVariance = oldVariance + (delta * delta2 - oldVariance) / count;
    return sqrt(max(newVariance, 0.01));
  }
}

import 'sync_status.dart';

class RiskInput {
  const RiskInput({
    required this.skinTemp,
    required this.sweatRate,
    required this.salinity,
    required this.wbgt,
    required this.elapsedHours,
    required this.zScore,
    required this.tempRate,
    required this.acclimatization,
    this.coldStart = false,
  });

  final double skinTemp;
  final double sweatRate;
  final double salinity;
  final double wbgt;
  final double elapsedHours;
  final double zScore;
  final double tempRate;
  final double acclimatization;
  final bool coldStart;
}

class RiskResult {
  const RiskResult({
    required this.status,
    required this.recommendation,
    required this.riskScore,
  });

  final WorkerStatus status;
  final String recommendation;
  final int riskScore;
}

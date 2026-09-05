import '../models/risk_result.dart';
import '../models/sync_status.dart';

/// Port of `label_risk()` from veltra_ml/generate_model.py
class RiskEngine {
  const RiskEngine();

  RiskResult evaluate(RiskInput input) {
    var riskScore = 0;

    if (input.skinTemp > 38.5) {
      riskScore += 3;
    } else if (input.skinTemp > 37.5) {
      riskScore += 1;
    }

    if (input.zScore > 2.5) {
      riskScore += 3;
    } else if (input.zScore > 1.5) {
      riskScore += 1;
    }

    if (input.sweatRate > 1.5) {
      riskScore += 2;
    } else if (input.sweatRate > 1.0) {
      riskScore += 1;
    }

    if (input.wbgt > 32) {
      riskScore += 2;
    } else if (input.wbgt > 28) {
      riskScore += 1;
    }

    if (input.tempRate > 0.3) {
      riskScore += 2;
    } else if (input.tempRate > 0.15) {
      riskScore += 1;
    }

    if (input.acclimatization < 1.3) {
      riskScore += 1;
    }

    if (input.skinTemp > 38.0 &&
        input.sweatRate > 1.5 &&
        input.wbgt > 30) {
      riskScore += 3;
    }

    if (input.coldStart) {
      riskScore += 1;
    }

    final status = _statusForScore(riskScore);
    return RiskResult(
      status: status,
      recommendation: _recommendationFor(status),
      riskScore: riskScore,
    );
  }

  WorkerStatus _statusForScore(int riskScore) {
    if (riskScore >= 8) return WorkerStatus.red;
    if (riskScore >= 4) return WorkerStatus.amber;
    return WorkerStatus.green;
  }

  String _recommendationFor(WorkerStatus status) {
    switch (status) {
      case WorkerStatus.green:
        return 'Continue work';
      case WorkerStatus.amber:
        return 'Drink 500mL water · re-scan in 30 min';
      case WorkerStatus.red:
        return 'Rest 15 min in shade';
      case WorkerStatus.none:
        return 'Continue work';
    }
  }
}

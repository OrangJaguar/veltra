/// Body metrics using standard BMI formula (WHO):
/// BMI = weight(kg) / height(m)²
abstract final class BodyMetrics {
  static double? calculateBmi({
    required double? heightCm,
    required double? weightKg,
  }) {
    if (heightCm == null ||
        weightKg == null ||
        heightCm <= 0 ||
        weightKg <= 0) {
      return null;
    }
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  static String? bmiLabel(double? bmi) {
    if (bmi == null) return null;
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  static String formatBmi(double? bmi) {
    if (bmi == null) return '—';
    return bmi.toStringAsFixed(1);
  }

  // Weight
  static double kgToLb(double kg) => kg * 2.20462;
  static double lbToKg(double lb) => lb / 2.20462;

  // Height
  static double cmToInches(double cm) => cm / 2.54;
  static double inchesToCm(double inches) => inches * 2.54;

  static ({int feet, double inches}) cmToFeetInches(double cm) {
    final totalInches = cmToInches(cm);
    final feet = totalInches ~/ 12;
    final inches = totalInches - (feet * 12);
    return (feet: feet, inches: inches);
  }

  static double feetInchesToCm(int feet, double inches) {
    return inchesToCm(feet * 12 + inches);
  }

  static String formatHeightCm(double? cm, {required bool useImperial}) {
    if (cm == null) return '—';
    if (!useImperial) return '${cm.round()} cm';
    final parts = cmToFeetInches(cm);
    return "${parts.feet}' ${parts.inches.toStringAsFixed(0)}\"";
  }

  static String formatWeightKg(double? kg, {required bool useImperial}) {
    if (kg == null) return '—';
    if (!useImperial) return '${kg.toStringAsFixed(1)} kg';
    return '${kgToLb(kg).toStringAsFixed(1)} lb';
  }
}

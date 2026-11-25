class ManualReading {
  const ManualReading({
    required this.foreheadTempC,
    this.stripVolumeUl,
    this.conductivityUsCm,
  });

  final double foreheadTempC;
  final double? stripVolumeUl;
  final double? conductivityUsCm;
}

class ManualParse {
  const ManualParse._({this.reading, this.error});

  const ManualParse.ok(ManualReading reading) : this._(reading: reading);

  const ManualParse.fail(String error) : this._(error: error);

  final ManualReading? reading;
  final String? error;
}

/// Blank volume and conductivity stay unavailable. Forehead temperature is required.
ManualParse parseManualEntry({
  required String temperature,
  required String volume,
  required String conductivity,
}) {
  final tempText = temperature.trim();
  if (tempText.isEmpty) {
    return const ManualParse.fail('Enter a forehead temperature.');
  }
  final forehead = double.tryParse(tempText);
  if (forehead == null) return const ManualParse.fail('Not a number.');
  if (forehead < 30 || forehead > 42) {
    return const ManualParse.fail('Temperature out of range.');
  }

  final volumeReading = _optional(
    volume,
    outOfRange: 'Volume out of range.',
  );
  if (volumeReading.error != null) return ManualParse.fail(volumeReading.error!);

  final conductivityReading = _optional(
    conductivity,
    outOfRange: 'Conductivity out of range.',
  );
  if (conductivityReading.error != null) {
    return ManualParse.fail(conductivityReading.error!);
  }

  return ManualParse.ok(
    ManualReading(
      foreheadTempC: forehead,
      stripVolumeUl: volumeReading.value,
      conductivityUsCm: conductivityReading.value,
    ),
  );
}

class _Optional {
  const _Optional({this.value, this.error});

  final double? value;
  final String? error;
}

_Optional _optional(String raw, {required String outOfRange}) {
  final text = raw.trim();
  if (text.isEmpty) return const _Optional();
  final value = double.tryParse(text);
  if (value == null) return const _Optional(error: 'Not a number.');
  if (value < 0) return _Optional(error: outOfRange);
  return _Optional(value: value);
}

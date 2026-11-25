/// One NDEF text line from a bench tag. Temperature is accepted only from
/// 30.0 to 42.0 °C. Volume and conductivity must be zero or greater.
class TestTagLine {
  const TestTagLine._({
    required this.saves,
    this.message,
    this.podId,
    this.foreheadTempC,
    this.stripVolumeUl,
    this.conductivityUsCm,
  });

  const TestTagLine.saved({
    required String podId,
    required double foreheadTempC,
    double? stripVolumeUl,
    double? conductivityUsCm,
  }) : this._(
          saves: true,
          podId: podId,
          foreheadTempC: foreheadTempC,
          stripVolumeUl: stripVolumeUl,
          conductivityUsCm: conductivityUsCm,
        );

  const TestTagLine.rejected(String message)
      : this._(saves: false, message: message);

  final bool saves;
  final String? message;
  final String? podId;
  final double? foreheadTempC;
  final double? stripVolumeUl;
  final double? conductivityUsCm;

  static const minForeheadC = 30.0;
  static const maxForeheadC = 42.0;
}

const unrelatedTagMessage = 'Unrelated tag.';
const unknownPrefixMessage = 'Unknown prefix.';
const tooFewFieldsMessage = 'Too few fields.';
const tooManyFieldsMessage = 'Too many fields.';
const notANumberMessage = 'Not a number.';
const missingPodMessage = 'Missing pod id.';
const volumeRangeMessage = 'Volume out of range.';
const conductivityRangeMessage = 'Conductivity out of range.';
const temperatureRangeMessage = 'Temperature out of range.';
const notSingleTextMessage = 'Not a single text record.';
const noTagFoundMessage = 'No tag found';
const holdCloserMessage = 'Hold the phone closer';
const nfcUnavailableMessage = 'NFC is not available on this phone.';

TestTagLine parseTestTagLine(String raw) {
  final line = raw.trim();
  if (line.isEmpty || line.contains('\n') || line.contains('\r')) {
    return const TestTagLine.rejected(unrelatedTagMessage);
  }
  final fields = line.split(',').map((field) => field.trim()).toList();
  final prefix = fields.first;
  if (prefix != 'VELTRA1' && prefix != 'VELTRA2') {
    if (prefix.startsWith('VELTRA')) {
      return const TestTagLine.rejected(unknownPrefixMessage);
    }
    return const TestTagLine.rejected(unrelatedTagMessage);
  }

  final expected = prefix == 'VELTRA1' ? 3 : 5;
  if (fields.length < expected) {
    return const TestTagLine.rejected(tooFewFieldsMessage);
  }
  if (fields.length > expected) {
    return const TestTagLine.rejected(tooManyFieldsMessage);
  }
  if (fields[1].isEmpty) {
    return const TestTagLine.rejected(missingPodMessage);
  }

  final temperature = double.tryParse(fields[2]);
  if (temperature == null) {
    return const TestTagLine.rejected(notANumberMessage);
  }
  if (temperature < TestTagLine.minForeheadC ||
      temperature > TestTagLine.maxForeheadC) {
    return const TestTagLine.rejected(temperatureRangeMessage);
  }

  double? volume;
  double? conductivity;
  if (prefix == 'VELTRA2') {
    volume = double.tryParse(fields[3]);
    conductivity = double.tryParse(fields[4]);
    if (volume == null || conductivity == null) {
      return const TestTagLine.rejected(notANumberMessage);
    }
    if (volume < 0) return const TestTagLine.rejected(volumeRangeMessage);
    if (conductivity < 0) {
      return const TestTagLine.rejected(conductivityRangeMessage);
    }
  }

  return TestTagLine.saved(
    podId: fields[1],
    foreheadTempC: temperature,
    stripVolumeUl: volume,
    conductivityUsCm: conductivity,
  );
}

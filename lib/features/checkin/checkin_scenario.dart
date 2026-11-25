import '../../models/check_in.dart';
import 'simulated_reading.dart';

class CheckInScenario {
  const CheckInScenario({
    required this.id,
    required this.label,
    required this.saves,
    this.failureMessage,
    this.foreheadTempC,
    this.stripVolumeUl,
    this.conductivityUsCm,
  });

  final String id;
  final String label;
  final bool saves;
  final String? failureMessage;
  final double? foreheadTempC;
  final double? stripVolumeUl;
  final double? conductivityUsCm;

  static const complete = CheckInScenario(
    id: 'complete',
    label: 'Complete reading',
    saves: true,
    foreheadTempC: SimulatedReading.foreheadTempC,
    stripVolumeUl: SimulatedReading.stripVolumeUl,
    conductivityUsCm: SimulatedReading.conductivityUsCm,
  );

  static const temperatureOnly = CheckInScenario(
    id: 'temperatureOnly',
    label: 'Temperature only',
    saves: true,
    foreheadTempC: SimulatedReading.foreheadTempC,
  );

  static const dryStrip = CheckInScenario(
    id: 'dryStrip',
    label: 'Dry strip',
    saves: false,
    failureMessage: 'The strip is dry.',
  );

  static const poorContact = CheckInScenario(
    id: 'poorContact',
    label: 'Poor contact',
    saves: false,
    failureMessage: 'Reseat the cartridge.',
  );

  static const timeout = CheckInScenario(
    id: 'timeout',
    label: 'Timeout',
    saves: false,
    failureMessage: 'Timed out. Try again.',
  );

  static const all = <CheckInScenario>[
    complete,
    temperatureOnly,
    dryStrip,
    poorContact,
    timeout,
  ];

  static CheckInScenario resolve(String? id) {
    for (final scenario in all) {
      if (scenario.id == id) return scenario;
    }
    return complete;
  }
}

const wrongPodMessage = 'Wrong pod for this worker.';

class ScenarioOutcome {
  const ScenarioOutcome({this.checkIn, this.message});

  final CheckIn? checkIn;
  final String? message;

  bool get saved => checkIn != null;
}

String physicalSourceMessage(String source) {
  if (source == 'sensor_pod') {
    return 'Check in reports the tag it sees and does not save.';
  }
  return 'Check in reads one text line from the tag.';
}

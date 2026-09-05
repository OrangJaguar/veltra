import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/demo_mode.dart';
import '../../../models/baseline.dart';
import '../../../models/risk_result.dart';
import '../../../models/scan_record.dart';
import '../../../models/sensor_reading.dart';
import '../../../models/shift_status.dart';
import '../../../models/weather_reading.dart';
import '../../../models/worker.dart';
import '../../../providers/dev_settings_provider.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/worker_providers.dart';
import '../../../services/baseline_service.dart';
import '../../../services/mock_scan_service.dart';
import '../../../services/risk_engine.dart';
import '../../../services/shift_service.dart';
import '../../../services/speech_worker_matcher.dart';
import '../../../services/weather_service.dart';

final mockScanServiceProvider = Provider<MockScanService>((ref) {
  return MockScanService(Random());
});

final riskEngineProvider = Provider<RiskEngine>((ref) => const RiskEngine());

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(ref.watch(databaseServiceProvider));
});

final shiftServiceProvider = Provider<ShiftService>((ref) {
  return ShiftService(ref.watch(databaseServiceProvider));
});

final baselineServiceProvider = Provider<BaselineService>((ref) {
  return BaselineService(ref.watch(baselineRepositoryProvider));
});

final speechWorkerMatcherProvider =
    Provider<SpeechWorkerMatcher>((ref) => SpeechWorkerMatcher());

final shiftStatusProvider = FutureProvider.autoDispose<ShiftStatus>((ref) async {
  final userId = ref.watch(activeUserIdProvider);
  if (userId == null) return const ShiftStatus();
  return ref.read(shiftServiceProvider).getStatus(userId);
});

final weatherReadingProvider =
    FutureProvider.autoDispose<WeatherReading>((ref) async {
  final userId = ref.watch(activeUserIdProvider);
  if (userId == null) return WeatherService.fallbackReading;
  return ref.read(weatherServiceProvider).getReading(userId);
});

final wbgtProvider = FutureProvider.autoDispose<double>((ref) async {
  final reading = await ref.watch(weatherReadingProvider.future);
  return reading.wbgt;
});

enum ScanFlowStep {
  idle,
  scanning,
  voiceMatch,
  computing,
  results,
  saving,
}

class ScanFlowState {
  const ScanFlowState({
    this.step = ScanFlowStep.idle,
    this.reading,
    this.worker,
    this.baseline,
    this.result,
    this.scanRecord,
    this.shiftStatus,
    this.wbgt,
    this.zScore,
    this.tempRate,
    this.voiceTranscript,
    this.voiceListening = false,
    this.error,
  });

  final ScanFlowStep step;
  final SensorReading? reading;
  final Worker? worker;
  final WorkerBaseline? baseline;
  final RiskResult? result;
  final ScanRecord? scanRecord;
  final ShiftStatus? shiftStatus;
  final double? wbgt;
  final double? zScore;
  final double? tempRate;
  final String? voiceTranscript;
  final bool voiceListening;
  final String? error;

  bool get isBusy =>
      step == ScanFlowStep.scanning ||
      step == ScanFlowStep.computing ||
      step == ScanFlowStep.saving;

  ScanFlowState copyWith({
    ScanFlowStep? step,
    SensorReading? reading,
    Worker? worker,
    WorkerBaseline? baseline,
    RiskResult? result,
    ScanRecord? scanRecord,
    ShiftStatus? shiftStatus,
    double? wbgt,
    double? zScore,
    double? tempRate,
    String? voiceTranscript,
    bool? voiceListening,
    String? error,
    bool clearError = false,
    bool clearWorker = false,
  }) {
    return ScanFlowState(
      step: step ?? this.step,
      reading: reading ?? this.reading,
      worker: clearWorker ? null : (worker ?? this.worker),
      baseline: baseline ?? this.baseline,
      result: result ?? this.result,
      scanRecord: scanRecord ?? this.scanRecord,
      shiftStatus: shiftStatus ?? this.shiftStatus,
      wbgt: wbgt ?? this.wbgt,
      zScore: zScore ?? this.zScore,
      tempRate: tempRate ?? this.tempRate,
      voiceTranscript: voiceTranscript ?? this.voiceTranscript,
      voiceListening: voiceListening ?? this.voiceListening,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final scanFlowProvider =
    StateNotifierProvider<ScanFlowNotifier, ScanFlowState>((ref) {
  return ScanFlowNotifier(ref);
});

class ScanFlowNotifier extends StateNotifier<ScanFlowState> {
  ScanFlowNotifier(this._ref) : super(const ScanFlowState());

  final Ref _ref;
  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;

  Future<void> startScan() async {
    if (state.isBusy) return;

    final userId = _ref.read(activeUserIdProvider);
    if (userId == null) {
      state = state.copyWith(error: 'Sign in or use Quick Demo first');
      return;
    }

    final workers = await _ref.read(workerRepositoryProvider).getWorkers(userId);
    if (workers.isEmpty) {
      state = state.copyWith(
        error: 'Add workers in Crew before scanning',
      );
      return;
    }

    state = state.copyWith(
      step: ScanFlowStep.scanning,
      clearError: true,
      clearWorker: true,
    );

    try {
      final shift = await _ref.read(shiftServiceProvider).ensureShiftForScan(userId);
      final wbgt = await _ref.read(weatherServiceProvider).getWbgt(userId);
      await Future<void>.delayed(const Duration(milliseconds: 800));

      final preset = _ref.read(mockScanPresetProvider);
      final reading = _ref.read(mockScanServiceProvider).generate(preset: preset);

      await HapticFeedback.mediumImpact();

      state = state.copyWith(
        step: ScanFlowStep.voiceMatch,
        reading: reading,
        shiftStatus: shift,
        wbgt: wbgt,
      );

      _ref.invalidate(shiftStatusProvider);
      _ref.invalidate(weatherReadingProvider);
      _ref.invalidate(wbgtProvider);

      await _startVoiceMatch(workers);
    } catch (e) {
      state = state.copyWith(
        step: ScanFlowStep.idle,
        error: 'Scan failed — try again',
      );
    }
  }

  Future<void> _startVoiceMatch(List<Worker> workers) async {
    state = state.copyWith(voiceListening: true, voiceTranscript: '');

    try {
      _speechReady = await _speech.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
    } catch (_) {
      _speechReady = false;
    }

    if (!_speechReady || !_speech.isAvailable) {
      state = state.copyWith(voiceListening: false);
      return;
    }

    final completer = Completer<void>();
    var heardText = '';

    await _speech.listen(
      onResult: (result) {
        heardText = result.recognizedWords;
        state = state.copyWith(voiceTranscript: heardText);
        if (result.finalResult && heardText.isNotEmpty) {
          final match = _ref
              .read(speechWorkerMatcherProvider)
              .matchTranscript(heardText, workers);
          if (match != null && !completer.isCompleted) {
            completer.complete();
            _speech.stop();
            selectWorker(match);
          }
        }
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 2),
      localeId: 'en_US',
    );

    await Future.any([
      completer.future,
      Future<void>.delayed(const Duration(seconds: 5)),
    ]);

    await _speech.stop();
    if (state.step == ScanFlowStep.voiceMatch) {
      state = state.copyWith(voiceListening: false);
      if (heardText.isNotEmpty) {
        final match = _ref
            .read(speechWorkerMatcherProvider)
            .matchTranscript(heardText, workers);
        if (match != null) {
          await selectWorker(match);
        }
      }
    }
  }

  Future<bool> submitManualScan({
    required Worker worker,
    required double skinTemp,
    required double sweatRate,
    required double salinity,
    required double sweatVolume,
  }) async {
    if (state.isBusy) return false;

    final userId = _ref.read(activeUserIdProvider);
    if (userId == null) {
      state = state.copyWith(error: 'Sign in or use Quick Demo first');
      return false;
    }

    state = state.copyWith(
      step: ScanFlowStep.computing,
      clearError: true,
      clearWorker: true,
    );

    try {
      final shift =
          await _ref.read(shiftServiceProvider).ensureShiftForScan(userId);
      final wbgt = await _ref.read(weatherServiceProvider).getWbgt(userId);
      final reading = SensorReading(
        skinTemp: skinTemp,
        sweatRate: sweatRate,
        salinity: salinity,
        sweatVolume: sweatVolume,
        mockNfcId: 'MANUAL',
      );

      state = state.copyWith(
        reading: reading,
        shiftStatus: shift,
        wbgt: wbgt,
      );

      _ref.invalidate(shiftStatusProvider);
      _ref.invalidate(weatherReadingProvider);
      _ref.invalidate(wbgtProvider);

      await selectWorker(worker);
      return state.step == ScanFlowStep.results;
    } catch (e) {
      state = state.copyWith(
        step: ScanFlowStep.idle,
        error: 'Manual entry failed — try again',
      );
      return false;
    }
  }

  Future<void> selectWorker(Worker worker) async {
    if (state.reading == null) return;

    await _speech.stop();
    state = state.copyWith(
      step: ScanFlowStep.computing,
      worker: worker,
      voiceListening: false,
    );

    final userId = _ref.read(activeUserIdProvider);
    if (userId == null) return;

    final baseline = await _ref.read(baselineRepositoryProvider).getBaseline(worker.id) ??
        WorkerBaseline(workerId: worker.id);
    final previousScan =
        await _ref.read(scanRepositoryProvider).getLatestScanForWorker(worker.id);

    final baselineService = _ref.read(baselineServiceProvider);
    final zScore = baselineService.computeZScore(
      baseline: baseline,
      salinity: state.reading!.salinity,
    );
    final elapsedHours = state.shiftStatus?.elapsedHours ?? 0;
    final tempRate = baselineService.computeTempRate(
      skinTemp: state.reading!.skinTemp,
      previousSkinTemp: previousScan?.skinTemp,
      previousScanAt: previousScan?.timestamp,
      elapsedHours: elapsedHours,
    );

    final riskResult = _ref.read(riskEngineProvider).evaluate(
          RiskInput(
            skinTemp: state.reading!.skinTemp,
            sweatRate: state.reading!.sweatRate,
            salinity: state.reading!.salinity,
            wbgt: state.wbgt ?? WeatherService.fallbackWbgt,
            elapsedHours: elapsedHours,
            zScore: zScore,
            tempRate: tempRate,
            acclimatization: baseline.acclimatization,
            coldStart: baseline.shiftCount < 4,
          ),
        );

    final scanRecord = _ref.read(scanRepositoryProvider).buildScanRecord(
          userId: userId,
          workerId: worker.id,
          skinTemp: state.reading!.skinTemp,
          sweatRate: state.reading!.sweatRate,
          salinity: state.reading!.salinity,
          sweatVolume: state.reading!.sweatVolume,
          wbgt: state.wbgt ?? WeatherService.fallbackWbgt,
          status: riskResult.status,
          recommendation: riskResult.recommendation,
          zScore: zScore,
          tempRate: tempRate,
          elapsedHours: elapsedHours,
        );

    state = state.copyWith(
      step: ScanFlowStep.results,
      baseline: baseline,
      result: riskResult,
      scanRecord: scanRecord,
      zScore: zScore,
      tempRate: tempRate,
    );
  }

  Future<void> saveAndReset() async {
    final userId = _ref.read(activeUserIdProvider);
    final worker = state.worker;
    final baseline = state.baseline;
    final scanRecord = state.scanRecord;
    final reading = state.reading;

    if (userId == null ||
        worker == null ||
        baseline == null ||
        scanRecord == null ||
        reading == null) {
      reset();
      return;
    }

    state = state.copyWith(step: ScanFlowStep.saving, clearError: true);

    try {
      final updatedBaseline = await _ref.read(baselineServiceProvider).updateAfterScan(
            baseline: baseline,
            reading: reading,
          );

      await _ref.read(scanRepositoryProvider).saveScan(
            userId: userId,
            worker: worker,
            baseline: updatedBaseline,
            scan: scanRecord,
          );

      _ref.invalidate(workersListProvider);
      _ref.invalidate(syncStatusProvider);
      try {
        await _ref.read(syncServiceProvider).flushQueue(userId);
        await recordLastSyncTime();
        _ref.invalidate(lastSyncTimeProvider);
      } catch (_) {}

      _ref.invalidate(shiftStatusProvider);
      reset();
    } catch (e) {
      state = state.copyWith(
        step: ScanFlowStep.results,
        error: 'Could not save scan — try again',
      );
    }
  }

  void reset() {
    _speech.stop();
    state = const ScanFlowState();
  }

  void cancelVoiceMatch() {
    _speech.stop();
    state = state.copyWith(
      voiceListening: false,
      voiceTranscript: '',
    );
  }
}

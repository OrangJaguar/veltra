import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/veltra_gradient_background.dart';
import '../../../core/widgets/veltra_primary_button.dart';
import '../../../models/check_in.dart';
import '../../../providers/worker_providers.dart';
import '../checkin_scenario.dart';
import '../nfc_log.dart';
import '../providers/demo_session_provider.dart';
import '../simulated_reading.dart';
import '../tag_decision.dart';
import '../test_tag_line.dart';

class CheckInSessionScreen extends ConsumerStatefulWidget {
  const CheckInSessionScreen({
    super.key,
    required this.workerId,
    required this.windowId,
  });

  final String workerId;
  final String windowId;

  @override
  ConsumerState<CheckInSessionScreen> createState() =>
      _CheckInSessionScreenState();
}

enum _SessionPhase { hold, reading, saving, failed }

class _CheckInSessionScreenState extends ConsumerState<CheckInSessionScreen> {
  final _uuid = const Uuid();
  late final String _attemptId = _uuid.v4();
  Timer? _timer;
  _SessionPhase _phase = _SessionPhase.hold;
  String? _error;
  String _source = CheckInSources.simulated;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _source = ref.read(demoSessionProvider).valueOrNull?.scanSource ??
        CheckInSources.simulated;
    if (_source == CheckInSources.simulated) {
      _timer = Timer(const Duration(milliseconds: 700), () {
        if (!mounted || _phase != _SessionPhase.hold) return;
        setState(() => _phase = _SessionPhase.reading);
        _timer = Timer(const Duration(milliseconds: 800), _complete);
      });
    } else {
      unawaited(_listen());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_source != CheckInSources.simulated) {
      unawaited(ref.read(tagSessionProvider).cancel());
    }
    super.dispose();
  }

  void _cancel() {
    _timer?.cancel();
    _left = true;
    if (_source != CheckInSources.simulated) {
      unawaited(ref.read(tagSessionProvider).cancel());
    }
    if (mounted) context.pop();
  }

  Future<void> _timeout() async {
    if (_phase == _SessionPhase.saving || _phase == _SessionPhase.failed) {
      return;
    }
    _timer?.cancel();
    setState(() => _phase = _SessionPhase.failed);
    final config = ref.read(demoSessionProvider).valueOrNull;
    if (config?.crewId == null) {
      setState(() => _error = 'Timed out. Try again.');
      return;
    }
    await ref.read(checkInRepositoryProvider).recordFailedAttempt(
          attemptId: _uuid.v4(),
          crewId: config!.crewId!,
          workerId: widget.workerId,
          windowId: widget.windowId,
          error: SimulatedReading.timeoutError,
        );
    if (!mounted) return;
    setState(() => _error = 'Timed out. Try again.');
  }

  Future<void> _complete() async {
    if (!mounted || _phase != _SessionPhase.reading) return;
    setState(() => _phase = _SessionPhase.saving);
    final config = ref.read(demoSessionProvider).valueOrNull;
    final crewId = config?.crewId;
    if (crewId == null) {
      setState(() {
        _phase = _SessionPhase.failed;
        _error = "Couldn't save";
      });
      return;
    }

    final weather = ref.read(optionalWeatherProvider).valueOrNull;
    try {
      final worker =
          await ref.read(workerRepositoryProvider).getWorker(widget.workerId);
      final outcome = await ref.read(checkInRepositoryProvider).applyScenario(
            attemptId: _uuid.v4(),
            crewId: crewId,
            workerId: widget.workerId,
            windowId: widget.windowId,
            capturedAt: DateTime.now().toUtc(),
            assignedPodId: worker?.podId,
            presentedPodId: config?.presentedPodId,
            scenario: CheckInScenario.resolve(config?.scenario),
            weather: weather,
          );
      if (!mounted) return;
      if (!outcome.saved || outcome.checkIn == null) {
        setState(() {
          _phase = _SessionPhase.failed;
          _error = outcome.message ?? "Couldn't save";
        });
        return;
      }
      HapticFeedback.lightImpact();
      bumpCheckIns(ref);
      context.go('/checkin/saved/${outcome.checkIn!.id}');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _SessionPhase.failed;
        _error = "Couldn't save";
      });
    }
  }

  Future<void> _listen() async {
    final result = await ref.read(tagSessionProvider).listen();
    if (!mounted || _left) return;
    final podDiagnostics = _source == CheckInSources.sensorPod;
    final decision = interpretTagRead(
      podDiagnostics: podDiagnostics,
      result: result,
    );
    if (decision.action == TagAction.cancel) {
      _left = true;
      if (mounted) context.pop();
      return;
    }

    if (decision.action == TagAction.save && decision.line != null) {
      await _saveTag(decision.line!, result);
      return;
    }

    final message = decision.message ?? noTagFoundMessage;
    _log(result, message);
    if (decision.action == TagAction.reject) {
      await _recordFailure(message);
    }
    if (!mounted || _left) return;
    setState(() {
      _phase = _SessionPhase.failed;
      _error = message;
    });
  }

  void _log(TagSessionResult result, String message) {
    addNfcLog(
      ref,
      NfcLogEntry(
        at: DateTime.now(),
        kind: _source == CheckInSources.sensorPod ? 'Pod' : 'Test tag',
        result: message,
        elapsed: result.elapsed,
        technologies: result.technologies,
        identifier: result.identifier,
        payload: result.text,
      ),
    );
  }

  Future<void> _recordFailure(String message) async {
    final config = ref.read(demoSessionProvider).valueOrNull;
    final crewId = config?.crewId;
    if (crewId == null) return;
    await ref.read(checkInRepositoryProvider).recordFailedAttempt(
          attemptId: _attemptId,
          crewId: crewId,
          workerId: widget.workerId,
          windowId: widget.windowId,
          error: message,
        );
  }

  Future<void> _saveTag(TestTagLine line, TagSessionResult result) async {
    if (!mounted || _phase == _SessionPhase.saving) return;
    setState(() => _phase = _SessionPhase.saving);
    final config = ref.read(demoSessionProvider).valueOrNull;
    final crewId = config?.crewId;
    if (crewId == null) {
      setState(() {
        _phase = _SessionPhase.failed;
        _error = "Couldn't save";
      });
      return;
    }
    try {
      final worker =
          await ref.read(workerRepositoryProvider).getWorker(widget.workerId);
      final outcome = await ref.read(checkInRepositoryProvider).saveTestTag(
            attemptId: _attemptId,
            crewId: crewId,
            workerId: widget.workerId,
            windowId: widget.windowId,
            capturedAt: DateTime.now().toUtc(),
            assignedPodId: worker?.podId,
            podId: line.podId!,
            foreheadTempC: line.foreheadTempC!,
            stripVolumeUl: line.stripVolumeUl,
            conductivityUsCm: line.conductivityUsCm,
            weather: ref.read(optionalWeatherProvider).valueOrNull,
          );
      if (!mounted || _left) return;
      if (!outcome.saved || outcome.checkIn == null) {
        final message = outcome.message ?? "Couldn't save";
        _log(result, message);
        setState(() {
          _phase = _SessionPhase.failed;
          _error = message;
        });
        return;
      }
      _log(result, 'Check-in saved');
      HapticFeedback.lightImpact();
      bumpCheckIns(ref);
      context.go('/checkin/saved/${outcome.checkIn!.id}');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _SessionPhase.failed;
        _error = "Couldn't save";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_phase) {
      _SessionPhase.hold => 'Hold phone near the pod',
      _SessionPhase.reading || _SessionPhase.saving => 'Reading',
      _SessionPhase.failed => _error ?? 'Timed out. Try again.',
    };

    return Scaffold(
      body: VeltraGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: VeltraTextStyles.title()),
                const Spacer(),
                if (_phase == _SessionPhase.reading ||
                    _phase == _SessionPhase.saving)
                  const Center(
                    child: CircularProgressIndicator(
                      color: VeltraColors.safetyOrange,
                    ),
                  ),
                const Spacer(),
                if (_phase == _SessionPhase.failed)
                  VeltraPrimaryButton(
                    label: 'Back',
                    onPressed: () => context.go('/checkin'),
                  )
                else
                  VeltraPrimaryButton(
                    label: 'Cancel',
                    onPressed: _phase == _SessionPhase.saving ? null : _cancel,
                  ),
                if (_source == CheckInSources.simulated &&
                    (_phase == _SessionPhase.hold ||
                        _phase == _SessionPhase.reading))
                  TextButton(
                    onPressed: _timeout,
                    child: Text(
                      'Simulate timeout',
                      style: VeltraTextStyles.body(VeltraColors.textMuted),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

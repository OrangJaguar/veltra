import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/veltra_primary_button.dart';
import '../../../models/check_in.dart';
import '../../../providers/worker_providers.dart';
import '../checkin_scenario.dart';
import '../manual_entry.dart';
import '../providers/demo_session_provider.dart';

class ManualCheckInSheet extends ConsumerStatefulWidget {
  const ManualCheckInSheet({
    super.key,
    required this.workerId,
    required this.windowId,
  });

  final String workerId;
  final String windowId;

  @override
  ConsumerState<ManualCheckInSheet> createState() => _ManualCheckInSheetState();
}

class _ManualCheckInSheetState extends ConsumerState<ManualCheckInSheet> {
  final _temperature = TextEditingController();
  final _volume = TextEditingController();
  final _conductivity = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _temperature.dispose();
    _volume.dispose();
    _conductivity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final parsed = parseManualEntry(
      temperature: _temperature.text,
      volume: _volume.text,
      conductivity: _conductivity.text,
    );
    if (parsed.reading == null) {
      setState(() => _error = parsed.error);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final config = ref.read(demoSessionProvider).valueOrNull;
    final crewId = config?.crewId;
    if (crewId == null) {
      setState(() {
        _saving = false;
        _error = "Couldn't save";
      });
      return;
    }

    try {
      final worker =
          await ref.read(workerRepositoryProvider).getWorker(widget.workerId);
      final presented = _blankToNull(config?.presentedPodId);
      final assigned = _blankToNull(worker?.podId);
      if (presented != null && assigned != null && presented != assigned) {
        await ref.read(checkInRepositoryProvider).recordFailedAttempt(
              attemptId: const Uuid().v4(),
              crewId: crewId,
              workerId: widget.workerId,
              windowId: widget.windowId,
              error: wrongPodMessage,
            );
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = wrongPodMessage;
        });
        return;
      }

      final reading = parsed.reading!;
      final saved = await ref.read(checkInRepositoryProvider).saveCheckIn(
            SaveCheckInRequest(
              attemptId: const Uuid().v4(),
              crewId: crewId,
              workerId: widget.workerId,
              windowId: widget.windowId,
              capturedAt: DateTime.now().toUtc(),
              source: CheckInSources.simulated,
              podId: presented ?? assigned,
              cartridgeSessionId: widget.windowId,
              foreheadTempC: reading.foreheadTempC,
              stripVolumeUl: reading.stripVolumeUl,
              conductivityUsCm: reading.conductivityUsCm,
              weather: ref.read(optionalWeatherProvider).valueOrNull,
            ),
          );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      bumpCheckIns(ref);
      context.go('/checkin/saved/${saved.checkIn.id}');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = "Couldn't save";
      });
    }
  }

  String? _blankToNull(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: VeltraColors.sunriseCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Manual entry', style: VeltraTextStyles.headline()),
            const SizedBox(height: 12),
            _Field(controller: _temperature, label: 'Forehead °C'),
            const SizedBox(height: 8),
            _Field(controller: _volume, label: 'Strip µL'),
            const SizedBox(height: 8),
            _Field(controller: _conductivity, label: 'Conductivity µS/cm'),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: VeltraTextStyles.body(VeltraColors.statusRed),
              ),
            ],
            const SizedBox(height: 16),
            VeltraPrimaryButton(
              label: 'Save',
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: VeltraTextStyles.body(VeltraColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

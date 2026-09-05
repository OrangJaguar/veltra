import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/veltra_primary_button.dart';
import '../../../core/widgets/worker_avatar.dart';
import '../../../models/worker.dart';
import '../providers/scan_flow_provider.dart';

class ManualScanSheet extends ConsumerStatefulWidget {
  const ManualScanSheet({super.key, required this.workers});

  final List<Worker> workers;

  @override
  ConsumerState<ManualScanSheet> createState() => _ManualScanSheetState();
}

class _ManualScanSheetState extends ConsumerState<ManualScanSheet> {
  Worker? _selectedWorker;
  final _skinTempController = TextEditingController(text: '37.0');
  final _sweatRateController = TextEditingController(text: '0.50');
  final _salinityController = TextEditingController(text: '50');
  final _sweatVolumeController = TextEditingController(text: '1.0');
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.workers.length == 1) {
      _selectedWorker = widget.workers.first;
    }
  }

  @override
  void dispose() {
    _skinTempController.dispose();
    _sweatRateController.dispose();
    _salinityController.dispose();
    _sweatVolumeController.dispose();
    super.dispose();
  }

  double? _parseField(String raw, String label) {
    final value = double.tryParse(raw.trim());
    if (value == null) {
      setState(() => _error = 'Enter a valid $label');
      return null;
    }
    return value;
  }

  Future<void> _submit() async {
    final worker = _selectedWorker;
    if (worker == null) {
      setState(() => _error = 'Select a worker');
      return;
    }

    final skinTemp = _parseField(_skinTempController.text, 'skin temp');
    if (skinTemp == null) return;
    final sweatRate = _parseField(_sweatRateController.text, 'sweat rate');
    if (sweatRate == null) return;
    final salinity = _parseField(_salinityController.text, 'salinity');
    if (salinity == null) return;
    final sweatVolume =
        _parseField(_sweatVolumeController.text, 'sweat volume');
    if (sweatVolume == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final success = await ref.read(scanFlowProvider.notifier).submitManualScan(
          worker: worker,
          skinTemp: skinTemp,
          sweatRate: sweatRate,
          salinity: salinity,
          sweatVolume: sweatVolume,
        );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        _submitting = false;
        _error =
            ref.read(scanFlowProvider).error ?? 'Could not compute result';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.78;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
      child: Material(
        color: VeltraColors.sunriseCream,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: sheetHeight,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VeltraColors.textMuted.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manual entry', style: VeltraTextStyles.title()),
                          Text(
                            'Enter readings without NFC',
                            style: VeltraTextStyles.caption(),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _submitting ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: VeltraColors.textMuted,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Worker', style: VeltraTextStyles.label()),
                      const SizedBox(height: 8),
                      if (widget.workers.length <= 4)
                        ...widget.workers.map(_workerTile)
                      else
                        DropdownButtonFormField<Worker>(
                          value: _selectedWorker,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.85),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          hint: Text(
                            'Select worker',
                            style: VeltraTextStyles.body(
                              VeltraColors.textMuted,
                            ),
                          ),
                          items: widget.workers
                              .map(
                                (worker) => DropdownMenuItem(
                                  value: worker,
                                  child: Text(
                                    worker.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _submitting
                              ? null
                              : (worker) =>
                                  setState(() => _selectedWorker = worker),
                        ),
                      const SizedBox(height: 12),
                      _ReadingField(
                        controller: _skinTempController,
                        label: 'Skin temp (°C)',
                        enabled: !_submitting,
                      ),
                      const SizedBox(height: 10),
                      _ReadingField(
                        controller: _sweatRateController,
                        label: 'Sweat rate (L/hr)',
                        enabled: !_submitting,
                      ),
                      const SizedBox(height: 10),
                      _ReadingField(
                        controller: _salinityController,
                        label: 'Salinity (mmol/L)',
                        enabled: !_submitting,
                      ),
                      const SizedBox(height: 10),
                      _ReadingField(
                        controller: _sweatVolumeController,
                        label: 'Sweat volume (L)',
                        enabled: !_submitting,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style:
                              VeltraTextStyles.caption(VeltraColors.statusRed),
                        ),
                      ],
                      const SizedBox(height: 16),
                      VeltraPrimaryButton(
                        label: _submitting ? 'Computing…' : 'Calculate result',
                        isLoading: _submitting,
                        onPressed: _submitting ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _workerTile(Worker worker) {
    final selected = _selectedWorker?.id == worker.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? VeltraColors.safetyOrange.withOpacity(0.12)
            : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _submitting
              ? null
              : () => setState(() => _selectedWorker = worker),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? VeltraColors.safetyOrange
                    : VeltraColors.glassBorder,
              ),
            ),
            child: Row(
              children: [
                WorkerAvatar(
                  name: worker.name,
                  photoPath: worker.photoPath,
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    worker.name,
                    style: VeltraTextStyles.body(
                      selected
                          ? VeltraColors.textPrimary
                          : VeltraColors.textSecondary,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: VeltraColors.safetyOrange,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingField extends StatelessWidget {
  const _ReadingField({
    required this.controller,
    required this.label,
    required this.enabled,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

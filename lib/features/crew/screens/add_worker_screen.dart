import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/utils/body_metrics.dart';
import '../../../core/utils/unit_preferences.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/unit_toggle_row.dart';
import '../../../core/widgets/veltra_gradient_background.dart';
import '../../../core/widgets/veltra_primary_button.dart';
import '../../../core/widgets/worker_avatar.dart';
import '../../../providers/unit_preferences_provider.dart';
import '../../../core/demo_mode.dart';
import '../../../models/worker.dart';
import '../../../providers/worker_providers.dart';

class AddWorkerScreen extends ConsumerStatefulWidget {
  const AddWorkerScreen({super.key, this.editWorkerId});

  final String? editWorkerId;

  @override
  ConsumerState<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends ConsumerState<AddWorkerScreen> {
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _nfcIdController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightCmController = TextEditingController();
  final _heightFtController = TextEditingController();
  final _heightInController = TextEditingController();
  final _weightController = TextEditingController();

  String? _pickedPhotoPath;
  String? _existingPhotoPath;
  Worker? _editingWorker;
  bool _isLoading = false;
  bool _loadingWorker = false;
  String? _error;

  bool get _isEditing => widget.editWorkerId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadWorker();
    }
  }

  Future<void> _loadWorker() async {
    setState(() => _loadingWorker = true);
    final worker =
        await ref.read(workerRepositoryProvider).getWorker(widget.editWorkerId!);
    if (!mounted || worker == null) {
      setState(() => _loadingWorker = false);
      return;
    }

    final units = ref.read(unitPreferencesProvider);
    _editingWorker = worker;
    _nameController.text = worker.name;
    _employeeIdController.text = worker.employeeId ?? '';
    _nfcIdController.text = worker.nfcId ?? '';
    if (worker.age != null) _ageController.text = '${worker.age}';
    if (worker.weightKg != null) {
      final weight = units.weightUnit == MeasureUnit.metric
          ? worker.weightKg!
          : BodyMetrics.kgToLb(worker.weightKg!);
      _weightController.text = weight.toStringAsFixed(1);
    }
    if (worker.heightCm != null) {
      if (units.heightUnit == MeasureUnit.metric) {
        _heightCmController.text = worker.heightCm!.toStringAsFixed(0);
      } else {
        final ftIn = BodyMetrics.cmToFeetInches(worker.heightCm!);
        _heightFtController.text = '${ftIn.feet}';
        _heightInController.text = ftIn.inches.toStringAsFixed(0);
      }
    }
    _existingPhotoPath = worker.photoPath;
    setState(() => _loadingWorker = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    _nfcIdController.dispose();
    _ageController.dispose();
    _heightCmController.dispose();
    _heightFtController.dispose();
    _heightInController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _pickedPhotoPath = image.path);
    }
  }

  double? _parseHeightCm(MeasureUnit unit) {
    if (unit == MeasureUnit.metric) {
      final cm = double.tryParse(_heightCmController.text.trim());
      return cm;
    }
    final ft = int.tryParse(_heightFtController.text.trim()) ?? 0;
    final inches = double.tryParse(_heightInController.text.trim()) ?? 0;
    if (ft == 0 && inches == 0) return null;
    return BodyMetrics.feetInchesToCm(ft, inches);
  }

  double? _parseWeightKg(MeasureUnit unit) {
    final value = double.tryParse(_weightController.text.trim());
    if (value == null) return null;
    return unit == MeasureUnit.metric ? value : BodyMetrics.lbToKg(value);
  }

  double? get _previewBmi {
    final units = ref.read(unitPreferencesProvider);
    return BodyMetrics.calculateBmi(
      heightCm: _parseHeightCm(units.heightUnit),
      weightKg: _parseWeightKg(units.weightUnit),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }

    final userId = ref.read(activeUserIdProvider);
    if (userId == null) return;

    final units = ref.read(unitPreferencesProvider);
    final age = int.tryParse(_ageController.text.trim());
    final heightCm = _parseHeightCm(units.heightUnit);
    final weightKg = _parseWeightKg(units.weightUnit);

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workerRepo = ref.read(workerRepositoryProvider);
      if (_isEditing && _editingWorker != null) {
        var updated = await workerRepo.updateWorker(
          worker: _editingWorker!,
          name: name,
          employeeId: _employeeIdController.text,
          nfcId: _nfcIdController.text,
          age: age,
          heightCm: heightCm,
          weightKg: weightKg,
        );

        if (_pickedPhotoPath != null) {
          final photoService = ref.read(photoServiceProvider);
          final savedPath = await photoService.saveWorkerPhoto(
            workerId: updated.id,
            sourcePath: _pickedPhotoPath!,
          );
          updated = updated.copyWith(photoPath: savedPath);
          await workerRepo.updateWorkerPhoto(
            worker: updated,
            photoPath: savedPath,
          );
        }
      } else {
        final worker = await workerRepo.addWorker(
          userId: userId,
          name: name,
          employeeId: _employeeIdController.text,
          nfcId: _nfcIdController.text,
          age: age,
          heightCm: heightCm,
          weightKg: weightKg,
        );

        if (_pickedPhotoPath != null) {
          final photoService = ref.read(photoServiceProvider);
          final savedPath = await photoService.saveWorkerPhoto(
            workerId: worker.id,
            sourcePath: _pickedPhotoPath!,
          );
          await workerRepo.updateWorkerPhoto(worker: worker, photoPath: savedPath);
        }
      }

      refreshWorkers(ref);
      try {
        await syncNow(ref);
      } catch (_) {
        // Saved locally — cloud sync can retry later.
      }

      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = 'Save failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(unitPreferencesProvider);
    final bmi = _previewBmi;
    final bmiLabel = BodyMetrics.bmiLabel(bmi);

    return Scaffold(
      body: VeltraGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: VeltraColors.textPrimary,
                    ),
                    Text(
                      _isEditing ? 'Edit worker' : 'Add worker',
                      style: VeltraTextStyles.title(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loadingWorker
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: VeltraColors.safetyOrange,
                        ),
                      )
                    : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    children: [
                      GlassCard(
                        child: Column(
                          children: [
                            WorkerAvatar(
                              name: _nameController.text.isEmpty
                                  ? '?'
                                  : _nameController.text,
                              photoPath: _pickedPhotoPath ?? _existingPhotoPath,
                              radius: 44,
                              onTap: _pickPhoto,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tap to add photo (optional)',
                              style: VeltraTextStyles.caption(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Basics', style: VeltraTextStyles.headline()),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Name *',
                                hintText: 'Jake',
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _employeeIdController,
                              decoration: const InputDecoration(
                                labelText: 'Employee ID (optional)',
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _nfcIdController,
                              decoration: const InputDecoration(
                                labelText: 'NFC ID (optional)',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Body stats (optional)',
                              style: VeltraTextStyles.headline(),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Used for ML personalization later',
                              style: VeltraTextStyles.caption(),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Age',
                                hintText: '28',
                              ),
                            ),
                            const SizedBox(height: 18),
                            UnitToggleRow(
                              label: 'Height',
                              selected: units.heightUnit,
                              onChanged: (unit) {
                                ref
                                    .read(unitPreferencesProvider.notifier)
                                    .setHeightUnit(unit);
                                setState(() {});
                              },
                            ),
                            const SizedBox(height: 12),
                            if (units.heightUnit == MeasureUnit.metric)
                              TextField(
                                controller: _heightCmController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Height (cm)',
                                  hintText: '178',
                                ),
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _heightFtController,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      decoration: const InputDecoration(
                                        labelText: 'Feet',
                                        hintText: '5',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _heightInController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                      decoration: const InputDecoration(
                                        labelText: 'Inches',
                                        hintText: '10',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 18),
                            UnitToggleRow(
                              label: 'Weight',
                              selected: units.weightUnit,
                              onChanged: (unit) {
                                ref
                                    .read(unitPreferencesProvider.notifier)
                                    .setWeightUnit(unit);
                                setState(() {});
                              },
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _weightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: units.weightUnit == MeasureUnit.metric
                                    ? 'Weight (kg)'
                                    : 'Weight (lb)',
                                hintText:
                                    units.weightUnit == MeasureUnit.metric
                                        ? '80'
                                        : '176',
                              ),
                            ),
                            if (bmi != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: VeltraColors.skyWorkBlue.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.monitor_weight_outlined,
                                      color: VeltraColors.skyWorkBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'BMI ${BodyMetrics.formatBmi(bmi)}',
                                      style: VeltraTextStyles.body(
                                        VeltraColors.skyWorkBlue,
                                      ),
                                    ),
                                    if (bmiLabel != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '· $bmiLabel',
                                        style: VeltraTextStyles.caption(
                                          VeltraColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: VeltraTextStyles.caption(VeltraColors.statusRed),
                        ),
                      ],
                      const SizedBox(height: 20),
                      VeltraPrimaryButton(
                        label: _isEditing ? 'Save Changes' : 'Save Worker',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _save,
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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo_crew.dart';
import '../../../core/demo_mode.dart';
import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/veltra_outlined_button.dart';
import '../../../core/widgets/veltra_primary_button.dart';
import '../../../core/widgets/worker_avatar.dart';
import '../../../models/check_in.dart';
import '../../../models/demo_config.dart';
import '../../../models/worker.dart';
import '../../../providers/worker_providers.dart';
import '../checkin_scenario.dart';
import '../nfc_log.dart';
import '../providers/demo_session_provider.dart';
import '../test_tag_line.dart';

enum AdminPane { bench, crew, tools }

class DemoAdminScreen extends ConsumerStatefulWidget {
  const DemoAdminScreen({super.key, this.pane = AdminPane.bench});

  final AdminPane pane;

  @override
  ConsumerState<DemoAdminScreen> createState() => _DemoAdminScreenState();
}

class _DemoAdminScreenState extends ConsumerState<DemoAdminScreen> {
  final _presentedPod = TextEditingController();
  final _crewName = TextEditingController();
  final _site = TextEditingController();
  String? _loadedCrewId;

  @override
  void dispose() {
    _presentedPod.dispose();
    _crewName.dispose();
    _site.dispose();
    super.dispose();
  }

  void _syncCrewFields() {
    final crew = ref.read(checkInCrewProvider).valueOrNull;
    if (crew == null || crew.id == _loadedCrewId) return;
    _loadedCrewId = crew.id;
    _crewName.text = crew.name;
    _site.text = crew.siteLabel ?? '';
  }

  Future<void> _saveConfig(DemoConfig Function(DemoConfig current) change) async {
    await ref.read(demoSessionProvider.notifier).saveConfig(change);
  }

  void _note(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(demoSessionProvider).valueOrNull;
    final crew = ref.watch(checkInCrewProvider).valueOrNull;
    final open = ref.watch(openCheckInWindowProvider).valueOrNull;
    final workers = ref.watch(crewWorkersProvider).valueOrNull ?? const <Worker>[];
    final crews = ref.watch(crewsProvider).valueOrNull ?? const [];
    _syncCrewFields();

    final source = config?.scanSource ?? CheckInSources.simulated;
    final scenario = CheckInScenario.resolve(config?.scenario);
    final nfcReady = ref.watch(nfcEnabledProvider);
    final nfcLog = ref.watch(nfcLogProvider);
    final title = switch (widget.pane) {
      AdminPane.bench => 'Bench',
      AdminPane.crew => 'Crew',
      AdminPane.tools => 'Tools',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text(title, style: VeltraTextStyles.title()),
        const SizedBox(height: 12),
        if (widget.pane == AdminPane.bench) ...[
          _section(
            'Scan source',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _sourceChip('Simulated', CheckInSources.simulated, source),
                _sourceChip('Physical test tag', CheckInSources.nfcTestTag, source),
                _sourceChip('Sensor pod', CheckInSources.sensorPod, source),
              ],
            ),
          ),
          if (source != CheckInSources.simulated)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                physicalSourceMessage(source),
                style: VeltraTextStyles.body(VeltraColors.textSecondary),
              ),
            ),
          const SizedBox(height: 12),
          _section(
            'NFC',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  nfcReady.when(
                    data: (ready) => ready ? 'NFC available' : nfcUnavailableMessage,
                    loading: () => 'Checking NFC…',
                    error: (_, __) => nfcUnavailableMessage,
                  ),
                  style: VeltraTextStyles.body(VeltraColors.textSecondary),
                ),
                const SizedBox(height: 8),
                if (nfcLog.isEmpty)
                  Text(
                    'No reads yet',
                    style: VeltraTextStyles.body(VeltraColors.textSecondary),
                  )
                else
                  for (final entry in nfcLog) ...[
                    Text(
                      '${entry.kind} · ${formatReadDuration(entry.elapsed)} · ${entry.result}',
                      style: VeltraTextStyles.body(),
                    ),
                    if (entry.technologies.isNotEmpty)
                      Text(entry.technologies.join(', '), style: VeltraTextStyles.caption()),
                    if (entry.identifier != null)
                      Text(entry.identifier!, style: VeltraTextStyles.caption()),
                    if (entry.payload != null && entry.payload!.isNotEmpty)
                      Text(entry.payload!, style: VeltraTextStyles.caption()),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            'Scenario',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in CheckInScenario.all)
                  ChoiceChip(
                    label: Text(item.label),
                    selected: scenario.id == item.id,
                    selectedColor: VeltraColors.safetyOrange,
                    labelStyle: VeltraTextStyles.caption(
                      scenario.id == item.id
                          ? VeltraColors.textOnOrange
                          : VeltraColors.textPrimary,
                    ),
                    onSelected: source == CheckInSources.simulated
                        ? (_) => _saveConfig(
                              (current) => current.copyWith(scenario: item.id),
                            )
                        : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            'Presented pod',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  config?.presentedPodId == null || config!.presentedPodId!.isEmpty
                      ? 'None'
                      : config.presentedPodId!,
                  style: VeltraTextStyles.headline(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _presentedPod,
                  decoration: const InputDecoration(hintText: 'TAG02'),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    VeltraOutlinedButton(
                      label: 'Set',
                      expanded: false,
                      onPressed: () async {
                        await _saveConfig(
                          (current) => current.copyWith(
                            presentedPodId: _presentedPod.text.trim(),
                          ),
                        );
                        _presentedPod.clear();
                      },
                    ),
                    VeltraOutlinedButton(
                      label: 'Clear',
                      expanded: false,
                      onPressed: () => _saveConfig(
                        (current) => current.copyWith(clearPresentedPod: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (widget.pane == AdminPane.crew) ...[
          _section(
            'Crew',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _crewName,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _site,
                  decoration: const InputDecoration(labelText: 'Site'),
                ),
                const SizedBox(height: 8),
                VeltraPrimaryButton(
                  label: 'Save crew',
                  onPressed: crew == null ? null : () => _renameCrew(crew.id),
                ),
                const SizedBox(height: 8),
                VeltraOutlinedButton(
                  label: 'New empty crew',
                  onPressed: _newCrew,
                ),
                const SizedBox(height: 8),
                for (final item in crews)
                  GestureDetector(
                    onTap: () => _switchCrew(item.id),
                    behavior: HitTestBehavior.opaque,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 52),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(item.name, style: VeltraTextStyles.body()),
                          ),
                          if (item.id == crew?.id)
                            Text('Current', style: VeltraTextStyles.caption()),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section(
            'Workers',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < workers.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  _workerRow(workers[i]),
                ],
                const SizedBox(height: 12),
                VeltraOutlinedButton(
                  label: 'Add worker',
                  onPressed: crew == null ? null : () => _addWorker(crew.id),
                ),
              ],
            ),
          ),
        ],
        if (widget.pane == AdminPane.tools)
          _section(
            'Demo crew',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VeltraOutlinedButton(
                  label: 'Unpaired bench read',
                  onPressed: open == null ? null : _unpaired,
                ),
                const SizedBox(height: 8),
                VeltraOutlinedButton(
                  label: 'Reset demo crew',
                  onPressed: _reset,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _sourceChip(String label, String value, String selected) {
    final on = selected == value;
    return ChoiceChip(
      label: Text(label),
      selected: on,
      selectedColor: VeltraColors.safetyOrange,
      labelStyle: VeltraTextStyles.caption(
        on ? VeltraColors.textOnOrange : VeltraColors.textPrimary,
      ),
      onSelected: (_) => _saveConfig(
        (current) => current.copyWith(scanSource: value),
      ),
    );
  }

  Widget _workerRow(Worker worker) {
    final detail = worker.archived
        ? 'Archived'
        : (worker.podId == null ? 'No pod' : worker.podId!);
    return Row(
      children: [
        WorkerAvatar(name: worker.name, radius: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(worker.name, style: VeltraTextStyles.headline()),
              Text(detail, style: VeltraTextStyles.caption()),
            ],
          ),
        ),
        VeltraOutlinedButton(
          label: 'Edit',
          expanded: false,
          onPressed: () => _editWorker(worker),
        ),
      ],
    );
  }

  Future<void> _renameCrew(String crewId) async {
    final name = _crewName.text.trim();
    if (name.isEmpty) return;
    await ref.read(checkInRepositoryProvider).renameCrew(
          crewId: crewId,
          name: name,
          siteLabel: _site.text,
        );
    bumpCheckIns(ref);
  }

  Future<void> _newCrew() async {
    final name = await _ask('Crew name');
    if (name == null || name.trim().isEmpty) return;
    final crew = await ref.read(checkInRepositoryProvider).createEmptyCrew(
          name: name,
        );
    await _saveConfig(
      (current) => current.copyWith(crewId: crew.id, clearWorker: true),
    );
    _loadedCrewId = null;
    bumpCheckIns(ref);
  }

  Future<void> _switchCrew(String crewId) async {
    final workers =
        await ref.read(checkInRepositoryProvider).workersInCrew(crewId);
    final currentId = ref.read(demoSessionProvider).valueOrNull?.workerId;
    final stillHere = workers.any((worker) => worker.id == currentId);
    await _saveConfig(
      (current) => current.copyWith(
        crewId: crewId,
        clearWorker: !stillHere,
        workerId: stillHere ? currentId : null,
      ),
    );
    _loadedCrewId = null;
    bumpCheckIns(ref);
  }

  Future<void> _addWorker(String crewId) async {
    final draft = await _openWorkerSheet();
    if (draft == null || !mounted) return;
    final userId = ref.read(activeUserIdProvider) ?? demoUserId;
    final created = await ref.read(checkInRepositoryProvider).addCrewWorker(
          userId: userId,
          crewId: crewId,
          name: draft.name,
        );
    await _writeProfile(created.id, draft);
    bumpCheckIns(ref);
  }

  Future<void> _editWorker(Worker worker) async {
    final draft = await _openWorkerSheet(worker);
    if (draft == null || !mounted) return;
    final repo = ref.read(checkInRepositoryProvider);
    if (draft.remove) {
      await repo.setWorkerArchived(workerId: worker.id, archived: !worker.archived);
    } else {
      await _writeProfile(worker.id, draft);
    }
    bumpCheckIns(ref);
  }

  Future<void> _writeProfile(String workerId, _WorkerDraft draft) async {
    final repo = ref.read(checkInRepositoryProvider);
    await repo.saveWorkerProfile(
      workerId: workerId,
      name: draft.name,
      employeeId: draft.employeeId,
      age: draft.age,
      heightCm: draft.heightCm,
      weightKg: draft.weightKg,
    );
    await repo.setWorkerPod(
      workerId: workerId,
      podId: draft.pod.trim().isEmpty ? null : draft.pod.trim(),
    );
  }

  Future<_WorkerDraft?> _openWorkerSheet([Worker? worker]) {
    return showModalBottomSheet<_WorkerDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VeltraColors.sunriseCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _WorkerSheet(worker: worker),
    );
  }

  Future<void> _unpaired() async {
    final config = ref.read(demoSessionProvider).valueOrNull;
    final window = ref.read(openCheckInWindowProvider).valueOrNull;
    final workerId = config?.workerId;
    if (config?.crewId == null || window == null || workerId == null) {
      _note('Pick a worker and open a window first');
      return;
    }
    await ref.read(checkInRepositoryProvider).recordUnpairedBench(
          attemptId: DateTime.now().microsecondsSinceEpoch.toString(),
          crewId: config!.crewId!,
          workerId: workerId,
          windowId: window.id,
        );
    _note('Unpaired read recorded');
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reset demo crew?', style: VeltraTextStyles.headline()),
          content: Text(
            'This clears ${DemoCrew.crewName} check-ins and restores Avery, Blake, and Casey. Other crews stay.',
            style: VeltraTextStyles.body(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    final userId = ref.read(activeUserIdProvider) ?? demoUserId;
    await ref.read(checkInRepositoryProvider).resetDemoCrew(userId);
    _loadedCrewId = null;
    ref.invalidate(demoSessionProvider);
    bumpCheckIns(ref);
  }

  Future<String?> _ask(String title, {String initial = ''}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: VeltraTextStyles.headline()),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  Widget _section(String title, Widget child) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: VeltraTextStyles.caption()),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _WorkerDraft {
  const _WorkerDraft({
    required this.name,
    required this.employeeId,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.pod,
    this.remove = false,
  });

  final String name;
  final String employeeId;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String pod;
  final bool remove;
}

class _WorkerSheet extends StatefulWidget {
  const _WorkerSheet({this.worker});

  final Worker? worker;

  @override
  State<_WorkerSheet> createState() => _WorkerSheetState();
}

class _WorkerSheetState extends State<_WorkerSheet> {
  late final TextEditingController _name;
  late final TextEditingController _employeeId;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _pod;
  String? _error;

  @override
  void initState() {
    super.initState();
    final worker = widget.worker;
    _name = TextEditingController(text: worker?.name ?? '');
    _employeeId = TextEditingController(text: worker?.employeeId ?? '');
    _age = TextEditingController(text: worker?.age?.toString() ?? '');
    _height = TextEditingController(text: worker?.heightCm?.round().toString() ?? '');
    _weight = TextEditingController(
      text: worker?.weightKg?.toStringAsFixed(1) ?? '',
    );
    _pod = TextEditingController(text: worker?.podId ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _employeeId.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _pod.dispose();
    super.dispose();
  }

  int? _whole(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  double? _decimal(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final worker = widget.worker;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              worker == null ? 'Add worker' : 'Edit ${worker.name}',
              style: VeltraTextStyles.title(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _employeeId,
              decoration: const InputDecoration(labelText: 'Employee ID'),
            ),
            TextField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            TextField(
              controller: _height,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Height (cm)'),
            ),
            TextField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
            ),
            TextField(
              controller: _pod,
              decoration: const InputDecoration(labelText: 'Pod'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: VeltraTextStyles.body(VeltraColors.statusRed)),
            ],
            const SizedBox(height: 16),
            VeltraPrimaryButton(label: 'Save', onPressed: _save),
            if (worker != null) ...[
              const SizedBox(height: 8),
              VeltraOutlinedButton(
                label: worker.archived ? 'Restore' : 'Delete',
                onPressed: () => Navigator.of(context).pop(
                  _WorkerDraft(
                    name: worker.name,
                    employeeId: worker.employeeId ?? '',
                    age: worker.age,
                    heightCm: worker.heightCm,
                    weightKg: worker.weightKg,
                    pod: worker.podId ?? '',
                    remove: true,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    final ageRaw = _age.text.trim();
    final heightRaw = _height.text.trim();
    final weightRaw = _weight.text.trim();
    if (ageRaw.isNotEmpty && _whole(ageRaw) == null) {
      setState(() => _error = 'Not a number.');
      return;
    }
    if (heightRaw.isNotEmpty && _decimal(heightRaw) == null) {
      setState(() => _error = 'Not a number.');
      return;
    }
    if (weightRaw.isNotEmpty && _decimal(weightRaw) == null) {
      setState(() => _error = 'Not a number.');
      return;
    }
    Navigator.of(context).pop(
      _WorkerDraft(
        name: name,
        employeeId: _employeeId.text,
        age: _whole(ageRaw),
        heightCm: _decimal(heightRaw),
        weightKg: _decimal(weightRaw),
        pod: _pod.text,
      ),
    );
  }
}

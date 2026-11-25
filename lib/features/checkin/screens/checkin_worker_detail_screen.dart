import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/veltra_gradient_background.dart';
import '../../../core/widgets/veltra_outlined_button.dart';
import '../../../core/widgets/worker_avatar.dart';
import '../../../models/check_in.dart';
import '../../../models/check_in_window.dart';
import '../../../models/roster_entry.dart';
import '../../../models/worker.dart';
import '../../../providers/worker_providers.dart';
import '../checkin_labels.dart';
import '../providers/demo_session_provider.dart';
import '../widgets/checkin_trend_chart.dart';
import '../widgets/worker_profile_card.dart';
import 'supervisor_roster_screen.dart';

class CheckInWorkerDetailScreen extends ConsumerWidget {
  const CheckInWorkerDetailScreen({super.key, required this.workerId});

  final String workerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkIns = ref.watch(workerCheckInsProvider(workerId));
    final window = ref.watch(latestWindowProvider).valueOrNull;
    final followUp = ref.watch(workerFollowUpProvider(workerId)).valueOrNull;

    return Scaffold(
      body: VeltraGradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: VeltraColors.textPrimary,
                ),
              ),
              Expanded(
                child: checkIns.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: VeltraColors.safetyOrange,
                    ),
                  ),
                  error: (_, __) => Center(
                    child: Text(
                      'Could not load this worker',
                      style: VeltraTextStyles.body(),
                    ),
                  ),
                  data: (rows) {
                    return _DetailBody(
                      workerId: workerId,
                      rows: rows,
                      window: window,
                      recheckOpen: followUp != null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({
    required this.workerId,
    required this.rows,
    required this.window,
    required this.recheckOpen,
  });

  final String workerId;
  final List<CheckIn> rows;
  final CheckInWindow? window;
  final bool recheckOpen;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  CheckInMetric _metric = CheckInMetric.forehead;

  @override
  Widget build(BuildContext context) {
    final window = widget.window;
    final worker = ref.watch(workerByIdProvider(widget.workerId)).valueOrNull;
    final inWindow = window == null
        ? null
        : widget.rows.where((row) => row.windowId == window.id).firstOrNull;
    final status = window == null
        ? null
        : rosterStatus(
            windowOpen: window.isOpen,
            hasCheckIn: inWindow != null,
            recheckRequested: widget.recheckOpen,
          );
    final color = status == null ? VeltraColors.textSecondary : rosterColor(status);
    final name = worker?.name ?? 'Worker';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
            ),
            child: WorkerAvatar(
              name: name,
              photoPath: worker?.photoPath,
              radius: 40,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(name, style: VeltraTextStyles.title(), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          status?.label ?? 'No open window',
          style: VeltraTextStyles.headline(color),
          textAlign: TextAlign.center,
        ),
        if (inWindow != null) ...[
          const SizedBox(height: 4),
          Text(
            '${formatCheckInTime(inWindow.capturedAt)} · ${checkInSourceLabel(inWindow.source)}',
            style: VeltraTextStyles.caption(),
            textAlign: TextAlign.center,
          ),
        ],
        if (window != null && !widget.recheckOpen) ...[
          const SizedBox(height: 16),
          VeltraOutlinedButton(
            label: 'Request a recheck',
            onPressed: () async {
              await ref.read(checkInRepositoryProvider).requestRecheck(
                    workerId: widget.workerId,
                    windowId: window.id,
                  );
              bumpCheckIns(ref);
            },
          ),
        ],
        const SizedBox(height: 16),
        if (worker != null)
          WorkerProfileCard(
            worker: worker,
            onEdit: () => _edit(worker),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Trend', style: VeltraTextStyles.headline()),
            const Spacer(),
            DropdownButton<CheckInMetric>(
              value: _metric,
              underline: const SizedBox.shrink(),
              style: VeltraTextStyles.body(),
              items: [
                for (final metric in CheckInMetric.values)
                  DropdownMenuItem(value: metric, child: Text(metric.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _metric = value);
              },
            ),
          ],
        ),
        CheckInTrendChart(
          checkIns: widget.rows,
          metric: _metric,
          showHeading: false,
        ),
      ],
    );
  }

  Future<void> _edit(Worker worker) async {
    final draft = await showModalBottomSheet<_Draft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: VeltraColors.sunriseCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ProfileSheet(worker: worker),
    );
    if (draft == null || !mounted) return;
    await ref.read(checkInRepositoryProvider).saveWorkerProfile(
          workerId: worker.id,
          name: draft.name,
          employeeId: draft.employeeId,
          age: draft.age,
          heightCm: draft.heightCm,
          weightKg: draft.weightKg,
        );
    bumpCheckIns(ref);
  }
}

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet({required this.worker});

  final Worker worker;

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _employeeId;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  String? _error;

  @override
  void initState() {
    super.initState();
    final worker = widget.worker;
    _name = TextEditingController(text: worker.name);
    _employeeId = TextEditingController(text: worker.employeeId ?? '');
    _age = TextEditingController(text: worker.age?.toString() ?? '');
    _height = TextEditingController(
      text: worker.heightCm?.round().toString() ?? '',
    );
    _weight = TextEditingController(
      text: worker.weightKg?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _employeeId.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit profile', style: VeltraTextStyles.title()),
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
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: VeltraTextStyles.body(VeltraColors.statusRed)),
          ],
          const SizedBox(height: 16),
          VeltraOutlinedButton(
            label: 'Save',
            onPressed: _save,
          ),
        ],
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
    final height = _decimal(heightRaw);
    final weight = _decimal(weightRaw);
    Navigator.of(context).pop(
      _Draft(
        name: name,
        employeeId: _employeeId.text,
        age: _whole(ageRaw),
        heightCm: height,
        weightKg: weight,
      ),
    );
  }
}

class _Draft {
  const _Draft({
    required this.name,
    required this.employeeId,
    required this.age,
    required this.heightCm,
    required this.weightKg,
  });

  final String name;
  final String employeeId;
  final int? age;
  final double? heightCm;
  final double? weightKg;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/worker.dart';
import '../../../providers/scan_providers.dart';
import '../../../providers/worker_providers.dart';
import '../widgets/status_filter_chips.dart';
import '../widgets/worker_list_tile.dart';

class CrewScreen extends ConsumerWidget {
  const CrewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncBootstrapProvider);
    final workersAsync = ref.watch(workersListProvider);
    final filteredWorkers = ref.watch(filteredWorkersProvider);
    final statusFilter = ref.watch(crewStatusFilterProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your crew', style: VeltraTextStyles.title()),
                    const SizedBox(height: 4),
                    workersAsync.when(
                      data: (_) => Text(
                        '${filteredWorkers.length} workers',
                        style: VeltraTextStyles.body(VeltraColors.textSecondary),
                      ),
                      loading: () => Text(
                        'Loading…',
                        style: VeltraTextStyles.body(VeltraColors.textMuted),
                      ),
                      error: (error, _) => Text(
                        'Load error — pull to retry',
                        style: VeltraTextStyles.caption(VeltraColors.statusRed),
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: VeltraColors.safetyOrange,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => context.push('/crew/add'),
                  borderRadius: BorderRadius.circular(16),
                  child: const SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(
                      Icons.add_rounded,
                      color: VeltraColors.textOnOrange,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StatusFilterChips(
            selected: statusFilter,
            onSelected: (status) =>
                ref.read(crewStatusFilterProvider.notifier).state = status,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: workersAsync.when(
              data: (_) {
                if (filteredWorkers.isEmpty) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: GlassCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 48,
                            color: VeltraColors.safetyOrange.withOpacity(0.7),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            statusFilter == null
                                ? 'Add your first worker'
                                : 'No ${statusFilter.label?.toLowerCase() ?? 'matching'} workers',
                            style: VeltraTextStyles.headline(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            statusFilter == null
                                ? 'Tap + to get started'
                                : 'Try another filter',
                            style:
                                VeltraTextStyles.body(VeltraColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: VeltraColors.safetyOrange,
                  onRefresh: () => syncNow(ref),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: filteredWorkers.length,
                    itemBuilder: (context, index) {
                      final worker = filteredWorkers[index];
                      return WorkerListTile(
                        worker: worker,
                        onTap: () => context.push('/crew/${worker.id}'),
                        onEdit: () => context.push('/crew/${worker.id}/edit'),
                        onDelete: () => _confirmDelete(context, ref, worker),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: VeltraColors.safetyOrange),
              ),
              error: (error, _) => Center(
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not load workers',
                        style: VeltraTextStyles.headline(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: VeltraTextStyles.caption(VeltraColors.statusRed),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => refreshWorkers(ref),
                        child: Text(
                          'Retry',
                          style: VeltraTextStyles.body(VeltraColors.safetyOrange),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Worker worker,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VeltraColors.sunriseCream,
        title: Text('Remove ${worker.name}?', style: VeltraTextStyles.headline()),
        content: Text(
          'This removes them from your crew.',
          style: VeltraTextStyles.body(VeltraColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: VeltraTextStyles.body()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: VeltraTextStyles.body(VeltraColors.statusRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(workerRepositoryProvider).deleteWorker(worker);
    refreshWorkers(ref);
    try {
      await syncNow(ref);
    } catch (_) {}
  }
}

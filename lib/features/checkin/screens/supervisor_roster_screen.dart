import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/worker_avatar.dart';
import '../../../models/roster_entry.dart';
import '../checkin_labels.dart';
import '../providers/demo_session_provider.dart';

class SupervisorDashboard extends ConsumerWidget {
  const SupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(latestWindowProvider);
    final roster = ref.watch(rosterProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dashboard', style: VeltraTextStyles.title()),
          const SizedBox(height: 4),
          Text(
            windowLabel(window.valueOrNull),
            style: VeltraTextStyles.body(VeltraColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: roster.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: VeltraColors.safetyOrange),
              ),
              error: (_, __) => const _Message('Could not load the crew'),
              data: (entries) {
                final counts = tallyRoster(entries);
                final exceptions = entries
                    .where((entry) => entry.status != RosterStatus.checkedIn)
                    .toList();
                final empty = window.valueOrNull == null
                    ? 'No open window.'
                    : 'Everyone is checked in.';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CountGrid(counts: counts),
                    const SizedBox(height: 12),
                    Expanded(
                      child: exceptions.isEmpty
                          ? _Message(empty)
                          : ListView.separated(
                              itemCount: exceptions.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final entry = exceptions[index];
                                return _OnceFade(
                                  key: ValueKey(entry.worker.id),
                                  index: index,
                                  child: RosterTile(entry: entry),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SupervisorWorkersScreen extends ConsumerWidget {
  const SupervisorWorkersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roster = ref.watch(rosterProvider);
    final window = ref.watch(latestWindowProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Workers', style: VeltraTextStyles.title()),
          const SizedBox(height: 12),
          Expanded(
            child: roster.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: VeltraColors.safetyOrange),
              ),
              error: (_, __) => const _Message('Could not load the crew'),
              data: (entries) {
                if (window.valueOrNull == null) {
                  return const _Message('No open window.');
                }
                if (entries.isEmpty) return const _Message('No workers.');
                return ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _OnceFade(
                      key: ValueKey(entry.worker.id),
                      index: index,
                      child: RosterTile(entry: entry),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RosterTile extends StatelessWidget {
  const RosterTile({super.key, required this.entry});

  final RosterEntry entry;

  @override
  Widget build(BuildContext context) {
    final checkIn = entry.latestCheckIn;
    final color = rosterColor(entry.status);
    final detail = checkIn == null
        ? entry.status.label
        : '${entry.status.label} · ${formatCheckInTime(checkIn.capturedAt)}';

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/checkin/worker/${entry.worker.id}'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: WorkerAvatar(name: entry.worker.name, radius: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.worker.name, style: VeltraTextStyles.headline()),
                    const SizedBox(height: 2),
                    Text(detail, style: VeltraTextStyles.caption(color)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: VeltraColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountGrid extends StatelessWidget {
  const _CountGrid({required this.counts});

  final Map<RosterStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.15,
      children: [
        for (final status in RosterStatus.values)
          _CountTile(status: status, count: counts[status] ?? 0),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.status, required this.count});

  final RosterStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = rosterColor(status);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$count', style: VeltraTextStyles.display(color)),
          Text(status.label, style: VeltraTextStyles.caption(color)),
        ],
      ),
    );
  }
}

Color rosterColor(RosterStatus status) {
  switch (status) {
    case RosterStatus.waiting:
      return VeltraColors.skyWorkBlue;
    case RosterStatus.checkedIn:
      return VeltraColors.statusGreen;
    case RosterStatus.retryRequested:
      return VeltraColors.statusAmber;
    case RosterStatus.missed:
      return VeltraColors.statusRed;
  }
}

class _OnceFade extends StatefulWidget {
  const _OnceFade({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_OnceFade> createState() => _OnceFadeState();
}

class _OnceFadeState extends State<_OnceFade> {
  bool _played = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _played = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child
        .animate(target: _played ? 1 : 0)
        .fadeIn(
          duration: 250.ms,
          delay: (50 * widget.index).ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: VeltraTextStyles.body(VeltraColors.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }
}

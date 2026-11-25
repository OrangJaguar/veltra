import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/veltra_colors.dart';
import '../../../core/theme/veltra_text_styles.dart';
import '../../../core/widgets/veltra_gradient_background.dart';
import '../../../models/demo_config.dart';
import '../checkin_nav.dart';
import '../providers/demo_session_provider.dart';
import '../widgets/checkin_tab_bar.dart';
import '../widgets/role_pill.dart';
import 'demo_admin_screen.dart';
import 'supervisor_roster_screen.dart';
import 'supervisor_settings_screen.dart';
import 'worker_history_screen.dart';
import 'worker_home_screen.dart';
import 'worker_settings_screen.dart';

class CheckInShell extends ConsumerStatefulWidget {
  const CheckInShell({super.key});

  @override
  ConsumerState<CheckInShell> createState() => _CheckInShellState();
}

class _CheckInShellState extends ConsumerState<CheckInShell> {
  final Map<String, String> _tabs = {
    DemoRoles.worker: CheckInTabs.scan,
    DemoRoles.supervisor: CheckInTabs.dashboard,
    DemoRoles.demoAdmin: CheckInTabs.bench,
  };

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(demoSessionProvider);

    return Scaffold(
      body: VeltraGradientBackground(
        child: SafeArea(
          bottom: false,
          child: session.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: VeltraColors.safetyOrange),
            ),
            error: (error, _) => Center(
              child: Text(
                'Could not open the demo',
                style: VeltraTextStyles.body(),
              ),
            ),
            data: (config) {
              final tab = _tabs[config.role] ?? CheckInTabs.forRole(config.role).first;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                    child: RolePill(
                      role: config.role,
                      onChanged: (role) {
                        setState(() {
                          _tabs[role] = CheckInTabs.forRole(role).first;
                        });
                        ref.read(demoSessionProvider.notifier).setRole(role);
                      },
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final curved = animation.drive(
                          CurveTween(curve: Curves.easeOutCubic),
                        );
                        return FadeTransition(
                          opacity: curved,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(curved),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey('${config.role}:$tab'),
                        child: _page(config.role, tab),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: session.maybeWhen(
        data: (config) {
          final tabs = CheckInTabs.forRole(config.role);
          final current = _tabs[config.role] ?? tabs.first;
          return CheckInTabBar(
            tabs: tabs,
            current: current,
            onSelected: (tab) => setState(() => _tabs[config.role] = tab),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _page(String role, String tab) {
    switch (role) {
      case DemoRoles.supervisor:
        switch (tab) {
          case CheckInTabs.workers:
            return const SupervisorWorkersScreen();
          case CheckInTabs.settings:
            return const SupervisorSettingsPage();
          default:
            return const SupervisorDashboard();
        }
      case DemoRoles.demoAdmin:
        switch (tab) {
          case CheckInTabs.crew:
            return const DemoAdminScreen(pane: AdminPane.crew);
          case CheckInTabs.tools:
            return const DemoAdminScreen(pane: AdminPane.tools);
          default:
            return const DemoAdminScreen(pane: AdminPane.bench);
        }
      default:
        switch (tab) {
          case CheckInTabs.history:
            return const WorkerHistoryPage();
          case CheckInTabs.settings:
            return const WorkerSettingsPage();
          default:
            return const WorkerHomeScreen();
        }
    }
  }
}

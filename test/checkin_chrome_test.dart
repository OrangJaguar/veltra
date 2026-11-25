import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veltra/features/checkin/checkin_nav.dart';
import 'package:veltra/features/checkin/widgets/checkin_tab_bar.dart';
import 'package:veltra/features/checkin/widgets/role_pill.dart';
import 'package:veltra/models/demo_config.dart';

void main() {
  testWidgets('role pill selects a role and shows no exit', (tester) async {
    String role = DemoRoles.worker;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return RolePill(
                role: role,
                onChanged: (next) => setState(() => role = next),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Exit demo'), findsNothing);
    expect(find.text('Veltra'), findsNothing);
    await tester.tap(find.text('Supervisor'));
    await tester.pumpAndSettle();
    expect(role, DemoRoles.supervisor);
  });

  testWidgets('tab bar stays on the role it was given', (tester) async {
    String tab = CheckInTabs.scan;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CheckInTabBar(
                tabs: CheckInTabs.worker,
                current: tab,
                onSelected: (next) => setState(() => tab = next),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(tab, CheckInTabs.history);
    expect(find.text('Dashboard'), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/veltra_theme.dart';

class VeltraApp extends ConsumerWidget {
  const VeltraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Veltra',
      debugShowCheckedModeBanner: false,
      theme: VeltraTheme.light,
      routerConfig: router,
    );
  }
}

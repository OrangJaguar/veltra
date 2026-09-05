import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/providers/auth_providers.dart';

/// Fixed local user id for offline demo walkthroughs.
const demoUserId = 'veltra-demo-foreman';

final demoModeProvider = StateProvider<bool>((ref) => false);

/// Signed-in Firebase uid, or [demoUserId] when demo mode is on.
final activeUserIdProvider = Provider<String?>((ref) {
  if (ref.watch(demoModeProvider)) return demoUserId;
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

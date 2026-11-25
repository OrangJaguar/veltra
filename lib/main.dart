import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase_gate.dart';
import 'firebase_options.dart';
import 'providers/worker_providers.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (error, stack) {
    firebaseReady = Firebase.apps.isNotEmpty;
    if (!firebaseReady) {
      debugPrint('Firebase unavailable, continuing offline: $error\n$stack');
    }
  }
  appDatabase = await DatabaseService.open();

  runApp(
    const ProviderScope(
      child: VeltraApp(),
    ),
  );
}

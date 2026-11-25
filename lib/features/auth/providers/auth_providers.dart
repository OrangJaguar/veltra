import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase_gate.dart';
import '../../../models/user_profile.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/user_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  if (!firebaseReady) return null;
  return FirebaseFirestore.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(firebaseAuthProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  if (firestore == null) {
    throw StateError('Firebase is not available');
  }
  return UserRepository(firestore);
});

final authStateProvider = StreamProvider<User?>((ref) {
  if (!firebaseReady) return Stream<User?>.value(null);
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  if (!firebaseReady) return Stream<UserProfile?>.value(null);
  final authRepo = ref.watch(authRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);

  return authRepo.authStateChanges().asyncExpand((user) {
    if (user == null) {
      return Stream<UserProfile?>.value(null);
    }
    return userRepo.watchProfile(user.uid);
  });
});

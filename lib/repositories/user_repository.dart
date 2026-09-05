import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

class UserRepository {
  UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Future<void> completeOnboarding({
    required String uid,
    required String email,
    required String crewName,
  }) async {
    final profile = UserProfile(
      uid: uid,
      email: email,
      crewName: crewName.trim(),
      onboardingComplete: true,
      createdAt: DateTime.now(),
    );
    await _userDoc(uid).set(profile.toFirestore());
  }
}

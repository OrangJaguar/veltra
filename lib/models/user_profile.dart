import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.crewName,
    required this.onboardingComplete,
    required this.createdAt,
  });

  final String uid;
  final String email;
  final String crewName;
  final bool onboardingComplete;
  final DateTime createdAt;

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      crewName: data['crewName'] as String? ?? '',
      onboardingComplete: data['onboardingComplete'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'crewName': crewName,
      'onboardingComplete': onboardingComplete,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

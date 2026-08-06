import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neurolens/features/auth/domain/models/user_profile.dart';

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createProfileIfMissing(User user) async {
    final userDocument = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDocument.get();

    if (snapshot.exists) {
      return;
    }

    await userDocument.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'plan': 'free',
      'creditsRemaining': 20,
      'creditsUsed': 0,
      'creditResetAt': _nextMonthlyReset(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return null;
      }

      return UserProfile.fromMap(data);
    });
  }

  DateTime _nextMonthlyReset() {
    final now = DateTime.now();

    if (now.month == 12) {
      return DateTime(now.year + 1, 1, 1);
    }

    return DateTime(now.year, now.month + 1, 1);
  }
}

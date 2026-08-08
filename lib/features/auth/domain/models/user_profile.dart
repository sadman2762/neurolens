class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.plan,
    required this.creditsRemaining,
    required this.creditsUsed,
  });

  final String uid;
  final String? email;
  final String plan;
  final int creditsRemaining;
  final int creditsUsed;

  bool get isPremium => plan == 'premium';

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String?,
      plan: map['plan'] as String? ?? 'free',
      creditsRemaining: map['creditsRemaining'] as int? ?? 0,
      creditsUsed: map['creditsUsed'] as int? ?? 0,
    );
  }
}

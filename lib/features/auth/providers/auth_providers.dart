import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/auth/data/auth_service.dart';
import 'package:neurolens/features/auth/data/user_profile_service.dart';
import 'package:neurolens/features/auth/domain/models/user_profile.dart';
import 'package:neurolens/features/auth/data/account_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);

  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return const Stream.empty();
  }

  return ref
      .watch(userProfileServiceProvider)
      .watchProfile(user.uid);
});

final accountServiceProvider = Provider<AccountService>((ref) {
  const backendUrl = String.fromEnvironment(
    'NEUROLENS_BACKEND_URL',
  );

  final service = AccountService(
    baseUrl: backendUrl,
  );

  ref.onDispose(service.dispose);

  return service;
});
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/auth/data/local_profile_service.dart';

final localProfileServiceProvider =
    Provider<LocalProfileService>((ref) {
  return LocalProfileService();
});

final localProfileProvider =
    StateNotifierProvider<
      LocalProfileController,
      AsyncValue<String?>
    >((ref) {
      return LocalProfileController(
        ref.watch(localProfileServiceProvider),
      );
    });

class LocalProfileController
    extends StateNotifier<AsyncValue<String?>> {
  LocalProfileController(this._service)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final LocalProfileService _service;

  Future<void> _load() async {
    try {
      final name = await _service.getName();

      if (!mounted) {
        return;
      }

      state = AsyncValue.data(name);
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }

      state = AsyncValue.error(
        error,
        stackTrace,
      );
    }
  }

  Future<void> saveName(String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return;
    }

    final previousState = state;

    state = const AsyncValue.loading();

    try {
      await _service.saveName(trimmedName);

      if (!mounted) {
        return;
      }

      state = AsyncValue.data(trimmedName);
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }

      state = previousState;

      Error.throwWithStackTrace(
        error,
        stackTrace,
      );
    }
  }

  Future<void> clearProfile() async {
    try {
      await _service.clearName();

      if (!mounted) {
        return;
      }

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }

      state = AsyncValue.error(
        error,
        stackTrace,
      );
    }
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    await _load();
  }
}
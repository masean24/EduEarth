import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return const OnboardingRepository();
});

/// AsyncNotifier yang mengelola status apakah pengguna sudah menyelesaikan onboarding.
class OnboardingNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repository = ref.watch(onboardingRepositoryProvider);
    return repository.isOnboardingCompleted();
  }

  Future<void> completeOnboarding() async {
    final repository = ref.read(onboardingRepositoryProvider);
    await repository.setOnboardingCompleted(true);
    state = const AsyncData(true);
  }

  Future<void> resetOnboarding() async {
    final repository = ref.read(onboardingRepositoryProvider);
    await repository.setOnboardingCompleted(false);
    state = const AsyncData(false);
  }
}

final onboardingStatusProvider =
    AsyncNotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);


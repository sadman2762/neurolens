import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/subscription/data/revenuecat_service.dart';

final isPremiumProvider = FutureProvider<bool>((ref) async {
  return RevenueCatService.hasPremiumAccess();
});

final subscriptionProvider = Provider<SubscriptionController>((ref) {
  return SubscriptionController(ref);
});

class SubscriptionController {
  SubscriptionController(this.ref);

  final Ref ref;

  Future<void> purchasePremium() async {
    await RevenueCatService.purchaseMonthlyPackage();

    ref.invalidate(isPremiumProvider);
  }

  Future<void> restorePurchases() async {
    await RevenueCatService.restorePurchases();

    ref.invalidate(isPremiumProvider);
  }
}

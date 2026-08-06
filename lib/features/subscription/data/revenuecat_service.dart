import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';

class RevenueCatService {
  RevenueCatService._();

  static const String premiumEntitlementId = 'premium';

  static bool _isConfigured = false;

  static bool get isConfigured => _isConfigured;

  static Future<void> configure({
    required String apiKey,
    String? userId,
  }) async {
    if (_isConfigured) {
      return;
    }

    final cleanApiKey = apiKey.trim();

    if (cleanApiKey.isEmpty) {
      throw const RevenueCatException('RevenueCat API key is missing.');
    }

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    final configuration = PurchasesConfiguration(cleanApiKey);

    final cleanUserId = userId?.trim();

    if (cleanUserId != null && cleanUserId.isNotEmpty) {
      configuration.appUserID = cleanUserId;
    }

    await Purchases.configure(configuration);
    _isConfigured = true;
  }

  static Future<CustomerInfo> identifyUser(String userId) async {
    if (!_isConfigured) {
      throw const RevenueCatException('RevenueCat has not been configured.');
    }

    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      throw const RevenueCatException('RevenueCat user ID is missing.');
    }

    final result = await Purchases.logIn(cleanUserId);
    return result.customerInfo;
  }

  static Future<bool> hasPremiumAccess() async {
    if (!_isConfigured) {
      return false;
    }

    final customerInfo = await Purchases.getCustomerInfo();

    return customerInfo.entitlements.active[premiumEntitlementId] != null;
  }

  static Future<CustomerInfo> restorePurchases() async {
    if (!_isConfigured) {
      throw const RevenueCatException('RevenueCat has not been configured.');
    }

    return Purchases.restorePurchases();
  }

  static Future<void> logOut() async {
    if (!_isConfigured) {
      return;
    }

    await Purchases.logOut();
  }

  static Future<Package> getMonthlyPackage() async {
    if (!_isConfigured) {
      throw const RevenueCatException('RevenueCat has not been configured.');
    }

    final offerings = await Purchases.getOfferings();
    final currentOffering = offerings.current;

    if (currentOffering == null) {
      throw const RevenueCatException('No RevenueCat offering is available.');
    }

    final monthlyPackage = currentOffering.monthly;

    if (monthlyPackage == null) {
      throw const RevenueCatException(
        'The monthly Premium package is unavailable.',
      );
    }

    return monthlyPackage;
  }

  static Future<CustomerInfo> purchaseMonthlyPackage() async {
    final monthlyPackage = await getMonthlyPackage();

    try {
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(monthlyPackage),
      );

      return purchaseResult.customerInfo;
    } on PlatformException catch (error) {
      final errorCode = PurchasesErrorHelper.getErrorCode(error);

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        throw const RevenueCatPurchaseCancelledException();
      }

      throw RevenueCatException(error.message ?? 'Premium purchase failed.');
    }
  }
}

class RevenueCatException implements Exception {
  const RevenueCatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RevenueCatPurchaseCancelledException implements Exception {
  const RevenueCatPurchaseCancelledException();

  @override
  String toString() => 'Purchase cancelled.';
}

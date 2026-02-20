import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';

class RevenueCatService {
  static const _androidKey = 'goog_xxxxxxxxxxxxxxxxxxxxxxxxxxx';
  static const _iosKey     = 'appl_xxxxxxxxxxxxxxxxxxxxxxxxxxx';
  static const _proEntitlement = 'pro';

  static bool _isPro = false;
  static bool get isPro => _isPro;
  static Future<bool> isProAsync() async => _isPro;

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      final key = defaultTargetPlatform == TargetPlatform.android
          ? _androidKey
          : _iosKey;
      await Purchases.setLogLevel(LogLevel.error);
      final config = PurchasesConfiguration(key);
      await Purchases.configure(config);
      await checkProStatus();
    } catch (_) {}
  }

  static Future<void> checkProStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      _isPro = info.entitlements.active.containsKey(_proEntitlement);
    } catch (_) {
      _isPro = false;
    }
  }

  static Future<List<Package>> getPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<bool> purchasePro(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      _isPro = info.entitlements.active.containsKey(_proEntitlement);
      return _isPro;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      _isPro = info.entitlements.active.containsKey(_proEntitlement);
      return _isPro;
    } catch (_) {
      return false;
    }
  }
}

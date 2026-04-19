import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();

  factory RevenueCatService() => _instance;

  RevenueCatService._internal();

  bool _isConfigured = false;
  String? _currentAppUserId;

  Future<void> ensureConfigured() async {
    if (_isConfigured) return;

    final apiKey = dotenv.env['REVENUECAT_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('RevenueCat: REVENUECAT_API_KEY未配置');
      return;
    }

    try {
      await rc.Purchases.setLogLevel(rc.LogLevel.debug);
      final configuration = rc.PurchasesConfiguration(apiKey);
      await rc.Purchases.configure(configuration);
      _isConfigured = true;
    } catch (e) {
      debugPrint('RevenueCat配置失败: $e');
    }
  }

  Future<void> syncCurrentUser(String? appUserId) async {
    if (!_isConfigured) return;

    final normalized = appUserId?.trim() ?? '';

    if (normalized.isEmpty) {
      if (_currentAppUserId == null) return;
      try {
        await rc.Purchases.logOut();
        _currentAppUserId = null;
      } catch (e) {
        debugPrint('RevenueCat logOut failed: $e');
      }
      return;
    }

    if (_currentAppUserId == normalized) return;

    try {
      await rc.Purchases.logIn(normalized);
      _currentAppUserId = normalized;
    } catch (e) {
      debugPrint('RevenueCat logIn failed: $e');
    }
  }

  bool get isProUser => false;
  String? get subscriptionStatus => null;
  String? get subscriptionExpirationDate => null;
  List<rc.Package>? get availablePackages => null;

  Future<void> purchasePackage(rc.Package package) async {
    await ensureConfigured();
    if (!_isConfigured) {
      throw Exception('RevenueCat未配置，无法购买');
    }
    await rc.Purchases.purchasePackage(package);
  }

  Future<rc.CustomerInfo> restorePurchases() async {
    await ensureConfigured();
    if (!_isConfigured) {
      throw Exception('RevenueCat未配置，无法恢复购买');
    }
    return await rc.Purchases.restorePurchases();
  }

  void dispose() {}
}

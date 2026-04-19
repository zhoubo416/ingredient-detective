import 'package:flutter/foundation.dart';
import '../models/subscription_status.dart';
import 'auth_service.dart';
import 'backend_api_service.dart';
import 'revenuecat_service.dart';

class SubscriptionManager with ChangeNotifier {
  static final SubscriptionManager _instance = SubscriptionManager._internal();

  factory SubscriptionManager() => _instance;

  SubscriptionManager._internal();

  final BackendApiService _backendApiService = BackendApiService();
  final AuthService _authService = AuthService();
  final RevenueCatService _revenueCatService = RevenueCatService();

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  SubscriptionStatus? _status;

  Future<void> _initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _loadStatus();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '订阅服务初始化失败: $e';
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await _initialize();
    }
  }

  Future<void> _loadStatus() async {
    if (!_authService.isSignedIn) {
      _status = null;
      return;
    }

    try {
      _status = await _backendApiService.getSubscriptionStatus();
    } catch (_) {
      _status ??= const SubscriptionStatus.free();
    }
  }

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isProUser => _status?.isPro ?? false;
  String? get subscriptionStatus => _status?.subscriptionStatus;
  String? get subscriptionExpirationDate => _status?.expirationDate;
  SubscriptionStatus? get backendStatus => _status;

  Future<void> purchasePackage(dynamic package) async {
    try {
      await ensureInitialized();
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _revenueCatService.purchasePackage(package);

      await _backendApiService.syncSubscriptionStatus(
        isPro: true,
        source: 'revenuecat',
      );
      await _loadStatus();
    } catch (e) {
      _errorMessage = '购买失败: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    try {
      await ensureInitialized();
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final customerInfo = await _revenueCatService.restorePurchases();
      final hasActiveEntitlement = customerInfo.entitlements.active.isNotEmpty;

      await _backendApiService.syncSubscriptionStatus(
        isPro: hasActiveEntitlement,
        source: 'revenuecat',
      );
      await _loadStatus();
    } catch (e) {
      _errorMessage = '恢复购买失败: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadSubscriptionStatus() async {
    try {
      await ensureInitialized();
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _loadStatus();
    } catch (e) {
      _errorMessage = '重新加载订阅状态失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _revenueCatService.dispose();
    super.dispose();
  }
}

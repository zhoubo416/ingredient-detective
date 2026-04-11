import 'package:flutter/foundation.dart';
import '../models/subscription_status.dart';
import 'auth_service.dart';
import 'backend_api_service.dart';
import 'revenuecat_service.dart';

class SubscriptionManager with ChangeNotifier {
  static final SubscriptionManager _instance = SubscriptionManager._internal();

  factory SubscriptionManager() {
    return _instance;
  }

  SubscriptionManager._internal() {
    _initializeFuture = _initialize();
  }

  final RevenueCatService _revenueCatService = RevenueCatService();
  final BackendApiService _backendApiService = BackendApiService();
  final AuthService _authService = AuthService();
  Future<void>? _initializeFuture;

  // 状态变量
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  SubscriptionStatus? _backendStatus;

  // 初始化
  Future<void> _initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _revenueCatService.initialize();
      _revenueCatService.addListener(_handleRevenueCatChanged);
      await _bindRevenueCatUser();
      await _syncStatusToBackend(refreshRevenueCat: true, allowFallback: true);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '订阅服务初始化失败: $e';
      await _loadBackendStatus();
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureInitialized() async {
    _initializeFuture ??= _initialize();
    await _initializeFuture;
  }

  Future<void> _bindRevenueCatUser() async {
    await _revenueCatService.syncCurrentUser(_authService.currentUser?.id);
  }

  void _handleRevenueCatChanged() {
    notifyListeners();
  }

  Future<void> _loadBackendStatus() async {
    if (!_authService.isSignedIn) {
      _backendStatus = null;
      return;
    }

    try {
      _backendStatus = await _backendApiService.getSubscriptionStatus();
    } catch (_) {
      _backendStatus ??= const SubscriptionStatus.free();
    }
  }

  Future<void> _syncStatusToBackend({
    bool refreshRevenueCat = false,
    bool allowFallback = false,
  }) async {
    await _bindRevenueCatUser();

    if (refreshRevenueCat) {
      await _revenueCatService.refreshCustomerInfo();
    }

    if (!_authService.isSignedIn) {
      return;
    }

    try {
      _backendStatus = await _backendApiService.syncSubscriptionStatus(
        isPro: _revenueCatService.isProUser,
        subscriptionStatus: _revenueCatService.subscriptionStatus,
        expirationDate: _revenueCatService.subscriptionExpirationDate,
      );
      _errorMessage = null;
    } catch (e) {
      if (!allowFallback) {
        rethrow;
      }
      await _loadBackendStatus();
    }
  }

  // 获取状态
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 订阅相关状态
  bool get isProUser => _backendStatus?.isPro ?? _revenueCatService.isProUser;
  String? get subscriptionStatus =>
      _backendStatus?.subscriptionStatus ??
      _revenueCatService.subscriptionStatus;
  String? get subscriptionExpirationDate =>
      _backendStatus?.expirationDate ??
      _revenueCatService.subscriptionExpirationDate;
  List? get availablePackages => _revenueCatService.availablePackages;
  SubscriptionStatus? get backendStatus => _backendStatus;

  // 购买产品
  Future<void> purchasePackage(dynamic package) async {
    try {
      await ensureInitialized();
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _revenueCatService.purchasePackage(package);
      await _syncStatusToBackend(refreshRevenueCat: true);
    } catch (e) {
      _errorMessage = '购买失败: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 恢复购买
  Future<void> restorePurchases() async {
    try {
      await ensureInitialized();
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _revenueCatService.restorePurchases();
      await _syncStatusToBackend(refreshRevenueCat: true);
    } catch (e) {
      _errorMessage = '恢复购买失败: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 打开客户中心
  Future<void> openCustomerCenter() async {
    try {
      await _revenueCatService.showCustomerCenter();
    } catch (e) {
      _errorMessage = '打开客户中心失败';
      notifyListeners();
    }
  }

  // 重新加载订阅状态
  Future<void> reloadSubscriptionStatus() async {
    try {
      await ensureInitialized();
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _syncStatusToBackend(refreshRevenueCat: true, allowFallback: true);
    } catch (e) {
      _errorMessage = '重新加载订阅状态失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSubscriptionStatus({bool syncWithBackend = true}) async {
    try {
      await ensureInitialized();
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (syncWithBackend) {
        await _syncStatusToBackend(
          refreshRevenueCat: true,
          allowFallback: true,
        );
      } else {
        await _loadBackendStatus();
      }
    } catch (e) {
      _errorMessage = '刷新订阅状态失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 清理错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _revenueCatService.removeListener(_handleRevenueCatChanged);
    _revenueCatService.dispose();
    super.dispose();
  }
}

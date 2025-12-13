import 'package:flutter/foundation.dart';
import 'revenuecat_service.dart';

class SubscriptionManager with ChangeNotifier {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  
  factory SubscriptionManager() {
    return _instance;
  }
  
  SubscriptionManager._internal() {
    _initialize();
  }
  
  final RevenueCatService _revenueCatService = RevenueCatService();
  
  // 状态变量
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  // 初始化
  Future<void> _initialize() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _revenueCatService.initialize();
      
      // 添加监听器
      _revenueCatService.addListener(() {
        notifyListeners();
      });
      
      _isInitialized = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = '订阅服务初始化失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 获取状态
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // 订阅相关状态
  bool get isProUser => _revenueCatService.isProUser;
  String? get subscriptionStatus => _revenueCatService.subscriptionStatus;
  String? get subscriptionExpirationDate => _revenueCatService.subscriptionExpirationDate;
  List? get availablePackages => _revenueCatService.availablePackages;
  
  // 购买产品
  Future<void> purchasePackage(dynamic package) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      await _revenueCatService.purchasePackage(package);
      
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
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      await _revenueCatService.restorePurchases();
      
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
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      await _revenueCatService.restorePurchases();
      
    } catch (e) {
      _errorMessage = '重新加载订阅状态失败: $e';
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
    _revenueCatService.dispose();
    super.dispose();
  }
}
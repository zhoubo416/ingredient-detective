import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  
  factory RevenueCatService() {
    return _instance;
  }
  
  RevenueCatService._internal();
  
  // 配置常量
  static const String entitlementId = 'pro_access';
  static const List<String> productIdentifiers = [
    'monthly',
    'yearly', 
    'lifetime'
  ];
  
  // 状态变量
  bool _isInitialized = false;
  rc.CustomerInfo? _customerInfo;
  List<rc.Package>? _availablePackages;
  
  // 初始化RevenueCat
  Future<void> initialize() async {
    try {
      await rc.Purchases.setLogLevel(rc.LogLevel.debug);
      
      // 从环境变量获取API密钥
      final apiKey = dotenv.env['REVENUECAT_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('REVENUECAT_API_KEY环境变量未配置');
      }
      
      // 配置RevenueCat
      final configuration = kDebugMode 
          ? rc.PurchasesConfiguration(apiKey)
          : rc.PurchasesConfiguration(apiKey);
      
      await rc.Purchases.configure(configuration);
      
      // 监听客户信息变化
      rc.Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _customerInfo = customerInfo;
        _notifyListeners();
      });
      
      _isInitialized = true;
      
      // 获取初始客户信息
      await _fetchCustomerInfo();
      
      // 获取可用产品
      await _fetchOfferings();
      
    } catch (e) {
      throw Exception('RevenueCat初始化失败: $e');
    }
  }
  
  // 获取客户信息
  Future<void> _fetchCustomerInfo() async {
    try {
      _customerInfo = await rc.Purchases.getCustomerInfo();
      _notifyListeners();
    } catch (e) {
      // 获取客户信息失败
    }
  }
  
  // 获取产品信息
  Future<void> _fetchOfferings() async {
    try {
      final offerings = await rc.Purchases.getOfferings();
      if (offerings.current != null) {
        _availablePackages = offerings.current!.availablePackages;
        _notifyListeners();
      }
    } catch (e) {
      // 获取产品信息失败
    }
  }
  
  // 检查用户是否拥有Pro权限
  bool get isProUser {
    if (_customerInfo == null) return false;
    
    final entitlements = _customerInfo!.entitlements.active;
    return entitlements.containsKey(entitlementId);
  }
  
  // 获取用户订阅状态
  String? get subscriptionStatus {
    if (_customerInfo == null) return null;
    
    final entitlement = _customerInfo!.entitlements.active[entitlementId];
    if (entitlement == null) return '未订阅';
    
    if (entitlement.isSandbox) {
      return '沙盒环境 - ${entitlement.productIdentifier}';
    }
    
    return '已订阅 - ${entitlement.productIdentifier}';
  }
  
  // 获取订阅过期时间
  String? get subscriptionExpirationDate {
    if (_customerInfo == null) return null;
    
    final entitlement = _customerInfo!.entitlements.active[entitlementId];
    if (entitlement != null && entitlement.isActive) {
      return entitlement.expirationDate;
    }
    return null;
  }
  
  // 获取可用产品包
  List<rc.Package>? get availablePackages => _availablePackages;
  
  // 购买产品
  Future<void> purchasePackage(rc.Package package) async {
    try {
      final purchaseResult = await rc.Purchases.purchasePackage(package);
      if (purchaseResult.customerInfo != null) {
        _customerInfo = purchaseResult.customerInfo;
        _notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // 恢复购买
  Future<rc.CustomerInfo> restorePurchases() async {
    try {
      final customerInfo = await rc.Purchases.restorePurchases();
      _customerInfo = customerInfo;
      _notifyListeners();
      return customerInfo;
    } catch (e) {
      rethrow;
    }
  }
  
  // 显示客户中心
  Future<void> showCustomerCenter() async {
    try {
      // RevenueCat SDK 7.x版本中，客户中心功能需要配置
      // 这里暂时留空，后续根据实际需求实现
    } catch (e) {
      rethrow;
    }
  }
  
  // 监听器管理
  final List<VoidCallback> _listeners = [];
  
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
  
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
  
  // 清理资源
  void dispose() {
    _listeners.clear();
  }
}
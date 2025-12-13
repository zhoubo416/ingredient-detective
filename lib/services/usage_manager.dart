import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class UsageManager extends ChangeNotifier {
  static const String _dailyUsageKey = 'daily_usage_count';
  static const String _lastUsageDateKey = 'last_usage_date';
  static const int _maxDailyUsage = 3;
  
  int _dailyUsageCount = 0;
  DateTime? _lastUsageDate;
  bool _isInitialized = false;
  Database? _database;
  
  UsageManager() {
    _initialize();
  }
  
  // 初始化
  Future<void> _initialize() async {
    await _initDatabase();
    await _loadUsageData();
    _isInitialized = true;
    notifyListeners();
  }
  
  // 初始化数据库
  Future<void> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ingredient_detective.db');
    _database = await openDatabase(path, version: 2);
  }
  
  // 从数据库查询当前天的使用次数
  Future<int> _getTodayUsageFromDatabase() async {
    if (_database == null) {
      await _initDatabase();
    }
    
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    
    try {
      final List<Map<String, dynamic>> result = await _database!.query(
        'analysis_history',
        where: 'analysisTime >= ? AND analysisTime < ?',
        whereArgs: [
          todayStart.toIso8601String(),
          tomorrowStart.toIso8601String()
        ],
      );
      
      return result.length;
    } catch (e) {
      print('从数据库查询今日使用次数失败: $e');
      return 0;
    }
  }
  
  // 加载使用数据
  Future<void> _loadUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 获取最后使用日期
    final lastDateString = prefs.getString(_lastUsageDateKey);
    if (lastDateString != null) {
      _lastUsageDate = DateTime.parse(lastDateString);
    }
    
    // 检查是否需要重置计数器
    final now = DateTime.now();
    if (_lastUsageDate == null || !_isSameDay(_lastUsageDate!, now)) {
      // 新的一天，重置计数器
      _dailyUsageCount = 0;
      _lastUsageDate = now;
      await _saveUsageData();
    } else {
      // 同一天，从数据库查询实际使用次数
      _dailyUsageCount = await _getTodayUsageFromDatabase();
      await _saveUsageData();
    }
    
    notifyListeners();
  }
  
  // 保存使用数据
  Future<void> _saveUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyUsageKey, _dailyUsageCount);
    await prefs.setString(_lastUsageDateKey, _lastUsageDate!.toIso8601String());
  }
  
  // 检查是否为同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
  
  // 获取当前使用次数
  int get dailyUsageCount => _dailyUsageCount;
  
  // 获取剩余使用次数（从数据库实时计算）
  Future<int> get remainingUsageCount async {
    final todayUsage = await _getTodayUsageFromDatabase();
    return _maxDailyUsage - todayUsage;
  }
  
  // 检查是否超过限制
  bool get isUsageLimitReached => _dailyUsageCount >= _maxDailyUsage;
  
  // 检查是否可以继续使用
  bool get canUse => !isUsageLimitReached;
  
  // 异步检查使用权限（确保数据已加载）
  Future<bool> canUseAsync() async {
    if (!_isInitialized) {
      await _initialize();
    }
    return !isUsageLimitReached;
  }
  
  // 记录一次使用
  Future<void> recordUsage() async {
    final now = DateTime.now();
    
    // 检查是否需要重置（跨天）
    if (_lastUsageDate == null || !_isSameDay(_lastUsageDate!, now)) {
      _dailyUsageCount = 0;
      _lastUsageDate = now;
    }
    
    _dailyUsageCount++;
    await _saveUsageData();
    notifyListeners();
  }
  
  // 重置使用次数（用于测试或特殊情况）
  Future<void> resetUsage() async {
    _dailyUsageCount = 0;
    _lastUsageDate = DateTime.now();
    await _saveUsageData();
    notifyListeners();
  }
  
  // 获取使用状态信息（异步方法）
  Future<String> get usageStatus async {
    final todayUsage = await _getTodayUsageFromDatabase();
    final isLimitReached = todayUsage >= _maxDailyUsage;
    
    if (isLimitReached) {
      return '今日使用次数已达上限（$maxDailyUsage 次）';
    } else {
      final remaining = _maxDailyUsage - todayUsage;
      return '今日剩余使用次数：$remaining/$maxDailyUsage';
    }
  }
  
  // 最大每日使用次数
  static int get maxDailyUsage => _maxDailyUsage;
}
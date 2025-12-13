import 'package:flutter/material.dart';
import 'camera_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'permission_test_page.dart';
import 'subscription_page.dart';
import '../services/subscription_manager.dart';
import '../services/usage_manager.dart';
import 'analysis_result_page.dart';

// 创建路由观察者
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver, RouteAware {
  int _currentIndex = 0;
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  final UsageManager _usageManager = UsageManager();
  String _usageStatus = '';
  bool _isLoading = true;

  final List<Widget> _pages = [
    const CameraPage(),
    const HistoryPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscriptionManager.addListener(_onSubscriptionChanged);
    // 监听使用次数更新
    UsageUpdateNotifier().addListener(_loadUsageData);
    _loadUsageData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 注册路由观察者
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route as PageRoute);
    }
  }

  Future<void> _loadUsageData() async {
    await _usageManager.canUseAsync();
    final status = await _usageManager.usageStatus;
    if (mounted) {
      setState(() {
        _usageStatus = status;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscriptionManager.removeListener(_onSubscriptionChanged);
    // 移除使用次数更新监听
    UsageUpdateNotifier().removeListener(_loadUsageData);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // 当页面被推入栈顶时调用（页面获得焦点）
  @override
  void didPush() {
    _loadUsageData();
  }

  // 当页面从栈顶弹出时调用（页面失去焦点）
  @override
  void didPopNext() {
    _loadUsageData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 当应用从后台返回时刷新订阅状态和使用次数状态
    if (state == AppLifecycleState.resumed) {
      _subscriptionManager.reloadSubscriptionStatus();
      _loadUsageData();
    }
  }

  void _onSubscriptionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配料侦探'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          // 显示剩余使用次数和订阅提示
          if (!_subscriptionManager.isProUser)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Text(
                      _usageStatus,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionPage(),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.star_border,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PermissionTestPage(),
                ),
              );
            },
            icon: const Icon(Icons.security),
            tooltip: '权限测试',
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: '分析',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '历史',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
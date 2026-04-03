import 'package:flutter/material.dart';

import 'camera_page.dart';
import 'history_page.dart';
import 'permission_test_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final _historyKey = GlobalKey<HistoryPageState>();

  late final List<Widget> _pages = [
    const CameraPage(),
    HistoryPage(key: _historyKey),
    const ProfilePage(),
  ];

  static const _titles = ['开始分析', '历史记录', '我的'];

  Widget _buildAppBarTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF163020),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          '配料侦探',
          style: TextStyle(fontSize: 12, color: Color(0xFF5D7762)),
        ),
      ],
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
        if (index == 1) _historyKey.currentState?.refresh();
      },
      extended: true,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFDFF1E0),
      selectedIconTheme: const IconThemeData(color: Color(0xFF2F7D32)),
      selectedLabelTextStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF2F7D32),
      ),
      unselectedLabelTextStyle: const TextStyle(color: Color(0xFF4B5563)),
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F8F2),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2EDE2)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.eco_rounded, color: Color(0xFF2F7D32)),
              SizedBox(height: 10),
              Text(
                '配料侦探',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 4),
              Text(
                '识别配料，给出健康判断',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.camera_alt_outlined),
          selectedIcon: Icon(Icons.camera_alt),
          label: Text('开始分析'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: Text('历史记录'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('我的'),
        ),
      ],
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PermissionTestPage(),
                  ),
                );
              },
              icon: const Icon(Icons.security_rounded),
              tooltip: '权限测试',
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1024;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F4),
          appBar: AppBar(
            centerTitle: false,
            titleSpacing: 20,
            title: _buildAppBarTitle(),
            backgroundColor: const Color(0xFFF8FBF8),
            foregroundColor: const Color(0xFF163020),
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            actions: isWide
                ? null
                : [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PermissionTestPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.security_rounded),
                      tooltip: '权限测试',
                    ),
                  ],
          ),
          body: isWide
              ? Row(
                  children: [
                    const SizedBox(width: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFDEE9E0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A17301A),
                            blurRadius: 22,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: _buildNavigationRail(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: _pages,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                )
              : IndexedStack(index: _currentIndex, children: _pages),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                    if (index == 1) _historyKey.currentState?.refresh();
                  },
                  height: 74,
                  backgroundColor: Colors.white,
                  indicatorColor: const Color(0xFFDFF1E0),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.camera_alt_outlined),
                      selectedIcon: Icon(Icons.camera_alt),
                      label: '分析',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history),
                      label: '历史',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: '我的',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

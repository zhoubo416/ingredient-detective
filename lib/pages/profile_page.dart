import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'privacy_policy_page.dart';
import '../services/auth_service.dart';
import '../services/backend_api_service.dart';
import '../models/analysis_history_item.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final BackendApiService _backendApiService = BackendApiService();

  String _userName = '用户';
  int _analysisCount = 0;
  int _healthyFoodCount = 0;
  int _attentionFoodCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStatistics();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? '用户';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _userName);
  }

  Future<void> _loadStatistics() async {
    try {
      final history = await _backendApiService.fetchHistory(limit: 100);
      _applyStatistics(history);
    } catch (_) {
      _applyStatistics(const []);
    }
  }

  void _applyStatistics(List<AnalysisHistoryItem> history) {
    final analysisCount = history.length;
    final healthyFoodCount = history.where((item) => item.healthScore >= 7.0).length;
    final attentionFoodCount = history.where((item) => item.healthScore < 5.0).length;

    if (!mounted) return;
    setState(() {
      _analysisCount = analysisCount;
      _healthyFoodCount = healthyFoodCount;
      _attentionFoodCount = attentionFoodCount;
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _showNameEditDialog() {
    final controller = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '请输入昵称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _userName = controller.text.trim();
                });
                _saveSettings();
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(title == '账号邮箱' ? (_authService.currentUser?.email ?? subtitle) : subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _authService.currentUser?.email ?? '已登录用户',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.person,
                        title: '个人信息',
                        subtitle: '修改昵称',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showNameEditDialog,
                      ),
                      const Divider(height: 1),
                      _buildSettingItem(
                        icon: Icons.mail_outline,
                        title: '账号邮箱',
                        subtitle: 'Supabase 登录账号',
                        trailing: const Icon(Icons.check_circle, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.help,
                        title: '使用帮助',
                        subtitle: '查看应用使用说明',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showHelpDialog,
                      ),
                      const Divider(height: 1),
                      _buildSettingItem(
                        icon: Icons.privacy_tip,
                        title: '隐私政策',
                        subtitle: '查看应用隐私政策',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyPage(),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      _buildSettingItem(
                        icon: Icons.logout,
                        title: '退出登录',
                        subtitle: '退出当前账号',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _signOut,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '使用统计',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('分析次数', _analysisCount.toString()),
                            _buildStatItem('健康食品', _healthyFoodCount.toString()),
                            _buildStatItem('关注食品', _attentionFoodCount.toString()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用帮助'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. 登录账号后进入分析页'),
              SizedBox(height: 8),
              Text('2. 选择食品包装图片上传到后台'),
              SizedBox(height: 8),
              Text('3. 后端完成 OCR 与 AI 分析'),
              SizedBox(height: 8),
              Text('4. 历史记录会按账号自动同步'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

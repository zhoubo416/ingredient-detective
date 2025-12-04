import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = '用户';
  String _defaultStandard = '中国标准';
  bool _autoSaveHistory = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? '用户';
      _defaultStandard = prefs.getString('defaultStandard') ?? '中国标准';
      _autoSaveHistory = prefs.getBool('autoSaveHistory') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _userName);
    await prefs.setString('defaultStandard', _defaultStandard);
    await prefs.setBool('autoSaveHistory', _autoSaveHistory);
  }

  void _showNameEditDialog() {
    TextEditingController controller = TextEditingController(text: _userName);
    
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
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 用户信息卡片
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
                const Text(
                  '配料侦探用户',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 个人信息设置
                Card(
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.person,
                        title: '个人信息',
                        subtitle: '修改昵称和基本信息',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showNameEditDialog,
                      ),
                      const Divider(height: 1),
                      _buildSettingItem(
                        icon: Icons.flag,
                        title: '默认分析标准',
                        subtitle: '设置默认使用的食品标准',
                        trailing: DropdownButton<String>(
                          value: _defaultStandard,
                          items: ['中国标准', '美国标准', '欧盟标准', '日本标准']
                              .map((standard) => DropdownMenuItem<String>(
                                    value: standard,
                                    child: Text(standard),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _defaultStandard = value!;
                            });
                            _saveSettings();
                          },
                        ),
                        onTap: null,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 应用设置
                Card(
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.save,
                        title: '自动保存历史记录',
                        subtitle: '分析完成后自动保存到历史记录',
                        trailing: Switch(
                          value: _autoSaveHistory,
                          onChanged: (value) {
                            setState(() {
                              _autoSaveHistory = value;
                            });
                            _saveSettings();
                          },
                        ),
                        onTap: null,
                      ),
                      const Divider(height: 1),
                      _buildSettingItem(
                        icon: Icons.help,
                        title: '使用帮助',
                        subtitle: '查看应用使用说明',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showHelpDialog(),
                      ),
                      const Divider(height: 1),
                      _buildSettingItem(
                        icon: Icons.info,
                        title: '关于应用',
                        subtitle: '版本信息和开发者信息',
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showAboutDialog(),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 统计信息
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
                            _buildStatItem('分析次数', '0'),
                            _buildStatItem('健康食品', '0'),
                            _buildStatItem('关注食品', '0'),
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
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('1. 点击"分析"页面拍照或选择图片'),
              SizedBox(height: 8),
              Text('2. 选择分析标准（中国/美国/欧盟/日本）'),
              SizedBox(height: 8),
              Text('3. 系统自动识别配料并分析营养价值'),
              SizedBox(height: 8),
              Text('4. 查看分析结果和健康评分'),
              SizedBox(height: 8),
              Text('5. 历史记录可在"历史"页面查看'),
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于配料侦探'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: 1.0.0'),
            SizedBox(height: 8),
            Text('开发者: 配料侦探团队'),
            SizedBox(height: 8),
            Text('功能: 食品配料分析工具'),
            SizedBox(height: 8),
            Text('技术支持: support@ingredient-detective.com'),
          ],
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
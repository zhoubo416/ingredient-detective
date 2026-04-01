import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/analysis_history_item.dart';
import '../models/user_health_profile.dart';
import '../services/auth_service.dart';
import '../services/backend_api_service.dart';
import '../services/user_health_profile_service.dart';
import 'login_page.dart';
import 'privacy_policy_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final BackendApiService _backendApiService = BackendApiService();
  final UserHealthProfileService _healthProfileService =
      UserHealthProfileService();

  String _userName = '用户';
  String _gender = '';
  double? _heightCm;
  double? _weightKg;
  List<String> _healthConditions = [];
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
    final healthProfile = await _healthProfileService.loadProfile();

    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('userName') ?? '用户';
      _gender = healthProfile.gender;
      _heightCm = healthProfile.heightCm;
      _weightKg = healthProfile.weightKg;
      _healthConditions = healthProfile.healthConditions;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _userName);
    await _healthProfileService.saveProfile(
      UserHealthProfile(
        gender: _gender,
        heightCm: _heightCm,
        weightKg: _weightKg,
        healthConditions: _healthConditions,
      ),
    );
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
    final healthyFoodCount = history
        .where((item) => item.healthScore >= 7.0)
        .length;
    final attentionFoodCount = history
        .where((item) => item.healthScore < 5.0)
        .length;

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

  String _healthSummary() {
    final parts = <String>[];
    if (_gender.trim().isNotEmpty) {
      parts.add(_gender.trim());
    }
    if (_heightCm != null) {
      parts.add('身高 ${_heightCm!.toStringAsFixed(0)} cm');
    }
    if (_weightKg != null) {
      parts.add('体重 ${_weightKg!.toStringAsFixed(1)} kg');
    }
    if (_healthConditions.isNotEmpty) {
      parts.add('既往情况 ${_healthConditions.join('、')}');
    }

    if (parts.isEmpty) {
      return '补充健康信息后，分析结果会结合你的身体情况给出更具体的饮食提醒。';
    }
    return parts.join(' · ');
  }

  bool get _hasHealthProfile {
    return _gender.trim().isNotEmpty ||
        _heightCm != null ||
        _weightKg != null ||
        _healthConditions.isNotEmpty;
  }

  List<String> _healthTags() {
    final tags = <String>[];
    if (_gender.trim().isNotEmpty) {
      tags.add(_gender.trim());
    }
    if (_heightCm != null) {
      tags.add('${_heightCm!.toStringAsFixed(0)} cm');
    }
    if (_weightKg != null) {
      tags.add('${_weightKg!.toStringAsFixed(1)} kg');
    }
    tags.addAll(_healthConditions);
    return tags;
  }

  void _showProfileEditDialog() {
    final nameController = TextEditingController(text: _userName);
    final heightController = TextEditingController(
      text: _heightCm?.toStringAsFixed(0) ?? '',
    );
    final weightController = TextEditingController(
      text: _weightKg?.toStringAsFixed(1) ?? '',
    );
    final conditionsController = TextEditingController(
      text: _healthConditions.join('，'),
    );
    String selectedGender = _gender;

    const genderOptions = ['男', '女', '其他', '不透露'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('个人与健康信息'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '昵称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGender.isEmpty
                        ? null
                        : selectedGender,
                    items: genderOptions
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedGender = value ?? '';
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: '性别',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: heightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: '身高(cm)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: '体重(kg)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: conditionsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '过往健康情况',
                      hintText: '例如：高血压，糖耐量异常，肾病（可留空）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '分析时会结合这些信息给出个性化提示，例如高糖、高盐或不适合你的配料提醒。',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final parsedHeight = double.tryParse(
                  heightController.text.trim(),
                );
                final parsedWeight = double.tryParse(
                  weightController.text.trim(),
                );
                final conditions = conditionsController.text
                    .split(RegExp(r'[，,、；;\n]'))
                    .map((item) => item.trim())
                    .where((item) => item.isNotEmpty)
                    .toSet()
                    .toList();

                setState(() {
                  _userName = nameController.text.trim().isEmpty
                      ? _userName
                      : nameController.text.trim();
                  _gender = selectedGender;
                  _heightCm = parsedHeight;
                  _weightKg = parsedWeight;
                  _healthConditions = conditions;
                });
                _saveSettings();
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2F7D32),
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFF3FBF4), Color(0xFFE7F4E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD9E8DB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A17301A),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF1E0),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFCBE0CE)),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 34,
                  color: Color(0xFF2F7D32),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF163020),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _authService.currentUser?.email ?? '已登录用户',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5C7663),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _hasHealthProfile
                ? '健康画像已启用，分析会结合你的身体情况给出个性化提示。'
                : '先补全健康画像，系统才能更准确判断高糖、高盐、高添加剂产品是否适合你。',
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF5A7360),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(
            onPressed: _showProfileEditDialog,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFFFFF),
              foregroundColor: const Color(0xFF1B5E20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: Text(_hasHealthProfile ? '编辑健康信息' : '补充健康信息'),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard() {
    final tags = _healthTags();

    return _buildSectionCard(
      title: '身体健康信息',
      subtitle: '这些信息会直接影响模型给出的饮食提醒与风险提示。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FAF6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE1EDE1)),
            ),
            child: Text(
              _healthSummary(),
              style: const TextStyle(
                fontSize: 13,
                height: 1.7,
                color: Color(0xFF374151),
              ),
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8F1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = [
      ('分析次数', _analysisCount.toString(), const Color(0xFF2F7D32)),
      ('较优食品', _healthyFoodCount.toString(), const Color(0xFF1B8A5A)),
      ('需关注', _attentionFoodCount.toString(), const Color(0xFFC73535)),
    ];

    return _buildSectionCard(
      title: '使用统计',
      subtitle: '基于最近同步到当前账号的分析记录。',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;
          if (isCompact) {
            return Column(
              children: stats
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildStatTile(
                        label: item.$1,
                        value: item.$2,
                        color: item.$3,
                      ),
                    ),
                  )
                  .toList(),
            );
          }

          return Row(
            children: stats
                .map(
                  (item) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: item == stats.last ? 0 : 10,
                      ),
                      child: _buildStatTile(
                        label: item.$1,
                        value: item.$2,
                        color: item.$3,
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDEE9E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A17301A),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildActionGroup({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return _buildSectionCard(
      title: title,
      subtitle: subtitle,
      child: Column(children: children),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool danger = false,
  }) {
    final accent = danger ? const Color(0xFFC73535) : const Color(0xFF2F7D32);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: danger ? const Color(0xFFC73535) : Colors.grey[500],
                  ),
            ],
          ),
        ),
      ),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. 在“开始分析”页上传食品包装图片或手动输入配料。'),
              SizedBox(height: 8),
              Text('2. 系统先提取配料文本，再交给模型做逐项分析。'),
              SizedBox(height: 8),
              Text('3. 如果你补充了健康信息，结果会附带个性化饮食提醒。'),
              SizedBox(height: 8),
              Text('4. 每次分析完成后都会自动写入当前账号的历史记录。'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1080;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 16),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: _buildHealthCard()),
                            const SizedBox(width: 16),
                            Expanded(flex: 4, child: _buildStatsCard()),
                          ],
                        )
                      else ...[
                        _buildHealthCard(),
                        const SizedBox(height: 16),
                        _buildStatsCard(),
                      ],
                      const SizedBox(height: 16),
                      _buildActionGroup(
                        title: '账号与服务',
                        subtitle: '管理个人账号、查看说明和了解数据使用方式。',
                        children: [
                          _buildActionTile(
                            icon: Icons.mail_outline_rounded,
                            title: '账号邮箱',
                            subtitle:
                                _authService.currentUser?.email ??
                                'Supabase 登录账号',
                            onTap: () {},
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF8F1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                '已绑定',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                          ),
                          _buildActionTile(
                            icon: Icons.help_outline_rounded,
                            title: '使用帮助',
                            subtitle: '查看上传、识别、分析与历史记录说明',
                            onTap: _showHelpDialog,
                          ),
                          _buildActionTile(
                            icon: Icons.privacy_tip_outlined,
                            title: '隐私政策',
                            subtitle: '查看健康信息、图片与分析结果的使用说明',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrivacyPolicyPage(),
                              ),
                            ),
                          ),
                          _buildActionTile(
                            icon: Icons.logout_rounded,
                            title: '退出登录',
                            subtitle: '退出当前账号并返回登录页',
                            onTap: _signOut,
                            danger: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

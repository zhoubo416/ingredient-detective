import 'package:flutter/material.dart';
import '../models/ingredient_analysis.dart';
import '../services/database_service.dart';
import '../services/usage_manager.dart';
import '../services/subscription_manager.dart';
import 'paywall_page.dart';

// 创建全局事件通知器
class UsageUpdateNotifier {
  static final UsageUpdateNotifier _instance = UsageUpdateNotifier._internal();
  factory UsageUpdateNotifier() => _instance;
  UsageUpdateNotifier._internal();

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}

class AnalysisResultPage extends StatefulWidget {
  final FoodAnalysisResult analysisResult;
  final bool isFromHistory;

  const AnalysisResultPage({super.key, required this.analysisResult, this.isFromHistory = false});

  @override
  State<AnalysisResultPage> createState() => _AnalysisResultPageState();
}

class _AnalysisResultPageState extends State<AnalysisResultPage> {
  bool _isSaved = false;
  late UsageManager _usageManager;
  late SubscriptionManager _subscriptionManager;
  int _remainingUses = 0;
  bool _isProUser = false;

  @override
  void initState() {
    super.initState();
    
    _usageManager = UsageManager();
    _subscriptionManager = SubscriptionManager();
    
    // 初始化使用次数和订阅状态
    _loadUsageAndSubscriptionStatus();
    
    // 如果是从历史页面进入的，说明记录已经保存过，不需要重复保存
    if (!widget.isFromHistory) {
      _saveToHistory();
    } else {
      // 从历史页面进入，标记为已保存
      setState(() {
        _isSaved = true;
      });
    }
  }

  Future<void> _loadUsageAndSubscriptionStatus() async {
    try {
      // 等待使用次数管理器初始化完成
      await _usageManager.canUseAsync();
      
      // 获取剩余使用次数（异步方法）
      final canUse = await _usageManager.canUseAsync();
      final todayUsage = _usageManager.dailyUsageCount;
      final remaining = await _usageManager.remainingUsageCount;
      
      // 检查订阅状态
      final isPro = _subscriptionManager.isProUser;
      
      setState(() {
        _remainingUses = remaining > 0 ? remaining : 0;
        _isProUser = isPro;
      });
    } catch (e) {
      // 如果获取失败，设置默认值
      setState(() {
        _remainingUses = 0;
        _isProUser = false;
      });
    }
  }

  void _navigateToSubscriptionPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaywallPage()),
    );
  }

  Widget _buildUsageAndSubscriptionWidget() {
    // 如果是订阅用户，不显示使用次数限制信息
    if (_isProUser) {
      return Container();
    }

    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                '今日剩余使用次数',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 剩余使用次数显示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '剩余次数: $_remainingUses / ${UsageManager.maxDailyUsage}',
                style: TextStyle(
                  fontSize: 14,
                  color: _remainingUses > 0 ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _remainingUses > 0 ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _remainingUses > 0 ? '可继续使用' : '次数已用完',
                  style: TextStyle(
                    fontSize: 12,
                    color: _remainingUses > 0 ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 订阅引导
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '升级到专业版',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '订阅专业版即可享受无限次使用，解锁所有高级功能',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _navigateToSubscriptionPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      '立即订阅',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
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

  Future<void> _saveToHistory() async {
    try {
      final dbService = DatabaseService();
      await dbService.insertAnalysisResult(widget.analysisResult);
      setState(() {
        _isSaved = true;
      });
      
      // 保存完成后通知首页刷新数据
      UsageUpdateNotifier().notifyListeners();
    } catch (e) {
      // 保存失败不影响页面展示
    }
  }

  Widget _buildHealthScoreWidget() {
    final score = widget.analysisResult.healthScore;
    Color color;
    String level;

    if (score >= 8) {
      color = Colors.green;
      level = '优秀';
    } else if (score >= 6) {
      color = Colors.orange;
      level = '良好';
    } else if (score >= 4) {
      color = Colors.yellow[700]!;
      level = '一般';
    } else {
      color = Colors.red;
      level = '较差';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '健康评分',
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 48,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            level,
            style: TextStyle(
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientCard(IngredientAnalysis ingredient) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ingredient.ingredientName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('主要作用:', ingredient.function),
            _buildInfoRow('营养价值:', ingredient.nutritionalValue),
            _buildInfoRow('合规性:', ingredient.complianceStatus),
            _buildInfoRow('加工度:', ingredient.processingLevel),
            if (ingredient.remarks.isNotEmpty)
              _buildInfoRow('备注:', ingredient.remarks),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析结果'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          if (_isSaved)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.check, color: Colors.white),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 食品名称和标准
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.analysisResult.foodName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '配料数量: ${widget.analysisResult.ingredients.length}种',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '分析时间: ${widget.analysisResult.analysisTime.toString().substring(0, 16)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 健康评分
            _buildHealthScoreWidget(),
            
            const SizedBox(height: 20),
            
            // 结构化分析结果
            _buildComplianceCard(),
            const SizedBox(height: 16),
            _buildProcessingCard(),
            const SizedBox(height: 16),
            _buildClaimsCard(),
            const SizedBox(height: 16),
            
            // 总体评价
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '总体评价',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.analysisResult.overallAssessment),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 配料分析
            const Text(
              '配料分析',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...widget.analysisResult.ingredients.map(_buildIngredientCard),
            
            const SizedBox(height: 20),
            
            // 建议
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '建议',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.analysisResult.recommendations),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 今日剩余使用次数和订阅引导
            _buildUsageAndSubscriptionWidget(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceCard() {
    final compliance = widget.analysisResult.compliance;
    Color statusColor;
    IconData statusIcon;
    
    switch (compliance.status) {
      case '合规':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case '不合规':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  '合规性分析',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  compliance.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(compliance.description),
            if (compliance.issues.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                '需要注意的问题：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...compliance.issues.map((issue) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(issue)),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingCard() {
    final processing = widget.analysisResult.processing;
    Color levelColor;
    
    switch (processing.level) {
      case '未加工':
        levelColor = Colors.green;
        break;
      case '轻度加工':
        levelColor = Colors.lightGreen;
        break;
      case '中度加工':
        levelColor = Colors.orange;
        break;
      case '高度加工':
        levelColor = Colors.deepOrange;
        break;
      case '超加工':
        levelColor = Colors.red;
        break;
      default:
        levelColor = Colors.grey;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  '加工度分析',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: levelColor),
                  ),
                  child: Text(
                    processing.level,
                    style: TextStyle(
                      color: levelColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '评分: ${processing.score.toStringAsFixed(1)}/5.0',
                  style: TextStyle(
                    color: levelColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(processing.description),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimsCard() {
    final claims = widget.analysisResult.claims;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  '特定宣称分析',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (claims.detectedClaims.isNotEmpty) ...[
              const Text(
                '检测到的宣称：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...claims.detectedClaims.map((claim) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(claim)),
                  ],
                ),
              )),
              const SizedBox(height: 8),
            ],
            if (claims.supportedClaims.isNotEmpty) ...[
              const Text(
                '有依据的宣称：',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              ...claims.supportedClaims.map((claim) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Expanded(child: Text(claim, style: const TextStyle(color: Colors.green))),
                  ],
                ),
              )),
              const SizedBox(height: 8),
            ],
            if (claims.questionableClaims.isNotEmpty) ...[
              const Text(
                '可疑的宣称：',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              ...claims.questionableClaims.map((claim) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Expanded(child: Text(claim, style: const TextStyle(color: Colors.orange))),
                  ],
                ),
              )),
              const SizedBox(height: 8),
            ],
            Text(claims.assessment),
          ],
        ),
      ),
    );
  }
}
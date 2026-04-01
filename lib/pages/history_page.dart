import 'package:flutter/material.dart';

import '../models/analysis_history_item.dart';
import '../services/backend_api_service.dart';
import 'analysis_result_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final BackendApiService _backendApiService = BackendApiService();

  List<AnalysisHistoryItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _backendApiService.fetchHistory();
      if (!mounted) return;
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载历史失败: $e')));
    }
  }

  Future<void> _deleteItem(AnalysisHistoryItem item) async {
    final originalIndex = _history.indexOf(item);
    if (originalIndex == -1) return;

    setState(() {
      _history.remove(item);
    });

    try {
      await _backendApiService.deleteHistoryItem(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除成功')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _history.insert(originalIndex, item);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
    }
  }

  ({Color color, Color softColor, String label}) _scoreTone(double score) {
    if (score >= 8) {
      return (
        color: const Color(0xFF1B8A5A),
        softColor: const Color(0xFFEAF8F1),
        label: '优秀',
      );
    }
    if (score >= 6) {
      return (
        color: const Color(0xFFD68C00),
        softColor: const Color(0xFFFFF4DA),
        label: '良好',
      );
    }
    if (score >= 4) {
      return (
        color: const Color(0xFFE56B00),
        softColor: const Color(0xFFFFEBDD),
        label: '一般',
      );
    }
    return (
      color: const Color(0xFFC73535),
      softColor: const Color(0xFFFEEBEC),
      label: '关注',
    );
  }

  String _sourceLabel(String sourceType) {
    switch (sourceType) {
      case 'image':
        return '图片识别';
      case 'manual':
        return '手动输入';
      default:
        return '配料分析';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }

  int _ingredientCount(AnalysisHistoryItem item) {
    final resultCount = item.result.ingredients.length;
    if (resultCount > 0) return resultCount;
    return item.ingredientLines.length;
  }

  String _recordPreview(AnalysisHistoryItem item) {
    final assessment = item.result.overallAssessment.trim();
    if (assessment.isNotEmpty) return assessment;

    final recommendations = item.result.recommendations.trim();
    if (recommendations.isNotEmpty) return recommendations;

    if (item.ingredientLines.isNotEmpty) {
      return '识别到 ${item.ingredientLines.length} 项配料，查看详情了解逐项分析。';
    }

    return '查看这次分析的完整配料解释与个性化提醒。';
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDEE9E0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2F7D32)),
          const SizedBox(width: 6),
          Text(
            '$label$value',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final healthyCount = _history.where((item) => item.healthScore >= 7).length;
    final attentionCount = _history
        .where((item) => item.healthScore < 5)
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
          const Text(
            '分析历史',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF163020),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '下拉可刷新，左滑记录可删除。每条记录都保留评分、结论与配料级解释。',
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF597260),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMetricChip(
                icon: Icons.inventory_2_outlined,
                label: '累计 ',
                value: '${_history.length} 条',
              ),
              _buildMetricChip(
                icon: Icons.favorite_outline,
                label: '较优 ',
                value: '$healthyCount 条',
              ),
              _buildMetricChip(
                icon: Icons.warning_amber_rounded,
                label: '需关注 ',
                value: '$attentionCount 条',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1EDE1)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 36,
              color: Color(0xFF2F7D32),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '还没有分析历史',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '先去上传一张配料表，系统会自动保存你的识别记录，后续可以回看每个配料的作用与整体结论。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.7,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(AnalysisHistoryItem item) {
    final tone = _scoreTone(item.healthScore);
    final progressValue = (item.healthScore.clamp(0, 10) / 10).toDouble();

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFC73535),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('确认删除'),
                content: const Text('确定要删除这条分析记录吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC73535),
                    ),
                    child: const Text('删除'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) => _deleteItem(item),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnalysisResultPage(
                analysisResult: item.result,
                isFromHistory: true,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Ink(
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: tone.softColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.healthScore.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: tone.color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tone.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: tone.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6F4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _sourceLabel(item.sourceType),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9CA3AF),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  item.foodName.trim().isEmpty ? '未命名商品' : item.foodName.trim(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _recordPreview(item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: progressValue,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(tone.color),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoPill(
                      icon: Icons.schedule_rounded,
                      text: _formatDateTime(item.createdAt),
                    ),
                    _buildInfoPill(
                      icon: Icons.list_alt_rounded,
                      text: '${_ingredientCount(item)} 项配料',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F8F4),
        body: _HistoryLoadingScaffold(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      body: RefreshIndicator(
        color: const Color(0xFF2F7D32),
        onRefresh: _loadHistory,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 1080
                ? 24.0
                : 16.0;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: _buildOverviewCard(),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    18,
                    horizontalPadding,
                    24,
                  ),
                  sliver: _history.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: _buildEmptyState(),
                            ),
                          ),
                        )
                      : SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1080),
                              child: Column(
                                children: List.generate(
                                  _history.length,
                                  (index) => _buildHistoryItem(_history[index]),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistoryLoadingScaffold extends StatelessWidget {
  const _HistoryLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF2F7D32),
            ),
          ),
          SizedBox(height: 14),
          Text(
            '正在同步历史记录',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

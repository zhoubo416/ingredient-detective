import 'package:flutter/material.dart';

import '../models/ingredient_analysis.dart';
import '../services/backend_api_service.dart';
import 'login_page.dart';

class AnalysisResultPage extends StatefulWidget {
  final FoodAnalysisResult? analysisResult;
  final QuickAnalysisResult? quickResult;
  final bool isFromHistory;

  const AnalysisResultPage({
    super.key,
    this.analysisResult,
    this.quickResult,
    this.isFromHistory = false,
  }) : assert(analysisResult != null || quickResult != null);

  @override
  State<AnalysisResultPage> createState() => _AnalysisResultPageState();
}

class _AnalysisResultPageState extends State<AnalysisResultPage> {
  final BackendApiService _apiService = BackendApiService();

  late FoodAnalysisResult _result;
  bool _isPolling = false;
  bool _showAllIngredients = false;
  String? _pollError;

  bool get _hasIngredients => _result.ingredients.isNotEmpty;

  bool get _needsPolling =>
      !widget.isFromHistory &&
      _result.detailedStatus != 'failed' &&
      _result.detailedStatus != 'complete' &&
      _result.rawMarkdown.isEmpty &&
      (_result.analysisId?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _result = widget.analysisResult ?? _fromQuickResult(widget.quickResult!);
    if (_needsPolling) {
      _startPolling();
    }
  }

  FoodAnalysisResult _fromQuickResult(QuickAnalysisResult quick) {
    return FoodAnalysisResult(
      foodName: quick.foodName,
      ingredients: const [],
      healthScore: quick.healthScore,
      compliance: quick.compliance,
      processing: quick.processing,
      claims: ClaimsAnalysis(
        detectedClaims: const [],
        supportedClaims: const [],
        questionableClaims: const [],
        assessment: '',
      ),
      overallAssessment: quick.overallAssessment,
      recommendations: '',
      warnings: const [],
      detailedStatus: 'pending',
      analysisTime: quick.createdAt,
    );
  }

  FoodAnalysisResult _mergeResult(
    FoodAnalysisResult current,
    FoodAnalysisResult incoming,
  ) {
    return FoodAnalysisResult(
      foodName: incoming.foodName.trim().isNotEmpty
          ? incoming.foodName
          : current.foodName,
      ingredients: incoming.ingredients.isNotEmpty
          ? incoming.ingredients
          : current.ingredients,
      healthScore: incoming.healthScore > 0
          ? incoming.healthScore
          : current.healthScore,
      compliance: incoming.compliance.status.trim().isNotEmpty
          ? incoming.compliance
          : current.compliance,
      processing: incoming.processing.level.trim().isNotEmpty
          ? incoming.processing
          : current.processing,
      claims: incoming.claims.assessment.trim().isNotEmpty
          ? incoming.claims
          : current.claims,
      overallAssessment: incoming.overallAssessment.trim().isNotEmpty
          ? incoming.overallAssessment
          : current.overallAssessment,
      recommendations: incoming.recommendations.trim().isNotEmpty
          ? incoming.recommendations
          : current.recommendations,
      warnings: incoming.warnings.isNotEmpty
          ? incoming.warnings
          : current.warnings,
      // 总是使用来自服务器的最新状态（优先完成/失败，再考虑待定）
      detailedStatus: incoming.detailedStatus != 'pending'
          ? incoming.detailedStatus
          : current.detailedStatus,
      // 总是优先使用来自服务器的错误信息（如果存在）
      detailedError: incoming.detailedError.trim().isNotEmpty
          ? incoming.detailedError
          : current.detailedError,
      analysisTime: incoming.analysisTime,
      analysisId: incoming.analysisId ?? current.analysisId,
      rawMarkdown: incoming.rawMarkdown.trim().isNotEmpty
          ? incoming.rawMarkdown
          : current.rawMarkdown,
    );
  }

  void _startPolling() {
    if (_isPolling || !_needsPolling) return;
    setState(() {
      _isPolling = true;
      _pollError = null;
    });
    _pollForDetails();
  }

  Future<void> _pollForDetails() async {
    const maxAttempts = 90;
    const pollInterval = Duration(seconds: 1);

    try {
      for (int i = 0; i < maxAttempts; i++) {
        if (i > 0) {
          await Future.delayed(pollInterval);
        }
        if (!mounted) return;

        try {
          final updated = await _apiService.getAnalysisResult(
            _result.analysisId!,
          );
          if (!mounted) return;

          setState(() {
            _result = _mergeResult(_result, updated);
            _pollError = null;
          });

          if (_result.detailedStatus == 'complete' ||
              _result.detailedStatus == 'failed' ||
              _result.rawMarkdown.isNotEmpty) {
            return;
          }
        } on UnauthorizedException {
          if (!mounted) return;
          _navigateToLogin();
          return;
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _pollError = e.toString();
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPolling = false;
        });
      } else {
        _isPolling = false;
      }
    }
  }

  Future<void> _refreshResult() async {
    final analysisId = _result.analysisId;
    if (analysisId == null || analysisId.isEmpty) return;

    try {
      final updated = await _apiService.getAnalysisResult(analysisId);
      if (!mounted) return;
      setState(() {
        _result = _mergeResult(_result, updated);
        _pollError = null;
      });
    } on UnauthorizedException {
      if (!mounted) return;
      _navigateToLogin();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pollError = e.toString();
      });
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  String _reportMarkdown() {
    final buffer = StringBuffer();

    if (_result.claims.assessment.trim().isNotEmpty) {
      buffer
        ..writeln('## 宣称分析')
        ..writeln(_result.claims.assessment.trim())
        ..writeln();
    }

    if (_pollError != null && _pollError!.trim().isNotEmpty) {
      buffer
        ..writeln('## 轮询状态')
        ..writeln('- 最近一次刷新错误: ${_pollError!.trim()}')
        ..writeln();
    }

    if (_result.detailedStatus == 'failed' &&
        _result.detailedError.trim().isNotEmpty) {
      buffer
        ..writeln('## 详细分析状态')
        ..writeln('- 详细配料分析失败: ${_result.detailedError.trim()}')
        ..writeln();
    }

    return buffer.toString();
  }

  String _safeValue(String value) {
    final text = value.trim();
    return text.isEmpty ? '待模型返回' : text;
  }

  String? _nonEmptyOrNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
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

  ({Color color, Color softColor, String label}) _ingredientTone(
    IngredientAnalysis ingredient,
  ) {
    if (ingredient.riskLevel == 'caution') {
      return (
        color: const Color(0xFFC2410C),
        softColor: const Color(0xFFFFEDD5),
        label: '需关注',
      );
    }

    if (ingredient.isAdditive || ingredient.riskLevel == 'additive') {
      return (
        color: const Color(0xFFB45309),
        softColor: const Color(0xFFFEF3C7),
        label: '添加剂',
      );
    }

    return (
      color: const Color(0xFF2F7D32),
      softColor: const Color(0xFFEAF8F1),
      label: '常规',
    );
  }

  List<String> _actionableAdvices() {
    final advice = <String>[
      ..._result.warnings
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty),
    ];

    for (final ingredient in _result.ingredients) {
      if (advice.length >= 4) break;
      final tone = _ingredientTone(ingredient);
      if (tone.label == '常规') continue;

      final impact = _nonEmptyOrNull(ingredient.negativeImpact);
      final action = _nonEmptyOrNull(ingredient.actionableAdvice);
      final reason = _nonEmptyOrNull(ingredient.riskReason);
      final details = [impact, action, reason].whereType<String>().join(' ');

      if (details.isEmpty) continue;
      advice.add('${ingredient.ingredientName}: $details');
    }

    final recommendation = _nonEmptyOrNull(_result.recommendations);
    if (recommendation != null) {
      advice.add(recommendation);
    }

    final seen = <String>{};
    return advice
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .where(seen.add)
        .take(4)
        .toList();
  }

  String? _reminderAdvice() {
    final advice = _actionableAdvices();
    if (advice.isEmpty) {
      return null;
    }
    return advice.join('\n\n');
  }

  List<IngredientAnalysis> get _visibleIngredients {
    if (_showAllIngredients || _result.ingredients.length <= 3) {
      return _result.ingredients;
    }
    return _result.ingredients.take(3).toList();
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(56)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHero() {
    final foodName = _result.foodName.trim().isNotEmpty
        ? _result.foodName
        : '未知食品';
    final tone = _scoreTone(_result.healthScore);
    final reminderAdvice = _reminderAdvice();

    return Container(
      padding: const EdgeInsets.all(16),
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
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      foodName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF163020),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildStatusChip(
                          icon: Icons.favorite_rounded,
                          label: '',
                          value: tone.label,
                          color: tone.color,
                        ),
                        _buildStatusChip(
                          icon: Icons.verified_user_outlined,
                          label: '',
                          value: _safeValue(_result.compliance.status),
                          color: const Color(0xFF256A54),
                        ),
                        _buildStatusChip(
                          icon: Icons.precision_manufacturing_outlined,
                          label: '加工 ',
                          value: _safeValue(_result.processing.level),
                          color: const Color(0xFF5B6FA8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: tone.softColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tone.color.withAlpha(60)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _result.healthScore.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: tone.color,
                      ),
                    ),
                    Text(
                      '/ 10',
                      style: TextStyle(
                        fontSize: 10,
                        color: tone.color.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _safeValue(_result.overallAssessment),
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: Color(0xFF57705D),
            ),
          ),
          if (reminderAdvice != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withAlpha(120),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reminderAdvice,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIngredientItem(IngredientAnalysis ingredient, int index) {
    final tone = _ingredientTone(ingredient);
    final hasCompliance = ingredient.complianceStatus.trim().isNotEmpty;
    final hasProcessing = ingredient.processingLevel.trim().isNotEmpty;
    final hasNutrition = ingredient.nutritionalValue.trim().isNotEmpty;
    final riskReason = _nonEmptyOrNull(ingredient.riskReason);
    final negativeImpact = _nonEmptyOrNull(ingredient.negativeImpact);
    final actionableAdvice = _nonEmptyOrNull(ingredient.actionableAdvice);

    final complianceAndProcessing = [
      if (hasCompliance) '合规: ${ingredient.complianceStatus.trim()}',
      if (hasProcessing) '加工: ${ingredient.processingLevel.trim()}',
    ].join(' · ');

    final riskSummary = [
      riskReason,
      negativeImpact,
    ].whereType<String>().join(' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.softColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tone.label == '常规'
              ? const Color(0xFFDEE9E0)
              : tone.color.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tone.softColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: tone.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.ingredientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (tone.label != '常规') ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tone.softColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tone.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: tone.color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildIngredientField(
            label: '作用分析',
            content: _safeValue(ingredient.function),
            emphasis: tone.label == '需关注',
          ),
          if (hasNutrition) ...[
            const SizedBox(height: 10),
            _buildIngredientField(
              label: '营养价值',
              content: ingredient.nutritionalValue.trim(),
            ),
          ],
          if (complianceAndProcessing.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildIngredientField(
              label: '合规/加工',
              content: complianceAndProcessing,
            ),
          ],
          if (riskSummary.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildIngredientField(
              label: '风险提示',
              content: riskSummary,
              emphasis: tone.label != '常规',
            ),
          ],
          if (actionableAdvice != null) ...[
            const SizedBox(height: 10),
            _buildIngredientField(
              label: '建议',
              content: actionableAdvice,
              emphasis: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandButton({bool prominent = false}) {
    final label = _showAllIngredients ? '收起配料明细' : '展开全部配料';

    if (prominent) {
      return FilledButton.tonalIcon(
        onPressed: () {
          setState(() {
            _showAllIngredients = !_showAllIngredients;
          });
        },
        icon: Icon(
          _showAllIngredients
              ? Icons.unfold_less_rounded
              : Icons.unfold_more_rounded,
        ),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: const Color(0xFF1B5E20),
          backgroundColor: const Color(0xFFEAF6EC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    return TextButton.icon(
      onPressed: () {
        setState(() {
          _showAllIngredients = !_showAllIngredients;
        });
      },
      icon: Icon(
        _showAllIngredients
            ? Icons.unfold_less_rounded
            : Icons.unfold_more_rounded,
      ),
      label: Text(label),
    );
  }

  Widget _buildIngredientField({
    required String label,
    required String content,
    bool emphasis = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: emphasis
                  ? const Color(0xFFB45309)
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.65,
              color: emphasis
                  ? const Color(0xFF92400E)
                  : const Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              const Expanded(
                child: Text(
                  '配料信息',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              if (_result.ingredients.length > 3) _buildExpandButton(),
            ],
          ),
          const SizedBox(height: 10),
          if (_result.rawMarkdown.isNotEmpty)
            _buildMarkdownView(_result.rawMarkdown)
          else if (_hasIngredients)
            ...List.generate(
              _visibleIngredients.length,
              (index) =>
                  _buildIngredientItem(_visibleIngredients[index], index),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE1ECE3)),
              ),
              child: Text(
                _isPolling ? '详细配料分析生成中，请稍候刷新。' : '暂未返回详细配料明细。',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
          if (_result.ingredients.length > 3) ...[
            const SizedBox(height: 4),
            if (!_showAllIngredients)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '还有 ${_result.ingredients.length - 3} 项配料未展开',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            _buildExpandButton(prominent: true),
          ],
        ],
      ),
    );
  }

  Widget _buildPollingNotice() {
    final hasFailure = _result.detailedStatus == 'failed';
    final color = hasFailure
        ? const Color(0xFFC73535)
        : _pollError == null
        ? const Color(0xFF2563EB)
        : const Color(0xFFC73535);
    final title = hasFailure
        ? '详细分析生成失败'
        : _pollError == null
        ? '正在补充详细配料分析'
        : '详细结果刷新异常';
    final content = hasFailure
        ? (_result.detailedError.trim().isNotEmpty
              ? _result.detailedError.trim()
              : '模型没有返回可用的结构化结果，请重新发起分析。')
        : _pollError == null
        ? '系统已经返回初步结论，正在继续补全每个配料的作用分析。你可以停留在此页等待，也可以手动刷新。'
        : '最近一次刷新没有成功，但不会影响已展示的结果。可以稍后再次刷新。';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDEE9E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  hasFailure
                      ? Icons.error_outline_rounded
                      : _pollError == null
                      ? Icons.hourglass_top_rounded
                      : Icons.error_outline_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.65,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: _isPolling
                ? null
                : hasFailure
                ? _refreshResult
                : _startPolling,
            icon: Icon(
              _isPolling
                  ? Icons.sync
                  : hasFailure
                  ? Icons.restart_alt_rounded
                  : Icons.refresh_rounded,
            ),
            label: Text(
              _isPolling
                  ? '生成中'
                  : hasFailure
                  ? '重新获取结果'
                  : '刷新详细结果',
            ),
            style: FilledButton.styleFrom(
              foregroundColor: const Color(0xFF1D4ED8),
              backgroundColor: const Color(0xFFEFF6FF),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildInlineSpans(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    final matcher = RegExp(r'\*\*(.*?)\*\*').allMatches(text);
    int start = 0;

    for (final match in matcher) {
      if (match.start > start) {
        spans.add(
          TextSpan(text: text.substring(start, match.start), style: baseStyle),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1) ?? '',
          style: baseStyle.copyWith(fontWeight: FontWeight.w800),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }

    return spans;
  }

  IconData _sectionIcon(String title) {
    if (title.contains('配料')) return Icons.science_outlined;
    if (title.contains('建议')) return Icons.lightbulb_outline_rounded;
    if (title.contains('宣称')) return Icons.campaign_outlined;
    if (title.contains('轮询')) return Icons.sync_problem_rounded;
    return Icons.dashboard_customize_outlined;
  }

  Widget _buildMarkdownView(String markdown) {
    final lines = markdown.split('\n');
    final widgets = <Widget>[];

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.isEmpty) continue;

      if (line.startsWith('### ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              line.substring(4),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
        );
        continue;
      }

      if (line.startsWith('## ')) {
        final title = line.substring(3);
        widgets.add(
          Container(
            margin: EdgeInsets.only(top: widgets.isEmpty ? 0 : 12, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _sectionIcon(title),
                  size: 16,
                  color: const Color(0xFF166534),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14532D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      if (line.startsWith('- ')) {
        final content = line.substring(2);
        const baseStyle = TextStyle(fontSize: 12.5, height: 1.5);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF9CA3AF),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: baseStyle.copyWith(color: const Color(0xFF374151)),
                      children: _buildInlineSpans(content, baseStyle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      const baseStyle = TextStyle(fontSize: 12.5, height: 1.5);
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 1, bottom: 1),
          child: RichText(
            text: TextSpan(
              style: baseStyle.copyWith(color: const Color(0xFF374151)),
              children: _buildInlineSpans(line, baseStyle),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildReportCard(String markdown) {
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
          const Text(
            '补充说明',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '这里展示额外的宣称分析与结果刷新状态。',
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          _buildMarkdownView(markdown),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markdown = _reportMarkdown();
    final hasExtraReport = markdown.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      appBar: AppBar(
        title: const Text('分析结果'),
        backgroundColor: const Color(0xFFF8FBF8),
        foregroundColor: const Color(0xFF163020),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          if (_isPolling)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFF2F7D32),
            ),
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF2F7D32),
              onRefresh: _refreshResult,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        children: [
                          _buildSummaryHero(),
                          const SizedBox(height: 12),
                          if (_needsPolling) ...[
                            _buildPollingNotice(),
                            const SizedBox(height: 12),
                          ],
                          _buildIngredientsCard(),
                          if (hasExtraReport) ...[
                            const SizedBox(height: 12),
                            _buildReportCard(markdown),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

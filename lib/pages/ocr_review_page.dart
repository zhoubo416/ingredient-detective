import 'package:flutter/material.dart';
import '../services/backend_api_service.dart';
import 'analysis_result_page.dart';
import 'subscription_page.dart';

/// OCR 识别结果编辑页 — 用户可修正 OCR 文本后再开始分析
class OcrReviewPage extends StatefulWidget {
  final OcrResult ocrResult;
  final String? productName;
  final Map<String, dynamic>? userHealthProfile;

  const OcrReviewPage({
    super.key,
    required this.ocrResult,
    this.productName,
    this.userHealthProfile,
  });

  @override
  State<OcrReviewPage> createState() => _OcrReviewPageState();
}

class _OcrReviewPageState extends State<OcrReviewPage> {
  late final TextEditingController _textController;
  late final TextEditingController _productNameController;
  final BackendApiService _backendApiService = BackendApiService();
  bool _isAnalyzing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.ocrResult.displayText);
    _productNameController =
        TextEditingController(text: widget.productName ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    _productNameController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = '请输入配料内容');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final result = await _backendApiService.analyzeIngredientsText(
        text,
        productName: _productNameController.text.trim(),
        userHealthProfile: widget.userHealthProfile,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisResultPage(analysisResult: result),
        ),
      );
    } on ForbiddenException catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pro 会员专享'),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('稍后再说'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionPage(),
                  ),
                );
              },
              child: const Text('升级 Pro'),
            ),
          ],
        ),
      );
      setState(() => _isAnalyzing = false);
    } catch (e) {
      setState(() {
        _error = '分析失败: $e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      appBar: AppBar(
        title: const Text('确认配料内容'),
        backgroundColor: const Color(0xFF2F7D32),
        foregroundColor: Colors.white,
        actions: [
          if (_isAnalyzing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 提示卡片
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '以下是图片识别结果，你可以修改或补充后再开始分析。\nOCR 识别了 ${widget.ocrResult.ingredientCount} 项配料。',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 产品名输入
              TextField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  labelText: '产品名称（可选）',
                  hintText: '如：风味酸乳',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // 配料文本编辑
              TextField(
                controller: _textController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: '配料内容',
                  hintText: '例如：小麦粉，白砂糖，植物油，食盐，香精',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),

              // 快捷提示
              Text(
                '提示：配料之间可以用逗号、分号或换行分隔。营养成分表内容（蛋白质、脂肪等）也可以保留，帮助更全面分析。',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 20),

              // 错误提示
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isAnalyzing ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('返回修改',
                          style: TextStyle(color: Color(0xFF374151))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isAnalyzing ? null : _startAnalysis,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isAnalyzing ? '分析中…' : '开始分析'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2F7D32),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/ingredient_analysis.dart';
import '../services/database_service.dart';

class AnalysisResultPage extends StatefulWidget {
  final FoodAnalysisResult analysisResult;

  const AnalysisResultPage({super.key, required this.analysisResult});

  @override
  State<AnalysisResultPage> createState() => _AnalysisResultPageState();
}

class _AnalysisResultPageState extends State<AnalysisResultPage> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _saveToHistory();
  }

  Future<void> _saveToHistory() async {
    try {
      final dbService = DatabaseService();
      await dbService.insertAnalysisResult(widget.analysisResult);
      setState(() {
        _isSaved = true;
      });
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color),
      ),
      child: Column(
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
            _buildInfoRow('安全等级:', ingredient.safetyLevel),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.analysisResult.foodName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '分析标准: ${widget.analysisResult.standardUsed}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '分析时间: ${widget.analysisResult.analysisTime.toString().substring(0, 16)}',
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
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
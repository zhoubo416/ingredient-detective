import 'package:flutter/material.dart';
import '../models/ingredient_analysis.dart';

class AnalysisResultPage extends StatelessWidget {
  final FoodAnalysisResult analysisResult;
  final bool isFromHistory;

  const AnalysisResultPage({
    super.key,
    required this.analysisResult,
    this.isFromHistory = false,
  });

  Widget _buildHealthScoreWidget() {
    final score = analysisResult.healthScore;
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
            if (ingredient.remarks.isNotEmpty) _buildInfoRow('备注:', ingredient.remarks),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceCard() {
    final compliance = analysisResult.compliance;
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
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                const Text(
                  '合规性分析',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              compliance.status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(compliance.description),
            if (compliance.issues.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...compliance.issues.map((issue) => Text('• $issue')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingCard() {
    final processing = analysisResult.processing;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '加工度分析',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${processing.level} (${processing.score.toStringAsFixed(1)}分)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(processing.description),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimsCard() {
    final claims = analysisResult.claims;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '宣称分析',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(claims.assessment),
            if (claims.detectedClaims.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('检测到的宣称: ${claims.detectedClaims.join('、')}'),
            ],
            if (claims.questionableClaims.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('需要进一步核实: ${claims.questionableClaims.join('、')}'),
            ],
          ],
        ),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      analysisResult.foodName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '配料数量: ${analysisResult.ingredients.length}种',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '分析时间: ${analysisResult.analysisTime.toString().substring(0, 16)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildHealthScoreWidget(),
            const SizedBox(height: 20),
            _buildComplianceCard(),
            const SizedBox(height: 16),
            _buildProcessingCard(),
            const SizedBox(height: 16),
            _buildClaimsCard(),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '总体评价',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(analysisResult.overallAssessment),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '配料分析',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...analysisResult.ingredients.map(_buildIngredientCard),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '建议',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(analysisResult.recommendations),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

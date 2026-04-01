class IngredientAnalysis {
  final String ingredientName;
  final String function;
  final String nutritionalValue;
  final String complianceStatus; // 合规性状态
  final String processingLevel; // 加工度等级
  final String remarks;
  final String riskLevel; // normal/additive/caution
  final String riskReason;
  final String actionableAdvice;
  final String negativeImpact;
  final bool isAdditive;

  IngredientAnalysis({
    required this.ingredientName,
    required this.function,
    required this.nutritionalValue,
    required this.complianceStatus,
    required this.processingLevel,
    required this.remarks,
    this.riskLevel = 'normal',
    this.riskReason = '',
    this.actionableAdvice = '',
    this.negativeImpact = '',
    this.isAdditive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'ingredientName': ingredientName,
      'function': function,
      'nutritionalValue': nutritionalValue,
      'complianceStatus': complianceStatus,
      'processingLevel': processingLevel,
      'remarks': remarks,
      'riskLevel': riskLevel,
      'riskReason': riskReason,
      'actionableAdvice': actionableAdvice,
      'negativeImpact': negativeImpact,
      'isAdditive': isAdditive,
    };
  }

  factory IngredientAnalysis.fromMap(Map<String, dynamic> map) {
    final name = _normalizeIngredientName(
      _asString(
        map['ingredientName'] ??
            map['name'] ??
            map['ingredient'] ??
            map['title'],
      ),
    );

    return IngredientAnalysis(
      ingredientName: name,
      function: _asString(map['function'] ?? map['role']),
      nutritionalValue: _asString(map['nutritionalValue'] ?? map['nutrition']),
      complianceStatus: _asString(
        map['complianceStatus'] ?? map['compliance'] ?? map['status'],
      ),
      processingLevel: _asString(
        map['processingLevel'] ?? map['processing'] ?? map['level'],
      ),
      remarks: _asString(map['remarks'] ?? map['note'] ?? map['notes']),
      riskLevel: _normalizeRiskLevel(map['riskLevel'] ?? map['risk_level']),
      riskReason: _asString(map['riskReason'] ?? map['risk_reason']),
      actionableAdvice: _asString(
        map['actionableAdvice'] ?? map['actionable_advice'] ?? map['advice'],
      ),
      negativeImpact: _asString(
        map['negativeImpact'] ?? map['negative_impact'],
      ),
      isAdditive: _asBool(map['isAdditive'] ?? map['is_additive']),
    );
  }
}

// 合规性分析结果
class ComplianceAnalysis {
  final String status; // 合规/不合规/待确认
  final String description; // 详细说明
  final List<String> issues; // 具体问题列表

  ComplianceAnalysis({
    required this.status,
    required this.description,
    required this.issues,
  });

  Map<String, dynamic> toMap() {
    return {'status': status, 'description': description, 'issues': issues};
  }

  factory ComplianceAnalysis.fromMap(Map<String, dynamic> map) {
    return ComplianceAnalysis(
      status: _asString(map['status']),
      description: _asString(map['description']),
      issues: _asStringList(map['issues']),
    );
  }
}

// 加工度分析结果
class ProcessingAnalysis {
  final String level; // 未加工/轻度加工/中度加工/高度加工/超加工
  final String description; // 详细说明
  final double score; // 加工度评分 (1-5分)

  ProcessingAnalysis({
    required this.level,
    required this.description,
    required this.score,
  });

  Map<String, dynamic> toMap() {
    return {'level': level, 'description': description, 'score': score};
  }

  factory ProcessingAnalysis.fromMap(Map<String, dynamic> map) {
    return ProcessingAnalysis(
      level: _asString(map['level']),
      description: _asString(map['description']),
      score: _asDouble(map['score'], 1.0),
    );
  }
}

// 特定宣称分析结果
class ClaimsAnalysis {
  final List<String> detectedClaims; // 检测到的宣称
  final List<String> supportedClaims; // 有依据的宣称
  final List<String> questionableClaims; // 可疑的宣称
  final String assessment; // 整体评估

  ClaimsAnalysis({
    required this.detectedClaims,
    required this.supportedClaims,
    required this.questionableClaims,
    required this.assessment,
  });

  Map<String, dynamic> toMap() {
    return {
      'detectedClaims': detectedClaims,
      'supportedClaims': supportedClaims,
      'questionableClaims': questionableClaims,
      'assessment': assessment,
    };
  }

  factory ClaimsAnalysis.fromMap(Map<String, dynamic> map) {
    return ClaimsAnalysis(
      detectedClaims: _asStringList(map['detectedClaims']),
      supportedClaims: _asStringList(map['supportedClaims']),
      questionableClaims: _asStringList(map['questionableClaims']),
      assessment: _asString(map['assessment']),
    );
  }
}

class FoodAnalysisResult {
  final String foodName;
  final List<IngredientAnalysis> ingredients;
  final double healthScore;
  final ComplianceAnalysis compliance; // 合规性分析
  final ProcessingAnalysis processing; // 加工度分析
  final ClaimsAnalysis claims; // 特定宣称分析
  final String overallAssessment;
  final String recommendations;
  final List<String> warnings;
  final DateTime analysisTime;
  final String? analysisId; // 用于轮询获取更新

  FoodAnalysisResult({
    required this.foodName,
    required this.ingredients,
    required this.healthScore,
    required this.compliance,
    required this.processing,
    required this.claims,
    required this.overallAssessment,
    required this.recommendations,
    this.warnings = const [],
    required this.analysisTime,
    this.analysisId,
  });

  Map<String, dynamic> toMap() {
    return {
      'foodName': foodName,
      'ingredients': ingredients
          .map((ingredient) => ingredient.toMap())
          .toList(),
      'healthScore': healthScore,
      'compliance': compliance.toMap(),
      'processing': processing.toMap(),
      'claims': claims.toMap(),
      'overallAssessment': overallAssessment,
      'recommendations': recommendations,
      'warnings': warnings,
      'analysisTime': analysisTime.toIso8601String(),
      'analysisId': analysisId,
    };
  }

  factory FoodAnalysisResult.fromMap(Map<String, dynamic> map) {
    final input = map['result'] is Map
        ? Map<String, dynamic>.from(map['result'] as Map)
        : map;

    return FoodAnalysisResult(
      foodName: _asString(input['foodName'] ?? input['food_name']),
      ingredients: _parseIngredients(input['ingredients']),
      healthScore: _asDouble(
        input['healthScore'] ?? input['health_score'],
        0.0,
      ),
      compliance: ComplianceAnalysis.fromMap(
        _asMap(input['compliance'] ?? input['compliance_analysis']),
      ),
      processing: ProcessingAnalysis.fromMap(
        _asMap(input['processing'] ?? input['processing_analysis']),
      ),
      claims: ClaimsAnalysis.fromMap(_asMap(input['claims'])),
      overallAssessment: _asString(
        input['overallAssessment'] ?? input['overall_assessment'],
      ),
      recommendations: _asString(input['recommendations']),
      warnings: _asStringList(input['warnings']),
      analysisTime: _asDateTime(
        input['analysisTime'] ?? input['analysis_time'],
      ),
      analysisId: _asNullableString(
        input['analysisId'] ?? map['id'] ?? input['analysis_id'],
      ),
    );
  }

  static List<IngredientAnalysis> _parseIngredients(dynamic value) {
    if (value is! List) return const [];

    final items = <IngredientAnalysis>[];
    final seenNames = <String>{};

    for (final item in value) {
      if (item is String) {
        final name = _normalizeIngredientName(item.trim());
        if (name.isEmpty) continue;
        if (!seenNames.add(name)) continue;
        items.add(
          IngredientAnalysis(
            ingredientName: name,
            function: '',
            nutritionalValue: '',
            complianceStatus: '',
            processingLevel: '',
            remarks: '',
          ),
        );
        continue;
      }

      if (item is Map) {
        final parsed = IngredientAnalysis.fromMap(
          Map<String, dynamic>.from(item),
        );
        final name = _normalizeIngredientName(parsed.ingredientName);
        if (name.isEmpty) continue;
        if (!seenNames.add(name)) continue;
        items.add(
          IngredientAnalysis(
            ingredientName: name,
            function: parsed.function,
            nutritionalValue: parsed.nutritionalValue,
            complianceStatus: parsed.complianceStatus,
            processingLevel: parsed.processingLevel,
            remarks: parsed.remarks,
            riskLevel: parsed.riskLevel,
            riskReason: parsed.riskReason,
            actionableAdvice: parsed.actionableAdvice,
            negativeImpact: parsed.negativeImpact,
            isAdditive: parsed.isAdditive,
          ),
        );
      }
    }
    return items;
  }
}

// 快速分析结果 - 两阶段分析的第一阶段
class QuickAnalysisResult {
  final String foodName;
  final double healthScore;
  final ComplianceAnalysis compliance;
  final ProcessingAnalysis processing;
  final String overallAssessment;
  final DateTime createdAt;

  QuickAnalysisResult({
    required this.foodName,
    required this.healthScore,
    required this.compliance,
    required this.processing,
    required this.overallAssessment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'foodName': foodName,
      'healthScore': healthScore,
      'compliance': compliance.toMap(),
      'processing': processing.toMap(),
      'overallAssessment': overallAssessment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QuickAnalysisResult.fromMap(Map<String, dynamic> map) {
    return QuickAnalysisResult(
      foodName: _asString(map['foodName']),
      healthScore: _asDouble(map['healthScore'], 0.0),
      compliance: ComplianceAnalysis.fromMap(_asMap(map['compliance'])),
      processing: ProcessingAnalysis.fromMap(_asMap(map['processing'])),
      overallAssessment: _asString(map['overallAssessment']),
      createdAt: _asDateTime(map['createdAt']),
    );
  }
}

String _asString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? _asNullableString(dynamic value) {
  final text = _asString(value);
  return text.isEmpty ? null : text;
}

double _asDouble(dynamic value, [double fallback = 0.0]) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  return fallback;
}

bool _asBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
  }
  return fallback;
}

DateTime _asDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return DateTime.now();
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  if (value is String && value.trim().isNotEmpty) {
    return [value.trim()];
  }
  return const [];
}

String _normalizeIngredientName(String input) {
  return input
      .replaceAll(RegExp(r'^(配料表?|产品配料|成分|主要成分|原料)[：:\s]*'), '')
      .replaceAll(RegExp(r'^[•·\-\d.\s]+'), '')
      .replaceAll(RegExp(r'[()（）\[\]【】]'), '')
      .trim();
}

String _normalizeRiskLevel(dynamic value) {
  final text = _asString(value, 'normal').toLowerCase();
  switch (text) {
    case 'normal':
    case 'additive':
    case 'caution':
      return text;
    default:
      return 'normal';
  }
}

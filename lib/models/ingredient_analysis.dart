class IngredientAnalysis {
  final String ingredientName;
  final String function;
  final String nutritionalValue;
  final String complianceStatus; // 合规性状态
  final String processingLevel; // 加工度等级
  final String remarks;

  IngredientAnalysis({
    required this.ingredientName,
    required this.function,
    required this.nutritionalValue,
    required this.complianceStatus,
    required this.processingLevel,
    required this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'ingredientName': ingredientName,
      'function': function,
      'nutritionalValue': nutritionalValue,
      'complianceStatus': complianceStatus,
      'processingLevel': processingLevel,
      'remarks': remarks,
    };
  }

  factory IngredientAnalysis.fromMap(Map<String, dynamic> map) {
    return IngredientAnalysis(
      ingredientName: map['ingredientName'] ?? '',
      function: map['function'] ?? '',
      nutritionalValue: map['nutritionalValue'] ?? '',
      complianceStatus: map['complianceStatus'] ?? '',
      processingLevel: map['processingLevel'] ?? '',
      remarks: map['remarks'] ?? '',
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
    return {
      'status': status,
      'description': description,
      'issues': issues,
    };
  }

  factory ComplianceAnalysis.fromMap(Map<String, dynamic> map) {
    return ComplianceAnalysis(
      status: map['status'] ?? '',
      description: map['description'] ?? '',
      issues: List<String>.from(map['issues'] ?? []),
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
    return {
      'level': level,
      'description': description,
      'score': score,
    };
  }

  factory ProcessingAnalysis.fromMap(Map<String, dynamic> map) {
    return ProcessingAnalysis(
      level: map['level'] ?? '',
      description: map['description'] ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 1.0,
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
      detectedClaims: List<String>.from(map['detectedClaims'] ?? []),
      supportedClaims: List<String>.from(map['supportedClaims'] ?? []),
      questionableClaims: List<String>.from(map['questionableClaims'] ?? []),
      assessment: map['assessment'] ?? '',
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
  final DateTime analysisTime;

  FoodAnalysisResult({
    required this.foodName,
    required this.ingredients,
    required this.healthScore,
    required this.compliance,
    required this.processing,
    required this.claims,
    required this.overallAssessment,
    required this.recommendations,
    required this.analysisTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'foodName': foodName,
      'ingredients': ingredients.map((ingredient) => ingredient.toMap()).toList(),
      'healthScore': healthScore,
      'compliance': compliance.toMap(),
      'processing': processing.toMap(),
      'claims': claims.toMap(),
      'overallAssessment': overallAssessment,
      'recommendations': recommendations,
      'analysisTime': analysisTime.toIso8601String(),
    };
  }

  factory FoodAnalysisResult.fromMap(Map<String, dynamic> map) {
    return FoodAnalysisResult(
      foodName: map['foodName'] ?? '',
      ingredients: (map['ingredients'] as List?)?.map((ingredientMap) => IngredientAnalysis.fromMap(ingredientMap)).toList() ?? [],
      healthScore: (map['healthScore'] as num?)?.toDouble() ?? 0.0,
      compliance: ComplianceAnalysis.fromMap(map['compliance'] ?? {}),
      processing: ProcessingAnalysis.fromMap(map['processing'] ?? {}),
      claims: ClaimsAnalysis.fromMap(map['claims'] ?? {}),
      overallAssessment: map['overallAssessment'] ?? '',
      recommendations: map['recommendations'] ?? '',
      analysisTime: DateTime.parse(map['analysisTime'] ?? DateTime.now().toIso8601String()),
    );
  }
}
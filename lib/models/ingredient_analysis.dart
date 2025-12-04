class IngredientAnalysis {
  final String ingredientName;
  final String function;
  final String nutritionalValue;
  final String safetyLevel;
  final String remarks;

  IngredientAnalysis({
    required this.ingredientName,
    required this.function,
    required this.nutritionalValue,
    required this.safetyLevel,
    required this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'ingredientName': ingredientName,
      'function': function,
      'nutritionalValue': nutritionalValue,
      'safetyLevel': safetyLevel,
      'remarks': remarks,
    };
  }

  factory IngredientAnalysis.fromMap(Map<String, dynamic> map) {
    return IngredientAnalysis(
      ingredientName: map['ingredientName'] ?? '',
      function: map['function'] ?? '',
      nutritionalValue: map['nutritionalValue'] ?? '',
      safetyLevel: map['safetyLevel'] ?? '',
      remarks: map['remarks'] ?? '',
    );
  }
}

class FoodAnalysisResult {
  final String foodName;
  final List<IngredientAnalysis> ingredients;
  final double healthScore;
  final String overallAssessment;
  final String recommendations;
  final String standardUsed;
  final DateTime analysisTime;

  FoodAnalysisResult({
    required this.foodName,
    required this.ingredients,
    required this.healthScore,
    required this.overallAssessment,
    required this.recommendations,
    required this.standardUsed,
    required this.analysisTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'foodName': foodName,
      'ingredients': ingredients.map((ingredient) => ingredient.toMap()).toList(),
      'healthScore': healthScore,
      'overallAssessment': overallAssessment,
      'recommendations': recommendations,
      'standardUsed': standardUsed,
      'analysisTime': analysisTime.toIso8601String(),
    };
  }

  factory FoodAnalysisResult.fromMap(Map<String, dynamic> map) {
    return FoodAnalysisResult(
      foodName: map['foodName'] ?? '',
      ingredients: (map['ingredients'] as List?)?.map((ingredientMap) => IngredientAnalysis.fromMap(ingredientMap)).toList() ?? [],
      healthScore: (map['healthScore'] as num?)?.toDouble() ?? 0.0,
      overallAssessment: map['overallAssessment'] ?? '',
      recommendations: map['recommendations'] ?? '',
      standardUsed: map['standardUsed'] ?? '',
      analysisTime: DateTime.parse(map['analysisTime'] ?? DateTime.now().toIso8601String()),
    );
  }
}
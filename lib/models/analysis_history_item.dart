import 'ingredient_analysis.dart';

class AnalysisHistoryItem {
  final String id;
  final String sourceType;
  final String? imageFilename;
  final List<String> ingredientLines;
  final String? rawOcrText;
  final String foodName;
  final double healthScore;
  final DateTime createdAt;
  final FoodAnalysisResult result;

  AnalysisHistoryItem({
    required this.id,
    required this.sourceType,
    required this.imageFilename,
    required this.ingredientLines,
    required this.rawOcrText,
    required this.foodName,
    required this.healthScore,
    required this.createdAt,
    required this.result,
  });

  factory AnalysisHistoryItem.fromMap(Map<String, dynamic> map) {
    return AnalysisHistoryItem(
      id: map['id']?.toString() ?? '',
      sourceType: map['sourceType']?.toString() ?? 'manual',
      imageFilename: map['imageFilename']?.toString(),
      ingredientLines: (map['ingredientLines'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      rawOcrText: map['rawOcrText']?.toString(),
      foodName: map['foodName']?.toString() ?? '',
      healthScore: (map['healthScore'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      result: FoodAnalysisResult.fromMap(
        Map<String, dynamic>.from(map['result'] as Map? ?? {}),
      ),
    );
  }
}

import '../models/ingredient_analysis.dart';

class AIService {
  static Future<FoodAnalysisResult> analyzeIngredients(
    List<String> ingredients,
    String productName,
  ) {
    throw UnsupportedError(
      'Local AIService has been retired. Use BackendApiService for real model analysis.',
    );
  }
}

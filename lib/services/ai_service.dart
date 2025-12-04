import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ingredient_analysis.dart';

class AIService {
  // DeepSeek API配置
  static const String _apiKey = 'sk-d3d05ed3d1944cac9ca1a95d7902cbd3';
  static const String _baseURL = 'https://api.deepseek.com/v1';
  static const String _model = 'deepseek-chat';

  static Future<FoodAnalysisResult> analyzeIngredients(
    List<String> ingredients, 
    String standard
  ) async {
    try {
      final response = await _callDeepSeekAPI(ingredients, standard);
      
      if (response != null && response.isNotEmpty) {
        return _parseAIResponse(response, ingredients, standard);
      } else {
        // 如果API调用失败，使用模拟数据作为备用
        return _getMockAnalysisResult(ingredients, standard);
      }
    } catch (e) {
      print('DeepSeek API调用失败: $e');
      // 返回模拟数据作为备用
      return _getMockAnalysisResult(ingredients, standard);
    }
  }

  static Future<String?> _callDeepSeekAPI(List<String> ingredients, String standard) async {
    try {
      print('开始调用DeepSeek API分析配料...');
      print('配料列表: $ingredients');
      print('分析标准: $standard');
      
      final requestBody = jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': '''你是一个专业的食品营养分析师和食品安全专家。请根据提供的配料列表，按照$standard标准进行详细分析。

请以JSON格式返回分析结果，包含以下字段：
{
  "foodName": "食品类型名称",
  "healthScore": 数值(0-10),
  "overallAssessment": "总体评价文字",
  "recommendations": "建议文字",
  "ingredients": [
    {
      "ingredientName": "配料名称",
      "function": "主要作用",
      "nutritionalValue": "营养价值",
      "safetyLevel": "安全等级",
      "remarks": "备注"
    }
  ]
}'''
          },
          {
            'role': 'user',
            'content': '''请分析以下配料：${ingredients.join(", ")}

请按照$standard标准进行分析，提供：
1. 每种配料的主要作用和营养价值
2. 安全性评估（安全/适量安全/需注意等）
3. 整体健康评分（0-10分，10分最健康）
4. 总体评价和建议

请确保返回标准的JSON格式。'''
          }
        ],
        'temperature': 0.3,
        'max_tokens': 3000,
      });
      
      print('DeepSeek API请求体: $requestBody');
      
      final response = await http.post(
        Uri.parse('$_baseURL/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: requestBody,
      );

      print('DeepSeek API响应状态码: ${response.statusCode}');
      print('DeepSeek API响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final content = data['choices'][0]['message']['content'];
          print('DeepSeek API分析结果: $content');
          return content;
        } else {
          print('DeepSeek API响应中没有choices字段');
        }
      } else {
        print('DeepSeek API错误: ${response.statusCode} - ${response.body}');
      }
      
      return null;
    } catch (e) {
      print('DeepSeek API调用异常: $e');
      return null;
    }
  }

  static FoodAnalysisResult _parseAIResponse(
    String response, 
    List<String> ingredients, 
    String standard
  ) {
    try {
      // 尝试解析DeepSeek返回的JSON格式数据
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonString = response.substring(jsonStart, jsonEnd);
        final data = jsonDecode(jsonString);
        
        // 解析配料分析
        final ingredientAnalyses = <IngredientAnalysis>[];
        if (data['ingredients'] != null) {
          for (var ingredientData in data['ingredients']) {
            ingredientAnalyses.add(IngredientAnalysis(
              ingredientName: ingredientData['ingredientName'] ?? '',
              function: ingredientData['function'] ?? '',
              nutritionalValue: ingredientData['nutritionalValue'] ?? '',
              safetyLevel: ingredientData['safetyLevel'] ?? '',
              remarks: ingredientData['remarks'] ?? '',
            ));
          }
        }
        
        // 如果没有解析到配料，使用原始配料列表生成
        if (ingredientAnalyses.isEmpty) {
          for (String ingredient in ingredients) {
            ingredientAnalyses.add(IngredientAnalysis(
              ingredientName: ingredient,
              function: _getMockFunction(ingredient),
              nutritionalValue: _getMockNutritionalValue(ingredient),
              safetyLevel: _getMockSafetyLevel(ingredient),
              remarks: _getMockRemarks(ingredient),
            ));
          }
        }
        
        return FoodAnalysisResult(
          foodName: data['foodName'] ?? _guessFoodType(ingredients),
          ingredients: ingredientAnalyses,
          healthScore: (data['healthScore'] as num?)?.toDouble() ?? _calculateHealthScore(ingredients),
          overallAssessment: data['overallAssessment'] ?? _generateOverallAssessment(_calculateHealthScore(ingredients), _guessFoodType(ingredients), standard),
          recommendations: data['recommendations'] ?? _generateRecommendations(ingredients, _calculateHealthScore(ingredients), standard),
          standardUsed: standard,
          analysisTime: DateTime.now(),
        );
      }
    } catch (e) {
      print('解析AI响应失败: $e');
    }
    
    // 如果解析失败，返回模拟数据
    return _getMockAnalysisResult(ingredients, standard);
  }

  static FoodAnalysisResult _getMockAnalysisResult(List<String> ingredients, String standard) {
    // 根据配料猜测食品类型
    final foodType = _guessFoodType(ingredients);
    
    // 计算健康评分（基于配料健康程度）
    final healthScore = _calculateHealthScore(ingredients);
    
    // 生成总体评价
    final overallAssessment = _generateOverallAssessment(healthScore, foodType, standard);
    
    // 生成建议
    final recommendations = _generateRecommendations(ingredients, healthScore, standard);

    final ingredientAnalyses = ingredients.map((ingredient) {
      return IngredientAnalysis(
        ingredientName: ingredient,
        function: _getMockFunction(ingredient),
        nutritionalValue: _getMockNutritionalValue(ingredient),
        safetyLevel: _getMockSafetyLevel(ingredient),
        remarks: _getMockRemarks(ingredient),
      );
    }).toList();

    return FoodAnalysisResult(
      foodName: foodType,
      ingredients: ingredientAnalyses,
      healthScore: healthScore,
      overallAssessment: overallAssessment,
      recommendations: recommendations,
      standardUsed: standard,
      analysisTime: DateTime.now(),
    );
  }
  
  static String _guessFoodType(List<String> ingredients) {
    // 根据配料猜测食品类型
    if (ingredients.any((ingredient) => ingredient.contains('可可'))) {
      return '巧克力制品';
    } else if (ingredients.any((ingredient) => ingredient.contains('牛乳'))) {
      return '乳制品';
    } else if (ingredients.any((ingredient) => ingredient.contains('马铃薯'))) {
      return '薯类零食';
    } else if (ingredients.any((ingredient) => ingredient.contains('猪肉'))) {
      return '肉制品';
    } else if (ingredients.any((ingredient) => ingredient.contains('小麦粉'))) {
      return '面食制品';
    } else if (ingredients.any((ingredient) => ingredient.contains('水') && ingredients.length <= 3)) {
      return '饮料';
    } else {
      return '加工食品';
    }
  }
  
  static double _calculateHealthScore(List<String> ingredients) {
    // 基于配料健康程度计算评分
    double score = 8.0; // 基础分
    
    // 健康配料加分
    final healthyIngredients = ['水', '牛乳', '鸡蛋', '大豆', '马铃薯', '蔬菜'];
    for (String healthy in healthyIngredients) {
      if (ingredients.any((ingredient) => ingredient.contains(healthy))) {
        score += 0.5;
      }
    }
    
    // 不健康配料减分
    final unhealthyIngredients = ['糖', '添加剂', '香精', '防腐剂', '色素'];
    for (String unhealthy in unhealthyIngredients) {
      if (ingredients.any((ingredient) => ingredient.contains(unhealthy))) {
        score -= 0.8;
      }
    }
    
    // 限制在0-10分之间
    return score.clamp(0.0, 10.0);
  }
  
  static String _generateOverallAssessment(double score, String foodType, String standard) {
    if (score >= 8.0) {
      return '$foodType整体健康程度优秀，符合$standard要求，可以适量食用';
    } else if (score >= 6.0) {
      return '$foodType整体健康程度良好，基本符合$standard要求，建议适量食用';
    } else if (score >= 4.0) {
      return '$foodType健康程度一般，部分成分需注意，建议控制摄入量';
    } else {
      return '$foodType健康程度较差，含有较多不健康成分，建议减少食用';
    }
  }
  
  static String _generateRecommendations(List<String> ingredients, double score, String standard) {
    final recommendations = <String>[];
    
    if (ingredients.any((ingredient) => ingredient.contains('糖'))) {
      recommendations.add('注意糖分摄入，建议选择低糖版本');
    }
    if (ingredients.any((ingredient) => ingredient.contains('添加剂'))) {
      recommendations.add('含有食品添加剂，建议选择天然成分较多的产品');
    }
    if (ingredients.any((ingredient) => ingredient.contains('盐'))) {
      recommendations.add('注意钠含量，高血压患者需谨慎');
    }
    if (ingredients.any((ingredient) => ingredient.contains('油'))) {
      recommendations.add('含有油脂，建议控制摄入量');
    }
    
    if (recommendations.isEmpty) {
      if (score >= 8.0) {
        return '该食品符合$standard健康要求，可以适量食用';
      } else {
        return '建议均衡饮食，适量食用各类食品';
      }
    }
    
    return recommendations.join('。') + '。';
  }

  static String _getMockFunction(String ingredient) {
    final functions = {
      '糖': '提供能量，增加甜味',
      '盐': '调味，维持电解质平衡',
      '面粉': '提供碳水化合物和能量',
      '水': '基础溶剂，维持生命活动',
      '油': '提供能量和必需脂肪酸',
    };
    return functions[ingredient] ?? '食品添加剂或调味剂';
  }

  static String _getMockNutritionalValue(String ingredient) {
    final values = {
      '糖': '高热量，无其他营养价值',
      '盐': '提供钠元素，但需适量',
      '面粉': '富含碳水化合物，提供能量',
      '水': '无热量，维持水分平衡',
      '油': '高热量，提供必需脂肪酸',
    };
    return values[ingredient] ?? '营养价值因具体成分而异';
  }

  static String _getMockSafetyLevel(String ingredient) {
    final levels = {
      '糖': '适量安全，过量有害',
      '盐': '适量安全，过量有害',
      '面粉': '安全',
      '水': '安全',
      '油': '适量安全，过量有害',
    };
    return levels[ingredient] ?? '一般安全';
  }

  static String _getMockRemarks(String ingredient) {
    final remarks = {
      '糖': '建议控制摄入量',
      '盐': '高血压患者需特别注意',
      '面粉': '适合作为主食',
      '水': '每日必需',
      '油': '选择健康油脂',
    };
    return remarks[ingredient] ?? '按需适量使用';
  }
}
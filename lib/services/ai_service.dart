import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ingredient_analysis.dart';
import '../config/api_config.dart';

class AIService {
  // DeepSeek API配置
  static String get _apiKey => ApiConfig.deepseekApiKey;
  static const String _baseURL = 'https://api.deepseek.com/v1';
  static const String _model = 'deepseek-chat';

  static Future<FoodAnalysisResult> analyzeIngredients(
    List<String> ingredients, 
    String productName
  ) async {
    try {
      final response = await _callDeepSeekAPI(ingredients, productName);
      
      if (response != null && response.isNotEmpty) {
        return _parseAIResponse(response, ingredients, productName);
      } else {
        // 如果API调用失败，使用模拟数据作为备用
        return _getMockAnalysisResult(ingredients, productName);
      }
    } catch (e) {
      print('DeepSeek API调用失败: $e');
      // 返回模拟数据作为备用
      return _getMockAnalysisResult(ingredients, productName);
    }
  }

  static Future<String?> _callDeepSeekAPI(List<String> ingredients, String productName) async {
    try {
      print('开始调用DeepSeek API分析配料...');
      print('配料列表: $ingredients');
      print('产品名称: $productName');
      
      final requestBody = jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': '''你是一个专业的食品营养分析师和食品安全专家。请根据提供的配料列表进行结构化分析。

请以JSON格式返回分析结果，包含以下字段：
{
  "foodName": "食品类型名称",
  "healthScore": 数值(0-10),
  "compliance": {
    "status": "合规/不合规/待确认",
    "description": "合规性详细说明",
    "issues": ["具体问题1", "具体问题2"]
  },
  "processing": {
    "level": "未加工/轻度加工/中度加工/高度加工/超加工",
    "description": "加工度详细说明",
    "score": 数值(1-5)
  },
  "claims": {
    "detectedClaims": ["检测到的宣称1", "宣称2"],
    "supportedClaims": ["有依据的宣称"],
    "questionableClaims": ["可疑的宣称"],
    "assessment": "宣称评估说明"
  },
  "overallAssessment": "总体评价文字",
  "recommendations": "建议文字",
  "ingredients": [
    {
      "ingredientName": "配料名称",
      "function": "主要作用",
      "nutritionalValue": "营养价值",
      "complianceStatus": "合规性状态",
      "processingLevel": "加工度等级",
      "remarks": "备注"
    }
  ]
}'''
          },
          {
            'role': 'user',
            'content': '''请分析产品"$productName"的配料：${ingredients.join(", ")}

请从以下三个维度进行结构化分析：

1. 合规性分析：
   - 检查配料是否符合食品安全法规
   - 识别可能的违规成分
   - 评估标签标识的准确性

2. 加工度分析：
   - 根据NOVA分类系统评估加工程度
   - 分析添加剂和人工成分的使用
   - 评估食品的天然程度

3. 特定宣称分析：
   - 识别产品可能的健康宣称
   - 评估宣称的科学依据
   - 指出可能的误导性表述

请提供：
- 每种配料的详细分析
- 整体健康评分（0-10分，10分最健康）
- 结构化的评估报告
- 针对性的消费建议

请确保返回标准的JSON格式。'''
          }
        ],
        'temperature': 0.3,
        'max_tokens': 4000,
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
    String productName
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
              complianceStatus: ingredientData['complianceStatus'] ?? '',
              processingLevel: ingredientData['processingLevel'] ?? '',
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
              complianceStatus: _getMockComplianceStatus(ingredient),
              processingLevel: _getMockProcessingLevel(ingredient),
              remarks: _getMockRemarks(ingredient),
            ));
          }
        }
        
        // 解析合规性分析
        final complianceData = data['compliance'] ?? {};
        final compliance = ComplianceAnalysis(
          status: complianceData['status'] ?? '待确认',
          description: complianceData['description'] ?? '需要进一步评估合规性',
          issues: List<String>.from(complianceData['issues'] ?? []),
        );
        
        // 解析加工度分析
        final processingData = data['processing'] ?? {};
        final processing = ProcessingAnalysis(
          level: processingData['level'] ?? '中度加工',
          description: processingData['description'] ?? '包含多种加工成分',
          score: (processingData['score'] as num?)?.toDouble() ?? 3.0,
        );
        
        // 解析特定宣称分析
        final claimsData = data['claims'] ?? {};
        final claims = ClaimsAnalysis(
          detectedClaims: List<String>.from(claimsData['detectedClaims'] ?? []),
          supportedClaims: List<String>.from(claimsData['supportedClaims'] ?? []),
          questionableClaims: List<String>.from(claimsData['questionableClaims'] ?? []),
          assessment: claimsData['assessment'] ?? '未检测到特定宣称',
        );
        
        return FoodAnalysisResult(
          foodName: data['foodName'] ?? _guessFoodType(ingredients),
          ingredients: ingredientAnalyses,
          healthScore: (data['healthScore'] as num?)?.toDouble() ?? _calculateHealthScore(ingredients),
          compliance: compliance,
          processing: processing,
          claims: claims,
          overallAssessment: data['overallAssessment'] ?? _generateOverallAssessment(_calculateHealthScore(ingredients), _guessFoodType(ingredients)),
          recommendations: data['recommendations'] ?? _generateRecommendations(ingredients, _calculateHealthScore(ingredients)),
          analysisTime: DateTime.now(),
        );
      }
    } catch (e) {
      print('解析AI响应失败: $e');
    }
    
    // 如果解析失败，返回模拟数据
    return _getMockAnalysisResult(ingredients, productName);
  }

  static FoodAnalysisResult _getMockAnalysisResult(List<String> ingredients, String productName) {
    // 根据配料猜测食品类型
    final foodType = _guessFoodType(ingredients);
    
    // 计算健康评分（基于配料健康程度）
    final healthScore = _calculateHealthScore(ingredients);
    
    // 生成总体评价
    final overallAssessment = _generateOverallAssessment(healthScore, foodType);
    
    // 生成建议
    final recommendations = _generateRecommendations(ingredients, healthScore);

    final ingredientAnalyses = ingredients.map((ingredient) {
      return IngredientAnalysis(
        ingredientName: ingredient,
        function: _getMockFunction(ingredient),
        nutritionalValue: _getMockNutritionalValue(ingredient),
        complianceStatus: _getMockComplianceStatus(ingredient),
        processingLevel: _getMockProcessingLevel(ingredient),
        remarks: _getMockRemarks(ingredient),
      );
    }).toList();

    // 生成模拟的合规性分析
    final compliance = ComplianceAnalysis(
      status: _getMockComplianceOverallStatus(ingredients),
      description: _getMockComplianceDescription(ingredients),
      issues: _getMockComplianceIssues(ingredients),
    );

    // 生成模拟的加工度分析
    final processing = ProcessingAnalysis(
      level: _getMockProcessingOverallLevel(ingredients),
      description: _getMockProcessingDescription(ingredients),
      score: _getMockProcessingScore(ingredients),
    );

    // 生成模拟的特定宣称分析
    final claims = ClaimsAnalysis(
      detectedClaims: _getMockDetectedClaims(productName),
      supportedClaims: _getMockSupportedClaims(productName),
      questionableClaims: _getMockQuestionableClaims(productName),
      assessment: _getMockClaimsAssessment(productName),
    );

    return FoodAnalysisResult(
      foodName: foodType,
      ingredients: ingredientAnalyses,
      healthScore: healthScore,
      compliance: compliance,
      processing: processing,
      claims: claims,
      overallAssessment: overallAssessment,
      recommendations: recommendations,
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
  
  static String _generateOverallAssessment(double score, String foodType) {
    if (score >= 8.0) {
      return '$foodType整体健康程度优秀，配料相对天然，可以适量食用';
    } else if (score >= 6.0) {
      return '$foodType整体健康程度良好，大部分配料安全，建议适量食用';
    } else if (score >= 4.0) {
      return '$foodType健康程度一般，部分成分需注意，建议控制摄入量';
    } else {
      return '$foodType健康程度较差，含有较多加工成分，建议减少食用';
    }
  }
  
  static String _generateRecommendations(List<String> ingredients, double score) {
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
        return '该食品整体健康程度较好，可以适量食用';
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

  static String _getMockComplianceStatus(String ingredient) {
    final status = {
      '糖': '合规',
      '盐': '合规',
      '面粉': '合规',
      '水': '合规',
      '油': '合规',
      '添加剂': '待确认',
      '香精': '待确认',
      '防腐剂': '需注意',
    };
    return status[ingredient] ?? '合规';
  }

  static String _getMockProcessingLevel(String ingredient) {
    final levels = {
      '糖': '轻度加工',
      '盐': '轻度加工',
      '面粉': '轻度加工',
      '水': '未加工',
      '油': '中度加工',
      '添加剂': '高度加工',
      '香精': '高度加工',
      '防腐剂': '高度加工',
    };
    return levels[ingredient] ?? '中度加工';
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

  // 合规性相关模拟方法
  static String _getMockComplianceOverallStatus(List<String> ingredients) {
    if (ingredients.any((ingredient) => ingredient.contains('防腐剂') || ingredient.contains('色素'))) {
      return '需注意';
    } else if (ingredients.any((ingredient) => ingredient.contains('添加剂') || ingredient.contains('香精'))) {
      return '待确认';
    }
    return '合规';
  }

  static String _getMockComplianceDescription(List<String> ingredients) {
    final hasAdditives = ingredients.any((ingredient) => ingredient.contains('添加剂'));
    final hasPreservatives = ingredients.any((ingredient) => ingredient.contains('防腐剂'));
    
    if (hasPreservatives) {
      return '含有防腐剂，需确认使用量是否符合国家标准';
    } else if (hasAdditives) {
      return '含有食品添加剂，建议查看具体添加剂种类和用量';
    }
    return '配料表中的成分均为常见食品原料，符合基本安全要求';
  }

  static List<String> _getMockComplianceIssues(List<String> ingredients) {
    final issues = <String>[];
    if (ingredients.any((ingredient) => ingredient.contains('防腐剂'))) {
      issues.add('防腐剂使用需符合GB 2760标准');
    }
    if (ingredients.any((ingredient) => ingredient.contains('色素'))) {
      issues.add('人工色素使用需在允许范围内');
    }
    return issues;
  }

  // 加工度相关模拟方法
  static String _getMockProcessingOverallLevel(List<String> ingredients) {
    final additiveCount = ingredients.where((ingredient) => 
      ingredient.contains('添加剂') || 
      ingredient.contains('香精') || 
      ingredient.contains('防腐剂') ||
      ingredient.contains('色素')
    ).length;
    
    if (additiveCount >= 3) return '超加工';
    if (additiveCount >= 2) return '高度加工';
    if (additiveCount >= 1) return '中度加工';
    if (ingredients.length > 3) return '轻度加工';
    return '未加工';
  }

  static String _getMockProcessingDescription(List<String> ingredients) {
    final level = _getMockProcessingOverallLevel(ingredients);
    switch (level) {
      case '超加工':
        return '含有多种食品添加剂和人工成分，加工程度很高';
      case '高度加工':
        return '含有较多加工成分，营养价值可能有所降低';
      case '中度加工':
        return '经过一定程度的工业加工，保留部分天然营养';
      case '轻度加工':
        return '经过基本加工处理，大部分营养得以保留';
      default:
        return '基本保持天然状态，营养价值较高';
    }
  }

  static double _getMockProcessingScore(List<String> ingredients) {
    final level = _getMockProcessingOverallLevel(ingredients);
    switch (level) {
      case '超加工': return 5.0;
      case '高度加工': return 4.0;
      case '中度加工': return 3.0;
      case '轻度加工': return 2.0;
      default: return 1.0;
    }
  }

  // 特定宣称相关模拟方法
  static List<String> _getMockDetectedClaims(String productName) {
    final claims = <String>[];
    if (productName.contains('无糖') || productName.contains('低糖')) {
      claims.add('无糖/低糖宣称');
    }
    if (productName.contains('天然') || productName.contains('纯天然')) {
      claims.add('天然宣称');
    }
    if (productName.contains('有机')) {
      claims.add('有机宣称');
    }
    if (productName.contains('健康') || productName.contains('营养')) {
      claims.add('健康营养宣称');
    }
    return claims;
  }

  static List<String> _getMockSupportedClaims(String productName) {
    final supported = <String>[];
    if (productName.contains('无糖')) {
      supported.add('无糖宣称');
    }
    return supported;
  }

  static List<String> _getMockQuestionableClaims(String productName) {
    final questionable = <String>[];
    if (productName.contains('纯天然')) {
      questionable.add('纯天然宣称');
    }
    if (productName.contains('健康')) {
      questionable.add('健康宣称');
    }
    return questionable;
  }

  static String _getMockClaimsAssessment(String productName) {
    final detected = _getMockDetectedClaims(productName);
    if (detected.isEmpty) {
      return '未检测到特定健康或营养宣称';
    }
    return '检测到${detected.length}项宣称，建议核实相关依据';
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../models/analysis_history_item.dart';
import '../models/ingredient_analysis.dart';
import 'auth_service.dart';

class BackendApiService {
  static final BackendApiService _instance = BackendApiService._internal();

  factory BackendApiService() => _instance;

  BackendApiService._internal();

  final AuthService _authService = AuthService();

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final baseUri = Uri.parse(ApiConfig.backendApiUrl);
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return baseUri.replace(
      path: '${baseUri.path}$normalizedPath'.replaceAll('//', '/'),
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = _authService.currentSession?.accessToken;

    if (token == null || token.isEmpty) {
      throw Exception('当前未登录，请重新登录后再试');
    }

    return {
      'Authorization': 'Bearer $token',
    };
  }

  Future<FoodAnalysisResult> analyzeImage(
    XFile image, {
    String? productName,
  }) async {
    if (!ApiConfig.isBackendConfigured) {
      throw Exception('BACKEND_API_URL 未配置');
    }

    final request = http.MultipartRequest(
      'POST',
      _buildUri('/api/analysis'),
    );

    request.headers.addAll(await _authorizedHeaders());

    if (productName != null && productName.trim().isNotEmpty) {
      request.fields['productName'] = productName.trim();
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        await image.readAsBytes(),
        filename: image.name,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(payload['statusMessage']?.toString() ?? '分析失败');
    }

    // 处理新的两阶段响应格式
    final quickResult = payload['quick'] as Map<String, dynamic>?;
    if (quickResult == null) {
      throw Exception('API 返回数据格式错误');
    }

    // 将快速结果转换为完整的 FoodAnalysisResult
    return FoodAnalysisResult(
      foodName: quickResult['foodName'] ?? '',
      ingredients: [], // 初始为空，稍后轮询填充
      healthScore: (quickResult['healthScore'] as num?)?.toDouble() ?? 0.0,
      compliance: ComplianceAnalysis(
        status: (quickResult['compliance'] as Map?)?['status'] ?? '',
        description: (quickResult['compliance'] as Map?)?['description'] ?? '',
        issues: [],
      ),
      processing: ProcessingAnalysis(
        level: (quickResult['processing'] as Map?)?['level'] ?? '',
        description: (quickResult['processing'] as Map?)?['description'] ?? '',
        score: ((quickResult['processing'] as Map?)?['score'] as num?)?.toDouble() ?? 1.0,
      ),
      claims: ClaimsAnalysis(
        detectedClaims: [],
        supportedClaims: [],
        questionableClaims: [],
        assessment: '详细分析生成中...',
      ),
      overallAssessment: quickResult['overallAssessment'] ?? '',
      recommendations: quickResult['recommendations'] ?? '',
      analysisTime: DateTime.now().toIso8601String(),
    );
  }

  Future<FoodAnalysisResult> analyzeIngredientsText(
    String ingredientsText, {
    String? productName,
  }) async {
    if (!ApiConfig.isBackendConfigured) {
      throw Exception('BACKEND_API_URL 未配置');
    }

    final response = await http.post(
      _buildUri('/api/analysis'),
      headers: {
        'Content-Type': 'application/json',
        ...await _authorizedHeaders(),
      },
      body: jsonEncode({
        'ingredientsText': ingredientsText,
        if (productName != null && productName.trim().isNotEmpty) 'productName': productName.trim(),
      }),
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(payload['statusMessage']?.toString() ?? '分析失败');
    }

    // 处理新的两阶段响应格式
    final quickResult = payload['quick'] as Map<String, dynamic>?;
    if (quickResult == null) {
      throw Exception('API 返回数据格式错误');
    }

    // 将快速结果转换为完整的 FoodAnalysisResult
    return FoodAnalysisResult(
      foodName: quickResult['foodName'] ?? '',
      ingredients: [], // 初始为空，稍后轮询填充
      healthScore: (quickResult['healthScore'] as num?)?.toDouble() ?? 0.0,
      compliance: ComplianceAnalysis(
        status: (quickResult['compliance'] as Map?)?['status'] ?? '',
        description: (quickResult['compliance'] as Map?)?['description'] ?? '',
        issues: [],
      ),
      processing: ProcessingAnalysis(
        level: (quickResult['processing'] as Map?)?['level'] ?? '',
        description: (quickResult['processing'] as Map?)?['description'] ?? '',
        score: ((quickResult['processing'] as Map?)?['score'] as num?)?.toDouble() ?? 1.0,
      ),
      claims: ClaimsAnalysis(
        detectedClaims: [],
        supportedClaims: [],
        questionableClaims: [],
        assessment: '详细分析生成中...',
      ),
      overallAssessment: quickResult['overallAssessment'] ?? '',
      recommendations: quickResult['recommendations'] ?? '',
      analysisTime: DateTime.now().toIso8601String(),
    );
  }

  Future<List<AnalysisHistoryItem>> fetchHistory({int limit = 30}) async {
    if (!ApiConfig.isBackendConfigured) {
      throw Exception('BACKEND_API_URL 未配置');
    }

    final response = await http.get(
      _buildUri('/api/history', {
        'limit': '$limit',
      }),
      headers: await _authorizedHeaders(),
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(payload['statusMessage']?.toString() ?? '加载历史失败');
    }

    final items = payload['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => AnalysisHistoryItem.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> deleteHistoryItem(String id) async {
    if (!ApiConfig.isBackendConfigured) {
      throw Exception('BACKEND_API_URL 未配置');
    }

    final response = await http.delete(
      _buildUri('/api/history/$id'),
      headers: await _authorizedHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(payload['statusMessage']?.toString() ?? '删除失败');
    }
  }

}

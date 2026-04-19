import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../models/analysis_history_item.dart';
import '../models/ingredient_analysis.dart';
import '../models/subscription_status.dart';
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
    final session = await _authService.getValidSession();
    final token = session?.accessToken;

    if (token == null || token.isEmpty) {
      throw Exception('当前未登录，请重新登录后再试');
    }

    return {'Authorization': 'Bearer $token'};
  }

  FoodAnalysisResult _buildQuickAnalysisResult(
    Map<String, dynamic> quickResult, {
    String? analysisId,
  }) {
    final compliance = Map<String, dynamic>.from(
      (quickResult['compliance'] as Map?) ?? const {},
    );
    final processing = Map<String, dynamic>.from(
      (quickResult['processing'] as Map?) ?? const {},
    );

    return FoodAnalysisResult(
      foodName: quickResult['foodName']?.toString() ?? '',
      ingredients: [], // 初始为空，稍后轮询填充
      healthScore: (quickResult['healthScore'] as num?)?.toDouble() ?? 0.0,
      compliance: ComplianceAnalysis(
        status: compliance['status']?.toString() ?? '',
        description: compliance['description']?.toString() ?? '',
        issues: const [],
      ),
      processing: ProcessingAnalysis(
        level: processing['level']?.toString() ?? '',
        description: processing['description']?.toString() ?? '',
        score: (processing['score'] as num?)?.toDouble() ?? 1.0,
      ),
      claims: ClaimsAnalysis(
        detectedClaims: const [],
        supportedClaims: const [],
        questionableClaims: const [],
        assessment: '',
      ),
      overallAssessment: quickResult['overallAssessment']?.toString() ?? '',
      recommendations: quickResult['recommendations']?.toString() ?? '',
      detailedStatus: 'pending',
      analysisTime: DateTime.now(),
      analysisId: analysisId,
    );
  }

  Future<FoodAnalysisResult> analyzeImage(
    XFile image, {
    String? productName,
    Map<String, dynamic>? userHealthProfile,
  }) async {
    if (!ApiConfig.isBackendConfigured) {
      throw Exception('BACKEND_API_URL 未配置');
    }

    final request = http.MultipartRequest('POST', _buildUri('/api/analysis'));

    request.headers.addAll(await _authorizedHeaders());

    if (productName != null && productName.trim().isNotEmpty) {
      request.fields['productName'] = productName.trim();
    }
    if (userHealthProfile != null && userHealthProfile.isNotEmpty) {
      request.fields['userHealthProfile'] = jsonEncode(userHealthProfile);
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
      if (response.statusCode == 401) {
        throw UnauthorizedException(
          payload['statusMessage']?.toString() ?? '登录已失效，请重新登录',
        );
      }
      if (response.statusCode == 403) {
        throw ForbiddenException(
          payload['statusMessage']?.toString() ?? '当前账号暂无权限执行该操作',
        );
      }
      throw Exception(payload['statusMessage']?.toString() ?? '分析失败');
    }

    // 处理新的两阶段响应格式
    final quickResultRaw = payload['quick'];
    final quickResult = quickResultRaw is Map
        ? Map<String, dynamic>.from(quickResultRaw)
        : null;
    final analysisId = payload['id']?.toString();
    if (quickResult == null) {
      throw Exception('API 返回数据格式错误');
    }

    // 如果详细结果已返回，直接使用
    final detailedResultRaw = payload['detailed'];
    final detailedResult = detailedResultRaw is Map
        ? Map<String, dynamic>.from(detailedResultRaw)
        : null;

    if (detailedResult != null) {
      detailedResult['analysisId'] = analysisId;
      return FoodAnalysisResult.fromMap(detailedResult);
    }

    // 否则返回快速结果（带有 analysisId 以便后续轮询）
    return _buildQuickAnalysisResult(
      quickResult,
      analysisId: analysisId,
    );
  }

  Future<FoodAnalysisResult> analyzeIngredientsText(
    String ingredientsText, {
    String? productName,
    Map<String, dynamic>? userHealthProfile,
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
        if (productName != null && productName.trim().isNotEmpty)
          'productName': productName.trim(),
        if (userHealthProfile != null && userHealthProfile.isNotEmpty)
          'userHealthProfile': userHealthProfile,
      }),
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        throw UnauthorizedException(
          payload['statusMessage']?.toString() ?? '登录已失效，请重新登录',
        );
      }
      if (response.statusCode == 403) {
        throw ForbiddenException(
          payload['statusMessage']?.toString() ?? '当前账号暂无权限执行该操作',
        );
      }
      throw Exception(payload['statusMessage']?.toString() ?? '分析失败');
    }

    // 处理新的两阶段响应格式
    final quickResultRaw = payload['quick'];
    final quickResult = quickResultRaw is Map
        ? Map<String, dynamic>.from(quickResultRaw)
        : null;
    final analysisId = payload['id']?.toString();
    if (quickResult == null) {
      throw Exception('API 返回数据格式错误');
    }

    // 如果详细结果已返回，直接使用
    final detailedResultRaw = payload['detailed'];
    final detailedResult = detailedResultRaw is Map
        ? Map<String, dynamic>.from(detailedResultRaw)
        : null;

    if (detailedResult != null) {
      detailedResult['analysisId'] = analysisId;
      return FoodAnalysisResult.fromMap(detailedResult);
    }

    // 否则返回快速结果（带有 analysisId 以便后续轮询）
    return _buildQuickAnalysisResult(
      quickResult,
      analysisId: analysisId,
    );
  }

  Future<List<AnalysisHistoryItem>> fetchHistory({int limit = 30}) async {
    if (!ApiConfig.isBackendConfigured) {
      throw Exception('BACKEND_API_URL 未配置');
    }

    final uri = _buildUri('/api/history', {'limit': '$limit'});
    debugPrint('[fetchHistory] GET $uri');

    final response = await http.get(uri, headers: await _authorizedHeaders());

    debugPrint(
      '[fetchHistory] status=${response.statusCode} bodyLength=${response.body.length}',
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('[fetchHistory] error: ${response.body}');
      throw Exception(payload['statusMessage']?.toString() ?? '加载历史失败');
    }

    final items = payload['items'] as List<dynamic>? ?? [];
    debugPrint('[fetchHistory] items count: ${items.length}');
    return items
        .map(
          (item) => AnalysisHistoryItem.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
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

  Future<SubscriptionStatus> getSubscriptionStatus() async {
    if (!ApiConfig.isBackendConfigured) {
      throw Exception('BACKEND_API_URL 未配置');
    }

    final response = await http.get(
      _buildUri('/api/subscription/status'),
      headers: await _authorizedHeaders(),
    );
    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        throw UnauthorizedException(
          payload['statusMessage']?.toString() ?? '登录已失效，请重新登录',
        );
      }
      throw Exception(payload['statusMessage']?.toString() ?? '获取订阅状态失败');
    }

    return SubscriptionStatus.fromMap(payload);
  }

  Future<SubscriptionStatus> syncSubscriptionStatus({
    required bool isPro,
    String source = 'revenuecat',
    String? subscriptionStatus,
    String? expirationDate,
  }) async {
    if (!ApiConfig.isBackendConfigured) {
      throw Exception('BACKEND_API_URL 未配置');
    }

    final response = await http.post(
      _buildUri('/api/subscription/sync'),
      headers: {
        'Content-Type': 'application/json',
        ...await _authorizedHeaders(),
      },
      body: jsonEncode({
        'isPro': isPro,
        'source': source,
        if (subscriptionStatus != null && subscriptionStatus.trim().isNotEmpty)
          'subscriptionStatus': subscriptionStatus.trim(),
        if (expirationDate != null && expirationDate.trim().isNotEmpty)
          'expirationDate': expirationDate.trim(),
      }),
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        throw UnauthorizedException(
          payload['statusMessage']?.toString() ?? '登录已失效，请重新登录',
        );
      }
      throw Exception(payload['statusMessage']?.toString() ?? '同步订阅状态失败');
    }

    return SubscriptionStatus.fromMap(payload);
  }

  // 获取单个分析结果的详情（用于轮询）
  Future<FoodAnalysisResult> getAnalysisResult(String analysisId) async {
    if (!ApiConfig.isBackendConfigured) {
      throw Exception('BACKEND_API_URL 未配置');
    }

    final response = await http.get(
      _buildUri('/api/analysis/$analysisId'),
      headers: await _authorizedHeaders(),
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        throw UnauthorizedException(
          payload['statusMessage']?.toString() ?? '登录已失效，请重新登录',
        );
      }
      if (response.statusCode == 403) {
        throw ForbiddenException(
          payload['statusMessage']?.toString() ?? '当前账号暂无权限执行该操作',
        );
      }
      throw Exception(payload['statusMessage']?.toString() ?? '获取分析结果失败');
    }

    // API 返回 AnalysisHistoryItem 格式
    final payloadResult = payload['result'];
    final result = payloadResult is Map
        ? Map<String, dynamic>.from(payloadResult)
        : Map<String, dynamic>.from(payload);

    result['analysisId'] = result['analysisId'] ?? payload['id'] ?? analysisId;
    return FoodAnalysisResult.fromMap(result);
  }
}

/// 未授权异常 - 用于 401 错误
class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException(this.message);

  @override
  String toString() => message;
}

/// 无权限异常 - 用于 403 错误
class ForbiddenException implements Exception {
  final String message;

  ForbiddenException(this.message);

  @override
  String toString() => message;
}

import 'package:flutter_dotenv/flutter_dotenv.dart';

// API配置 - 敏感信息请勿提交到版本控制
class ApiConfig {
  static String _read(String key) {
    return dotenv.env[key]?.trim() ?? '';
  }

  static String get backendApiUrl => _read('BACKEND_API_URL');

  static String get supabaseUrl => _read('SUPABASE_URL');

  static String get supabaseAnonKey => _read('SUPABASE_ANON_KEY');

  // deeepseek API
  static String get deepseekApiKey => _read('DEEPSEEK_API_KEY');

  // 阿里云OCR API配置
  static String get aliyunAccessKeyId => _read('ALIYUN_ACCESS_KEY_ID');
  
  static String get aliyunAccessKeySecret => _read('ALIYUN_ACCESS_KEY_SECRET');
  
  static const String aliyunOcrEndpoint = 'https://ocr-api.cn-hangzhou.aliyuncs.com';
  static const String aliyunRegionId = 'cn-hangzhou';
  
  static bool get isSupabaseConfigured {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }

  static bool get isBackendConfigured {
    return backendApiUrl.isNotEmpty;
  }

  // 检查配置是否完整
  static bool get isAliyunConfigValid {
    return aliyunAccessKeyId.isNotEmpty && aliyunAccessKeySecret.isNotEmpty;
  }
}

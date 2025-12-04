  import 'package:flutter_dotenv/flutter_dotenv.dart';

// API配置 - 敏感信息请勿提交到版本控制
class ApiConfig {
  // deeepseek API
  static String get deepseekApiKey  => dotenv.get('DEEPSEEK_API_KEY');

  // 阿里云OCR API配置
  static String get aliyunAccessKeyId => dotenv.get('ALIYUN_ACCESS_KEY_ID');
  
  static String get aliyunAccessKeySecret => dotenv.get('ALIYUN_ACCESS_KEY_SECRET');
  
  static const String aliyunOcrEndpoint = 'https://ocr-api.cn-hangzhou.aliyuncs.com';
  static const String aliyunRegionId = 'cn-hangzhou';
  
  // 检查配置是否完整
  static bool get isAliyunConfigValid {
    return aliyunAccessKeyId.isNotEmpty && aliyunAccessKeySecret.isNotEmpty;
  }
}
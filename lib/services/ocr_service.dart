import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import '../config/api_config.dart';

class OCRService {
  // 阿里云OCR API配置 - 从环境变量读取
  static String get _accessKeyId => ApiConfig.aliyunAccessKeyId;
  static String get _accessKeySecret => ApiConfig.aliyunAccessKeySecret;
  static const String _endpoint = ApiConfig.aliyunOcrEndpoint;
  static const String _regionId = ApiConfig.aliyunRegionId;

  static Future<List<String>> extractTextFromImage(dynamic imageFile) async {
    try {
      print('开始OCR识别，图片路径: ${imageFile.toString()}');
      
      // 在Web环境中，阿里云OCR API可能存在跨域问题
      if (kIsWeb) {
        throw Exception('Web环境不支持阿里云OCR API调用');
      }
      
      print('移动端环境，调用阿里云OCR API...');
      // 调用阿里云OCR API（仅在移动端）
      final ocrResult = await _callAliCloudOCR(imageFile);
      
      print('OCR API返回结果: $ocrResult');
      
      if (ocrResult.isEmpty) {
        throw Exception('OCR识别结果为空');
      }
      
      // 解析OCR结果，提取配料信息
      final ingredients = _parseIngredients(ocrResult);
      print('解析出的配料: $ingredients');
      
      if (ingredients.isEmpty) {
        throw Exception('无法从OCR结果中解析出配料信息');
      }
      
      return ingredients;
    } catch (e) {
      print('OCR处理失败: $e');
      // 直接抛出异常，终止流程
      throw Exception('OCR识别失败: $e');
    }
  }

  static Future<String> _callAliCloudOCR(dynamic imageFile) async {
    try {
      print('准备调用阿里云OCR API...');
      
      // 在Web环境中跳过真实API调用
      if (kIsWeb) {
        throw Exception('Web环境不支持阿里云OCR API调用');
      }
      
      // 检查阿里云配置是否有效
      if (!ApiConfig.isAliyunConfigValid) {
        print('阿里云配置不完整，使用模拟数据');
        throw Exception('阿里云OCR配置不完整');
      }
      
      // 读取图片文件并转换为base64
      print('读取图片文件...');
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      print('图片转换为base64完成，长度: ${base64Image.length}');
      
      // 构建请求参数
      final timestamp = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc());
      final nonce = DateTime.now().millisecondsSinceEpoch.toString();
      
      print('构建请求参数...');
      print('Timestamp: $timestamp');
      print('Nonce: $nonce');
      
      // 阿里云OCR API的正确参数格式（参考JavaScript版本）
      final Map<String, String> params = {
        'Action': 'RecognizeGeneral',
        'Version': '2021-07-07',
        'RegionId': _regionId,
        'Format': 'JSON',
        'Timestamp': timestamp,
        'SignatureMethod': 'HMAC-SHA1',
        'SignatureVersion': '1.0',
        'SignatureNonce': nonce,
        'AccessKeyId': _accessKeyId,
      };
      
      // 生成签名（使用标准encodeURIComponent，参考JavaScript版本）
      print('生成API签名...');
      final signature = _generateSignature(params, 'POST');
      params['Signature'] = signature;
      print('签名生成完成: ${signature.substring(0, 10)}...');
      
      // 构建请求URL（使用标准encodeURIComponent，参考JavaScript版本）
      final queryString = params.entries
          .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}')
          .join('&');
      final requestUrl = '$_endpoint/?$queryString';
      
      print('发送HTTP请求到: $requestUrl');
      
      // 发送请求，将图像数据作为二进制数据发送（参考JavaScript版本）
      // 将Base64解码为二进制数据
      final binaryData = base64Decode(base64Image);
      
      final response = await http.post(
        Uri.parse(requestUrl),
        headers: {
          'Content-Type': 'application/octet-stream', // 使用二进制流格式
        },
        body: binaryData, // 直接发送二进制数据
      );
      
      print('HTTP响应状态码: ${response.statusCode}');
      print('HTTP响应内容: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('解析响应JSON: $responseData');
        
        // 解析阿里云OCR响应 - 修复类型转换问题
        if (responseData['Data'] != null) {
          // 处理Data字段可能是字符串的情况
          dynamic dataField = responseData['Data'];
          String content;
          
          if (dataField is String) {
            // Data字段是JSON字符串，需要再次解析
            final nestedData = json.decode(dataField);
            content = nestedData['content'] ?? '';
          } else if (dataField is Map) {
            // Data字段是Map对象
            content = dataField['content'] ?? '';
          } else {
            content = '';
          }
          
          if (content.isNotEmpty) {
            print('OCR识别成功，内容: $content');
            return content;
          } else {
            print('响应中没有找到content字段');
          }
        } else {
          print('响应中没有Data字段');
          print('完整响应结构: $responseData');
        }
      }
      
      throw Exception('OCR API调用失败: ${response.statusCode}, 响应: ${response.body}');
    } catch (e) {
      print('OCR API调用异常: $e');
      throw Exception('OCR处理失败: $e');
    }
  }

  static String _generateSignature(Map<String, String> params, String method) {
    // 移除Signature参数
    final sortedParams = Map<String, String>.from(params);
    sortedParams.remove('Signature');
    
    // 按字典序排序参数
    final sortedKeys = sortedParams.keys.toList()..sort();
    
    // 构建查询字符串（使用标准encodeURIComponent，参考JavaScript版本）
    final queryString = sortedKeys
        .map((key) => '${Uri.encodeComponent(key)}=${Uri.encodeComponent(sortedParams[key]!)}')
        .join('&');
    
    // 构建待签名字符串（使用标准encodeURIComponent，参考JavaScript版本）
    final stringToSign = '$method&${Uri.encodeComponent('/')}&${Uri.encodeComponent(queryString)}';
    
    // 使用HMAC-SHA1生成签名
    final key = utf8.encode('$_accessKeySecret&');
    final bytes = utf8.encode(stringToSign);
    final hmacSha1 = Hmac(sha1, key);
    final digest = hmacSha1.convert(bytes);
    
    return base64Encode(digest.bytes);
  }

  static List<String> _parseIngredients(String text) {
    print('开始解析OCR文本: $text');
    
    // 简化的文本解析逻辑
    final lines = text.split('\n');
    final ingredients = <String>[];
    
    // 扩展的配料关键词列表
    final ingredientKeywords = [
      // 基础原料
      '小麦粉', '面粉', '白砂糖', '糖', '植物油', '食用油', '油', '食盐', '盐', '水',
      // 蛋白质
      '奶粉', '牛奶', '鸡蛋', '蛋', '牛乳', '乳', '大豆', '豆', '肉', '猪肉', '牛肉', '鸡肉',
      // 淀粉类
      '淀粉', '玉米淀粉', '马铃薯', '土豆', '米', '大米',
      // 调味料
      '谷氨酸钠', '味精', '香精', '香料', '酵母', '发酵粉', '泡打粉',
      // 添加剂
      '添加剂', '防腐剂', '色素', '甜味剂', '增稠剂', '乳化剂', '抗氧化剂',
      // 其他常见配料
      '可可', '巧克力', '奶油', '黄油', '芝麻', '花生', '核桃', '杏仁',
      '柠檬酸', '维生素', '钙', '铁', '锌'
    ];
    
    print('分行处理文本，共${lines.length}行');
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;
      
      print('处理第${i+1}行: $line');
      
      // 移除数字、百分号、括号等
      final cleanedLine = line.replaceAll(RegExp(r'[0-9%.()（）]'), '').trim();
      print('清理后: $cleanedLine');
      
      // 检查是否包含配料关键词
      bool found = false;
      for (String keyword in ingredientKeywords) {
        if (cleanedLine.contains(keyword)) {
          // 避免重复添加
          if (!ingredients.contains(cleanedLine)) {
            ingredients.add(cleanedLine);
            print('找到配料: $cleanedLine (匹配关键词: $keyword)');
          }
          found = true;
          break;
        }
      }
      
      // 如果没有匹配关键词，但行内容看起来像配料（长度合适且包含中文）
      if (!found && cleanedLine.length > 1 && cleanedLine.length < 20 && 
          RegExp(r'[\u4e00-\u9fa5]').hasMatch(cleanedLine)) {
        // 排除一些明显不是配料的词
        final excludeWords = ['营养成分', '保质期', '生产日期', '厂家', '地址', '电话', '网址', '条码'];
        bool shouldExclude = false;
        for (String exclude in excludeWords) {
          if (cleanedLine.contains(exclude)) {
            shouldExclude = true;
            break;
          }
        }
        
        if (!shouldExclude && !ingredients.contains(cleanedLine)) {
          ingredients.add(cleanedLine);
          print('添加可能的配料: $cleanedLine');
        }
      }
    }
    
    print('最终解析出的配料列表: $ingredients');
    
    return ingredients;
  }
}
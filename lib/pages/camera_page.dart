import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../services/ocr_service.dart';
import '../services/ai_service.dart';
import '../widgets/permission_guide_dialog.dart';
import 'analysis_result_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  // 移除标准选择相关变量

  Future<void> _pickImage(ImageSource source) async {
    // 在Web和桌面应用中，跳过权限检查
    if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      // Web和桌面应用通常不需要权限检查
      await _pickImageWithoutPermission(source);
    } else {
      // 移动设备需要请求权限
      await _pickImageWithPermission(source);
    }
  }

  Future<void> _pickImageWithPermission(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 直接尝试使用image_picker，让系统自动处理权限
      print('直接尝试选择图片，让系统处理权限...');
      
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        print('图片选择成功: ${image.path}');
        await _processImage(image.path);
      } else {
        print('用户取消了图片选择或权限被拒绝');
        // 如果用户取消或权限被拒绝，显示指导对话框
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PermissionGuideDialog(
            permissionType: source == ImageSource.camera ? 'camera' : 'photos',
          ),
        );
      }
    } catch (e) {
      print('图片选择过程出错: $e');
      // 如果出现权限错误，显示指导对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PermissionGuideDialog(
          permissionType: source == ImageSource.camera ? 'camera' : 'photos',
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImageWithoutPermission(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      
      if (image != null) {
        await _processImage(image.path);
      }
    } catch (e) {
      _showErrorDialog('图片选择失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  

  Future<void> _processImage(String imagePath) async {
    try {
      // 使用OCR识别配料文字
      dynamic imageFile;
      if (kIsWeb) {
        // Web环境下直接传递路径
        imageFile = imagePath;
      } else {
        // 移动端使用File对象
        imageFile = File(imagePath);
      }
      
      final ingredients = await OCRService.extractTextFromImage(imageFile);
      
      // 根据配料生成食品名称
      final foodName = _generateFoodName(ingredients);
      
      // 显示分析进度
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('正在分析$foodName...')),
        );
      }
      
      // 使用AI分析配料
      final result = await AIService.analyzeIngredients(ingredients, foodName);
      
      // 跳转到结果页面
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisResultPage(analysisResult: result),
        ),
      );
    } catch (e) {
      _showErrorDialog('分析失败: $e');
    }
  }

  String _generateFoodName(List<String> ingredients) {
    // 根据配料生成食品名称
    if (ingredients.isEmpty) {
      return '食品';
    }
    
    // 根据主要配料推断食品类型
    final firstIngredient = ingredients.first.toLowerCase();
    
    if (firstIngredient.contains('小麦粉') || firstIngredient.contains('面粉')) {
      return '面食制品';
    } else if (firstIngredient.contains('牛乳') || firstIngredient.contains('牛奶')) {
      return '乳制品';
    } else if (firstIngredient.contains('可可') || firstIngredient.contains('巧克力')) {
      return '巧克力制品';
    } else if (firstIngredient.contains('猪肉') || firstIngredient.contains('牛肉') || firstIngredient.contains('鸡肉')) {
      return '肉制品';
    } else if (firstIngredient.contains('马铃薯') || firstIngredient.contains('土豆')) {
      return '薯类零食';
    } else if (firstIngredient.contains('水') && ingredients.length <= 3) {
      return '饮料';
    } else if (firstIngredient.contains('糖') || firstIngredient.contains('甜味')) {
      return '甜味食品';
    } else {
      return '加工食品';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 应用图标和标题
            const Icon(
              Icons.search,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              '配料侦探',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '拍照分析食品配料，了解营养价值和健康情况',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            
            // 分析维度说明
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '分析维度',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildAnalysisDimension(Icons.verified_user, '合规性', '检查配料是否符合食品安全法规'),
                  const SizedBox(height: 8),
                  _buildAnalysisDimension(Icons.settings, '加工度', '评估食品的加工程度和天然性'),
                  const SizedBox(height: 8),
                  _buildAnalysisDimension(Icons.campaign, '特定宣称', '识别和验证产品的健康宣称'),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // 拍照按钮
            if (_isLoading)
              LoadingAnimationWidget.threeRotatingDots(
                color: Colors.green,
                size: 50,
              )
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('拍照分析'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('从相册选择'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisDimension(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';
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
  String _selectedStandard = '中国标准';
  final List<String> _standards = ['中国标准', '美国标准', '欧盟标准', '日本标准'];

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

  void _showPermissionDeniedDialog(ImageSource source) {
    String permissionName;
    String action;
    String detailMessage;
    List<String> steps;
    
    if (source == ImageSource.camera) {
      permissionName = '相机';
      action = '拍照';
      detailMessage = '配料侦探需要相机权限来拍摄食品配料照片进行营养分析。';
      if (Platform.isIOS) {
        steps = [
          '1. 点击"去设置"按钮',
          '2. 找到"配料侦探"应用',
          '3. 点击"相机"',
          '4. 选择"允许"',
          '5. 返回应用重试'
        ];
      } else {
        steps = [
          '1. 点击"去设置"按钮',
          '2. 找到"应用权限"或"权限管理"',
          '3. 找到"配料侦探"应用',
          '4. 开启"相机"权限',
          '5. 返回应用重试'
        ];
      }
    } else {
      permissionName = '相册';
      action = '选择照片';
      detailMessage = '配料侦探需要相册权限来选择食品配料照片进行营养分析。';
      if (Platform.isIOS) {
        steps = [
          '1. 点击"去设置"按钮',
          '2. 找到"配料侦探"应用',
          '3. 点击"照片"',
          '4. 选择"所有照片"或"选中的照片"',
          '5. 返回应用重试'
        ];
      } else {
        steps = [
          '1. 点击"去设置"按钮',
          '2. 找到"应用权限"或"权限管理"',
          '3. 找到"配料侦探"应用',
          '4. 开启"存储"或"照片"权限',
          '5. 返回应用重试'
        ];
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              source == ImageSource.camera ? Icons.camera_alt : Icons.photo_library,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Text('需要开启$permissionName权限'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '权限已被永久拒绝，需要手动开启',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(detailMessage),
              const SizedBox(height: 16),
              Text(
                '请按以下步骤开启权限：',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...steps.map((step) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  step,
                  style: const TextStyle(fontSize: 14),
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('稍后设置'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.settings),
            label: const Text('去设置'),
          ),
        ],
      ),
    );
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
      
      // 获取食品名称
      final foodName = OCRService.getMockFoodName(ingredients);
      
      // 显示分析进度
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('正在分析$foodName...')),
        );
      }
      
      // 使用AI分析配料
      final result = await AIService.analyzeIngredients(ingredients, _selectedStandard);
      
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
            
            // 标准选择
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '选择分析标准:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedStandard,
                    isExpanded: true,
                    items: _standards.map((standard) {
                      return DropdownMenuItem<String>(
                        value: standard,
                        child: Text(standard),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStandard = value!;
                      });
                    },
                  ),
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
}
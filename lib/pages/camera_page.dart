import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../services/backend_api_service.dart';
import '../widgets/permission_guide_dialog.dart';
import 'analysis_result_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final BackendApiService _backendApiService = BackendApiService();
  bool _isLoading = false;
  String? _lastFailedImageName;

  Future<void> _pickImage(ImageSource source) async {
    // 在Web和桌面应用中，跳过权限检查
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
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
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _processImage(image);
      } else {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PermissionGuideDialog(
            permissionType: source == ImageSource.camera ? 'camera' : 'photos',
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
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
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      
      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showErrorDialog('图片选择失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processImage(XFile image) async {
    try {
      final result = await _backendApiService.analyzeImage(image);

      // 显示分析进度
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('正在分析${result.foodName}...')),
        );
      }

      // 跳转到结果页面
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisResultPage(analysisResult: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _lastFailedImageName = image.name;

      if (e.toString().contains('No ingredient text could be extracted from the image.')) {
        await _showManualInputDialog(
          initialMessage: '这张图片没有成功识别出配料文字。你可以重新拍清晰一点的配料表，或直接手动输入配料继续分析。',
        );
        return;
      }

      _showErrorDialog('分析失败: $e');
    }
  }

  Future<void> _showManualInputDialog({required String initialMessage}) async {
    final ingredientsController = TextEditingController();
    final productNameController = TextEditingController();
    bool isSubmitting = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submitManualAnalysis() async {
              final ingredientsText = ingredientsController.text.trim();

              if (ingredientsText.isEmpty) {
                setDialogState(() {
                  dialogError = '请输入至少一项配料';
                });
                return;
              }

              setDialogState(() {
                isSubmitting = true;
                dialogError = null;
              });

              try {
                final result = await _backendApiService.analyzeIngredientsText(
                  ingredientsText,
                  productName: productNameController.text.trim(),
                );

                if (!dialogContext.mounted || !mounted) return;
                Navigator.of(dialogContext).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnalysisResultPage(analysisResult: result),
                  ),
                );
              } catch (error) {
                setDialogState(() {
                  dialogError = error.toString();
                  isSubmitting = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('手动输入配料'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      initialMessage,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    if (_lastFailedImageName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '图片: $_lastFailedImageName',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: productNameController,
                      decoration: const InputDecoration(
                        labelText: '产品名（可选）',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ingredientsController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: '配料内容',
                        hintText: '例如：小麦粉，白砂糖，植物油，食盐，香精',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : submitManualAnalysis,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('继续分析'),
                ),
              ],
            );
          },
        );
      },
    );

    ingredientsController.dispose();
    productNameController.dispose();
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

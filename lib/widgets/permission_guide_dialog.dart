import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PermissionGuideDialog extends StatelessWidget {
  final String permissionType; // 'camera' or 'photos'
  
  const PermissionGuideDialog({
    super.key,
    required this.permissionType,
  });

  @override
  Widget build(BuildContext context) {
    final isCamera = permissionType == 'camera';
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isCamera ? Icons.camera_alt : Icons.photo_library,
            color: Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '需要${isCamera ? "相机" : "相册"}权限',
              style: const TextStyle(fontSize: 18),
            ),
          ),
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
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '权限被拒绝，需要手动开启',
                      style: TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '配料侦探需要${isCamera ? "相机" : "相册"}权限来${isCamera ? "拍摄" : "选择"}食品配料照片进行营养分析。',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              '请按以下步骤手动开启权限：',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildStepCard('1', '完全关闭配料侦探应用'),
            _buildStepCard('2', '打开iPhone【设置】→【隐私与安全性】'),
            _buildStepCard('3', isCamera ? '点击【相机】' : '点击【照片】'),
            _buildStepCard('4', isCamera ? '找到并开启【配料侦探】' : '找到【配料侦探】点击进入'),
            _buildStepCard('5', isCamera ? '' : '选择【所有照片】'),
            _buildStepCard('6', '返回配料侦探应用重新尝试'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '重要提示',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 必须先完全关闭应用，再去设置权限\n• 权限设置路径：设置 → 隐私与安全性 → ${isCamera ? "相机" : "照片"}\n• 如果没有看到配料侦探，说明应用还没有请求过权限',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('我知道了'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            // 尝试打开设置（可能不会直接跳转到应用设置）
            SystemNavigator.pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.settings),
          label: const Text('关闭应用'),
        ),
      ],
    );
  }

  Widget _buildStepCard(String stepNumber, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
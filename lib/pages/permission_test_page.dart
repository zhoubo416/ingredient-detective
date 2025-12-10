import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionTestPage extends StatefulWidget {
  const PermissionTestPage({super.key});

  @override
  State<PermissionTestPage> createState() => _PermissionTestPageState();
}

class _PermissionTestPageState extends State<PermissionTestPage> {
  String _cameraStatus = '未检查';
  String _photosStatus = '未检查';
  String _storageStatus = '未检查';

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final photosStatus = await Permission.photos.status;
    final storageStatus = await Permission.storage.status;

    setState(() {
      _cameraStatus = cameraStatus.toString();
      _photosStatus = photosStatus.toString();
      _storageStatus = storageStatus.toString();
    });
  }

  Future<void> _requestPermission(Permission permission, String name) async {
    final status = await permission.request();
    print('$name 权限请求结果: $status');
    await _checkAllPermissions();
  }

  Widget _buildPermissionTile(String title, String status, Permission permission) {
    Color statusColor;
    IconData statusIcon;
    
    if (status.contains('granted')) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status.contains('denied')) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (status.contains('permanentlyDenied')) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.help;
    }

    return Card(
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(title),
        subtitle: Text(status),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _requestPermission(permission, title),
              icon: const Icon(Icons.refresh),
              tooltip: '请求权限',
            ),
            IconButton(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings),
              tooltip: '打开设置',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('权限测试'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _checkAllPermissions,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新状态',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '权限状态检查',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPermissionTile('相机权限', _cameraStatus, Permission.camera),
            _buildPermissionTile('相册权限', _photosStatus, Permission.photos),
            _buildPermissionTile('存储权限', _storageStatus, Permission.storage),
            const SizedBox(height: 20),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          '权限说明',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• granted: 权限已授予'),
                    const Text('• denied: 权限被拒绝'),
                    const Text('• permanentlyDenied: 权限被永久拒绝'),
                    const Text('• limited: 权限受限（iOS）'),
                    const SizedBox(height: 8),
                    const Text(
                      '如果权限被永久拒绝，需要手动到设置中开启权限。',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
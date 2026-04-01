import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  bool _isInitializing = true;
  bool _isCapturing = false;
  int _selectedCameraIndex = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = '未检测到可用摄像头';
          _isInitializing = false;
        });
        return;
      }

      _cameras = cameras;
      await _setupController(_selectedCameraIndex);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '相机初始化失败: $error';
        _isInitializing = false;
      });
    }
  }

  Future<void> _setupController(int index) async {
    final previous = _controller;
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await previous?.dispose();
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _selectedCameraIndex = index;
        _isInitializing = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '相机初始化失败: $error';
        _isInitializing = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isInitializing || _isCapturing) return;
    setState(() {
      _isInitializing = true;
    });
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupController(nextIndex);
  }

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing ||
        _isInitializing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('拍照失败: $error')));
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Widget _buildGuideCorner({
    required Alignment alignment,
    required BorderRadius borderRadius,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: Colors.white, width: 3),
        ),
      ),
    );
  }

  Widget _buildViewfinderFrame() {
    return Center(
      child: Container(
        width: 300,
        height: 420,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.28),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            _buildGuideCorner(
              alignment: Alignment.topLeft,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
              ),
            ),
            _buildGuideCorner(
              alignment: Alignment.topRight,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
              ),
            ),
            _buildGuideCorner(
              alignment: Alignment.bottomLeft,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
              ),
            ),
            _buildGuideCorner(
              alignment: Alignment.bottomRight,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(18),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '请将整块配料表放入框内',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('拍照分析'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 48,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: controller == null
                      ? const SizedBox.shrink()
                      : FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: controller.value.previewSize?.height ?? 1,
                            height: controller.value.previewSize?.width ?? 1,
                            child: CameraPreview(controller),
                          ),
                        ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  top: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '将配料表尽量放在取景框中央，保持文字清晰完整',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(child: _buildViewfinderFrame()),
                ),
                Positioned(
                  left: 28,
                  right: 28,
                  bottom: 132,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '避免反光、模糊和倾斜，尽量让配料名称完整可见',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    minimum: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    child: Row(
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: _takePhoto,
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Center(
                              child: Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: _isCapturing
                                      ? Colors.white54
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              onPressed: _cameras.length > 1
                                  ? _switchCamera
                                  : null,
                              icon: const Icon(
                                Icons.cameraswitch_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              tooltip: '切换摄像头',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

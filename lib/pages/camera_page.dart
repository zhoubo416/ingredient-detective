import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../services/backend_api_service.dart';
import '../services/subscription_manager.dart';
import '../services/user_health_profile_service.dart';
import '../widgets/permission_guide_dialog.dart';
import 'analysis_result_page.dart';
import 'camera_capture_page.dart';
import 'subscription_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final BackendApiService _backendApiService = BackendApiService();
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  final UserHealthProfileService _userHealthProfileService =
      UserHealthProfileService();

  bool _isLoading = false;
  String? _lastFailedImageName;

  @override
  void initState() {
    super.initState();
    _subscriptionManager.addListener(_handleSubscriptionChanged);
    _warmUpSubscriptionStatus();
  }

  @override
  void dispose() {
    _subscriptionManager.removeListener(_handleSubscriptionChanged);
    super.dispose();
  }

  void _handleSubscriptionChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _warmUpSubscriptionStatus() async {
    try {
      await _subscriptionManager.refreshSubscriptionStatus(
        syncWithBackend: true,
      );
    } catch (_) {
      // 忽略预热失败，实际使用时再提示。
    }
  }

  Future<bool> _ensureProAccess() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _subscriptionManager.refreshSubscriptionStatus(
        syncWithBackend: true,
      );

      if (_subscriptionManager.isProUser) {
        return true;
      }
    } catch (error) {
      if (!mounted) return false;
      _showErrorDialog('检查 Pro 会员状态失败: $error');
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    if (!mounted) return false;
    await _showProRequiredDialog();
    return false;
  }

  Future<void> _showProRequiredDialog({String? message}) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pro 会员专享'),
        content: Text(
          message ??
              '配料分析功能仅对 Pro 会员开放，包括拍照分析、相册上传和手动输入配料。你仍然可以继续使用历史记录、个人资料等其他功能。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('稍后再说'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionPage(),
                ),
              );
            },
            child: const Text('升级 Pro'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!await _ensureProAccess()) {
      return;
    }

    final supportsPreviewCamera =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (source == ImageSource.camera && supportsPreviewCamera) {
      await _captureFromCameraPreview();
      return;
    }

    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      await _pickImageWithoutPermission(source);
    } else {
      await _pickImageWithPermission(source);
    }
  }

  Future<void> _captureFromCameraPreview() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final image = await Navigator.of(context).push<XFile>(
        MaterialPageRoute(builder: (context) => const CameraCapturePage()),
      );

      if (image != null) {
        await _processImage(image);
      }
    } catch (error) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const PermissionGuideDialog(permissionType: 'camera'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    } catch (_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PermissionGuideDialog(
          permissionType: source == ImageSource.camera ? 'camera' : 'photos',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processImage(XFile image) async {
    try {
      final healthProfile = await _userHealthProfileService.loadProfile();
      final result = await _backendApiService.analyzeImage(
        image,
        userHealthProfile: healthProfile.isEmpty ? null : healthProfile.toMap(),
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('正在分析${result.foodName}...')));
      }

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

      if (e.toString().contains(
        'No ingredient text could be extracted from the image.',
      )) {
        await _showManualInputDialog(
          initialMessage: '这张图片没有成功识别出配料文字。你可以重新拍清晰一点的配料表，或直接手动输入配料继续分析。',
        );
        return;
      }

      if (e is ForbiddenException) {
        await _showProRequiredDialog(message: e.message);
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
                final healthProfile = await _userHealthProfileService
                    .loadProfile();
                final result = await _backendApiService.analyzeIngredientsText(
                  ingredientsText,
                  productName: productNameController.text.trim(),
                  userHealthProfile: healthProfile.isEmpty
                      ? null
                      : healthProfile.toMap(),
                );

                if (!dialogContext.mounted || !mounted) return;
                Navigator.of(dialogContext).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AnalysisResultPage(analysisResult: result),
                  ),
                );
              } catch (error) {
                if (error is ForbiddenException) {
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  await _showProRequiredDialog(message: error.message);
                  return;
                }

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
                child: SingleChildScrollView(
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
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
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
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
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

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool filled = true,
    String? badge,
  }) {
    final child = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: filled
                ? Colors.white.withValues(alpha: 0.18)
                : const Color(0xFFDFF1E0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: filled ? Colors.white : const Color(0xFF2F7D32),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: filled ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: filled
                            ? Colors.white.withValues(alpha: 0.18)
                            : const Color(0xFFEAF6EC),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: filled
                              ? Colors.white
                              : const Color(0xFF2F7D32),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: filled ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: filled ? Colors.white : const Color(0xFF6B7280),
        ),
      ],
    );

    if (filled) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A9A54), Color(0xFF66AF6D)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x143A8441),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDEE9E0)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDEE9E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisDimension({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDEE9E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              height: 1.55,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.16),
        child: Center(
          child: Container(
            width: 164,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1217301A),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingAnimationWidget.threeRotatingDots(
                  color: const Color(0xFF2F7D32),
                  size: 42,
                ),
                const SizedBox(height: 12),
                const Text(
                  '正在准备分析',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '你会得到什么',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.health_and_safety_outlined,
          title: '健康评分与总体判断',
          subtitle: '先看这款食品值不值得继续了解，再决定买不买。',
          color: const Color(0xFF2F7D32),
        ),
        const SizedBox(height: 10),
        _buildFeatureCard(
          icon: Icons.psychology_alt_outlined,
          title: '逐项配料作用分析',
          subtitle: '不是只把名字识别出来，而是解释每个配料的实际意义。',
          color: const Color(0xFF0F766E),
        ),
        const SizedBox(height: 10),
        _buildFeatureCard(
          icon: Icons.person_search_outlined,
          title: '结合健康信息的提醒',
          subtitle: '对控糖、减脂或慢病管理用户，提示会更有针对性。',
          color: const Color(0xFF2563EB),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    final isProUser = _subscriptionManager.isProUser;
    final statusText =
        _subscriptionManager.isLoading && !_subscriptionManager.isInitialized
        ? '正在检查 Pro 权限'
        : isProUser
        ? 'Pro 已开通，拍照和文本分析已解锁'
        : '当前账号未开通 Pro，分析入口已锁定';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDEE9E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A17301A),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isProUser
                  ? const Color(0xFFEAF8F1)
                  : const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isProUser
                    ? const Color(0xFFD6E5D8)
                    : const Color(0xFFF3D7A6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isProUser
                      ? Icons.verified_rounded
                      : Icons.lock_outline_rounded,
                  color: isProUser
                      ? const Color(0xFF2F7D32)
                      : const Color(0xFFB7791F),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isProUser
                          ? const Color(0xFF1F5A28)
                          : const Color(0xFF8A5A16),
                    ),
                  ),
                ),
                if (!isProUser)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionPage(),
                        ),
                      );
                    },
                    child: const Text('升级'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.camera_alt_rounded,
            title: '拍照分析',
            subtitle: '打开拍照预览页，直接对准配料表后拍摄',
            onTap: () => _pickImage(ImageSource.camera),
            filled: false,
            badge: isProUser ? '推荐' : 'Pro',
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.photo_library_outlined,
            title: '从相册选择',
            subtitle: '上传已有包装图片，继续完成识别和分析',
            onTap: () => _pickImage(ImageSource.gallery),
            filled: false,
            badge: isProUser ? null : 'Pro',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              if (!await _ensureProAccess()) {
                return;
              }
              await _showManualInputDialog(
                initialMessage: '你可以直接手动输入商品名和配料文本，适合没有清晰图片时继续分析。',
              );
            },
            icon: const Icon(Icons.edit_note_rounded),
            label: Text(isProUser ? '手动输入配料' : '手动输入配料 · Pro'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2F7D32),
              side: const BorderSide(color: Color(0xFFD6E5D8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionSection({required int crossAxisCount}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD6E6D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '分析维度',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 1 ? 2.4 : 1.55,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildAnalysisDimension(
                icon: Icons.verified_user_outlined,
                title: '合规性',
                description: '检查配料和标签表达是否清晰，识别明显风险点。',
                color: const Color(0xFF2563EB),
              ),
              _buildAnalysisDimension(
                icon: Icons.factory_outlined,
                title: '加工度',
                description: '评估成分复杂度和加工程度，帮助判断天然性。',
                color: const Color(0xFF7C3AED),
              ),
              _buildAnalysisDimension(
                icon: Icons.tips_and_updates_outlined,
                title: '饮食建议',
                description: '结合整体结果给出可执行的日常食用建议。',
                color: const Color(0xFFD97706),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1080;
                final isMedium = constraints.maxWidth >= 760;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: Column(
                                    children: [_buildFeaturesSection()],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _buildActionsSection(),
                                      const SizedBox(height: 18),
                                      _buildDimensionSection(crossAxisCount: 1),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _buildActionsSection(),
                            const SizedBox(height: 20),
                            _buildFeaturesSection(),
                            const SizedBox(height: 20),
                            _buildDimensionSection(
                              crossAxisCount: isMedium ? 2 : 1,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }
}

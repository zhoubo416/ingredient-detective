import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/auth_feedback.dart';
import '../services/auth_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isSignIn = true;
  bool _isSubmitting = false;
  String? _message;

  Future<void> _showEmailActionDialog({
    required String title,
    required String actionLabel,
    required Future<void> Function(String email) onConfirm,
  }) async {
    final controller = TextEditingController(text: _emailController.text.trim());
    bool isSubmitting = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit() async {
              final email = controller.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                setState(() {
                  dialogError = '请输入有效邮箱';
                });
                return;
              }

              setState(() {
                isSubmitting = true;
                dialogError = null;
              });

              try {
                await onConfirm(email);
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
              } catch (error) {
                setState(() {
                  dialogError = AuthFeedback.fromError(error);
                  isSubmitting = false;
                });
              }
            }

            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '邮箱',
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
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : submit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(actionLabel),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> _handlePasswordReset() async {
    await _showEmailActionDialog(
      title: '发送重置密码邮件',
      actionLabel: '发送邮件',
      onConfirm: (email) async {
        await _authService.resetPasswordForEmail(email: email);
        if (!mounted) return;
        setState(() {
          _message = AuthFeedback.resetPasswordSuccess();
        });
      },
    );
  }

  Future<void> _handleResendConfirmation() async {
    await _showEmailActionDialog(
      title: '重发确认邮件',
      actionLabel: '重新发送',
      onConfirm: (email) async {
        await _authService.resendSignupConfirmation(email: email);
        if (!mounted) return;
        setState(() {
          _message = AuthFeedback.resendConfirmationSuccess();
        });
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      if (_isSignIn) {
        await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        final response = await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        setState(() {
          _message = AuthFeedback.signUpSuccess(
            hasSession: response.session != null,
          );
        });

        if (response.session != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _message = AuthFeedback.fromError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = ApiConfig.isSupabaseConfigured && ApiConfig.isBackendConfigured;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F2),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '配料侦探',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignIn ? '登录后才能使用识别与分析功能' : '创建账号后开始使用',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignIn
                            ? '如果你刚注册过但登录失败，先检查邮箱是否已经完成确认。'
                            : '部分项目会要求先点确认邮件中的链接；短时间频繁注册也可能触发发送限流。',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      if (!isConfigured) ...[
                        const SizedBox(height: 16),
                        const Text(
                          '当前缺少移动端 Supabase 或后端地址配置，请补充 assets/.env 后再试。',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () {
                                setState(() {
                                  _isSignIn = true;
                                  _message = null;
                                });
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: _isSignIn ? Colors.green[100] : Colors.grey[100],
                              ),
                              child: const Text('登录'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () {
                                setState(() {
                                  _isSignIn = false;
                                  _message = null;
                                });
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: !_isSignIn ? Colors.green[100] : Colors.grey[100],
                              ),
                              child: const Text('注册'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: '邮箱',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '请输入邮箱';
                                }
                                if (!value.contains('@')) {
                                  return '请输入有效邮箱';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: '密码',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '请输入密码';
                                }
                                if (value.length < 6) {
                                  return '密码至少需要 6 位';
                                }
                                return null;
                              },
                            ),
                            if (_message != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _message!,
                                style: TextStyle(
                                  color: _message!.contains('成功') ? Colors.green[700] : Colors.red[700],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: !isConfigured || _isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(_isSignIn ? '登录并进入应用' : '创建账号'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.end,
                                children: [
                                if (_isSignIn)
                                  TextButton(
                                    onPressed: _isSubmitting ? null : _handlePasswordReset,
                                    child: const Text('忘记密码'),
                                  ),
                                TextButton(
                                  onPressed: _isSubmitting ? null : _handleResendConfirmation,
                                  child: const Text('重发确认邮件'),
                                ),
                              ],
                            ),
                          ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

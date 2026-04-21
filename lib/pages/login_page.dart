import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/auth_feedback.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

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

  bool _isSignUp = false;
  bool _isSubmitting = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      final success = await _authService.signInWithGoogle();
      if (!mounted) return;

      if (success && _authService.isSignedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        setState(() {
          _message = 'Google 登录未成功，请重试';
        });
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

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      final success = await _authService.signInWithApple();
      if (!mounted) return;

      if (success && _authService.isSignedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        setState(() {
          _message = 'Apple 登录未成功，请重试';
        });
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      if (!_isSignUp) {
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 420 ? 420.0 : constraints.maxWidth;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Center(
                child: SizedBox(
                  width: maxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu, size: 32, color: Colors.green[800]),
                          const SizedBox(width: 12),
                          Text(
                            '配料侦探',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isSignUp ? '创建账号后开始使用' : '登录后才能使用识别与分析功能',
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      _SocialButton(
                        icon: SizedBox(
                          width: 20,
                          height: 20,
                          child: CustomPaint(painter: _GoogleLogoPainter()),
                        ),
                        label: '使用 Google 账号登录',
                        onPressed: !isConfigured || _isSubmitting ? null : _handleGoogleSignIn,
                      ),
                      const SizedBox(height: 12),
                      _SocialButton(
                        icon: const Icon(Icons.apple, size: 20),
                        label: '使用 Apple 账号登录',
                        onPressed: !isConfigured || _isSubmitting ? null : _handleAppleSignIn,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('或使用邮箱登录', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: '邮箱',
                                hintText: 'name@example.com',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white,
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
                              decoration: InputDecoration(
                                labelText: '密码',
                                hintText: '至少 6 位',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.white,
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
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _message!.contains('成功') ? Colors.green[50] : Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _message!.contains('成功') ? Colors.green[200]! : Colors.red[200]!,
                                  ),
                                ),
                                child: Text(
                                  _message!,
                                  style: TextStyle(
                                    color: _message!.contains('成功') ? Colors.green[700] : Colors.red[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: !isConfigured || _isSubmitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: _isSignUp ? Colors.green[600] : Colors.green[700],
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      _isSignUp ? '创建账号' : '登录并进入应用',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: _isSubmitting ? null : () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                    _message = null;
                                  });
                                },
                                child: Text(
                                  _isSignUp ? '已有账号？去登录' : '没有账号？去注册',
                                  style: TextStyle(color: Colors.green[700]),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isSignUp ? '注册即表示你已阅读并同意' : '继续登录即表示你已阅读并同意',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const TermsOfServicePage()),
                                    );
                                  },
                                  child: const Text('《用户协议》', style: TextStyle(fontSize: 12)),
                                ),
                                const Text('与', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                                    );
                                  },
                                  child: const Text('《隐私政策》', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final redPaint = Paint()..color = const Color(0xFFEA4335);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    canvas.save();
    canvas.translate(centerX, centerY);

    path.reset();
    path.moveTo(0, -radius);
    path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, bluePaint);

    path.reset();
    path.moveTo(radius, 0);
    path.arcToPoint(Offset(0, radius), radius: Radius.circular(radius));
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, greenPaint);

    path.reset();
    path.moveTo(0, radius);
    path.arcToPoint(Offset(-radius, 0), radius: Radius.circular(radius));
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, yellowPaint);

    path.reset();
    path.moveTo(-radius, 0);
    path.arcToPoint(Offset(0, -radius), radius: Radius.circular(radius));
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

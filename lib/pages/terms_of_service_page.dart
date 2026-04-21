import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import '../config/api_config.dart';

class TermsOfServicePage extends StatefulWidget {
  const TermsOfServicePage({super.key});

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage> {
  String _htmlContent = '';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTermsOfService();
  }

  Future<void> _loadTermsOfService() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.backendApiUrl}/api/terms'));

      if (response.statusCode == 200) {
        setState(() {
          _htmlContent = response.body;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '无法加载用户协议内容，状态码: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载用户协议时出错: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户协议'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载用户协议...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = '';
                });
                _loadTermsOfService();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Html(
        data: _htmlContent,
        style: {
          'body': Style(
            fontSize: FontSize(14),
            lineHeight: LineHeight(1.6),
          ),
          'h1': Style(
            fontSize: FontSize(20),
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
          'h2': Style(
            fontSize: FontSize(18),
            fontWeight: FontWeight.bold,
          ),
          'a': Style(
            color: Colors.green[700],
            textDecoration: TextDecoration.underline,
          ),
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PrivacyPolicyPage extends StatefulWidget {
   const PrivacyPolicyPage({super.key});
 
   @override
   State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
 }

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String _privacyPolicyContent = '';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  Future<void> _loadPrivacyPolicy() async {
    try {
      final response = await http.get(Uri.parse(
          'https://gist.githubusercontent.com/zhoubo416/addfdb6e112bbc4be9481e4a8a77c2b1/raw/c5529495a9902db4f03a7a6c6a5d7ba6004a4a97/gistfile1.md'
      ));

      if (response.statusCode == 200) {
        setState(() {
          _privacyPolicyContent = response.body;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '无法加载隐私政策内容，状态码: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载隐私政策时出错: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私政策'),
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
            Text('正在加载隐私政策...'),
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
              onPressed: _loadPrivacyPolicy,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMarkdownContent(_privacyPolicyContent),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '本隐私政策内容来源于GitHub Gist，确保您看到的是最新版本。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(String content) {
    // 简单的Markdown解析和显示
    final lines = content.split('\n');
    List<Widget> widgets = [];

    for (String line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // 处理标题
      if (line.startsWith('#')) {
        int level = 0;
        while (line.startsWith('#') && level < 3) {
          line = line.substring(1);
          level++;
        }
        line = line.trim();
        
        TextStyle style;
        switch (level) {
          case 1:
            style = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green);
            break;
          case 2:
            style = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
            break;
          case 3:
            style = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
            break;
          default:
            style = const TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
        }
        
        widgets.add(Text(line, style: style));
        widgets.add(const SizedBox(height: 8));
      }
      // 处理列表项
      else if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(child: Text(line.substring(line.indexOf(' ') + 1))),
            ],
          ),
        ));
      }
      // 处理普通文本
      else {
        widgets.add(Text(line, style: const TextStyle(fontSize: 14, height: 1.5)));
        widgets.add(const SizedBox(height: 8));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    );
  }
  
  Widget _buildSubsectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
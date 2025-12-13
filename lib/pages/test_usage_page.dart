import 'package:flutter/material.dart';
import '../services/usage_manager.dart';

class TestUsagePage extends StatefulWidget {
  const TestUsagePage({super.key});

  @override
  State<TestUsagePage> createState() => _TestUsagePageState();
}

class _TestUsagePageState extends State<TestUsagePage> {
  final UsageManager _usageManager = UsageManager();
  bool _isLoading = true;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _loadUsageData();
  }

  Future<void> _loadUsageData() async {
    await _usageManager.canUseAsync();
    await _updateStatus();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateStatus() async {
    final status = await _usageManager.usageStatus;
    setState(() {
      _status = status;
    });
  }

  Future<void> _recordUsage() async {
    setState(() {
      _isLoading = true;
    });

    final canUse = await _usageManager.canUseAsync();
    
    if (canUse) {
      await _usageManager.recordUsage();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('使用次数已记录')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今日使用次数已达上限')),
      );
    }

    await _updateStatus();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _resetUsage() async {
    setState(() {
      _isLoading = true;
    });

    await _usageManager.resetUsage();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('使用次数已重置')),
    );

    await _updateStatus();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('使用次数测试页面'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '使用次数状态',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('状态: $_status'),
                          const SizedBox(height: 4),
                          Text('当前使用次数: ${_usageManager.dailyUsageCount}'),
                          const SizedBox(height: 4),
                          Text('最大允许次数: ${UsageManager.maxDailyUsage}'),
                          const SizedBox(height: 4),
                          Text('是否超过限制: ${_usageManager.isUsageLimitReached}'),
                          const SizedBox(height: 4),
                          Text('是否允许使用: ${_usageManager.canUse}'),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _recordUsage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('记录使用次数'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetUsage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('重置使用次数'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '测试说明',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• 当前每日使用次数限制设置为: 1次'),
                    Text('• 点击"记录使用次数"模拟使用应用'),
                    Text('• 点击"重置使用次数"清除使用记录'),
                    Text('• 使用超过1次后应该显示限制提示'),
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
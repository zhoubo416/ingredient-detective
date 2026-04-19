import 'package:flutter/material.dart';
import '../services/subscription_manager.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  
  @override
  void initState() {
    super.initState();
    _subscriptionManager.addListener(_onSubscriptionChanged);
  }
  
  @override
  void dispose() {
    _subscriptionManager.removeListener(_onSubscriptionChanged);
    super.dispose();
  }
  
  void _onSubscriptionChanged() {
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('升级到 配料侦探 Pro'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (!_subscriptionManager.isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载订阅信息...'),
          ],
        ),
      );
    }
    
    if (_subscriptionManager.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('处理中...'),
          ],
        ),
      );
    }
    
    if (_subscriptionManager.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              '发生错误',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _subscriptionManager.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _subscriptionManager.clearError();
                _subscriptionManager.reloadSubscriptionStatus();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    
    if (_subscriptionManager.isProUser) {
      return _buildProUserView();
    }
    
    return _buildNonProView();
  }
  
  Widget _buildProUserView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          Text(
            '您已是 配料侦探 Pro 用户！',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '感谢您支持配料侦探！您已解锁所有高级功能。',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildSubscriptionStatus(),
        ],
      ),
    );
  }
  
  Widget _buildNonProView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64),
          SizedBox(height: 16),
          Text('订阅功能开发中'),
          SizedBox(height: 8),
          Text('请联系管理员开通 Pro 权限'),
        ],
      ),
    );
  }
  
  Widget _buildSubscriptionStatus() {
    final status = _subscriptionManager.subscriptionStatus;
    final expiry = _subscriptionManager.subscriptionExpirationDate;
    
    return Column(
      children: [
        if (status != null)
          Text(
            '状态: $status',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        if (expiry != null)
          Text(
            '到期时间: $expiry',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }
}

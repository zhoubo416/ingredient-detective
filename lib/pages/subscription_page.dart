import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
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
    
    return _buildSubscriptionOptions();
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
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _openCustomerCenter,
            icon: const Icon(Icons.settings),
            label: const Text('管理订阅'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubscriptionOptions() {
    final packages = _subscriptionManager.availablePackages;
    
    if (packages == null || packages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64),
            SizedBox(height: 16),
            Text('暂无订阅选项'),
            SizedBox(height: 8),
            Text('请稍后重试或联系客服'),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // 头部介绍
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          color: Colors.green[50],
          child: Column(
            children: [
              Icon(Icons.star, color: Colors.green[700], size: 48),
              const SizedBox(height: 16),
              Text(
                '升级到 配料侦探 Pro',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '解锁高级功能，获得更好的使用体验',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        // 功能列表
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildFeatureItem('无限次成分分析', '不再受每日限制'),
              _buildFeatureItem('高级分析报告', '详细的营养成分分析'),
              _buildFeatureItem('历史记录保存', '永久保存分析记录'),
              _buildFeatureItem('无广告体验', '纯净的使用环境'),
              _buildFeatureItem('优先技术支持', '快速响应您的问题'),
              
              const SizedBox(height: 24),
              
              // 订阅选项
              ...packages.map((package) => _buildPackageCard(package)),
              
              const SizedBox(height: 16),
              
              // 恢复购买按钮
              TextButton(
                onPressed: _restorePurchases,
                child: const Text('恢复购买'),
              ),
              
              const SizedBox(height: 8),
              
              // 条款说明
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '订阅将自动续期，除非在当前周期结束前至少24小时取消。付款将在确认购买时从您的账户中扣除。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFeatureItem(String title, String subtitle) {
    return ListTile(
      leading: Icon(Icons.check_circle, color: Colors.green[600]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
  }
  
  Widget _buildPackageCard(rc.Package package) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        title: Text(
          package.storeProduct.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(package.storeProduct.description),
            const SizedBox(height: 4),
            Text(
              package.storeProduct.priceString,
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _purchasePackage(package),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
          ),
          child: const Text('订阅'),
        ),
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
  
  Future<void> _purchasePackage(rc.Package package) async {
    try {
      await _subscriptionManager.purchasePackage(package);
      
      // 购买成功后显示成功消息
      if (_subscriptionManager.isProUser) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('订阅成功！欢迎使用 配料侦探 Pro'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('购买失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _restorePurchases() async {
    try {
      await _subscriptionManager.restorePurchases();
      
      if (_subscriptionManager.isProUser) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('恢复购买成功！'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('未找到有效的订阅'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('恢复购买失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _openCustomerCenter() async {
    try {
      await _subscriptionManager.openCustomerCenter();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开客户中心失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
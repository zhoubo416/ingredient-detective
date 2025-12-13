import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  late Future<List<rc.Package>> _packagesFuture;

  @override
  void initState() {
    super.initState();
    _packagesFuture = rc.Purchases.getOfferings().then((offerings) {
      final current = offerings.current;
      if (current != null && current.availablePackages.isNotEmpty) {
        return current.availablePackages;
      }
      return [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('升级到 Pro'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<rc.Package>>(
          future: _packagesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      '无法加载订阅选项',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '请检查网络连接后重试',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final packages = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                final package = packages[index];
                return _buildPackageCard(package, context);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPackageCard(rc.Package package, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.storeProduct.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              package.storeProduct.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              package.storeProduct.priceString,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => _purchasePackage(package, context),
                child: const Text('立即订阅', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchasePackage(rc.Package package, BuildContext context) async {
    try {
      final result = await rc.Purchases.purchasePackage(package);
      
      if (result.customerInfo.entitlements.active.isNotEmpty) {
        // 购买成功
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('购买失败: $e')),
      );
    }
  }
}
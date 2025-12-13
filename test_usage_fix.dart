import 'package:flutter_application_1/services/usage_manager.dart';

void main() async {
  print('开始测试修复后的使用次数限制功能...\n');
  
  // 创建使用次数管理器
  final usageManager = UsageManager();
  
  // 等待初始化完成
  await usageManager.canUseAsync();
  
  print('初始状态:');
  print('  当前使用次数: ${usageManager.dailyUsageCount}');
  print('  最大允许次数: ${UsageManager.maxDailyUsage}');
  print('  剩余使用次数: ${await usageManager.remainingUsageCount}');
  print('  是否超过限制: ${usageManager.isUsageLimitReached}');
  print('  是否允许使用: ${usageManager.canUse}');
  print('  状态信息: ${await usageManager.usageStatus}\n');
  
  // 测试第一次使用
  print('=== 测试第一次使用 ===');
  final canUse1 = await usageManager.canUseAsync();
  if (canUse1) {
    await usageManager.recordUsage();
    print('✓ 第一次使用成功');
    print('  当前使用次数: ${usageManager.dailyUsageCount}');
    print('  剩余使用次数: ${await usageManager.remainingUsageCount}');
    print('  是否允许使用: ${usageManager.canUse}');
    print('  状态信息: ${await usageManager.usageStatus}');
  } else {
    print('✗ 第一次使用被拒绝');
  }
  print('');
  
  // 测试第二次使用（应该被拒绝，因为限制是1次）
  print('=== 测试第二次使用 ===');
  final canUse2 = await usageManager.canUseAsync();
  if (canUse2) {
    await usageManager.recordUsage();
    print('✓ 第二次使用成功');
    print('  当前使用次数: ${usageManager.dailyUsageCount}');
    print('  剩余使用次数: ${await usageManager.remainingUsageCount}');
    print('  是否允许使用: ${usageManager.canUse}');
    print('  状态信息: ${await usageManager.usageStatus}');
  } else {
    print('✗ 第二次使用被拒绝（正确行为）');
    print('  当前使用次数: ${usageManager.dailyUsageCount}');
    print('  剩余使用次数: ${await usageManager.remainingUsageCount}');
    print('  是否允许使用: ${usageManager.canUse}');
    print('  状态信息: ${await usageManager.usageStatus}');
  }
  print('');
  
  // 重置使用次数
  print('=== 重置使用次数 ===');
  await usageManager.resetUsage();
  print('✓ 使用次数已重置');
  print('  当前使用次数: ${usageManager.dailyUsageCount}');
  print('  剩余使用次数: ${await usageManager.remainingUsageCount}');
  print('  是否允许使用: ${usageManager.canUse}');
  print('  状态信息: ${await usageManager.usageStatus}');
  print('');
  
  print('测试完成！');
  
  // 验证显示是否正确
  print('=== 验证显示格式 ===');
  print('期望显示格式: 剩余次数: X/1');
  final status = await usageManager.usageStatus;
  print('实际显示格式: $status');
  
  if (status.contains('1')) {
    print('✓ 显示格式正确');
  } else {
    print('✗ 显示格式不正确');
  }
}
import 'package:flutter_application_1/services/usage_manager.dart';

void main() async {
  print('开始测试使用次数限制功能...\n');
  
  // 创建使用次数管理器
  final usageManager = UsageManager();
  
  // 等待初始化完成
  await usageManager.canUseAsync();
  
  print('初始状态:');
  print('  当前使用次数: ${usageManager.dailyUsageCount}');
  print('  最大允许次数: ${UsageManager.maxDailyUsage}');
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
    print('  是否允许使用: ${usageManager.canUse}');
  } else {
    print('✗ 第一次使用被拒绝');
  }
  print('');
  
  // 测试第二次使用（应该被拒绝，因为限制是1次）
  print('=== 测试第二次使用 ===');
  final canUse2 = await usageManager.canUseAsync();
  if (canUse2) {
    await usageManager.recordUsage();
    print('✗ 第二次使用成功（不应该发生）');
    print('  当前使用次数: ${usageManager.dailyUsageCount}');
  } else {
    print('✓ 第二次使用被正确拒绝');
    print('  当前使用次数: ${usageManager.dailyUsageCount}');
    print('  是否超过限制: ${usageManager.isUsageLimitReached}');
    print('  状态信息: ${await usageManager.usageStatus}');
  }
  print('');
  
  // 重置使用次数进行测试
  print('=== 重置使用次数 ===');
  await usageManager.resetUsage();
  print('✓ 使用次数已重置');
  print('  当前使用次数: ${usageManager.dailyUsageCount}');
  print('  是否允许使用: ${usageManager.canUse}');
  print('');
  
  // 测试重置后的使用
  print('=== 测试重置后的使用 ===');
  final canUse3 = await usageManager.canUseAsync();
  if (canUse3) {
    await usageManager.recordUsage();
    print('✓ 重置后第一次使用成功');
    print('  当前使用次数: ${usageManager.dailyUsageCount}');
  } else {
    print('✗ 重置后第一次使用被拒绝');
  }
  
  print('\n测试完成！');
}
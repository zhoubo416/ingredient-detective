# RevenueCat 集成配置指南

## 1. RevenueCat 后台配置

### 1.1 创建产品和权益

在 RevenueCat 后台 (https://app.revenuecat.com) 进行以下配置：

#### 权益 (Entitlements)
- **权益名称**: `pro_access`
- **描述**: 配料侦探 Pro 权限
- **产品标识符**: 关联以下产品

#### 产品配置 (Products)
- **月订阅**: `monthly`
- **年订阅**: `yearly`  
- **终身购买**: `lifetime`

#### 产品组合 (Offerings)
- **默认组合**: 包含所有三个产品
- 设置月订阅为推荐产品
- 配置年订阅的折扣信息

### 1.2 定价配置

在 App Store Connect 和 Google Play Console 中设置对应价格：

| 产品类型 | 产品标识符 | 建议价格 | 描述 |
|---------|-----------|---------|------|
| 月订阅 | monthly | ¥15/月 | 每月自动续订 |
| 年订阅 | yearly | ¥128/年 | 年度订阅，节省33% |
| 终身 | lifetime | ¥298 | 一次性购买，永久使用 |

## 2. 应用内配置

### 2.1 API 密钥配置

当前使用的测试API密钥：
```
test_CvDYRHNZrKLxPmTaJUiVKUsiCEX
```

生产环境需要替换为：
```
appl_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 2.2 平台特定配置

#### iOS 配置
- 部署目标：iOS 13.0+ ✅ 已配置
- In-App Purchase Capability：需要在 Xcode 中启用
- 沙盒测试账户：需要在 App Store Connect 中创建

#### Android 配置
- BILLING 权限：✅ 已配置
- MainActivity：✅ 已配置为 FlutterFragmentActivity
- Google Play 结算库：自动处理

## 3. 功能实现说明

### 3.1 订阅状态管理

应用实现了完整的订阅状态管理：
- 自动初始化 RevenueCat SDK
- 实时监听订阅状态变化
- 支持应用生命周期状态恢复
- 完整的错误处理和重试机制

### 3.2 用户界面

#### 订阅页面 (`subscription_page.dart`)
- 显示可用订阅选项
- 实时显示订阅状态
- 购买和恢复购买功能
- 客户中心入口

#### Paywall 页面 (`paywall_page.dart`)
- 使用 RevenueCat UI 组件
- 标准化的购买流程
- 自动处理本地化

#### 主页集成
- 非 Pro 用户显示升级按钮
- 实时订阅状态指示
- 应用栏集成订阅入口

### 3.3 权益检查

在需要限制功能的地方使用：
```dart
if (SubscriptionManager().isProUser) {
  // 允许访问 Pro 功能
} else {
  // 显示限制或引导升级
}
```

## 4. 测试指南

### 4.1 沙盒测试

#### iOS 沙盒测试
1. 在 App Store Connect 创建沙盒测试员
2. 使用测试账户登录设备
3. 测试购买流程和恢复购买

#### Android 内部测试
1. 上传应用到 Google Play 内部测试轨道
2. 添加测试人员
3. 测试购买流程

### 4.2 测试场景

- [ ] 新用户首次购买
- [ ] 现有用户恢复购买
- [ ] 订阅续期测试
- [ ] 取消订阅流程
- [ ] 升级订阅测试
- [ ] 错误场景处理

## 5. 上线前检查清单

### 技术配置
- [ ] RevenueCat 生产环境 API 密钥
- [ ] App Store Connect 产品配置
- [ ] Google Play Console 产品配置
- [ ] 权益和产品关联正确
- [ ] 定价信息准确

### 功能测试
- [ ] 购买流程正常工作
- [ ] 恢复购买功能正常
- [ ] 权益检查逻辑正确
- [ ] 错误处理完善
- [ ] 用户界面本地化

### 合规性检查
- [ ] 隐私政策包含订阅条款
- [ ] 应用内购买说明清晰
- [ ] 取消订阅指引明确
- [ ] 价格显示准确

## 6. 常见问题处理

### 6.1 初始化失败
- 检查网络连接
- 验证 API 密钥
- 检查平台配置

### 6.2 购买失败
- 检查沙盒账户状态
- 验证产品配置
- 检查设备支付设置

### 6.3 权益状态不同步
- 调用 `restorePurchases()`
- 检查网络连接
- 联系 RevenueCat 支持

## 7. 监控和分析

### RevenueCat 仪表板
- 监控订阅指标
- 分析用户转化率
- 跟踪收入数据

### 应用内分析
- 记录购买事件
- 跟踪用户行为
- 监控错误率

## 8. 后续优化建议

1. **A/B 测试定价策略**
2. **优化 Paywall 设计**
3. **实现个性化推荐**
4. **添加促销活动支持**
5. **集成更多分析工具**

---

**注意**: 上线前务必在真实环境中进行全面测试，确保订阅功能稳定可靠。
# 配料详细信息加载问题 - 修复方案

## 问题症状
- Flutter 端上传图片后，配料详细信息一直不显示
- 页面显示"详细配料分析生成中，请稍候刷新"
- 轮询 90 秒后仍无结果或显示失败

## 根本原因分析

### 1. **数据传递链路问题** ✅ 已修复
**位置**：`apps/web/server/api/analysis/[id].get.ts`

**问题**：GET 端点每次从数据库读取数据时都会调用 `normalizeFoodAnalysisResult()` 再次规范化，这可能导致：
- 复杂的 `ingredients` 数组在转换中丢失
- `detailedStatus` 和 `detailedError` 被覆盖

**修复**：确保从数据库读取的 `result` 被正确传递，同时保证 `detailedStatus` 和 `detailedError` 不被覆盖。

### 2. **Flutter 端状态同步问题** ✅ 已修复
**位置**：`lib/pages/analysis_result_page.dart`

**问题**：`_mergeResult()` 方法可能在某些情况下不正确地处理 `detailedStatus` 状态。

**修复**：改进状态合并逻辑，确保从服务器返回的 `detailedStatus` 和 `detailedError` 始终被正确更新。

### 3. **日志和调试信息** ✅ 已改进
**位置**：`apps/web/server/api/analysis.post.ts`

**问题**：后台任务失败时的日志信息不完整，难以排查问题。

**修复**：改进错误日志，包含详细的错误堆栈跟踪和分析结果数量等信息。

## 已修复的内容

### 修复 1：GET 端点数据返回
```typescript
// 原问题：重复规范化导致数据可能丢失
result: normalizeFoodAnalysisResult(row.result, ...)

// 修复后：直接使用数据库数据，同时确保状态字段完整
result: {
  ...normalizeFoodAnalysisResult(...),
  detailedStatus: storedResult.detailedStatus,  // 从原始数据读取
  detailedError: storedResult.detailedError      // 从原始数据读取
}
```

### 修复 2：Flutter 端状态合并
```dart
// 修复后：优先使用服务器的最新状态
detailedStatus: incoming.detailedStatus != 'pending'
    ? incoming.detailedStatus  // 优先使用服务器状态
    : current.detailedStatus,
detailedError: incoming.detailedError.trim().isNotEmpty
    ? incoming.detailedError    // 总是优先使用服务器错误
    : current.detailedError,
```

### 修复 3：后端日志改进
```typescript
console.error('[analysis-detailed-error]', JSON.stringify({
  analysisId,
  userId,
  error: errorMessage,
  stack: errorStack,        // 添加错误堆栈
  totalMs: Date.now() - startedAt  // 添加耗时
}))
```

## 后续诊断步骤

如果修复后仍然有问题，请按以下步骤诊断：

### 1. **检查后端日志**
查看 `[analysis-detailed-error]` 日志，确认错误信息：
```bash
# 查看最近的详细分析错误
tail -f logs/server.log | grep "analysis-detailed-error"
```

常见错误：
- `Model response does not contain valid JSON` - LLM 返回格式错误
- `Detailed analysis response is missing ingredients` - LLM 没有返回 ingredients 字段
- 超时错误 - 请求超过 90 秒

### 2. **查询数据库**
```sql
SELECT id, result->>'detailedStatus' as status,
       result->>'detailedError' as error,
       result->'ingredients' as ingredients_count
FROM analysis_results
ORDER BY created_at DESC LIMIT 10;
```

检查：
- `detailedStatus` 是否被正确设置为 'complete' 或 'failed'
- `ingredients` 数组是否有数据（如果是 'complete'）
- `detailedError` 中的错误信息

### 3. **检查 Flutter 日志**
在 Flutter 应用中启用详细日志：
```dart
// 在 analysis_result_page.dart 中添加调试输出
debugPrint('[Polling] Attempt $i: detailedStatus=${_result.detailedStatus}, ingredientCount=${_result.ingredients.length}');
```

### 4. **手动测试 API**
```bash
# 获取特定分析结果
curl -H "Authorization: Bearer <token>" \
  https://api.example.com/api/analysis/<analysisId>
```

查看返回的 JSON 中 `result.detailedStatus` 和 `result.ingredients` 的内容。

## 已知的根本问题（需要后续优化）

### LLM JSON 生成格式错误
**文档参考**：docs/analysis-flow.md 第 8.3 和第 10 节

**问题**：详细分析的 prompt 要求模型输出 1200 tokens 以内的严格 JSON，但 LLM（特别是在有限 tokens 和复杂要求下）经常返回格式错误的 JSON。

**当前表现**：
- `JSON.parse()` 失败
- 详细分析被标记为 `failed`
- Flutter 端显示错误或一直轮询（如果网络丢包导致未收到失败通知）

**长期解决方案**（建议）：
1. **使用结构化输出**（如果 LLM 支持）
   - DeepSeek：使用 `response_format: { type: "json_object" }`
   - Qwen：使用结构化返回

2. **拆分详细分析任务**
   - 先生成 ingredients 列表
   - 再逐个分析每个配料
   - 最后汇总结果

3. **改进 Prompt**
   - 减少要求的字段数量
   - 降低 JSON 嵌套深度
   - 增加示例和格式要求

4. **添加重试机制**
   - 当 JSON 解析失败时，自动重试
   - 逐步降低要求的细节程度

## 测试清单

修复完成后，请按以下步骤测试：

- [ ] 上传一张简单的食品包装图片（如牛奶、酸奶）
- [ ] 确认快速结果在 5-10 秒内显示
- [ ] 等待详细配料分析
  - [ ] **成功路径**：10-60 秒内显示完整的配料详情
  - [ ] **失败路径**：如果失败，应在 90 秒内显示错误信息，而不是继续等待
- [ ] 检查后端日志中的 `[analysis-detailed-complete]` 或 `[analysis-detailed-error]` 消息
- [ ] 刷新页面，确认已保存的数据能正确加载

## 附加建议

1. **增加用户反馈机制**
   - 在配料详情卡片中显示"自动重试"按钮
   - 允许用户手动刷新而不是被动等待

2. **改进超时处理**
   - 当轮询达到 30 秒时，显示"仍在生成中..."的进度提示
   - 当达到 60 秒时，建议用户稍后重试

3. **增加详细分析的可选性**
   - 用户可以选择"仅显示快速结果"，跳过详细分析
   - 稍后可随时手动获取详细分析

## 相关文件

- 流程文档：`docs/analysis-flow.md`
- 快速分析 prompt：`apps/web/server/utils/analysis.ts` (第 224-251 行)
- 详细分析 prompt：`apps/web/server/utils/analysis.ts` (第 285-336 行)
- Flutter 轮询逻辑：`lib/pages/analysis_result_page.dart` (第 120-161 行)

# 两阶段分析功能测试指南

## 测试目标
验证 `/api/analysis` 端点的两阶段响应流程：
1. 快速阶段 - 2-3 秒内返回关键指标（健康评分、合规性、加工度）
2. 详细阶段 - 后台异步生成配料详情

## 环境准备

```bash
# 启动 Nuxt 服务（确保运行在 3000 端口）
cd apps/web
npm run dev

# 另一个终端启动 Flutter Web（可使用不同端口）
cd .
flutter run -d chrome --web-port 8080
```

## 手动测试步骤

### 步骤 1: 测试 API 快速返回
```bash
# 准备测试图片（任何食品包装图片）
# 使用 curl 发送分析请求

curl -X POST http://localhost:3000/api/analysis \
  -H "Authorization: Bearer YOUR_SUPABASE_TOKEN" \
  -F "image=@/path/to/food/package.jpg"
```

**期望结果：**
- 2-3 秒内收到响应
- 响应包含：
  - `quickResult` 对象（健康评分、合规性、加工度、总体评价）
  - `analysisId`（用于轮询详细结果）
  - `Server-Timing` 响应头（显示快速分析耗时）

```json
{
  "success": true,
  "quickResult": {
    "foodName": "产品名称",
    "healthScore": 6.5,
    "compliance": {
      "status": "合规",
      "description": "...",
      "issues": []
    },
    "processing": {
      "level": "中度加工",
      "description": "...",
      "score": 3.5
    },
    "overallAssessment": "..."
  },
  "analysisId": "uuid-xxx",
  "timestamp": "2024-03-31T10:00:00Z"
}
```

### 步骤 2: 测试轮询获取详细结果
```bash
# 使用上一步返回的 analysisId 轮询详细结果
curl http://localhost:3000/api/analysis/[analysisId] \
  -H "Authorization: Bearer YOUR_SUPABASE_TOKEN"
```

**预期行为：**
- 首次轮询（快速生成进行中）：返回 202 Accepted，配料列表为空
- 最终轮询（生成完成）：返回 200 OK，包含完整的 `ingredients` 数组

```json
{
  "success": true,
  "result": {
    "foodName": "产品名称",
    "healthScore": 6.5,
    "ingredients": [
      {
        "ingredientName": "成分1",
        "function": "防腐剂",
        "nutritionalValue": "...对健康...",
        "complianceStatus": "合规",
        "processingLevel": "高度加工",
        "remarks": "..."
      }
    ],
    "compliance": {...},
    "processing": {...},
    "claims": {...},
    "overallAssessment": "...",
    "recommendations": "..."
  }
}
```

### 步骤 3: 测试 Nuxt 前端交互
1. 打开 Nuxt 应用（http://localhost:3000）
2. 上传食品包装图片
3. **验证第一阶段（2-3秒）：**
   - 快速显示健康评分卡片（大数字）
   - 显示合规性分析
   - 显示加工度分析
   - 显示总体评价
4. **验证第二阶段（后续自动加载）：**
   - 配料分析区域显示"详细配料分析生成中..."
   - 进度条逐渐填充
   - 等待配料列表自动加载（应在 30-60 秒内完成）

### 步骤 4: 测试 Flutter 前端交互
1. 启动 Flutter Web 应用
2. 上传同一张食品图片
3. **验证快速响应：**
   - AnalysisResultPage 立即显示 QuickAnalysisResult
   - 健康评分、合规性、加工度快速可见
4. **验证详细加载：**
   - 配料分析区域显示加载动画
   - 等待后台完成，前端自动轮询获取
   - 配料列表逐步出现

## 性能指标验证

| 指标 | 目标 | 验证方式 |
|------|------|--------|
| 快速阶段延迟 | < 3 秒 | 使用浏览器 DevTools，观察第一个响应时间 |
| 总完成时间 | 保持 30-60 秒 | 从上传开始到配料列表完全加载 |
| 用户体验 | 2-3 秒出现评分 | 无明显卡顿，首屏快速响应 |

## 故障排查

### 快速阶段超过 3 秒
- 检查 `REQUEST_TIMEOUT_MS` 设置（应为 90000）
- 确认 AI 服务（DeepSeek/DashScope）连接正常
- 检查网络延迟

### 配料详情未加载
- 检查后台异步任务是否正确启动（控制台日志）
- 验证数据库写入是否成功
- 确认轮询间隔合理（建议 2-5 秒）

### 数据不一致
- 清空浏览器缓存，重新上传
- 检查数据库中的 `analysis_results` 表记录
- 验证 `ingredients_array` 字段是否正确序列化

## 清理测试数据

```sql
-- 删除测试分析记录（可选）
DELETE FROM analysis_results
WHERE created_at > NOW() - INTERVAL '1 hour'
  AND user_id = 'test-user-id';
```

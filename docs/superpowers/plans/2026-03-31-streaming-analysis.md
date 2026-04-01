# 流式分析结果优化实现计划

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 通过两阶段 AI 分析，实现快速首屏展示关键指标（2-3秒），异步加载详细配料分析。

**Architecture:**
- **第一阶段**：快速 AI 调用生成健康评分、合规性、加工度、总体评价（精简 prompt，max_tokens 小）
- **第二阶段**：标准 AI 调用生成详细配料分析（在后台运行，前端异步轮询或 webhook）
- 数据库一次性存储完整结果，前端根据获取时间分阶段渲染

**Tech Stack:** TypeScript/Nuxt (backend), Vue 3 (frontend), Supabase, DeepSeek/DashScope

---

## Chunk 1: 数据模型与 API 契约定义

### Task 1: 定义新的数据类型

**Files:**
- Modify: `apps/web/shared/analysis.ts` - 添加新类型

**Step:**

在 `apps/web/shared/analysis.ts` 末尾添加以下类型定义：

```typescript
// 第一阶段快速分析结果（2-3秒内返回）
export interface QuickAnalysisResult {
  foodName: string
  healthScore: number
  overallAssessment: string
  compliance: {
    status: string // '合规' | '不合规' | '待确认'
    description: string
  }
  processing: {
    level: string // '轻度加工' | '中度加工' | '高度加工'
    score: number
  }
  recommendations: string
}

// API 响应格式：快速返回 + 完整版本
export interface AnalysisResponse {
  id: string // 分析记录 ID
  quick: QuickAnalysisResult // 立即可用
  isComplete: boolean // 是否已生成详细分析
}

// 标记：详细结果已完成
export interface AnalysisCompleteEvent {
  id: string
  isComplete: true
}
```

**验证：** 检查是否能在 TypeScript 中正确编译，无类型错误。

---

### Task 2: 修改数据库 schema（可选）

**Files:**
- Modify: `apps/web/supabase/schema.sql`

**Step:**

在 `analysis_results` 表中添加字段追踪分析完成状态：

```sql
ALTER TABLE analysis_results
ADD COLUMN IF NOT EXISTS quick_analysis_at TIMESTAMP DEFAULT NULL,
ADD COLUMN IF NOT EXISTS detailed_analysis_at TIMESTAMP DEFAULT NULL;

-- 创建索引以查询未完成的分析
CREATE INDEX IF NOT EXISTS idx_analysis_incomplete
ON analysis_results(user_id, created_at DESC)
WHERE detailed_analysis_at IS NULL;
```

**验证：** 运行 SQL 后检查表结构。

---

## Chunk 2: 后端 AI 分析逻辑重构

### Task 3: 拆分 AI 分析为两个函数

**Files:**
- Modify: `apps/web/server/utils/analysis.ts`

**Step 1: 实现快速分析函数**

在 `analysis.ts` 中添加新函数（放在 `analyzeIngredients` 之前）：

```typescript
export async function analyzeQuickMetrics(
  ingredients: string[],
  productName: string,
  timings?: TimingMap
): Promise<QuickAnalysisResult> {
  const llm = resolveLlmConfig()

  if (!llm) {
    // Mock 模式
    return {
      foodName: productName || guessFoodName(ingredients),
      healthScore: calculateHealthScore(ingredients),
      overallAssessment: generateOverallAssessment(
        calculateHealthScore(ingredients),
        productName || guessFoodName(ingredients)
      ),
      compliance: buildMockCompliance(ingredients),
      processing: buildMockProcessing(ingredients),
      recommendations: generateRecommendations(
        ingredients,
        calculateHealthScore(ingredients)
      )
    }
  }

  const systemPrompt = `你是食品营养快速评估师。快速返回 JSON，格式如下，不包含逐项配料分析：
{
  "foodName": "食品类型",
  "healthScore": 0-10 数值,
  "overallAssessment": "一句话总体评价",
  "compliance": {"status": "合规/不合规/待确认", "description": "简述"},
  "processing": {"level": "轻/中/高", "score": 1-5},
  "recommendations": "一句建议"
}`

  const userPrompt = `快速评估产品 "${productName}" 的配料：${ingredients.join(', ')}。只返回 JSON，无其他文本。`

  const { signal, clear } = createTimeoutSignal()

  try {
    const requestStartedAt = Date.now()
    const response = await fetch(llm.url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${llm.apiKey}`
      },
      body: JSON.stringify({
        model: llm.model,
        temperature: 0.2, // 更低温度，更稳定
        max_tokens: 400, // 大幅降低
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt }
        ]
      }),
      signal
    })
    recordTiming(timings ?? {}, 'ai.quick_fetch', Date.now() - requestStartedAt, {
      provider: llm.provider,
      model: llm.model
    })

    const parseStartedAt = Date.now()
    const payload = await response.json() as {
      choices?: Array<{ message?: { content?: string } }>
    }
    recordTiming(timings ?? {}, 'ai.quick_parse', Date.now() - parseStartedAt)

    if (!response.ok) {
      throw new Error('API error')
    }

    const content = payload.choices?.[0]?.message?.content
    if (!content) {
      throw new Error('No content')
    }

    const jsonStart = content.indexOf('{')
    const jsonEnd = content.lastIndexOf('}') + 1
    const data = JSON.parse(content.slice(jsonStart, jsonEnd)) as QuickAnalysisResult

    return {
      foodName: data.foodName ?? guessFoodName(ingredients),
      healthScore: typeof data.healthScore === 'number' ? data.healthScore : calculateHealthScore(ingredients),
      overallAssessment: data.overallAssessment ?? '',
      compliance: {
        status: data.compliance?.status ?? '待确认',
        description: data.compliance?.description ?? ''
      },
      processing: {
        level: data.processing?.level ?? '中度加工',
        score: typeof data.processing?.score === 'number' ? data.processing.score : 3
      },
      recommendations: data.recommendations ?? ''
    }
  } catch {
    // fallback 到 mock
    return {
      foodName: productName || guessFoodName(ingredients),
      healthScore: calculateHealthScore(ingredients),
      overallAssessment: generateOverallAssessment(
        calculateHealthScore(ingredients),
        productName || guessFoodName(ingredients)
      ),
      compliance: buildMockCompliance(ingredients),
      processing: buildMockProcessing(ingredients),
      recommendations: generateRecommendations(
        ingredients,
        calculateHealthScore(ingredients)
      )
    }
  } finally {
    clear()
  }
}
```

**Step 2: 修改原 `analyzeIngredients` 为详细分析（保持原逻辑）**

无需修改现有逻辑，保持原样。

**Step 3: Commit**

```bash
git add apps/web/server/utils/analysis.ts
git commit -m "feat(analysis): add quick metrics AI function for fast first-stage analysis"
```

---

### Task 4: 修改 `/api/analysis` 端点支持两阶段返回

**Files:**
- Modify: `apps/web/server/api/analysis.post.ts`

**Step 1: 修改响应流程**

替换现有的 `export default defineEventHandler` 部分：

```typescript
export default defineEventHandler(async event => {
  const startedAt = Date.now()
  const requestId = randomUUID()
  const timings: TimingMap = {}
  const user = await measureTiming(timings, 'auth', () => requireApiUser(event))

  // ... 保持现有的请求解析逻辑不变 ...
  // (contentType 判断、imageBuffer 解析等)

  if (ingredientLines.length === 0) {
    throw createError({
      statusCode: 422,
      statusMessage: 'Provide an ingredient list or upload a package image.'
    })
  }

  const resolvedProductName = productName || guessFoodName(ingredientLines)

  // 第一阶段：快速分析（立即返回）
  const quick = await measureTiming(
    timings,
    'ai.quick',
    () => analyzeQuickMetrics(ingredientLines, resolvedProductName, timings)
  )

  // 保存到数据库（先保存快速结果）
  const supabase = getSupabaseAdminClient()
  const { data, error } = await measureTiming(timings, 'db.insert', async () => {
    return supabase
      .from('analysis_results')
      .insert({
        user_id: user.id,
        source_type: sourceType,
        image_filename: imageFilename,
        raw_ocr_text: rawOcrText,
        ingredient_lines: ingredientLines as unknown as Json,
        food_name: quick.foodName,
        health_score: quick.healthScore,
        result: {} as Json, // 暂时空结果，稍后填充
        quick_analysis_at: new Date().toISOString()
      })
      .select('id')
      .single()
  })

  if (error || !data) {
    throw createError({
      statusCode: 500,
      statusMessage: error?.message ?? 'Failed to save analysis result.'
    })
  }

  const analysisId = data.id

  // 第二阶段：异步生成详细分析（后台执行，不阻塞响应）
  generateDetailedAnalysisInBackground(
    analysisId,
    user.id,
    ingredientLines,
    resolvedProductName,
    imageFilename,
    rawOcrText,
    sourceType
  ).catch(err => {
    console.error('[analysis-background-error]', { analysisId, error: err })
  })

  const totalMs = Date.now() - startedAt
  recordTiming(timings, 'request.total', totalMs)

  setResponseHeader(event, 'X-Request-Id', requestId)
  setResponseHeader(event, 'X-Analysis-Timing', JSON.stringify({
    requestId,
    stage: 'quick',
    durationMs: totalMs,
    ...flattenTimingMap(timings)
  }))

  console.info('[analysis-quick]', JSON.stringify({
    requestId,
    userId: user.id,
    analysisId,
    totalMs
  }))

  // 返回快速结果 + 记录 ID
  return {
    id: analysisId,
    quick,
    isComplete: false
  }
})
```

**Step 2: 添加后台处理函数**

在同文件末尾添加：

```typescript
async function generateDetailedAnalysisInBackground(
  analysisId: string,
  userId: string,
  ingredientLines: string[],
  productName: string,
  imageFilename: string | null,
  rawOcrText: string | null,
  sourceType: AnalysisSourceType
) {
  try {
    const timings: TimingMap = {}
    const startedAt = Date.now()

    // 生成详细分析
    const fullAnalysis = await measureTiming(
      timings,
      'ai.detailed',
      () => analyzeIngredients(ingredientLines, productName, timings)
    )

    const supabase = getSupabaseAdminClient()
    await measureTiming(timings, 'db.update', async () => {
      return supabase
        .from('analysis_results')
        .update({
          result: fullAnalysis as unknown as Json,
          detailed_analysis_at: new Date().toISOString()
        })
        .eq('id', analysisId)
    })

    const totalMs = Date.now() - startedAt

    console.info('[analysis-detailed-complete]', JSON.stringify({
      analysisId,
      userId,
      totalMs,
      timings
    }))
  } catch (err) {
    console.error('[analysis-detailed-error]', {
      analysisId,
      error: err instanceof Error ? err.message : String(err)
    })
  }
}
```

**Step 3: 在文件顶部导入新函数**

```typescript
import { analyzeQuickMetrics, analyzeIngredients } from '~/server/utils/analysis'
```

**Step 4: Commit**

```bash
git add apps/web/server/api/analysis.post.ts
git commit -m "feat(api): implement two-stage analysis - quick response + background detailed"
```

---

## Chunk 3: 前端 Nuxt 组件适配

### Task 5: 修改 AnalysisComposer 组件处理两阶段响应

**Files:**
- Modify: `apps/web/components/analysis/AnalysisComposer.vue`

**Step 1: 更新提交逻辑**

找到 `async function handleSubmit()` 部分，修改为：

```typescript
async function handleSubmit() {
  loading.value = true
  errorMessage.value = ''

  try {
    const formData = new FormData()
    if (selectedImage.value) {
      formData.append('image', selectedImage.value)
    }
    if (ingredientText.value) {
      formData.append('ingredientsText', ingredientText.value)
    }
    if (productName.value) {
      formData.append('productName', productName.value)
    }

    // 提交分析请求
    const response = await $fetch<AnalysisResponse>('/api/analysis', {
      method: 'POST',
      body: formData
    })

    // 立即发出已完成事件（带快速结果）
    const quickHistoryItem: AnalysisHistoryItem = {
      id: response.id,
      sourceType: 'image',
      imageFilename: null,
      ingredientLines: [],
      rawOcrText: null,
      foodName: response.quick.foodName,
      healthScore: response.quick.healthScore,
      createdAt: new Date().toISOString(),
      result: {
        foodName: response.quick.foodName,
        ingredients: [],
        healthScore: response.quick.healthScore,
        compliance: response.quick.compliance,
        processing: response.quick.processing,
        claims: {
          detectedClaims: [],
          supportedClaims: [],
          questionableClaims: [],
          assessment: '详细分析中...'
        },
        overallAssessment: response.quick.overallAssessment,
        recommendations: response.quick.recommendations,
        analysisTime: new Date()
      }
    }

    emit('completed', quickHistoryItem)

    // 后台轮询完整结果
    if (!response.isComplete) {
      pollForDetailedAnalysis(response.id)
    }
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '分析失败'
  } finally {
    loading.value = false
  }
}

// 新增：轮询完整分析结果
async function pollForDetailedAnalysis(analysisId: string, maxAttempts = 30) {
  for (let i = 0; i < maxAttempts; i++) {
    await new Promise(resolve => setTimeout(resolve, 1000)) // 每秒轮询一次

    try {
      const response = await $fetch<{ items: AnalysisHistoryItem[] }>('/api/history', {
        query: { limit: 1 }
      })

      const completed = response.items.find(item => item.id === analysisId)
      if (completed && completed.result.ingredients && completed.result.ingredients.length > 0) {
        // 发出更新事件，让父组件刷新结果显示
        emit('completed', completed)
        return
      }
    } catch (err) {
      console.warn('[poll-error]', err)
    }
  }
}
```

**Step 2: Commit**

```bash
git add apps/web/components/analysis/AnalysisComposer.vue
git commit -m "feat(composer): handle two-stage analysis with polling for detailed results"
```

---

### Task 6: 修改 AnalysisResultCard 支持渐进式加载

**Files:**
- Modify: `apps/web/components/analysis/AnalysisResultCard.vue`

**Step 1: 在配料列表中显示加载状态**

找到 `<div v-else class="space-y-6">` 部分，修改配料部分为：

```vue
<div class="space-y-4">
  <div class="flex items-center justify-between">
    <h3 class="text-xl font-semibold text-slate-900">逐项配料分析</h3>
    <span class="text-sm text-slate-500">
      {{ result.ingredients.length > 0 ? result.ingredients.length : '加载中' }} 项
    </span>
  </div>

  <div v-if="result.ingredients.length === 0" class="rounded-[1.5rem] border border-dashed border-slate-300 bg-amber-50/50 px-6 py-8 text-sm text-slate-600">
    <p>详细配料分析生成中，请稍候...</p>
    <div class="mt-3 h-1 w-full overflow-hidden rounded-full bg-slate-200">
      <div class="h-full w-1/3 animate-pulse bg-amber-400"></div>
    </div>
  </div>

  <div v-else class="grid gap-4">
    <div
      v-for="ingredient in result.ingredients"
      :key="ingredient.ingredientName"
      class="rounded-[1.5rem] border border-slate-900/5 bg-white/85 p-5"
    >
      <!-- 保持原有代码 -->
    </div>
  </div>
</div>
```

**Step 2: Commit**

```bash
git add apps/web/components/analysis/AnalysisResultCard.vue
git commit -m "feat(result-card): show loading state for detailed analysis"
```

---

## Chunk 4: 前端 Flutter 适配

### Task 7: 更新 Flutter 数据模型

**Files:**
- Modify: `lib/models/ingredient_analysis.dart`

**Step 1: 添加快速结果类型**

在文件末尾添加：

```dart
class QuickAnalysisResult {
  final String foodName;
  final double healthScore;
  final String overallAssessment;
  final ComplianceAnalysis compliance;
  final ProcessingAnalysis processing;
  final String recommendations;

  QuickAnalysisResult({
    required this.foodName,
    required this.healthScore,
    required this.overallAssessment,
    required this.compliance,
    required this.processing,
    required this.recommendations,
  });

  factory QuickAnalysisResult.fromMap(Map<String, dynamic> map) {
    return QuickAnalysisResult(
      foodName: map['foodName'] ?? '',
      healthScore: (map['healthScore'] as num?)?.toDouble() ?? 0.0,
      overallAssessment: map['overallAssessment'] ?? '',
      compliance: ComplianceAnalysis.fromMap(map['compliance'] ?? {}),
      processing: ProcessingAnalysis.fromMap(map['processing'] ?? {}),
      recommendations: map['recommendations'] ?? '',
    );
  }
}

class AnalysisResponse {
  final String id;
  final QuickAnalysisResult quick;
  final bool isComplete;

  AnalysisResponse({
    required this.id,
    required this.quick,
    required this.isComplete,
  });

  factory AnalysisResponse.fromMap(Map<String, dynamic> map) {
    return AnalysisResponse(
      id: map['id'] ?? '',
      quick: QuickAnalysisResult.fromMap(map['quick'] ?? {}),
      isComplete: map['isComplete'] ?? false,
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/models/ingredient_analysis.dart
git commit -m "feat(models): add QuickAnalysisResult and AnalysisResponse types"
```

---

### Task 8: 修改 Flutter 分析请求处理

**Files:**
- Modify: `lib/services/analysis_service.dart` (或类似的 API 服务)

**Step 1: 查找现有分析调用代码**

```bash
grep -r "api/analysis" lib/
```

**Step 2: 修改为两阶段处理**

找到发送分析请求的位置，修改为：

```dart
// 第一阶段：快速获取结果
final response = await http.post(
  Uri.parse('$apiUrl/api/analysis'),
  headers: {...},
  body: formData,
) as AnalysisResponse;

// 立即显示快速结果
showQuickAnalysis(response.quick);

// 第二阶段：后台轮询完整结果
if (!response.isComplete) {
  _pollForDetailedAnalysis(response.id);
}
```

**Step 3: 实现轮询函数**

```dart
Future<void> _pollForDetailedAnalysis(String analysisId) async {
  for (int i = 0; i < 30; i++) {
    await Future.delayed(const Duration(seconds: 1));

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/history?limit=1'),
        headers: {...},
      );

      final items = (response as List).cast<Map<String, dynamic>>();
      final item = items.firstWhereOrNull((i) => i['id'] == analysisId);

      if (item != null && item['result']['ingredients']?.isNotEmpty == true) {
        // 更新 UI 显示完整结果
        updateAnalysisResult(AnalysisHistoryItem.fromMap(item));
        return;
      }
    } catch (e) {
      debugPrint('Poll error: $e');
    }
  }
}
```

**Step 4: Commit**

```bash
git add lib/services/analysis_service.dart
git commit -m "feat(analysis-service): implement polling for detailed analysis"
```

---

## Chunk 5: 测试与验证

### Task 9: 集成测试

**Files:**
- Create: `apps/web/tests/analysis-streaming.test.ts`

**Step 1: 编写测试代码**

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { analyzeQuickMetrics } from '~/server/utils/analysis'

describe('Two-Stage Analysis', () => {
  it('should return quick metrics within 5 seconds', async () => {
    const ingredients = ['水', '糖', '香精', '食用油']
    const productName = '碳酸饮料'

    const startTime = Date.now()
    const result = await analyzeQuickMetrics(ingredients, productName)
    const duration = Date.now() - startTime

    expect(result).toBeDefined()
    expect(result.healthScore).toBeGreaterThanOrEqual(0)
    expect(result.healthScore).toBeLessThanOrEqual(10)
    expect(result.compliance.status).toMatch(/合规|不合规|待确认/)
    expect(result.processing.level).toBeDefined()
    expect(duration).toBeLessThan(5000) // 5 秒内完成
  })

  it('quick metrics should have all required fields', async () => {
    const ingredients = ['鸡蛋', '牛乳', '盐']
    const result = await analyzeQuickMetrics(ingredients, '蛋糕')

    expect(result.foodName).toBeTruthy()
    expect(result.healthScore).toBeGreaterThanOrEqual(0)
    expect(result.overallAssessment).toBeTruthy()
    expect(result.compliance).toHaveProperty('status')
    expect(result.compliance).toHaveProperty('description')
    expect(result.processing).toHaveProperty('level')
    expect(result.processing).toHaveProperty('score')
    expect(result.recommendations).toBeTruthy()
  })
})
```

**Step 2: 运行测试**

```bash
cd apps/web
npm run test tests/analysis-streaming.test.ts
```

**Expected:** 所有测试通过

**Step 3: Commit**

```bash
git add apps/web/tests/analysis-streaming.test.ts
git commit -m "test(analysis): add two-stage streaming tests"
```

---

### Task 10: 手动集成测试

**Files:** NA（手动测试）

**Step:**

1. 启动后端：
```bash
cd apps/web
npm run dev -- --port 3000
```

2. 启动前端（Nuxt）：在另一个终端中已启动的 3000 端口查看

3. 上传一张食品包装图片或输入配料文本

4. 验证：
   - ✓ 快速结果在 2-3 秒内显示
   - ✓ 健康评分、合规性、加工度立即展示
   - ✓ 配料列表显示"加载中"
   - ✓ 10-30 秒后配料详情逐步填充
   - ✓ Server-Timing 头显示 `stage: quick`
   - ✓ 数据库中 `quick_analysis_at` 有值，`detailed_analysis_at` 最终也有值

5. 验证 Flutter 客户端（如适用）：
```bash
flutter run
```
   - 上传图片并验证快速结果展示

**Step: Commit**

```bash
git add .
git commit -m "test: manual integration test for two-stage analysis - verified UI flow"
```

---

## Summary

**关键改动：**
1. ✓ 数据库字段：追踪 `quick_analysis_at` 和 `detailed_analysis_at`
2. ✓ AI 逻辑：拆分为 `analyzeQuickMetrics`（快速）和 `analyzeIngredients`（详细）
3. ✓ API 响应：从单次 JSON → `{ id, quick, isComplete }`
4. ✓ 后端异步：后台生成详细分析，主线程立即返回
5. ✓ 前端轮询：Nuxt/Flutter 异步轮询 `/api/history` 获取完整结果
6. ✓ UI 渐进：快速展示关键指标，配料列表显示加载态

**性能提升预期：**
- 首屏时间：从 ~30-60s（等待完整 AI 分析）→ 2-3s（快速指标）
- 总完成时间：保持不变（30-60s），但用户体验大幅提升

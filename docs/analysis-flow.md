# 图片分析链路说明

本文档基于当前代码整理 Flutter 端从上传图片开始，到 Nuxt 服务端 OCR、快速分析、详细分析、轮询返回的完整链路。内容对应 2026-04-02 当前实现，不是设计稿。

## 1. 入口与涉及文件

Flutter 入口:

- [lib/pages/camera_page.dart](/Users/bozhou/code/github/ingredient-detective/lib/pages/camera_page.dart)
- [lib/services/backend_api_service.dart](/Users/bozhou/code/github/ingredient-detective/lib/services/backend_api_service.dart)
- [lib/pages/analysis_result_page.dart](/Users/bozhou/code/github/ingredient-detective/lib/pages/analysis_result_page.dart)
- [lib/models/ingredient_analysis.dart](/Users/bozhou/code/github/ingredient-detective/lib/models/ingredient_analysis.dart)
- [lib/services/auth_service.dart](/Users/bozhou/code/github/ingredient-detective/lib/services/auth_service.dart)

Nuxt 服务端入口:

- [apps/web/server/api/analysis.post.ts](/Users/bozhou/code/github/ingredient-detective/apps/web/server/api/analysis.post.ts)
- [apps/web/server/api/analysis/[id].get.ts](/Users/bozhou/code/github/ingredient-detective/apps/web/server/api/analysis/[id].get.ts)
- [apps/web/server/utils/ocr.ts](/Users/bozhou/code/github/ingredient-detective/apps/web/server/utils/ocr.ts)
- [apps/web/server/utils/analysis.ts](/Users/bozhou/code/github/ingredient-detective/apps/web/server/utils/analysis.ts)
- [apps/web/server/utils/supabase.ts](/Users/bozhou/code/github/ingredient-detective/apps/web/server/utils/supabase.ts)
- [apps/web/shared/analysis.ts](/Users/bozhou/code/github/ingredient-detective/apps/web/shared/analysis.ts)

## 2. 总体流程

图片分析的真实链路如下：

1. Flutter 首页选择图片或拍照。
2. Flutter 读取当前 Supabase session，并把 `Authorization: Bearer <accessToken>` 带到 Nuxt 的 `POST /api/analysis`。
3. Nuxt 校验登录态。
4. 如果是图片上传，Nuxt 先调用阿里云 OCR 识别原始文字。
5. Nuxt 从 OCR 文本中提取配料行。
6. Nuxt 同时启动两个大模型任务：
   - 快速分析 `analyzeQuickMetrics(...)`
   - 详细分析 `analyzeIngredients(...)`
7. Nuxt 等待快速分析先完成，把快速结果写库并立即返回给 Flutter。
8. Flutter 先展示快速结果页面。
9. Nuxt 在后台继续跑详细分析，完成后更新数据库。
10. Flutter 用 `GET /api/analysis/:id` 轮询，拿到完整结果后刷新页面。

这里的关键点是：当前已经是“两阶段分析”。

- 第一阶段返回快结果
- 第二阶段后台补全详细配料分析

## 3. Flutter 端请求过程

### 3.1 图片入口

入口在 [camera_page.dart](/Users/bozhou/code/github/ingredient-detective/lib/pages/camera_page.dart)。

- `_pickImage(ImageSource source)` 决定是拍照还是从相册选图
- `_captureFromCameraPreview()` 处理预览拍照
- `_processImage(XFile image)` 真正发起分析

`_processImage(...)` 当前做了这几件事：

1. 从 `UserHealthProfileService` 读取用户健康档案
2. 调用 `BackendApiService.analyzeImage(...)`
3. 收到快结果后跳转到 `AnalysisResultPage`
4. 如果 OCR 没提取到配料，弹出手动输入对话框，走 `analyzeIngredientsText(...)`

### 3.2 Flutter 实际调用的接口

图片上传调用 [backend_api_service.dart](/Users/bozhou/code/github/ingredient-detective/lib/services/backend_api_service.dart) 中的：

- `analyzeImage(XFile image, { productName, userHealthProfile })`

它会发一个 `multipart/form-data` 请求到：

```text
POST /api/analysis
```

表单字段：

- `image`: 图片二进制
- `productName`: 可选
- `userHealthProfile`: 可选，JSON 字符串

请求头：

```text
Authorization: Bearer <supabase access token>
```

如果是手动输入配料，调用的是：

- `analyzeIngredientsText(String ingredientsText, { productName, userHealthProfile })`

它发送 JSON 到同一个接口：

```json
{
  "ingredientsText": "配料1, 配料2, 配料3",
  "productName": "可选商品名",
  "userHealthProfile": {
    "gender": "女",
    "heightCm": 165,
    "weightKg": 55,
    "healthConditions": ["高血压"]
  }
}
```

### 3.3 Flutter 端登录态校验

鉴权在 [auth_service.dart](/Users/bozhou/code/github/ingredient-detective/lib/services/auth_service.dart)。

当前请求前会调用：

- `getValidSession()`

逻辑是：

1. 先读本地 session
2. session 过期则尝试 refresh
3. 再调用 Supabase `getUser(accessToken)` 验证 token
4. 验证失败则清理登录态

这部分是为了解决之前出现的：

```text
401 Invalid Supabase session.
```

也就是说，如果这里 token 失效，分析链路在服务端入口就会直接失败，根本不会进入 OCR 或大模型分析。

## 4. `POST /api/analysis` 服务端链路

主入口在 [analysis.post.ts](/Users/bozhou/code/github/ingredient-detective/apps/web/server/api/analysis.post.ts)。

### 4.1 鉴权

接口开始先执行：

- `requireApiUser(event)`

位置在 [supabase.ts](/Users/bozhou/code/github/ingredient-detective/apps/web/server/utils/supabase.ts)。

逻辑：

1. 优先读 Nuxt 自己的 cookie 登录态
2. 如果没有 cookie，则读取 `Authorization: Bearer ...`
3. 调用 Supabase `auth.getUser(token)` 校验
4. 校验失败返回 `401 Invalid Supabase session.`

### 4.2 请求解析

`analysis.post.ts` 支持两种输入：

1. `multipart/form-data`
2. `application/json`

解析后的内部变量主要有：

- `productName`
- `sourceType`，取值 `image` 或 `manual`
- `imageFilename`
- `ingredientLines`
- `rawOcrText`
- `imageBuffer`
- `userHealthProfile`

### 4.3 图片转配料文本

如果请求里带的是图片，服务端会调用：

- `extractIngredientsFromImageBuffer(imageBuffer, timings)`

位置在 [ocr.ts](/Users/bozhou/code/github/ingredient-detective/apps/web/server/utils/ocr.ts)。

真实步骤：

1. 调阿里云 OCR `RecognizeGeneral`
2. 拿到 `rawText`
3. 用 `extractIngredientLines(rawText)` 提取配料项
4. 如果 OCR 有文字但严格提取失败，则再做一轮更宽松的文本拆分

当前 OCR 侧还保留了一些“配料提取规则”，例如：

- 识别配料区标题，如 `配料表`、`配料`
- 遇到 `营养成分表`、`保质期`、`生产日期` 等停止标记时跳过
- 用关键字、分隔符、token 清洗来识别可能的配料项

这部分不是营养判断硬编码，而是 OCR 文本清洗与配料切分规则。

如果最后 `ingredientLines.length === 0`，接口直接返回：

```text
422 Provide an ingredient list or upload a package image.
```

如果 OCR 没识别出任何有效文字，还可能直接返回：

```text
422 No ingredient text could be extracted from the image.
```

## 5. 大模型分析调用

模型调用封装在 [analysis.ts](/Users/bozhou/code/github/ingredient-detective/apps/web/server/utils/analysis.ts)。

### 5.1 模型提供方选择

当前根据环境变量自动选：

- `deepseek`
- `qwen`，通过 DashScope 兼容接口

优先顺序：

1. 如果 `LLM_PROVIDER=deepseek` 或配置了 `DEEPSEEK_API_KEY`，优先走 DeepSeek
2. 否则如果配置了 `DASHSCOPE_API_KEY`，走 Qwen

超时时间：

```text
REQUEST_TIMEOUT_MS = 90000
```

即单次 LLM 请求最多等 90 秒。

### 5.2 快速分析 prompt

快速分析函数：

- `analyzeQuickMetrics(ingredients, productName, userHealthProfile, timings)`

当前 `systemPrompt`：

```text
你是食品营养快速评估师。快速返回 JSON，格式如下，不包含逐项配料分析：
{
  "foodName": "食品类型",
  "healthScore": 0-10 数值,
  "overallAssessment": "一句话总体评价",
  "compliance": {"status": "合规/不合规/待确认", "description": "简述"},
  "processing": {"level": "轻/中/高", "score": 1-5},
  "recommendations": "一句建议"
}
```

当前 `userPrompt` 模板：

```text
快速评估产品 "${productName}" 的配料：${ingredients.join(', ')}。
${healthPrompt || '无额外用户健康信息。'}
如果未提供商品名称，请根据配料判断并返回一个准确、克制的食品名称或品类。
在 overallAssessment 和 recommendations 中体现个性化提醒（如控糖、控盐等）。只返回 JSON，无其他文本。
```

快速分析调用参数：

- `temperature: 0.2`
- `max_tokens: 400`

### 5.3 快速分析返回格式

服务端期望模型返回：

```json
{
  "foodName": "食品类型",
  "healthScore": 5,
  "overallAssessment": "一句话总体评价",
  "compliance": {
    "status": "合规",
    "description": "简述"
  },
  "processing": {
    "level": "高",
    "score": 4
  },
  "recommendations": "一句建议"
}
```

服务端收到后会校验至少这几个关键字段：

- `foodName`
- `healthScore`
- `processing.score`

### 5.4 详细分析 prompt

详细分析函数：

- `analyzeIngredients(ingredients, productName, userHealthProfile, timings)`

当前 `systemPrompt`：

```text
你是一个食品营养分析师。请分析配料并返回 JSON，格式如下：
{
  "foodName": "食品类型",
  "healthScore": 0-10 数值,
  "compliance": {"status": "合规/不合规/待确认", "description": "说明", "issues": []},
  "processing": {"level": "加工度", "description": "说明", "score": 1-5 数值},
  "claims": {"detectedClaims": [], "supportedClaims": [], "questionableClaims": [], "assessment": "评估"},
  "overallAssessment": "总体评价",
  "recommendations": "建议",
  "warnings": ["最多 3 条真正有用的提醒，聚焦负面影响和规避建议，没有就返回 []"],
  "ingredients": [{
    "ingredientName": "名称",
    "function": "作用",
    "nutritionalValue": "营养",
    "complianceStatus": "合规性",
    "processingLevel": "加工度",
    "remarks": "补充说明，没有可空字符串",
    "riskLevel": "normal/additive/caution",
    "riskReason": "为什么这样判断",
    "actionableAdvice": "针对用户可执行的建议，没有则空字符串",
    "negativeImpact": "可能的不良影响，没有则空字符串",
    "isAdditive": true
  }]
}
```

当前 `userPrompt` 模板：

```text
分析产品 "${productName}" 的配料：${ingredients.join(', ')}。
${healthPrompt || '无额外用户健康信息。'}
请从合规性、加工度、宣称三个维度分析，并结合用户背景给出个性化建议。
要求：
1. 不要用前端再猜测风险，必须为每个配料明确给出 riskLevel、riskReason、actionableAdvice、negativeImpact、isAdditive。
2. 如果某个配料属于食品添加剂，请将 isAdditive 设为 true，riskLevel 至少为 additive。
3. 如果某个配料可能带来额外健康负担、摄入风险、或不适合特定人群，请将 riskLevel 设为 caution，并写清 negativeImpact 与 actionableAdvice。
4. warnings 只保留真正有用的负面提醒与规避建议，最多 3 条；没有就返回空数组。
5. 请基于食品配料与食品添加剂的通行定义判断 isAdditive，不要仅凭“甜”“咸”“看起来像加工原料”做机械归类。
6. 如果未提供商品名称，请根据配料判断并返回一个准确、克制的食品名称或品类。
7. 所有字段都要简短直接：overallAssessment、recommendations、claims.assessment 控制在 50 字内；每个配料的 function、nutritionalValue、riskReason、actionableAdvice、negativeImpact 尽量控制在 30 字内。
8. 只返回一行紧凑 JSON，不要 markdown，不要代码块，不要注释，不要额外说明，不要在字符串里使用换行。
只返回 JSON。
```

详细分析调用参数：

- `temperature: 0.3`
- `max_tokens: 1200`

### 5.5 详细分析返回格式

服务端期望模型返回完整 `FoodAnalysisResult` 结构，核心部分如下：

```json
{
  "foodName": "巴氏杀菌热处理风味酸乳",
  "healthScore": 5,
  "compliance": {
    "status": "合规",
    "description": "符合GB标准，配料及过敏原标识清晰。",
    "issues": []
  },
  "processing": {
    "level": "高",
    "description": "含多种糖和添加剂，加工程度较高。",
    "score": 4
  },
  "claims": {
    "detectedClaims": [],
    "supportedClaims": [],
    "questionableClaims": [],
    "assessment": ""
  },
  "overallAssessment": "含糖和添加剂较多，营养价值一般。",
  "recommendations": "偶尔饮用即可，注意总糖摄入。",
  "warnings": ["如需控糖，建议减少同日甜食摄入"],
  "ingredients": [
    {
      "ingredientName": "白砂糖",
      "function": "提供甜味",
      "nutritionalValue": "提供能量",
      "complianceStatus": "合规使用",
      "processingLevel": "加工原料",
      "remarks": "",
      "riskLevel": "caution",
      "riskReason": "添加糖较多时增加控糖负担",
      "actionableAdvice": "控糖人群减少摄入频次",
      "negativeImpact": "过量摄入增加能量和糖负担",
      "isAdditive": false
    }
  ]
}
```

服务端目前至少要求：

- `foodName` 非空
- `ingredients` 非空

否则判定详细分析失败。

## 6. 两阶段返回与数据库写入

### 6.1 为什么接口会先返回一部分

在 [analysis.post.ts](/Users/bozhou/code/github/ingredient-detective/apps/web/server/api/analysis.post.ts) 中，当前代码会先启动详细分析：

```ts
const detailedAnalysisPromise = analyzeIngredients(...)
```

然后再执行快速分析：

```ts
const quick = await analyzeQuickMetrics(...)
```

这样做的目的不是等详细分析完成，而是让详细分析尽早开始跑。

### 6.2 快速结果先写库

快速分析完成后，服务端会先把以下结构写进 `analysis_results.result`：

```json
{
  "foodName": "...",
  "ingredients": [],
  "healthScore": 5,
  "compliance": {
    "status": "...",
    "description": "...",
    "issues": []
  },
  "processing": {
    "level": "...",
    "description": "",
    "score": 4
  },
  "claims": {
    "detectedClaims": [],
    "supportedClaims": [],
    "questionableClaims": [],
    "assessment": ""
  },
  "overallAssessment": "...",
  "recommendations": "...",
  "warnings": [],
  "detailedStatus": "pending",
  "detailedError": "",
  "analysisTime": "2026-04-02T..."
}
```

然后 `POST /api/analysis` 立即返回：

```json
{
  "id": "891f3619-49be-4aca-8d7c-3f28ff14d105",
  "quick": {
    "foodName": "巴氏杀菌热处理风味酸乳",
    "healthScore": 5,
    "overallAssessment": "含多种添加剂和糖的加工乳制品，营养价值一般。",
    "compliance": {
      "status": "合规",
      "description": "符合GB标准，配料及过敏原标识清晰。"
    },
    "processing": {
      "level": "高",
      "score": 4
    },
    "recommendations": "建议作为偶尔的零食，注意糖分摄入。"
  },
  "isComplete": false
}
```

这就是你之前看到“接口已经返回了数据，但页面只显示一部分”的根本原因：这个响应本身就只包含 `quick`，不包含详细配料数组。

### 6.3 详细分析后台补写

后台通过：

```ts
event.waitUntil(generateDetailedAnalysisInBackground(...))
```

继续执行详细分析。

成功时把数据库更新为：

- `detailedStatus: "complete"`
- `detailedError: ""`
- `result.ingredients`: 完整详细配料分析

失败时把数据库更新为：

- `detailedStatus: "failed"`
- `detailedError: "<错误信息>"`
- 其他字段保留快照

## 7. Flutter 端如何拿到详细结果

页面在 [analysis_result_page.dart](/Users/bozhou/code/github/ingredient-detective/lib/pages/analysis_result_page.dart)。

### 7.1 初始展示

Flutter 从 `POST /api/analysis` 收到的只是快结果，所以会先构造一个本地对象：

- `ingredients = []`
- `detailedStatus = 'pending'`
- `analysisId = 返回的 id`

因此刚进入结果页时，页面能显示：

- 食品名称
- 健康评分
- 合规状态
- 加工程度
- 总体评价

但还没有逐项配料详情。

### 7.2 轮询条件

当前满足以下条件才会轮询：

1. 不是从历史页进入
2. `detailedStatus != 'failed'`
3. 当前 `ingredients` 为空
4. `analysisId` 非空

### 7.3 轮询接口

Flutter 调用：

```text
GET /api/analysis/:id
```

服务端返回单条历史记录，核心字段：

```json
{
  "id": "analysis-id",
  "result": {
    "...": "...",
    "ingredients": [],
    "detailedStatus": "pending",
    "detailedError": ""
  },
  "isComplete": false
}
```

当详细分析完成后，`result.ingredients` 会变成非空。

当详细分析失败后，`detailedStatus` 会变成 `failed`。

### 7.4 当前轮询策略

当前 Flutter 端轮询配置：

- 间隔：1 秒
- 最大次数：90 次

也就是最多轮询约 90 秒。

停止条件：

1. `ingredients` 非空
2. `detailedStatus == 'failed'`
3. 到达最大轮询次数

## 8. 为什么“调用成功了，还是很慢”

当前慢，主要不是一个点，而是三个点叠加。

### 8.1 图片链路天然多一步 OCR

图片上传不是直接进大模型，而是：

1. 上传图片
2. 调阿里云 OCR
3. OCR 文本切配料
4. 再调大模型

所以图片链路一定比“手动输入配料文本”更慢。

### 8.2 详细分析 prompt 很重

详细分析要求模型输出：

- 总体评价
- 合规性
- 加工程度
- 宣称分析
- warnings
- 每一个配料的结构化字段
- 个性化建议

而且返回必须是严格 JSON。

这比只给一个 Markdown 段落更慢，也更容易失败。

### 8.3 当前实际主故障是“模型返回非法 JSON”

今天本地运行日志已经出现过这条错误：

```text
Detailed analysis failed: Expected ',' or ']' after array element in JSON at position 5577 (line 144 column 10)
```

这说明服务端不是单纯“等很久”，而是：

1. 已经等了较长时间
2. 模型最终返回了格式错误的 JSON
3. 服务端 `JSON.parse(...)` 失败
4. 详细分析被标记为 `failed`

同一次排查中，快速阶段约 9.3 秒完成，详细阶段在约 56 秒后失败。

所以你看到的“很久没有结果”，其中一部分其实是失败前的长等待，而不是最终一定会成功。

## 9. 当前已做过的修正

目前代码里已经有这些修正：

1. 详细分析改为和快速分析并行启动，不再完全串行等待
2. 后台详细分析通过 `event.waitUntil(...)` 执行，不阻塞首个响应
3. Flutter 端进入结果页后立即开始轮询，不再额外等待 2 秒
4. 轮询频率改为 1 秒一次
5. Flutter 请求前会验证并尽量刷新 Supabase session，减少 `401 Invalid Supabase session`
6. 数据库里增加 `detailedStatus` 和 `detailedError`，可以区分“仍在生成”和“已经失败”
7. 详细分析 prompt 已经收紧，并把 `max_tokens` 从更高值降到 `1200`

这些修正解决了“页面一直傻等不知道失败了”的问题，但还没有从根上解决“详细 JSON 容易生成失败”的问题。

## 10. 当前最值得优先优化的点

如果后面继续优化，建议按这个优先级处理：

1. 把详细分析改成真正的结构化输出模式，而不是让模型自由生成 JSON 字符串后再 `JSON.parse`
2. 适当拆分详细任务，避免一次性输出过大的 `ingredients` 数组
3. 针对长配料表增加截断或分段分析策略
4. 对详细分析失败增加明确重试机制，而不是只靠前端轮询
5. 把 OCR 原文、提取后的配料、快分析、详分析耗时统一记录到可查看日志中

其中第 1 条最关键。当前最大问题不是“前端没显示”，而是“后端详细分析经常拿不到可解析的结构化结果”。

## 11. 一句话总结

当前系统的真实行为是：

- `POST /api/analysis` 只保证先返回快速结果
- 详细配料分析依赖后台异步大模型任务
- Flutter 页面是否能显示完整详情，取决于后续 `GET /api/analysis/:id` 轮询时数据库里是否已经写入完整结果
- 现在详细阶段慢和失败的核心瓶颈，是大模型要生成较大的严格 JSON，且当前仍存在返回非法 JSON 的情况

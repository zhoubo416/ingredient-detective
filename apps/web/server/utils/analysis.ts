import type {
  ClaimsAnalysis,
  ComplianceAnalysis,
  FoodAnalysisResult,
  IngredientAnalysis,
  ProcessingAnalysis,
  QuickAnalysisResult
} from '~/shared/analysis'
import { useRuntimeConfig } from '#imports'
import type { TimingMap } from '~/server/utils/timing'
import { recordTiming } from '~/server/utils/timing'

const REQUEST_TIMEOUT_MS = 90_000
const DASHSCOPE_BASE_URL = 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions'
const DEEPSEEK_BASE_URL = 'https://api.deepseek.com/v1/chat/completions'

interface LlmConfig {
  apiKey: string
  model: string
  provider: 'qwen' | 'deepseek'
  url: string
}

export interface UserHealthProfileContext {
  gender?: string
  heightCm?: number
  weightKg?: number
  healthConditions?: string[]
}

type PartialFoodAnalysisResult = Partial<FoodAnalysisResult> & {
  ingredients?: unknown
  compliance?: Partial<ComplianceAnalysis> | null
  processing?: Partial<ProcessingAnalysis> | null
  claims?: Partial<ClaimsAnalysis> | null
}

function createTimeoutSignal() {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS)

  return {
    signal: controller.signal,
    clear: () => clearTimeout(timeout)
  }
}

function buildUserHealthContextPrompt(profile?: UserHealthProfileContext | null) {
  if (!profile) {
    return ''
  }

  const lines: string[] = []

  if (profile.gender?.trim()) {
    lines.push(`- 性别: ${profile.gender.trim()}`)
  }
  if (typeof profile.heightCm === 'number' && profile.heightCm > 0) {
    lines.push(`- 身高: ${profile.heightCm} cm`)
  }
  if (typeof profile.weightKg === 'number' && profile.weightKg > 0) {
    lines.push(`- 体重: ${profile.weightKg} kg`)
  }
  if (Array.isArray(profile.healthConditions) && profile.healthConditions.length > 0) {
    lines.push(`- 既往健康情况: ${profile.healthConditions.join('、')}`)
  }

  if (lines.length === 0) {
    return ''
  }

  return `以下是用户健康背景，请在评估中给出个性化饮食提醒（使用“建议/可能/需注意”，不要做医疗诊断）：\n${lines.join('\n')}`
}

function normalizeIngredientEntry(entry: unknown): IngredientAnalysis | null {
  if (typeof entry === 'string') {
    const ingredientName = entry.trim()
    if (!ingredientName) {
      return null
    }

    return {
      ingredientName,
      function: '',
      nutritionalValue: '',
      complianceStatus: '',
      processingLevel: '',
      remarks: '',
      riskLevel: 'normal',
      riskReason: '',
      actionableAdvice: '',
      negativeImpact: '',
      isAdditive: false
    }
  }

  if (!entry || typeof entry !== 'object') {
    return null
  }

  const candidate = entry as Record<string, unknown>
  const ingredientName = String(
    candidate.ingredientName
    ?? candidate.name
    ?? candidate.ingredient
    ?? candidate.title
    ?? ''
  ).trim()

  if (!ingredientName) {
    return null
  }

  return {
    ingredientName,
    function: String(candidate.function ?? candidate.role ?? '').trim(),
    nutritionalValue: String(candidate.nutritionalValue ?? candidate.nutrition ?? '').trim(),
    complianceStatus: String(candidate.complianceStatus ?? candidate.compliance ?? candidate.status ?? '').trim(),
    processingLevel: String(candidate.processingLevel ?? candidate.processing ?? candidate.level ?? '').trim(),
    remarks: String(candidate.remarks ?? candidate.note ?? candidate.notes ?? '').trim(),
    riskLevel: normalizeRiskLevel(candidate.riskLevel ?? candidate.risk_level),
    riskReason: String(candidate.riskReason ?? candidate.risk_reason ?? '').trim(),
    actionableAdvice: String(candidate.actionableAdvice ?? candidate.actionable_advice ?? candidate.advice ?? '').trim(),
    negativeImpact: String(candidate.negativeImpact ?? candidate.negative_impact ?? '').trim(),
    isAdditive: typeof candidate.isAdditive === 'boolean'
      ? candidate.isAdditive
      : typeof candidate.is_additive === 'boolean'
        ? candidate.is_additive
        : false
  }
}

function normalizeIngredientRecords(input: unknown) {
  if (Array.isArray(input)) {
    return input
      .map(entry => normalizeIngredientEntry(entry))
      .filter((entry): entry is IngredientAnalysis => Boolean(entry))
  }

  return []
}

export function normalizeFoodAnalysisResult(
  input: unknown,
  _ingredientLines: string[],
  fallback: {
    foodName?: string
    healthScore?: number
    analysisTime?: string
  } = {}
): FoodAnalysisResult {
  const data = input && typeof input === 'object'
    ? input as PartialFoodAnalysisResult
    : {}

  return {
    foodName: typeof data.foodName === 'string' && data.foodName.trim()
      ? data.foodName
      : fallback.foodName ?? '',
    ingredients: normalizeIngredientRecords(data.ingredients),
    healthScore: typeof data.healthScore === 'number'
      ? data.healthScore
      : fallback.healthScore ?? 0,
    compliance: {
      status: typeof data.compliance?.status === 'string' ? data.compliance.status : '',
      description: typeof data.compliance?.description === 'string' ? data.compliance.description : '',
      issues: Array.isArray(data.compliance?.issues)
        ? data.compliance.issues.map(item => String(item).trim()).filter(Boolean)
        : []
    },
    processing: {
      level: typeof data.processing?.level === 'string' ? data.processing.level : '',
      description: typeof data.processing?.description === 'string' ? data.processing.description : '',
      score: typeof data.processing?.score === 'number' ? data.processing.score : 0
    },
    claims: {
      detectedClaims: Array.isArray(data.claims?.detectedClaims)
        ? data.claims.detectedClaims.map(item => String(item).trim()).filter(Boolean)
        : [],
      supportedClaims: Array.isArray(data.claims?.supportedClaims)
        ? data.claims.supportedClaims.map(item => String(item).trim()).filter(Boolean)
        : [],
      questionableClaims: Array.isArray(data.claims?.questionableClaims)
        ? data.claims.questionableClaims.map(item => String(item).trim()).filter(Boolean)
        : [],
      assessment: typeof data.claims?.assessment === 'string' ? data.claims.assessment : ''
    },
    overallAssessment: typeof data.overallAssessment === 'string' ? data.overallAssessment : '',
    recommendations: typeof data.recommendations === 'string' ? data.recommendations : '',
    warnings: Array.isArray((data as FoodAnalysisResult).warnings)
      ? (data as FoodAnalysisResult).warnings.map(item => String(item).trim()).filter(Boolean)
      : [],
    detailedStatus: data.detailedStatus === 'complete' || data.detailedStatus === 'failed'
      ? data.detailedStatus
      : 'pending',
    detailedError: typeof data.detailedError === 'string' ? data.detailedError : '',
    analysisTime: typeof data.analysisTime === 'string'
      ? data.analysisTime
      : fallback.analysisTime ?? new Date(0).toISOString(),
    rawMarkdown: typeof (data as Record<string, unknown>).rawMarkdown === 'string'
      ? (data as Record<string, unknown>).rawMarkdown as string
      : ''
  }
}

function normalizeRiskLevel(value: unknown): IngredientAnalysis['riskLevel'] {
  const text = String(value ?? '').trim().toLowerCase()
  if (text === 'additive' || text === 'caution') {
    return text
  }
  return 'normal'
}

function extractJsonObject(response: string) {
  const jsonStart = response.indexOf('{')
  const jsonEnd = response.lastIndexOf('}') + 1

  if (jsonStart === -1 || jsonEnd <= jsonStart) {
    throw new Error('Model response does not contain valid JSON')
  }

  return JSON.parse(response.slice(jsonStart, jsonEnd)) as Record<string, unknown>
}

function parseQuickAnalysisResult(response: string) {
  const data = extractJsonObject(response)
  const healthScore = typeof data.healthScore === 'number'
    ? data.healthScore
    : Number(data.healthScore)
  const processingScore = data.processing && typeof data.processing === 'object' && typeof (data.processing as Record<string, unknown>).score === 'number'
    ? (data.processing as Record<string, unknown>).score as number
    : Number((data.processing as Record<string, unknown> | undefined)?.score)

  const foodName = String(data.foodName ?? '').trim()
  if (!foodName) {
    throw new Error('Quick analysis response is missing foodName')
  }
  if (!Number.isFinite(healthScore)) {
    throw new Error('Quick analysis response is missing healthScore')
  }
  if (!Number.isFinite(processingScore)) {
    throw new Error('Quick analysis response is missing processing.score')
  }

  const compliance = data.compliance && typeof data.compliance === 'object'
    ? data.compliance as Record<string, unknown>
    : {}
  const processing = data.processing && typeof data.processing === 'object'
    ? data.processing as Record<string, unknown>
    : {}

  return {
    foodName,
    healthScore,
    overallAssessment: String(data.overallAssessment ?? '').trim(),
    compliance: {
      status: String(compliance.status ?? '').trim(),
      description: String(compliance.description ?? '').trim()
    },
    processing: {
      level: String(processing.level ?? '').trim(),
      score: processingScore
    },
    recommendations: String(data.recommendations ?? '').trim()
  } satisfies QuickAnalysisResult
}

function parseDetailedAnalysisResult(response: string, ingredientLines: string[]) {
  const data = extractJsonObject(response)
  const result = normalizeFoodAnalysisResult(data, ingredientLines)

  if (!result.foodName.trim()) {
    throw new Error('Detailed analysis response is missing foodName')
  }
  if (!result.ingredients.length) {
    throw new Error('Detailed analysis response is missing ingredients')
  }

  return result
}

function parseDetailedMarkdownAnalysis(markdown: string, ingredientLines: string[]) {
  console.info('[parse-start]', {
    markdownLength: markdown.length,
    ingredientCount: ingredientLines.length,
    ingredientNames: ingredientLines
  })

  const lines = markdown.split('\n')
  console.info('[parse-lines-count]', { linesCount: lines.length })

  let foodName = ''
  let healthScore = 5
  let complianceStatus = '待确认'
  let processingLevel = '未知'
  let overallAssessment = ''
  let recommendations = ''
  let claimsAssessment = ''

  // 提取基本信息
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim()

    // 产品名称 (# 开头，第一个)
    if (line.startsWith('# ') && !foodName) {
      foodName = line.substring(2).trim()
      console.info('[parse-found-foodname]', { foodName })
    }

    // 总体评分部分
    if (line.includes('健康评分')) {
      const match = line.match(/(\d+)/)
      if (match) {
        healthScore = Math.min(10, Math.max(0, parseInt(match[1])))
        console.info('[parse-found-health-score]', { healthScore })
      }
    }
    if (line.includes('合规性:')) {
      const match = line.match(/合规性:\s*(.+?)(?:\n|$)/)
      if (match) {
        complianceStatus = match[1].trim()
        console.info('[parse-found-compliance]', { complianceStatus })
      }
    }
    if (line.includes('加工度:') && !line.includes('###')) {
      const match = line.match(/加工度:\s*(.+?)(?:\n|$)/)
      if (match) {
        processingLevel = match[1].trim()
        console.info('[parse-found-processing-level]', { processingLevel })
      }
    }
    if (line.includes('总体评价:')) {
      const match = line.match(/总体评价:\s*(.+?)(?:\n|$)/)
      if (match) {
        overallAssessment = match[1].trim().substring(0, 100)
        console.info('[parse-found-assessment]', { overallAssessment })
      }
    }
    if (line.includes('建议:') && !line.includes('###')) {
      const match = line.match(/建议:\s*(.+?)(?:\n|$)/)
      if (match) {
        recommendations = match[1].trim().substring(0, 100)
        console.info('[parse-found-recommendations]', { recommendations })
      }
    }
  }

  // 提取配料信息
  const ingredients: IngredientAnalysis[] = []

  for (const ingredientName of ingredientLines) {
    const normalizedName = ingredientName.trim()
    if (!normalizedName) continue

    console.info('[parse-ingredient-start]', { ingredientName: normalizedName })

    // 在 Markdown 中查找这个配料的标题 (### 或 ## 开头)
    let ingredientStartIdx = -1
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim()
      if ((line.startsWith('### ') || line.startsWith('## ')) &&
          line.toLowerCase().includes(normalizedName.toLowerCase())) {
        ingredientStartIdx = i
        console.info('[parse-found-ingredient-title]', { index: i, line })
        break
      }
    }

    // 如果找不到标题，在内容中查找配料名
    if (ingredientStartIdx < 0) {
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].toLowerCase().includes(normalizedName.toLowerCase())) {
          ingredientStartIdx = i
          console.info('[parse-found-ingredient-content]', { index: i, line: lines[i] })
          break
        }
      }
    }

    // 提取该配料的详细信息
    let function_ = ''
    let nutritionalValue = ''
    let complianceStatus_ = ''
    let processingLevel_ = ''
    let riskLevel: 'normal' | 'additive' | 'caution' = 'normal'
    let riskReason = ''
    let negativeImpact = ''
    let actionableAdvice = ''
    let isAdditive = false

    if (ingredientStartIdx >= 0) {
      const contextStart = ingredientStartIdx
      const contextEnd = Math.min(ingredientStartIdx + 15, lines.length)

      console.info('[parse-ingredient-context-range]', { start: contextStart, end: contextEnd })

      for (let i = contextStart; i < contextEnd; i++) {
        const line = lines[i].trim()

        // 停止条件：遇到下一个配料或章节
        if (i > ingredientStartIdx && (line.startsWith('###') || line.startsWith('##'))) {
          console.info('[parse-ingredient-context-end]', { atLine: i })
          break
        }

        // 提取字段
        if (line.includes('作用:')) {
          const match = line.match(/作用:\s*(.+?)(?:\n|$)/)
          if (match) {
            function_ = match[1].trim().substring(0, 40)
            console.info('[parse-ingredient-function]', { function: function_ })
          }
        }
        if (line.includes('营养价值:')) {
          const match = line.match(/营养价值:\s*(.+?)(?:\n|$)/)
          if (match) {
            nutritionalValue = match[1].trim().substring(0, 40)
            console.info('[parse-ingredient-nutrition]', { nutritionalValue })
          }
        }
        if (line.includes('合规性:')) {
          const match = line.match(/合规性:\s*(.+?)(?:\n|$)/)
          if (match) {
            complianceStatus_ = match[1].trim().substring(0, 30)
            console.info('[parse-ingredient-compliance]', { compliance: complianceStatus_ })
          }
        }
        if (line.includes('加工度:')) {
          const match = line.match(/加工度:\s*(.+?)(?:\n|$)/)
          if (match) {
            processingLevel_ = match[1].trim().substring(0, 30)
            console.info('[parse-ingredient-processing]', { processing: processingLevel_ })
          }
        }
        if (line.includes('风险等级:')) {
          const match = line.match(/风险等级:\s*(.+?)(?:\n|$)/)
          if (match) {
            const level = match[1].trim().toLowerCase()
            if (level.includes('添加剂')) {
              riskLevel = 'additive'
              isAdditive = true
            } else if (level.includes('需关注')) {
              riskLevel = 'caution'
            } else {
              riskLevel = 'normal'
            }
            console.info('[parse-ingredient-risk-level]', { riskLevel, originalText: match[1].trim() })
          }
        }
        if (line.includes('风险说明:')) {
          const match = line.match(/风险说明:\s*(.+?)(?:\n|$)/)
          if (match) {
            riskReason = match[1].trim().substring(0, 40)
            console.info('[parse-ingredient-risk-reason]', { riskReason })
          }
        }
        if (line.includes('不良影响:')) {
          const match = line.match(/不良影响:\s*(.+?)(?:\n|$)/)
          if (match) {
            negativeImpact = match[1].trim().substring(0, 40)
            console.info('[parse-ingredient-negative-impact]', { negativeImpact })
          }
        }
        if (line.includes('建议:')) {
          const match = line.match(/建议:\s*(.+?)(?:\n|$)/)
          if (match) {
            actionableAdvice = match[1].trim().substring(0, 40)
            console.info('[parse-ingredient-advice]', { actionableAdvice })
          }
        }
      }
    } else {
      console.warn('[parse-ingredient-not-found]', { ingredientName: normalizedName })
    }

    const ingredient: IngredientAnalysis = {
      ingredientName: normalizedName,
      function: function_,
      nutritionalValue,
      complianceStatus: complianceStatus_,
      processingLevel: processingLevel_,
      remarks: '',
      riskLevel,
      riskReason,
      actionableAdvice,
      negativeImpact,
      isAdditive
    }

    console.info('[parse-ingredient-complete]', {
      name: normalizedName,
      hasFunction: !!function_.trim(),
      function: function_,
      riskLevel,
      isAdditive
    })

    ingredients.push(ingredient)
  }

  console.info('[parse-markdown-complete]', {
    ingredientCount: ingredients.length,
    withFunctions: ingredients.filter(i => i.function.trim()).length,
    foodName
  })

  return {
    foodName: foodName.trim() || '未知食品',
    healthScore: Number.isFinite(healthScore) ? healthScore : 5,
    compliance: {
      status: complianceStatus,
      description: '',
      issues: []
    },
    processing: {
      level: processingLevel,
      description: '',
      score: 3
    },
    claims: {
      detectedClaims: [],
      supportedClaims: [],
      questionableClaims: [],
      assessment: claimsAssessment.trim()
    },
    overallAssessment: overallAssessment.trim(),
    recommendations: recommendations.trim(),
    ingredients,
    detailedStatus: 'complete' as const,
    detailedError: '',
    warnings: [],
    analysisTime: new Date().toISOString()
  } satisfies FoodAnalysisResult
}

function buildRequestBody(
  llm: LlmConfig,
  messages: Array<{ role: string; content: string }>,
  temperature: number,
  maxTokens: number,
  useJsonMode: boolean = true
) {
  const baseBody = {
    model: llm.model,
    temperature,
    max_tokens: maxTokens,
    messages
  } as Record<string, unknown>

  // 为支持的模型添加 response_format
  if (useJsonMode) {
    if (llm.provider === 'deepseek') {
      // DeepSeek 支持 JSON 对象格式
      baseBody.response_format = {
        type: 'json_object'
      }
    } else if (llm.provider === 'qwen') {
      // Qwen/DashScope 使用字符串格式
      baseBody.response_format = 'json'
    }
  }

  return baseBody
}

function resolveLlmConfig() {
  const config = useRuntimeConfig()
  const preferredProvider = String(config.llmProvider || '').trim().toLowerCase()
  const configuredModel = String(config.llmModel || '').trim()

  if ((preferredProvider === 'deepseek' || (!preferredProvider && config.deepseekApiKey)) && config.deepseekApiKey) {
    return {
      provider: 'deepseek',
      apiKey: config.deepseekApiKey,
      model: configuredModel || 'deepseek-chat',
      url: DEEPSEEK_BASE_URL
    } satisfies LlmConfig
  }

  if (config.dashscopeApiKey) {
    return {
      provider: 'qwen',
      apiKey: config.dashscopeApiKey,
      model: configuredModel || 'qwen-plus',
      url: DASHSCOPE_BASE_URL
    } satisfies LlmConfig
  }

  return null
}

export async function analyzeQuickMetrics(
  ingredients: string[],
  productName: string,
  userHealthProfile?: UserHealthProfileContext | null,
  timings?: TimingMap
): Promise<QuickAnalysisResult> {
  const llm = resolveLlmConfig()

  if (!llm) {
    throw new Error('LLM is not configured')
  }

  const systemPrompt = `你是食品营养快速评估师。必须返回有效的 JSON 对象格式，json 格式如下，不包含逐项配料分析：
{
  "foodName": "食品类型",
  "healthScore": 0-10 数值,
  "overallAssessment": "一句话总体评价",
  "compliance": {"status": "合规/不合规/待确认", "description": "简述"},
  "processing": {"level": "轻/中/高", "score": 1-5},
  "recommendations": "一句建议"
}`

  const healthPrompt = buildUserHealthContextPrompt(userHealthProfile)
  const userPrompt = `快速评估产品 "${productName}" 的配料：${ingredients.join(', ')}。
${healthPrompt || '无额外用户健康信息。'}
如果未提供商品名称，请根据配料判断并返回一个准确、克制的食品名称或品类。
在 overallAssessment 和 recommendations 中体现个性化提醒（如控糖、控盐等）。只返回 JSON，无其他文本。`

  const { signal, clear } = createTimeoutSignal()

  try {
    const requestStartedAt = Date.now()
    const requestBody = buildRequestBody(
      llm,
      [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      0.2,
      400,
      true  // 启用 JSON 模式
    )

    console.info('[ai-quick-request]', JSON.stringify({
      provider: llm.provider,
      model: llm.model,
      hasResponseFormat: 'response_format' in requestBody,
      responseFormat: requestBody.response_format
    }))

    const response = await fetch(llm.url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${llm.apiKey}`
      },
      body: JSON.stringify(requestBody),
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

    return parseQuickAnalysisResult(content)
  } catch (error) {
    throw new Error(`Quick analysis failed: ${error instanceof Error ? error.message : String(error)}`)
  } finally {
    clear()
  }
}

export async function analyzeIngredients(
  ingredients: string[],
  productName: string,
  userHealthProfile?: UserHealthProfileContext | null,
  timings?: TimingMap
) {
  const llm = resolveLlmConfig()

  if (!llm) {
    throw new Error('LLM is not configured')
  }

  const systemPrompt = `你是一个食品营养分析师。请用 Markdown 格式分析配料，遵循以下结构：

## 配料名称
- 作用: [配料的作用，20-30字]
- 营养价值: [营养价值或无]
- 合规性: ✅ 合规 / ⚠️ 待确认 / ❌ 不合规（根据实际情况选一个）
- 加工度: ⚙️ 低 / 🔧 中 / 🏭 高（根据实际情况选一个）
- 风险等级: ✅ 正常 [说明，30字内] / ⚠️ 添加剂 [说明，30字内] / 🚨 需关注 [说明，30字内]（根据实际情况选一个）
- 不良影响: 💚 无 / 💛 [轻微影响，30字内] / ❤️ [明显影响，30字内]（根据实际情况选一个）
- 建议提醒: 💡 [建议提醒，30字内或无]

[为每个配料重复上面的格式]

`

  const healthPrompt = buildUserHealthContextPrompt(userHealthProfile)
  const userPrompt = `分析产品 “${productName}” 的配料：${ingredients.join(', ')}。
${healthPrompt || '无额外用户健康信息。'}

【重要】
- 只分析上面列出的真实配料，忽略产品标准号、生产许可证等非配料内容
- **必须为每个配料提供完整的作用分析**（不能为空或”未知”）
  - 如”小麦粉”→”提供碳水化合物和能量”
  - 如”食盐”→”调味和防腐作用”
- 按上面的 Markdown 格式输出，每个配料都要有所有字段
- 根据配料推断产品名称（如未提供）`

  const { signal, clear } = createTimeoutSignal()

  try {
    console.info('[detailed-analysis-start]', {
      ingredientCount: ingredients.length,
      productName,
      ingredients: ingredients.join(', ')
    })

    const requestStartedAt = Date.now()
    const requestBody = buildRequestBody(
      llm,
      [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      0.3,
      3000,  // 增加到 3000 tokens，足够所有配料详细分析
      false  // 详细分析使用 Markdown 格式，不启用 JSON 模式
    )

    console.info('[llm-request-params]', {
      provider: llm.provider,
      model: llm.model,
      messages: [
        { role: 'system', contentLength: systemPrompt.length },
        { role: 'user', contentLength: userPrompt.length }
      ],
      temperature: 0.3,
      maxTokens: 3000,
      url: llm.url
    })

    console.info('[llm-system-prompt]', systemPrompt)
    console.info('[llm-user-prompt]', userPrompt)

    const response = await fetch(llm.url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${llm.apiKey}`
      },
      body: JSON.stringify(requestBody),
      signal
    })
    recordTiming(timings ?? {}, 'ai.fetch', Date.now() - requestStartedAt, {
      provider: llm.provider,
      model: llm.model,
      ingredientCount: ingredients.length,
      promptChars: systemPrompt.length + userPrompt.length
    })

    const parseStartedAt = Date.now()
    const payload = await response.json() as {
      choices?: Array<{ message?: { content?: string } }>
    }
    recordTiming(timings ?? {}, 'ai.read_response', Date.now() - parseStartedAt)

    console.info('[llm-response-status]', {
      status: response.status,
      statusText: response.statusText,
      ok: response.ok
    })

    if (!response.ok) {
      console.error('[llm-response-error]', JSON.stringify(payload))
      throw new Error(`Detailed analysis API error: ${response.status}`)
    }

    const content = payload.choices?.[0]?.message?.content
    if (!content) {
      console.error('[llm-response-empty]', { payload })
      throw new Error('Detailed analysis response is empty')
    }

    console.info('[llm-response-content-length]', { contentLength: content.length })
    console.info('[llm-response-content]', content.substring(0, 2000))
    console.info('[llm-response-content-full]', content)

    // 直接返回原始 Markdown，不进行任何处理
    const normalizeStartedAt = Date.now()
    recordTiming(timings ?? {}, 'ai.parse_markdown', Date.now() - normalizeStartedAt, {
      contentChars: content.length
    })

    console.info('[detailed-analysis-raw-markdown]', {
      contentLength: content.length,
      preview: content.substring(0, 200)
    })

    return {
      foodName: '',
      ingredients: [],
      healthScore: 0,
      compliance: { status: '', description: '', issues: [] },
      processing: { level: '', description: '', score: 0 },
      claims: { detectedClaims: [], supportedClaims: [], questionableClaims: [], assessment: '' },
      overallAssessment: '',
      recommendations: '',
      warnings: [],
      detailedStatus: 'complete' as const,
      detailedError: '',
      analysisTime: new Date().toISOString(),
      // 直接返回原始 Markdown
      rawMarkdown: content
    } satisfies FoodAnalysisResult & { rawMarkdown: string }
  } catch (error) {
    console.error('[detailed-analysis-error]', {
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined
    })
    throw new Error(`Detailed analysis failed: ${error instanceof Error ? error.message : String(error)}`)
  } finally {
    clear()
  }
}

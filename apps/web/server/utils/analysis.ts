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
    analysisTime: typeof data.analysisTime === 'string'
      ? data.analysisTime
      : fallback.analysisTime ?? new Date(0).toISOString()
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

  const systemPrompt = `你是食品营养快速评估师。快速返回 JSON，格式如下，不包含逐项配料分析：
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

  const systemPrompt = `你是一个食品营养分析师。请分析配料并返回 JSON，格式如下：
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
}`

  const healthPrompt = buildUserHealthContextPrompt(userHealthProfile)
  const userPrompt = `分析产品 "${productName}" 的配料：${ingredients.join(', ')}。
${healthPrompt || '无额外用户健康信息。'}
请从合规性、加工度、宣称三个维度分析，并结合用户背景给出个性化建议。
要求：
1. 不要用前端再猜测风险，必须为每个配料明确给出 riskLevel、riskReason、actionableAdvice、negativeImpact、isAdditive。
2. 如果某个配料属于食品添加剂，请将 isAdditive 设为 true，riskLevel 至少为 additive。
3. 如果某个配料可能带来额外健康负担、摄入风险、或不适合特定人群，请将 riskLevel 设为 caution，并写清 negativeImpact 与 actionableAdvice。
4. warnings 只保留真正有用的负面提醒与规避建议，最多 3 条；没有就返回空数组。
5. 请基于食品配料与食品添加剂的通行定义判断 isAdditive，不要仅凭“甜”“咸”“看起来像加工原料”做机械归类。
6. 如果未提供商品名称，请根据配料判断并返回一个准确、克制的食品名称或品类。
只返回 JSON。`

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
        temperature: 0.3,
        max_tokens: 2000,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt }
        ]
      }),
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

    if (!response.ok) {
      throw new Error(`Detailed analysis API error: ${response.status}`)
    }

    const content = payload.choices?.[0]?.message?.content
    if (!content) {
      throw new Error('Detailed analysis response is empty')
    }

    const normalizeStartedAt = Date.now()
    const result = parseDetailedAnalysisResult(content, ingredients)
    recordTiming(timings ?? {}, 'ai.parse_json', Date.now() - normalizeStartedAt, {
      contentChars: content.length
    })

    return result
  } catch (error) {
    throw new Error(`Detailed analysis failed: ${error instanceof Error ? error.message : String(error)}`)
  } finally {
    clear()
  }
}

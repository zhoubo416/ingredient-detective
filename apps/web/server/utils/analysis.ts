import type {
  ClaimsAnalysis,
  ComplianceAnalysis,
  FoodAnalysisResult,
  IngredientAnalysis,
  ProcessingAnalysis
} from '~/shared/analysis'
import { useRuntimeConfig } from '#imports'
import { guessFoodName } from '~/shared/analysis'
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

function createTimeoutSignal() {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS)

  return {
    signal: controller.signal,
    clear: () => clearTimeout(timeout)
  }
}

function mockIngredientRecord(ingredientName: string): IngredientAnalysis {
  const lower = ingredientName.toLowerCase()
  const isAdditive = ['糖', '香精', '防腐剂', '色素', '甜味剂', '乳化剂'].some(token => lower.includes(token))

  return {
    ingredientName,
    function: isAdditive ? '用于调味、着色或延长保质期' : '作为食品主体原料或基础配料',
    nutritionalValue: isAdditive ? '营养贡献有限，更多影响口感与风味' : '提供基础能量或营养成分',
    complianceStatus: isAdditive ? '待确认' : '常见配料',
    processingLevel: isAdditive ? '较高' : '中等',
    remarks: isAdditive ? '建议结合摄入频率评估' : '可结合整体配方继续判断'
  }
}

function calculateHealthScore(ingredients: string[]) {
  let score = 8

  for (const token of ['水', '牛乳', '鸡蛋', '大豆', '马铃薯', '蔬菜']) {
    if (ingredients.some(ingredient => ingredient.includes(token))) {
      score += 0.5
    }
  }

  for (const token of ['糖', '添加剂', '香精', '防腐剂', '色素']) {
    if (ingredients.some(ingredient => ingredient.includes(token))) {
      score -= 0.8
    }
  }

  return Math.max(0, Math.min(10, Number(score.toFixed(1))))
}

function generateOverallAssessment(score: number, foodName: string) {
  if (score >= 8) {
    return `${foodName}整体健康程度优秀，配料相对天然，可以适量食用。`
  }
  if (score >= 6) {
    return `${foodName}整体健康程度良好，大部分配料常见，建议关注糖和添加剂含量。`
  }
  if (score >= 4) {
    return `${foodName}健康程度一般，部分成分需要留意，建议控制食用频率。`
  }

  return `${foodName}健康程度偏低，加工成分较多，更适合作为偶尔食用的食品。`
}

function generateRecommendations(ingredients: string[], score: number) {
  const suggestions = ['优先比较同类产品中配料表更短、原料更清晰的版本。']

  if (ingredients.some(ingredient => ingredient.includes('糖'))) {
    suggestions.push('如果正在控糖，建议搭配无糖饮品并减少一次性摄入量。')
  }

  if (ingredients.some(ingredient => ingredient.includes('防腐剂') || ingredient.includes('香精'))) {
    suggestions.push('添加剂较多时，建议降低日常高频购买比例。')
  }

  if (score >= 8) {
    suggestions.push('整体风险较低，但仍建议关注总能量和总脂肪。')
  }

  return suggestions.join(' ')
}

function buildMockCompliance(ingredients: string[]): ComplianceAnalysis {
  const issues = ingredients.filter(ingredient =>
    ['防腐剂', '香精', '甜味剂', '色素'].some(token => ingredient.includes(token))
  )

  return {
    status: issues.length > 0 ? '待确认' : '合规',
    description: issues.length > 0
      ? '存在需要进一步核对标签宣称或使用范围的成分。'
      : '未发现明显异常配料，整体更接近常见合规配方。',
    issues
  }
}

function buildMockProcessing(ingredients: string[]): ProcessingAnalysis {
  const additiveCount = ingredients.filter(ingredient =>
    ['添加剂', '香精', '甜味剂', '乳化剂', '防腐剂'].some(token => ingredient.includes(token))
  ).length

  if (additiveCount >= 3) {
    return {
      level: '高度加工',
      description: '配方中存在多种风味或稳定性添加成分。',
      score: 4.5
    }
  }

  if (additiveCount >= 1) {
    return {
      level: '中度加工',
      description: '存在一定加工痕迹，但仍保留主体原料信息。',
      score: 3
    }
  }

  return {
    level: '轻度加工',
    description: '配料结构相对简单，主体原料更明确。',
    score: 1.8
  }
}

function buildMockClaims(foodName: string): ClaimsAnalysis {
  return {
    detectedClaims: [],
    supportedClaims: [],
    questionableClaims: [],
    assessment: `当前未检测到 ${foodName} 上下文中的明确宣传语，需要结合商品包装正面文案判断。`
  }
}

function buildMockResult(ingredients: string[], productName: string): FoodAnalysisResult {
  const foodName = productName || guessFoodName(ingredients)
  const healthScore = calculateHealthScore(ingredients)

  return {
    foodName,
    ingredients: ingredients.map(mockIngredientRecord),
    healthScore,
    compliance: buildMockCompliance(ingredients),
    processing: buildMockProcessing(ingredients),
    claims: buildMockClaims(foodName),
    overallAssessment: generateOverallAssessment(healthScore, foodName),
    recommendations: generateRecommendations(ingredients, healthScore),
    analysisTime: new Date().toISOString()
  }
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

function parseAiResponse(response: string, ingredients: string[], productName: string) {
  try {
    const jsonStart = response.indexOf('{')
    const jsonEnd = response.lastIndexOf('}') + 1

    if (jsonStart === -1 || jsonEnd <= jsonStart) {
      return buildMockResult(ingredients, productName)
    }

    const data = JSON.parse(response.slice(jsonStart, jsonEnd)) as Partial<FoodAnalysisResult> & {
      compliance?: Partial<ComplianceAnalysis>
      processing?: Partial<ProcessingAnalysis>
      claims?: Partial<ClaimsAnalysis>
    }

    const mock = buildMockResult(ingredients, productName)

    return {
      foodName: data.foodName ?? mock.foodName,
      ingredients: Array.isArray(data.ingredients) && data.ingredients.length > 0
        ? data.ingredients.map(ingredient => ({
          ingredientName: ingredient.ingredientName ?? '',
          function: ingredient.function ?? '',
          nutritionalValue: ingredient.nutritionalValue ?? '',
          complianceStatus: ingredient.complianceStatus ?? '',
          processingLevel: ingredient.processingLevel ?? '',
          remarks: ingredient.remarks ?? ''
        }))
        : mock.ingredients,
      healthScore: typeof data.healthScore === 'number' ? data.healthScore : mock.healthScore,
      compliance: {
        status: data.compliance?.status ?? mock.compliance.status,
        description: data.compliance?.description ?? mock.compliance.description,
        issues: Array.isArray(data.compliance?.issues) ? data.compliance.issues : mock.compliance.issues
      },
      processing: {
        level: data.processing?.level ?? mock.processing.level,
        description: data.processing?.description ?? mock.processing.description,
        score: typeof data.processing?.score === 'number' ? data.processing.score : mock.processing.score
      },
      claims: {
        detectedClaims: Array.isArray(data.claims?.detectedClaims) ? data.claims.detectedClaims : mock.claims.detectedClaims,
        supportedClaims: Array.isArray(data.claims?.supportedClaims) ? data.claims.supportedClaims : mock.claims.supportedClaims,
        questionableClaims: Array.isArray(data.claims?.questionableClaims) ? data.claims.questionableClaims : mock.claims.questionableClaims,
        assessment: data.claims?.assessment ?? mock.claims.assessment
      },
      overallAssessment: data.overallAssessment ?? mock.overallAssessment,
      recommendations: data.recommendations ?? mock.recommendations,
      analysisTime: new Date().toISOString()
    } satisfies FoodAnalysisResult
  } catch {
    return buildMockResult(ingredients, productName)
  }
}

export async function analyzeIngredients(
  ingredients: string[],
  productName: string,
  timings?: TimingMap
) {
  const llm = resolveLlmConfig()

  if (!llm) {
    return buildMockResult(ingredients, productName)
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
  "ingredients": [{"ingredientName": "名称", "function": "作用", "nutritionalValue": "营养", "complianceStatus": "合规性", "processingLevel": "加工度", "remarks": "备注"}]
}`

  const userPrompt = `分析产品 "${productName}" 的配料：${ingredients.join(', ')}。
请从合规性、加工度、宣称三个维度分析，只返回 JSON。`

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
      return buildMockResult(ingredients, productName)
    }

    const content = payload.choices?.[0]?.message?.content
    if (!content) {
      return buildMockResult(ingredients, productName)
    }

    const normalizeStartedAt = Date.now()
    const result = parseAiResponse(content, ingredients, productName)
    recordTiming(timings ?? {}, 'ai.parse_json', Date.now() - normalizeStartedAt, {
      contentChars: content.length
    })

    return result
  } catch {
    return buildMockResult(ingredients, productName)
  } finally {
    clear()
  }
}

export type AnalysisSourceType = 'image' | 'manual'

export interface IngredientAnalysis {
  ingredientName: string
  function: string
  nutritionalValue: string
  complianceStatus: string
  processingLevel: string
  remarks: string
  riskLevel: 'normal' | 'additive' | 'caution'
  riskReason: string
  actionableAdvice: string
  negativeImpact: string
  isAdditive: boolean
}

export interface ComplianceAnalysis {
  status: string
  description: string
  issues: string[]
}

export interface ProcessingAnalysis {
  level: string
  description: string
  score: number
}

export interface ClaimsAnalysis {
  detectedClaims: string[]
  supportedClaims: string[]
  questionableClaims: string[]
  assessment: string
}

export interface FoodAnalysisResult {
  foodName: string
  ingredients: IngredientAnalysis[]
  healthScore: number
  compliance: ComplianceAnalysis
  processing: ProcessingAnalysis
  claims: ClaimsAnalysis
  overallAssessment: string
  recommendations: string
  warnings: string[]
  detailedStatus?: 'pending' | 'complete' | 'failed'
  detailedError?: string
  analysisTime: string
  rawMarkdown?: string
}

export interface AnalysisHistoryItem {
  id: string
  sourceType: AnalysisSourceType
  imageFilename: string | null
  ingredientLines: string[]
  rawOcrText: string | null
  foodName: string
  healthScore: number
  createdAt: string
  result: FoodAnalysisResult
}

export function normalizeIngredientLines(input: string): string[] {
  return input
    .split(/\r?\n|[，,、；;]/g)
    .map(line => line.trim())
    .filter(Boolean)
}

export function guessFoodName(ingredients: string[]): string {
  const first = ingredients[0]?.toLowerCase() ?? ''

  if (first.includes('小麦粉') || first.includes('面粉')) {
    return '面食制品'
  }
  if (first.includes('牛乳') || first.includes('牛奶')) {
    return '乳制品'
  }
  if (first.includes('可可') || first.includes('巧克力')) {
    return '巧克力制品'
  }
  if (first.includes('猪肉') || first.includes('牛肉') || first.includes('鸡肉')) {
    return '肉制品'
  }
  if (first.includes('马铃薯') || first.includes('土豆')) {
    return '薯类零食'
  }
  if (first.includes('水') && ingredients.length <= 3) {
    return '饮料'
  }
  if (first.includes('糖') || first.includes('甜味')) {
    return '甜味食品'
  }

  return '加工食品'
}

export function getScoreTone(score: number) {
  if (score >= 8) {
    return {
      label: '优秀',
      color: 'success' as const
    }
  }
  if (score >= 6) {
    return {
      label: '良好',
      color: 'warning' as const
    }
  }
  if (score >= 4) {
    return {
      label: '一般',
      color: 'warning' as const
    }
  }

  return {
    label: '关注',
    color: 'error' as const
  }
}

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

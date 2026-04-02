import type { AnalysisHistoryItem } from '~/shared/analysis'
import type { AnalysisSourceType } from '~/shared/analysis'
import { normalizeFoodAnalysisResult } from '~/server/utils/analysis'
import { getSupabaseAdminClient, requireApiUser } from '~/server/utils/supabase'

function mapHistoryRow(row: Record<string, unknown>): AnalysisHistoryItem {
  const ingredientLines = Array.isArray(row.ingredient_lines) ? row.ingredient_lines.map(item => String(item)) : []
  const foodName = String(row.food_name)
  const storedResult = row.result && typeof row.result === 'object' ? row.result as Record<string, unknown> : {}

  return {
    id: String(row.id),
    sourceType: row.source_type as AnalysisSourceType,
    imageFilename: row.image_filename ? String(row.image_filename) : null,
    ingredientLines,
    rawOcrText: row.raw_ocr_text ? String(row.raw_ocr_text) : null,
    foodName,
    healthScore: Number(row.health_score ?? 0),
    createdAt: String(row.created_at),
    result: {
      // 直接使用数据库中存储的结果，避免重复规范化导致数据丢失
      ...normalizeFoodAnalysisResult(storedResult, ingredientLines, {
        foodName,
        healthScore: Number(row.health_score ?? 0),
        analysisTime: String(row.created_at)
      }),
      // 确保 detailedStatus 和 detailedError 从原始 storedResult 中读取，不被覆盖
      detailedStatus: storedResult.detailedStatus === 'complete' || storedResult.detailedStatus === 'failed'
        ? storedResult.detailedStatus as string
        : 'pending',
      detailedError: typeof storedResult.detailedError === 'string' ? storedResult.detailedError : ''
    }
  }
}

export default defineEventHandler(async event => {
  const id = getRouterParam(event, 'id')
  if (!id) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Analysis ID is required'
    })
  }

  const user = await requireApiUser(event)
  const supabase = getSupabaseAdminClient()

  const { data, error } = await supabase
    .from('analysis_results')
    .select('*')
    .eq('id', id)
    .eq('user_id', user.id)
    .single()

  if (error || !data) {
    throw createError({
      statusCode: 404,
      statusMessage: 'Analysis not found'
    })
  }

  const history = mapHistoryRow(data)

  // 详细分析完成或失败时都不应继续轮询
  const isComplete =
    history.result.detailedStatus === 'complete' ||
    history.result.detailedStatus === 'failed'

  return {
    ...history,
    isComplete
  }
})

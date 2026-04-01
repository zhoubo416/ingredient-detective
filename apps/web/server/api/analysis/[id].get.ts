import type { AnalysisHistoryItem } from '~/shared/analysis'
import type { AnalysisSourceType } from '~/shared/analysis'
import { normalizeFoodAnalysisResult } from '~/server/utils/analysis'
import { getSupabaseAdminClient, requireApiUser } from '~/server/utils/supabase'

function mapHistoryRow(row: Record<string, unknown>): AnalysisHistoryItem {
  const ingredientLines = Array.isArray(row.ingredient_lines) ? row.ingredient_lines.map(item => String(item)) : []
  const foodName = String(row.food_name)

  return {
    id: String(row.id),
    sourceType: row.source_type as AnalysisSourceType,
    imageFilename: row.image_filename ? String(row.image_filename) : null,
    ingredientLines,
    rawOcrText: row.raw_ocr_text ? String(row.raw_ocr_text) : null,
    foodName,
    healthScore: Number(row.health_score ?? 0),
    createdAt: String(row.created_at),
    result: normalizeFoodAnalysisResult(row.result, ingredientLines, {
      foodName,
      healthScore: Number(row.health_score ?? 0),
      analysisTime: String(row.created_at)
    })
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

  // 检查是否详细分析已完成（result.ingredients 不为空）
  const isComplete =
    history.result.ingredients &&
    Array.isArray(history.result.ingredients) &&
    history.result.ingredients.length > 0

  return {
    ...history,
    isComplete
  }
})

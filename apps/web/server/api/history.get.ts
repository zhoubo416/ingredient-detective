import { getQuery } from 'h3'
import type { AnalysisHistoryItem, AnalysisSourceType } from '~/shared/analysis'
import { getSupabaseAdminClient, requireApiUser } from '~/server/utils/supabase'

function mapHistoryRow(row: Record<string, unknown>): AnalysisHistoryItem {
  return {
    id: String(row.id),
    sourceType: row.source_type as AnalysisSourceType,
    imageFilename: row.image_filename ? String(row.image_filename) : null,
    ingredientLines: Array.isArray(row.ingredient_lines) ? row.ingredient_lines.map(item => String(item)) : [],
    rawOcrText: row.raw_ocr_text ? String(row.raw_ocr_text) : null,
    foodName: String(row.food_name),
    healthScore: Number(row.health_score ?? 0),
    createdAt: String(row.created_at),
    result: row.result as AnalysisHistoryItem['result']
  }
}

export default defineEventHandler(async event => {
  const user = await requireApiUser(event)
  const supabase = getSupabaseAdminClient()
  const query = getQuery(event)
  const limit = Math.min(Number(query.limit ?? 12), 50)

  const { data, error } = await supabase
    .from('analysis_results')
    .select('id, source_type, image_filename, ingredient_lines, raw_ocr_text, food_name, health_score, result, created_at')
    .eq('user_id', user.id)
    .order('created_at', { ascending: false })
    .limit(limit)

  if (error) {
    throw createError({
      statusCode: 500,
      statusMessage: error.message
    })
  }

  return {
    items: (data ?? []).map(row => mapHistoryRow(row))
  }
})

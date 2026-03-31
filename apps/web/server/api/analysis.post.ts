import { randomUUID } from 'node:crypto'
import { Buffer } from 'node:buffer'
import { readBody, readMultipartFormData, setResponseHeader } from 'h3'
import { z } from 'zod'
import type { AnalysisHistoryItem, AnalysisResponse, AnalysisSourceType } from '~/shared/analysis'
import { guessFoodName, normalizeIngredientLines } from '~/shared/analysis'
import { analyzeIngredients, analyzeQuickMetrics, normalizeFoodAnalysisResult } from '~/server/utils/analysis'
import { decodeBase64Image, extractIngredientLines, extractIngredientsFromImageBuffer } from '~/server/utils/ocr'
import { getSupabaseAdminClient, requireApiUser } from '~/server/utils/supabase'
import type { TimingMap } from '~/server/utils/timing'
import { flattenTimingMap, measureTiming, recordTiming } from '~/server/utils/timing'
import type { Json } from '~/types/database.types'

const bodySchema = z.object({
  ingredientsText: z.string().trim().optional(),
  imageBase64: z.string().trim().optional(),
  filename: z.string().trim().optional(),
  productName: z.string().trim().optional()
})

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
    result: normalizeFoodAnalysisResult(row.result, ingredientLines, foodName)
  }
}

export default defineEventHandler(async event => {
  const startedAt = Date.now()
  const requestId = randomUUID()
  const timings: TimingMap = {}
  const user = await measureTiming(timings, 'auth', () => requireApiUser(event))
  const contentType = event.node.req.headers['content-type'] ?? ''

  let productName = ''
  let sourceType: AnalysisSourceType = 'manual'
  let imageFilename: string | null = null
  let ingredientLines: string[] = []
  let rawOcrText: string | null = null
  let imageBuffer: Buffer | null = null

  if (contentType.includes('multipart/form-data')) {
    const formData = await measureTiming(timings, 'request.parse_multipart', () => readMultipartFormData(event))
    const imagePart = formData?.find(part => part.type?.startsWith('image/') || part.name === 'image')
    const ingredientPart = formData?.find(part => part.name === 'ingredientsText')
    const productPart = formData?.find(part => part.name === 'productName')

    productName = productPart?.data?.toString('utf8').trim() ?? ''

    if (imagePart?.data?.length) {
      sourceType = 'image'
      imageFilename = imagePart.filename ?? null
      imageBuffer = imagePart.data
      recordTiming(timings, 'request.image_bytes', 0, {
        bytes: imagePart.data.byteLength,
        filename: imageFilename
      })
    } else if (ingredientPart?.data?.length) {
      ingredientLines = normalizeIngredientLines(ingredientPart.data.toString('utf8'))
    }
  } else {
    const rawBody = await measureTiming(timings, 'request.read_body', () => readBody(event))
    const body = bodySchema.parse(rawBody)
    recordTiming(timings, 'request.parse_json', 0)
    productName = body.productName ?? ''

    if (body.imageBase64) {
      sourceType = 'image'
      imageFilename = body.filename ?? null
      imageBuffer = decodeBase64Image(body.imageBase64)
      recordTiming(timings, 'request.image_bytes', 0, {
        bytes: imageBuffer.byteLength,
        filename: imageFilename
      })
    } else if (body.ingredientsText) {
      ingredientLines = normalizeIngredientLines(body.ingredientsText)
    }
  }

  if (imageBuffer) {
    const ocr = await measureTiming(
      timings,
      'ocr.total',
      () => extractIngredientsFromImageBuffer(imageBuffer, timings),
      { bytes: imageBuffer.byteLength }
    )
    rawOcrText = ocr.rawText
    ingredientLines = ocr.ingredientLines.length > 0 ? ocr.ingredientLines : extractIngredientLines(ocr.rawText)
  }

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
        result: {} as Json // 暂时空结果，稍后填充
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
    String(analysisId),
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
    id: String(analysisId),
    quick,
    isComplete: false
  } satisfies AnalysisResponse
})

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
          result: fullAnalysis as unknown as Json
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

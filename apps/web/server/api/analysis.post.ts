import { randomUUID } from 'node:crypto'
import { Buffer } from 'node:buffer'
import { readBody, readMultipartFormData, setResponseHeader } from 'h3'
import { z } from 'zod'
import type { AnalysisHistoryItem, AnalysisSourceType } from '~/shared/analysis'
import { guessFoodName, normalizeIngredientLines } from '~/shared/analysis'
import { analyzeIngredients } from '~/server/utils/analysis'
import { decodeBase64Image, extractIngredientLines, extractIngredientsFromImageBuffer } from '~/server/utils/ocr'
import { getSupabaseAdminClient, requireApiUser } from '~/server/utils/supabase'
import { flattenTimingMap, measureTiming, recordTiming } from '~/server/utils/timing'
import type { Json } from '~/types/database.types'

const bodySchema = z.object({
  ingredientsText: z.string().trim().optional(),
  imageBase64: z.string().trim().optional(),
  filename: z.string().trim().optional(),
  productName: z.string().trim().optional()
})

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
  const startedAt = Date.now()
  const requestId = randomUUID()
  const timings = {}
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
  const analysis = await measureTiming(
    timings,
    'ai.total',
    () => analyzeIngredients(ingredientLines, resolvedProductName, timings),
    { ingredientCount: ingredientLines.length }
  )

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
        food_name: analysis.foodName,
        health_score: analysis.healthScore,
        result: analysis as unknown as Json
      })
      .select('id, source_type, image_filename, ingredient_lines, raw_ocr_text, food_name, health_score, result, created_at')
      .single()
  })

  if (error || !data) {
    throw createError({
      statusCode: 500,
      statusMessage: error?.message ?? 'Failed to save analysis result.'
    })
  }

  const totalMs = Date.now() - startedAt
  recordTiming(timings, 'request.total', totalMs, {
    sourceType,
    ingredientCount: ingredientLines.length,
    rawOcrTextLength: rawOcrText?.length ?? 0
  })

  setResponseHeader(event, 'Server-Timing', [
    `auth;dur=${timings.auth?.ms ?? 0}`,
    `parse;dur=${(timings['request.parse_multipart']?.ms ?? 0) + (timings['request.read_body']?.ms ?? 0) + (timings['request.parse_json']?.ms ?? 0)}`,
    `ocr;dur=${timings['ocr.total']?.ms ?? 0}`,
    `ai;dur=${timings['ai.total']?.ms ?? 0}`,
    `db;dur=${timings['db.insert']?.ms ?? 0}`,
    `total;dur=${totalMs}`
  ].join(', '))
  setResponseHeader(event, 'X-Request-Id', requestId)
  setResponseHeader(event, 'X-Analysis-Timing', JSON.stringify({
    requestId,
    ...flattenTimingMap(timings)
  }))
  console.info('[analysis-timing]', JSON.stringify({
    requestId,
    userId: user.id,
    sourceType,
    imageFilename,
    timings,
    totalMs
  }))

  return mapHistoryRow(data)
})

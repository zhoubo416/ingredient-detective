import { randomUUID } from 'node:crypto'
import { readBody, readMultipartFormData, setResponseHeader } from 'h3'
import { z } from 'zod'
import type { AnalysisResponse, AnalysisSourceType, FoodAnalysisResult } from '~/shared/analysis'
import { normalizeIngredientLines } from '~/shared/analysis'
import { analyzeIngredients, analyzeQuickMetrics } from '~/server/utils/analysis'
import type { UserHealthProfileContext } from '~/server/utils/analysis'
import { decodeBase64Image, extractIngredientLines, extractIngredientsFromImageBuffer } from '~/server/utils/ocr'
import { requireProAccess } from '~/server/utils/subscription'
import { getSupabaseAdminClient, requireApiUser } from '~/server/utils/supabase'
import type { TimingMap } from '~/server/utils/timing'
import { flattenTimingMap, measureTiming, recordTiming } from '~/server/utils/timing'
import type { Json } from '~/types/database.types'

const healthProfileSchema = z.object({
  gender: z.string().trim().optional(),
  heightCm: z.number().positive().max(260).optional(),
  weightKg: z.number().positive().max(500).optional(),
  healthConditions: z.array(z.string().trim().min(1).max(100)).max(20).optional()
})

const bodySchema = z.object({
  ingredientsText: z.string().trim().optional(),
  imageBase64: z.string().trim().optional(),
  filename: z.string().trim().optional(),
  productName: z.string().trim().optional(),
  userHealthProfile: healthProfileSchema.optional()
})

function buildStoredQuickResult(quick: AnalysisResponse['quick']) {
  return {
    foodName: quick.foodName,
    ingredients: [],
    healthScore: quick.healthScore,
    compliance: {
      status: quick.compliance.status,
      description: quick.compliance.description,
      issues: []
    },
    processing: {
      level: quick.processing.level,
      description: '',
      score: quick.processing.score
    },
    claims: {
      detectedClaims: [],
      supportedClaims: [],
      questionableClaims: [],
      assessment: ''
    },
    overallAssessment: quick.overallAssessment,
    recommendations: quick.recommendations,
    warnings: [],
    detailedStatus: 'pending',
    detailedError: '',
    analysisTime: new Date().toISOString()
  }
}

export default defineEventHandler(async event => {
  const startedAt = Date.now()
  const requestId = randomUUID()
  const timings: TimingMap = {}
  const user = await measureTiming(timings, 'auth', () => requireApiUser(event))
  await measureTiming(timings, 'subscription', () => requireProAccess(user.id))
  const contentType = event.node.req.headers['content-type'] ?? ''

  let productName = ''
  let sourceType: AnalysisSourceType = 'manual'
  let imageFilename: string | null = null
  let ingredientLines: string[] = []
  let rawOcrText: string | null = null
  let userHealthProfile: UserHealthProfileContext | null = null

  const parsePromise = (async () => {
    if (contentType.includes('multipart/form-data')) {
      const formData = await measureTiming(timings, 'request.parse_multipart', () => readMultipartFormData(event))
      const imagePart = formData?.find(part => part.type?.startsWith('image/') || part.name === 'image')
      const ingredientPart = formData?.find(part => part.name === 'ingredientsText')
      const productPart = formData?.find(part => part.name === 'productName')
      const healthProfilePart = formData?.find(part => part.name === 'userHealthProfile')

      productName = productPart?.data?.toString('utf8').trim() ?? ''
      if (healthProfilePart?.data?.length) {
        try {
          const parsed = JSON.parse(healthProfilePart.data.toString('utf8'))
          const validated = healthProfileSchema.safeParse(parsed)
          if (validated.success) {
            userHealthProfile = validated.data
          }
        } catch {
          // ignore invalid client health profile
        }
      }

      if (imagePart?.data?.length) {
        sourceType = 'image'
        imageFilename = imagePart.filename ?? null
        return imagePart.data
      } else if (ingredientPart?.data?.length) {
        ingredientLines = normalizeIngredientLines(ingredientPart.data.toString('utf8'))
      }
    } else {
      const rawBody = await measureTiming(timings, 'request.read_body', () => readBody(event))
      const body = bodySchema.parse(rawBody)
      recordTiming(timings, 'request.parse_json', 0)
      productName = body.productName ?? ''
      userHealthProfile = body.userHealthProfile ?? null

      if (body.imageBase64) {
        sourceType = 'image'
        imageFilename = body.filename ?? null
        return decodeBase64Image(body.imageBase64)
      } else if (body.ingredientsText) {
        ingredientLines = normalizeIngredientLines(body.ingredientsText)
      }
    }
    return null
  })()

  const imageBuffer = await parsePromise

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

  const resolvedProductName = productName.trim()
  const detailedTimings: TimingMap = {}

  const [quick, detailed] = await Promise.all([
    measureTiming(timings, 'ai.quick', () =>
      analyzeQuickMetrics(ingredientLines, resolvedProductName, userHealthProfile, timings)
    ),
    measureTiming(timings, 'ai.detailed', () =>
      analyzeIngredients(ingredientLines, resolvedProductName, userHealthProfile, detailedTimings)
    )
  ])

  const fullResult: FoodAnalysisResult = {
    ...buildStoredQuickResult(quick),
    ...detailed,
    foodName: quick.foodName || detailed.foodName || quick.foodName,
    healthScore: quick.healthScore || detailed.healthScore || quick.healthScore,
    overallAssessment: quick.overallAssessment || detailed.overallAssessment || quick.overallAssessment,
    recommendations: quick.recommendations || detailed.recommendations || quick.recommendations,
    compliance: quick.compliance.status ? {
      status: quick.compliance.status,
      description: quick.compliance.description,
      issues: detailed.compliance?.issues || []
    } : detailed.compliance,
    processing: quick.processing.level ? {
      level: quick.processing.level,
      description: detailed.processing?.description || '',
      score: quick.processing.score
    } : detailed.processing,
    detailedStatus: 'complete',
    detailedError: ''
  }

  const supabase = getSupabaseAdminClient()

  event.waitUntil(
    (async () => {
      const { data, error } = await supabase
        .from('analysis_results')
        .insert({
          user_id: user.id,
          source_type: sourceType,
          image_filename: imageFilename,
          raw_ocr_text: rawOcrText,
          ingredient_lines: ingredientLines as unknown as Json,
          food_name: quick.foodName,
          health_score: quick.healthScore,
          result: fullResult as unknown as Json
        })
        .select('id')
        .single()

      if (error || !data) {
        console.error('[db-insert-error]', error?.message)
        return
      }

      await supabase
        .from('analysis_results')
        .update({
          result: fullResult as unknown as Json
        })
        .eq('id', data.id)
    })()
  )

  const totalMs = Date.now() - startedAt
  recordTiming(timings, 'request.total', totalMs)

  setResponseHeader(event, 'X-Request-Id', requestId)
  setResponseHeader(event, 'X-Analysis-Timing', JSON.stringify({
    requestId,
    stage: 'full',
    durationMs: totalMs,
    ...flattenTimingMap(timings)
  }))

  console.info('[analysis-complete]', JSON.stringify({
    requestId,
    userId: user.id,
    totalMs,
    ingredientCount: detailed.ingredients?.length ?? 0
  }))

  return {
    id: 'pending',
    quick,
    detailed: fullResult,
    isComplete: true
  } satisfies AnalysisResponse
})

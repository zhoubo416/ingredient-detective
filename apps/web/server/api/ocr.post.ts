import { readBody, readMultipartFormData } from 'h3'
import { decodeBase64Image, extractIngredientLines, extractIngredientsFromImageBuffer } from '~/server/utils/ocr'
import { requireApiUser } from '~/server/utils/supabase'
import type { TimingMap } from '~/server/utils/timing'
import { flattenTimingMap, measureTiming, recordTiming } from '~/server/utils/timing'

export default defineEventHandler(async event => {
  const startedAt = Date.now()
  const timings: TimingMap = {}
  await measureTiming(timings, 'auth', () => requireApiUser(event))
  const contentType = event.node.req.headers['content-type'] ?? ''

  let rawText = ''
  let ingredientLines: string[] = []

  if (contentType.includes('multipart/form-data')) {
    const formData = await measureTiming(timings, 'request.parse_multipart', () => readMultipartFormData(event))
    const imagePart = formData?.find(part => part.type?.startsWith('image/') || part.name === 'image')

    if (!imagePart?.data?.length) {
      throw createError({ statusCode: 400, statusMessage: '请上传一张配料表图片' })
    }

    const ocr = await measureTiming(
      timings,
      'ocr.total',
      () => extractIngredientsFromImageBuffer(imagePart.data, timings),
      { bytes: imagePart.data.byteLength }
    )
    rawText = ocr.rawText
    ingredientLines = ocr.ingredientLines.length > 0 ? ocr.ingredientLines : extractIngredientLines(ocr.rawText)
  } else {
    const rawBody = await measureTiming(timings, 'request.read_body', () => readBody(event))
    const body = rawBody as { imageBase64?: string }

    if (!body.imageBase64) {
      throw createError({ statusCode: 400, statusMessage: '请提供图片 base64 数据' })
    }

    const imageBuffer = decodeBase64Image(body.imageBase64)
    const ocr = await measureTiming(
      timings,
      'ocr.total',
      () => extractIngredientsFromImageBuffer(imageBuffer, timings),
      { bytes: imageBuffer.byteLength }
    )
    rawText = ocr.rawText
    ingredientLines = ocr.ingredientLines.length > 0 ? ocr.ingredientLines : extractIngredientLines(ocr.rawText)
  }

  const totalMs = Date.now() - startedAt
  recordTiming(timings, 'request.total', totalMs)

  setResponseHeader(event, 'X-Ocr-Timing', JSON.stringify({
    durationMs: totalMs,
    ...flattenTimingMap(timings)
  }))

  return {
    rawText,
    ingredientLines,
    ingredientCount: ingredientLines.length
  }
})

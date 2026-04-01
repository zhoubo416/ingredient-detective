import { createHmac } from 'node:crypto'
import { Buffer } from 'node:buffer'
import { createError } from 'h3'
import { useRuntimeConfig } from '#imports'
import { normalizeIngredientLines } from '~/shared/analysis'
import type { TimingMap } from '~/server/utils/timing'
import { recordTiming } from '~/server/utils/timing'

const ingredientKeywords = [
  '小麦粉', '面粉', '白砂糖', '糖', '植物油', '食用油', '油', '食盐', '盐', '水',
  '奶粉', '牛奶', '鸡蛋', '蛋', '牛乳', '乳', '大豆', '豆', '肉', '猪肉', '牛肉', '鸡肉',
  '淀粉', '玉米淀粉', '马铃薯', '土豆', '米', '大米',
  '谷氨酸钠', '味精', '香精', '香料', '酵母', '发酵粉', '泡打粉',
  '添加剂', '防腐剂', '色素', '甜味剂', '增稠剂', '乳化剂', '抗氧化剂',
  '可可', '巧克力', '奶油', '黄油', '芝麻', '花生', '核桃', '杏仁',
  '柠檬酸', '维生素', '钙', '铁', '锌'
]

const excludeWords = ['营养成分', '保质期', '生产日期', '厂家', '地址', '电话', '网址', '条码']

const ingredientSectionLabels = ['配料表', '配料', '产品配料', '成分', '主要成分', '原料']
const sectionStopMarkers = [
  '营养成分表',
  '营养成分',
  '食用方法',
  '贮存条件',
  '储存条件',
  '保质期',
  '生产日期',
  '生产商',
  '制造商',
  '委托方',
  '地址',
  '电话',
  '净含量',
  '执行标准',
  '产品类型',
  '过敏原'
]

function encodeAliyun(value: string) {
  return encodeURIComponent(value)
    .replace(/\+/g, '%20')
    .replace(/\*/g, '%2A')
    .replace(/%7E/g, '~')
}

function generateSignature(
  params: Record<string, string>,
  method: string,
  accessKeySecret: string
) {
  const sortedKeys = Object.keys(params)
    .filter(key => key !== 'Signature')
    .sort()

  const queryString = sortedKeys
    .map(key => `${encodeAliyun(key)}=${encodeAliyun(params[key] ?? '')}`)
    .join('&')

  const stringToSign = `${method}&${encodeAliyun('/')}&${encodeAliyun(queryString)}`

  return createHmac('sha1', `${accessKeySecret}&`)
    .update(stringToSign)
    .digest('base64')
}

export function parseIngredientsFromText(text: string) {
  const lines = text.split('\n')
  const ingredients = new Set<string>()

  for (const rawLine of lines) {
    const line = rawLine.trim()
    if (!line) {
      continue
    }

    if (sectionStopMarkers.some(marker => line.includes(marker))) {
      continue
    }

    const cleanedLine = stripIngredientLabels(line)
      .replace(/[【】[\]]/g, ' ')
      .replace(/[：:]/g, ' ')
      .trim()

    const rawTokens = cleanedLine
      .split(/[，,、；;。/]/g)
      .map(token => normalizeToken(token))
      .filter(Boolean)

    const hasKeywordInLine = ingredientKeywords.some(keyword => cleanedLine.includes(keyword))

    for (const token of rawTokens) {
      if (!isLikelyIngredientToken(token)) {
        continue
      }

      if (hasKeywordInLine || ingredientKeywords.some(keyword => token.includes(keyword))) {
        ingredients.add(token)
        continue
      }

      // 对没有命中关键词的 token 做保守保留：长度较短且中文占比高
      if (token.length <= 16 && /[\u4e00-\u9fa5]{2,}/.test(token)) {
        ingredients.add(token)
      }
    }
  }

  return Array.from(ingredients)
}

function stripIngredientLabels(text: string) {
  return ingredientSectionLabels.reduce((current, label) => {
    return current.replace(new RegExp(`${label}[：:]?`, 'g'), ' ')
  }, text)
}

function extractIngredientSection(text: string) {
  const matchedLabel = ingredientSectionLabels.find(label => text.includes(label))
  if (!matchedLabel) {
    return text
  }

  const index = text.indexOf(matchedLabel)
  const section = text.slice(index + matchedLabel.length)
  const stopIndexes = sectionStopMarkers
    .map(marker => section.indexOf(marker))
    .filter(pos => pos >= 0)

  if (stopIndexes.length === 0) {
    return section
  }

  return section.slice(0, Math.min(...stopIndexes))
}

function parseIngredientsFromLooseText(text: string) {
  const baseText = stripIngredientLabels(extractIngredientSection(text))
    .replace(/[·•]/g, ' ')
    .replace(/[【】\[\]]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()

  if (!baseText) {
    return []
  }

  const tokens = normalizeIngredientLines(
    baseText
      .replace(/\s+/g, '\n')
      .replace(/[（(][^）)]*[）)]/g, match => match.replace(/[，,、；;]/g, ' '))
  )

  const candidates = tokens
    .map(item => normalizeToken(item))
    .filter(Boolean)
    .filter(item => isLikelyIngredientToken(item))

  return Array.from(new Set(candidates))
}

function normalizeToken(input: string) {
  return input
    .replace(/^[：:\-•\d.\s]+/, '')
    .replace(/[()（）]/g, '')
    .replace(/\s+/g, '')
    .trim()
}

function isLikelyIngredientToken(token: string) {
  if (!token) return false
  if (token.length < 2 || token.length > 24) return false
  if (excludeWords.some(word => token.includes(word))) return false
  if (sectionStopMarkers.some(marker => token.includes(marker))) return false

  if (/^\d+([./-]\d+)*$/.test(token)) return false
  if (/^\d+(g|kg|ml|l|kcal|%)$/i.test(token)) return false
  if (/^\d{4}[./-]\d{1,2}[./-]\d{1,2}$/.test(token)) return false

  // 纯英文数字且非食品添加剂编码，视为噪音
  if (/^[a-z0-9%.\-]+$/i.test(token) && !/^e\d{3,4}$/i.test(token)) {
    return false
  }

  return /[\u4e00-\u9fa5a-zA-Z]/.test(token)
}

export function extractIngredientLines(text: string) {
  const strictMatches = parseIngredientsFromText(text)
  if (strictMatches.length > 0) {
    return strictMatches
  }

  const looseMatches = parseIngredientsFromLooseText(text)
  if (looseMatches.length > 0) {
    return looseMatches
  }

  return []
}

export async function extractIngredientsFromImageBuffer(
  imageBuffer: Buffer,
  timings?: TimingMap
) {
  const config = useRuntimeConfig()

  if (!config.aliyunAccessKeyId || !config.aliyunAccessKeySecret) {
    throw createError({
      statusCode: 500,
      statusMessage: 'Aliyun OCR is not configured.'
    })
  }

  const timestamp = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z')
  const nonce = `${Date.now()}`

  const params: Record<string, string> = {
    Action: 'RecognizeGeneral',
    Version: '2021-07-07',
    RegionId: config.aliyunRegionId,
    Format: 'JSON',
    Timestamp: timestamp,
    SignatureMethod: 'HMAC-SHA1',
    SignatureVersion: '1.0',
    SignatureNonce: nonce,
    AccessKeyId: config.aliyunAccessKeyId
  }

  params.Signature = generateSignature(params, 'POST', config.aliyunAccessKeySecret)

  const queryString = Object.entries(params)
    .map(([key, value]) => `${encodeAliyun(key)}=${encodeAliyun(value)}`)
    .join('&')

  const fetchStartedAt = Date.now()
  const response = await fetch(`${config.aliyunOcrEndpoint}/?${queryString}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/octet-stream'
    },
    body: new Uint8Array(imageBuffer)
  })
  recordTiming(timings ?? {}, 'ocr.fetch', Date.now() - fetchStartedAt, {
    bytes: imageBuffer.byteLength
  })

  const responseReadStartedAt = Date.now()
  const responseText = await response.text()
  recordTiming(timings ?? {}, 'ocr.read_response', Date.now() - responseReadStartedAt, {
    chars: responseText.length
  })

  if (!response.ok) {
    throw createError({
      statusCode: 502,
      statusMessage: `Aliyun OCR failed: ${responseText}`
    })
  }

  const parseStartedAt = Date.now()
  const payload = JSON.parse(responseText) as {
    Data?: string | { content?: string }
  }

  const rawData = payload.Data
  const nested = typeof rawData === 'string'
    ? JSON.parse(rawData) as { content?: string }
    : rawData
  recordTiming(timings ?? {}, 'ocr.parse_response', Date.now() - parseStartedAt)

  const rawText = nested?.content?.trim() ?? ''
  const extractStartedAt = Date.now()
  const ingredientLines = extractIngredientLines(rawText)
  recordTiming(timings ?? {}, 'ocr.extract_lines', Date.now() - extractStartedAt, {
    rawTextLength: rawText.length,
    ingredientCount: ingredientLines.length
  })

  if (!rawText) {
    throw createError({
      statusCode: 422,
      statusMessage: 'No ingredient text could be extracted from the image.'
    })
  }

  return {
    rawText,
    ingredientLines
  }
}

export function decodeBase64Image(input: string) {
  const cleaned = input.replace(/^data:image\/[a-zA-Z0-9.+-]+;base64,/, '')
  return Buffer.from(cleaned, 'base64')
}

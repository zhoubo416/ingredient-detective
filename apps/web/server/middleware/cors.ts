import {
  appendResponseHeader,
  defineEventHandler,
  getRequestHeader,
  setResponseHeader,
  setResponseStatus
} from 'h3'

function normalizeOrigin(input: string) {
  try {
    return new URL(input).origin
  } catch {
    return ''
  }
}

function isLocalOrigin(origin: string) {
  return /^http:\/\/localhost:\d+$/.test(origin) || /^http:\/\/127\.0\.0\.1:\d+$/.test(origin)
}

export default defineEventHandler(event => {
  if (!event.path.startsWith('/api/')) {
    return
  }

  const requestOrigin = getRequestHeader(event, 'origin') ?? ''
  const marketingOrigin = normalizeOrigin(useRuntimeConfig().public.marketingSiteUrl)
  const allowOrigin =
    (requestOrigin && isLocalOrigin(requestOrigin) && requestOrigin) ||
    (requestOrigin && requestOrigin === marketingOrigin && requestOrigin) ||
    ''

  if (allowOrigin) {
    setResponseHeader(event, 'Access-Control-Allow-Origin', allowOrigin)
    setResponseHeader(event, 'Access-Control-Allow-Credentials', 'true')
  }

  setResponseHeader(event, 'Access-Control-Allow-Methods', 'GET,POST,DELETE,OPTIONS')
  setResponseHeader(event, 'Access-Control-Allow-Headers', 'Authorization,Content-Type')
  appendResponseHeader(event, 'Vary', 'Origin')

  if (event.method === 'OPTIONS') {
    setResponseStatus(event, 204)
    return ''
  }
})

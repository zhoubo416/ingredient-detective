import { readBody } from 'h3'
import { z } from 'zod'
import { updateSubscriptionStatusForUser } from '~/server/utils/subscription'
import { requireApiUser } from '~/server/utils/supabase'

const bodySchema = z.object({
  isPro: z.boolean(),
  source: z.string().trim().max(50).optional(),
  subscriptionStatus: z.string().trim().max(120).optional(),
  expirationDate: z.string().trim().max(120).optional()
})

export default defineEventHandler(async event => {
  const user = await requireApiUser(event)
  const rawBody = await readBody(event)
  const body = bodySchema.parse(rawBody)

  return updateSubscriptionStatusForUser(user.id, {
    isPro: body.isPro,
    source: body.source,
    subscriptionStatus: body.subscriptionStatus,
    expirationDate: body.expirationDate
  })
})

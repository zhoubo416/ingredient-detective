import { getSubscriptionStatusForUser } from '~/server/utils/subscription'
import { requireApiUser } from '~/server/utils/supabase'

export default defineEventHandler(async event => {
  const user = await requireApiUser(event)
  return getSubscriptionStatusForUser(user.id)
})

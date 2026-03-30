import { getRouterParam } from 'h3'
import { getSupabaseAdminClient, requireApiUser } from '~/server/utils/supabase'

export default defineEventHandler(async event => {
  const user = await requireApiUser(event)
  const id = getRouterParam(event, 'id')

  if (!id) {
    throw createError({
      statusCode: 400,
      statusMessage: 'History id is required.'
    })
  }

  const supabase = getSupabaseAdminClient()
  const { error } = await supabase
    .from('analysis_results')
    .delete()
    .eq('id', id)
    .eq('user_id', user.id)

  if (error) {
    throw createError({
      statusCode: 500,
      statusMessage: error.message
    })
  }

  return {
    success: true
  }
})

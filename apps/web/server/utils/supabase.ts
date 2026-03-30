import type { H3Event } from 'h3'
import type { SupabaseClient } from '@supabase/supabase-js'
import { createClient } from '@supabase/supabase-js'
import { createError, getHeader } from 'h3'
import { useRuntimeConfig } from '#imports'
import { serverSupabaseUser } from '#supabase/server'
import type { Database } from '~/types/database.types'

export interface AuthenticatedUser {
  id: string
  email: string | null
}

let adminClient: SupabaseClient<Database> | null = null
let authClient: SupabaseClient<Database> | null = null

function getKeys() {
  const config = useRuntimeConfig()

  if (!config.public.supabaseUrl || !config.public.supabaseAnonKey) {
    throw createError({
      statusCode: 500,
      statusMessage: 'Supabase public keys are not configured.'
    })
  }

  return {
    url: config.public.supabaseUrl,
    anonKey: config.public.supabaseAnonKey,
    serviceRoleKey: config.supabaseServiceRoleKey
  }
}

export function getSupabaseAdminClient() {
  const { url, serviceRoleKey } = getKeys()

  if (!serviceRoleKey) {
    throw createError({
      statusCode: 500,
      statusMessage: 'Supabase service role key is not configured.'
    })
  }

  if (!adminClient) {
    adminClient = createClient<Database>(url, serviceRoleKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false
      }
    })
  }

  return adminClient
}

function getSupabaseAuthClient() {
  const { url, anonKey } = getKeys()

  if (!authClient) {
    authClient = createClient<Database>(url, anonKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false
      }
    })
  }

  return authClient
}

function getBearerToken(event: H3Event) {
  const authHeader = getHeader(event, 'authorization')
  if (!authHeader?.startsWith('Bearer ')) {
    return null
  }

  return authHeader.slice('Bearer '.length).trim()
}

function normalizeServerUser(user: Record<string, unknown>) {
  const id =
    (typeof user.id === 'string' && user.id) ||
    (typeof user.sub === 'string' && user.sub) ||
    ''

  if (!id) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Invalid Supabase session.'
    })
  }

  return {
    id,
    email: typeof user.email === 'string' ? user.email : null
  } satisfies AuthenticatedUser
}

export async function requireApiUser(event: H3Event): Promise<AuthenticatedUser> {
  const cookieUser = await serverSupabaseUser(event)
  if (cookieUser) {
    return normalizeServerUser(cookieUser as Record<string, unknown>)
  }

  const token = getBearerToken(event)
  if (!token) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Authentication required.'
    })
  }

  const { data, error } = await getSupabaseAuthClient().auth.getUser(token)
  if (error || !data.user) {
    throw createError({
      statusCode: 401,
      statusMessage: 'Invalid Supabase session.'
    })
  }

  return {
    id: data.user.id,
    email: data.user.email ?? null
  }
}

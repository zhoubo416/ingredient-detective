import { createError } from 'h3'
import { PRO_ENTITLEMENT_ID } from '~/shared/subscription'
import type { SubscriptionStatusResponse } from '~/shared/subscription'
import { getSupabaseAdminClient } from '~/server/utils/supabase'

type MetadataRecord = Record<string, unknown>

interface SubscriptionUpdateInput {
  isPro: boolean
  source?: string | null
  subscriptionStatus?: string | null
  expirationDate?: string | null
}

function asRecord(value: unknown): MetadataRecord {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return {}
  }

  return value as MetadataRecord
}

function asNullableString(value: unknown) {
  if (typeof value !== 'string') {
    return null
  }

  const trimmed = value.trim()
  return trimmed ? trimmed : null
}

function normalizeSubscriptionStatus(appMetadata: MetadataRecord): SubscriptionStatusResponse {
  const subscription = asRecord(appMetadata.subscription)
  const nestedIsPro = typeof subscription.isPro === 'boolean' ? subscription.isPro : null
  const topLevelIsPro = typeof appMetadata[PRO_ENTITLEMENT_ID] === 'boolean'
    ? appMetadata[PRO_ENTITLEMENT_ID] as boolean
    : null

  return {
    isPro: nestedIsPro ?? topLevelIsPro ?? false,
    entitlementId: PRO_ENTITLEMENT_ID,
    source: asNullableString(subscription.source),
    subscriptionStatus: asNullableString(subscription.subscriptionStatus),
    expirationDate: asNullableString(subscription.expirationDate),
    syncedAt: asNullableString(subscription.syncedAt)
  }
}

async function loadAuthUserById(userId: string) {
  const supabase = getSupabaseAdminClient()
  const { data, error } = await supabase.auth.admin.getUserById(userId)

  if (error || !data.user) {
    throw createError({
      statusCode: 500,
      statusMessage: '无法读取当前账号的订阅状态。'
    })
  }

  return data.user
}

export async function getSubscriptionStatusForUser(userId: string) {
  const user = await loadAuthUserById(userId)
  return normalizeSubscriptionStatus(asRecord(user.app_metadata))
}

export async function updateSubscriptionStatusForUser(
  userId: string,
  input: SubscriptionUpdateInput
) {
  const user = await loadAuthUserById(userId)
  const appMetadata = asRecord(user.app_metadata)
  const currentSubscription = asRecord(appMetadata.subscription)

  const nextAppMetadata = {
    ...appMetadata,
    [PRO_ENTITLEMENT_ID]: input.isPro,
    subscription: {
      ...currentSubscription,
      entitlementId: PRO_ENTITLEMENT_ID,
      isPro: input.isPro,
      source: input.source ?? asNullableString(currentSubscription.source),
      subscriptionStatus: input.subscriptionStatus ?? null,
      expirationDate: input.expirationDate ?? null,
      syncedAt: new Date().toISOString()
    }
  }

  const supabase = getSupabaseAdminClient()
  const { data, error } = await supabase.auth.admin.updateUserById(userId, {
    app_metadata: nextAppMetadata
  })

  if (error || !data.user) {
    throw createError({
      statusCode: 500,
      statusMessage: '无法同步订阅状态。'
    })
  }

  return normalizeSubscriptionStatus(asRecord(data.user.app_metadata))
}

export async function requireProAccess(userId: string) {
  const status = await getSubscriptionStatusForUser(userId)

  if (status.isPro) {
    return status
  }

  throw createError({
    statusCode: 403,
    statusMessage: '当前账号未开通 Pro，暂无法使用图片上传或文字配料分析。请先在移动端升级 Pro。'
  })
}

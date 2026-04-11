export const PRO_ENTITLEMENT_ID = 'pro_access'

export interface SubscriptionStatusResponse {
  isPro: boolean
  entitlementId: string
  source: string | null
  subscriptionStatus: string | null
  expirationDate: string | null
  syncedAt: string | null
}

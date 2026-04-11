class SubscriptionStatus {
  final bool isPro;
  final String entitlementId;
  final String? source;
  final String? subscriptionStatus;
  final String? expirationDate;
  final String? syncedAt;

  const SubscriptionStatus({
    required this.isPro,
    required this.entitlementId,
    this.source,
    this.subscriptionStatus,
    this.expirationDate,
    this.syncedAt,
  });

  factory SubscriptionStatus.fromMap(Map<String, dynamic> map) {
    return SubscriptionStatus(
      isPro: map['isPro'] == true,
      entitlementId: map['entitlementId']?.toString() ?? 'pro_access',
      source: map['source']?.toString(),
      subscriptionStatus: map['subscriptionStatus']?.toString(),
      expirationDate: map['expirationDate']?.toString(),
      syncedAt: map['syncedAt']?.toString(),
    );
  }

  const SubscriptionStatus.free()
    : isPro = false,
      entitlementId = 'pro_access',
      source = null,
      subscriptionStatus = null,
      expirationDate = null,
      syncedAt = null;
}

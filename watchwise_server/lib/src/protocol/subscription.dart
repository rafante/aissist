import 'package:serverpod/serverpod.dart';

/// Subscription entity for AIssist platform
class Subscription extends TableRow with ProtocolSerialization {
  @override
  String get tableName => 'subscriptions';

  late int id;
  late int userId;
  late String tier; // 'free', 'premium', 'pro'
  late String status; // 'active', 'cancelled', 'expired', 'pending'
  late DateTime startDate;
  late DateTime? endDate;
  late String? paymentId; // Stripe/PagSeguro payment ID
  late double? amount; // Monthly amount
  late String? currency; // 'BRL', 'USD'
  late DateTime createdAt;
  late DateTime updatedAt;

  Subscription({
    this.id = 0,
    required this.userId,
    this.tier = 'free',
    this.status = 'active',
    DateTime? startDate,
    this.endDate,
    this.paymentId,
    this.amount,
    this.currency = 'BRL',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    startDate = startDate ?? DateTime.now(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'tier': tier,
    'status': status,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'paymentId': paymentId,
    'amount': amount,
    'currency': currency,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  @override
  Subscription fromJson(Map<String, dynamic> json) => Subscription(
    id: json['id'] ?? 0,
    userId: json['userId'],
    tier: json['tier'] ?? 'free',
    status: json['status'] ?? 'active',
    startDate: DateTime.parse(json['startDate']),
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    paymentId: json['paymentId'],
    amount: json['amount']?.toDouble(),
    currency: json['currency'] ?? 'BRL',
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  /// Check if subscription is currently active
  bool get isActive {
    if (status != 'active') return false;
    if (tier == 'free') return true;
    if (endDate == null) return true;
    return DateTime.now().isBefore(endDate!);
  }

  /// Days remaining in subscription
  int? get daysRemaining {
    if (tier == 'free' || endDate == null) return null;
    final remaining = endDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Get subscription features
  Map<String, dynamic> get features {
    switch (tier) {
      case 'premium':
        return {
          'dailyQueries': 100,
          'aiRecommendations': true,
          'advancedFilters': true,
          'exportLists': true,
          'prioritySupport': false,
          'customLists': 10,
        };
      case 'pro':
        return {
          'dailyQueries': 500,
          'aiRecommendations': true,
          'advancedFilters': true,
          'exportLists': true,
          'prioritySupport': true,
          'customLists': -1, // unlimited
          'apiAccess': true,
        };
      default: // free
        return {
          'dailyQueries': 5,
          'aiRecommendations': true,
          'advancedFilters': false,
          'exportLists': false,
          'prioritySupport': false,
          'customLists': 1,
        };
    }
  }

  /// Get monthly price for tier
  static double getPriceForTier(String tier, {String currency = 'BRL'}) {
    if (currency == 'BRL') {
      switch (tier) {
        case 'premium': return 19.90;
        case 'pro': return 39.90;
        default: return 0.0;
      }
    }
    // USD prices
    switch (tier) {
      case 'premium': return 3.99;
      case 'pro': return 7.99;
      default: return 0.0;
    }
  }
}
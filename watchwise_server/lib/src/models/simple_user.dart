/// Simple User model for standalone system (no Serverpod dependencies)
class SimpleUser {
  final int id;
  final String email;
  final String passwordHash;
  final String subscriptionTier;
  int dailyUsageCount;
  final DateTime createdAt;
  DateTime updatedAt;

  SimpleUser({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.subscriptionTier,
    this.dailyUsageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to JSON for API responses (excluding sensitive data)
  Map<String, dynamic> toPublicJson() {
    final dailyLimit = subscriptionTier == 'pro' ? 500 
                     : subscriptionTier == 'premium' ? 100 
                     : 5;
    
    return {
      'id': id,
      'email': email,
      'subscriptionTier': subscriptionTier,
      'remainingQueries': dailyLimit - dailyUsageCount,
      'dailyUsageCount': dailyUsageCount,
      'dailyLimit': dailyLimit,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert to full JSON (for internal use)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'passwordHash': passwordHash,
      'subscriptionTier': subscriptionTier,
      'dailyUsageCount': dailyUsageCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory SimpleUser.fromJson(Map<String, dynamic> json) {
    return SimpleUser(
      id: json['id'],
      email: json['email'],
      passwordHash: json['passwordHash'],
      subscriptionTier: json['subscriptionTier'] ?? 'free',
      dailyUsageCount: json['dailyUsageCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
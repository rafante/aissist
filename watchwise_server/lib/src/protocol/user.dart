import 'package:serverpod/serverpod.dart';

/// User entity for AIssist platform
class User extends TableRow with ProtocolSerialization {
  @override
  String get tableName => 'users';

  late int id;
  late String email;
  late String passwordHash;
  late DateTime createdAt;
  late DateTime updatedAt;
  late String subscriptionTier; // 'free', 'premium', 'pro'
  late int dailyUsageCount;
  late DateTime lastUsageReset;
  late bool isActive;

  User({
    this.id = 0,
    required this.email,
    required this.passwordHash,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.subscriptionTier = 'free',
    this.dailyUsageCount = 0,
    DateTime? lastUsageReset,
    this.isActive = true,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now(),
    lastUsageReset = lastUsageReset ?? DateTime.now();

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'passwordHash': passwordHash,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'subscriptionTier': subscriptionTier,
    'dailyUsageCount': dailyUsageCount,
    'lastUsageReset': lastUsageReset.toIso8601String(),
    'isActive': isActive,
  };

  @override
  User fromJson(Map<String, dynamic> json) => User(
    id: json['id'] ?? 0,
    email: json['email'],
    passwordHash: json['passwordHash'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    subscriptionTier: json['subscriptionTier'] ?? 'free',
    dailyUsageCount: json['dailyUsageCount'] ?? 0,
    lastUsageReset: DateTime.parse(json['lastUsageReset']),
    isActive: json['isActive'] ?? true,
  );

  /// Check if user has exceeded daily limit
  bool get hasExceededDailyLimit {
    final limits = {
      'free': 5,
      'premium': 100, // High but not unlimited for abuse protection
      'pro': 500,
    };
    
    final limit = limits[subscriptionTier] ?? 5;
    return dailyUsageCount >= limit;
  }

  /// Get remaining queries for today
  int get remainingQueries {
    final limits = {
      'free': 5,
      'premium': 100,
      'pro': 500,
    };
    
    final limit = limits[subscriptionTier] ?? 5;
    return (limit - dailyUsageCount).clamp(0, limit);
  }

  /// Reset daily usage if needed
  void resetDailyUsageIfNeeded() {
    final now = DateTime.now();
    if (now.difference(lastUsageReset).inDays >= 1) {
      dailyUsageCount = 0;
      lastUsageReset = now;
      updatedAt = now;
    }
  }

  /// Increment usage count
  void incrementUsage() {
    resetDailyUsageIfNeeded();
    dailyUsageCount++;
    updatedAt = DateTime.now();
  }

  /// User without sensitive data for API responses
  Map<String, dynamic> toPublicJson() => {
    'id': id,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
    'subscriptionTier': subscriptionTier,
    'dailyUsageCount': dailyUsageCount,
    'remainingQueries': remainingQueries,
    'isActive': isActive,
  };
}
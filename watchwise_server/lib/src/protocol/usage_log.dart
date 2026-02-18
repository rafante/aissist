import 'package:serverpod/serverpod.dart';

/// Usage tracking for AIssist queries
class UsageLog extends TableRow with ProtocolSerialization {
  @override
  String get tableName => 'usage_logs';

  late int id;
  late int userId;
  late String query;
  late String? response;
  late int responseLength;
  late int processingTimeMs;
  late String? llmModel; // 'reviva:latest', 'gpt-4', etc
  late double? estimatedCost; // Cost in credits/tokens
  late String status; // 'success', 'error', 'rate_limited'
  late String? errorMessage;
  late String userAgent;
  late String? ipAddress;
  late DateTime createdAt;

  UsageLog({
    this.id = 0,
    required this.userId,
    required this.query,
    this.response,
    this.responseLength = 0,
    this.processingTimeMs = 0,
    this.llmModel,
    this.estimatedCost,
    this.status = 'success',
    this.errorMessage,
    this.userAgent = 'AIssist-Web/1.0',
    this.ipAddress,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'query': query,
    'response': response,
    'responseLength': responseLength,
    'processingTimeMs': processingTimeMs,
    'llmModel': llmModel,
    'estimatedCost': estimatedCost,
    'status': status,
    'errorMessage': errorMessage,
    'userAgent': userAgent,
    'ipAddress': ipAddress,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  UsageLog fromJson(Map<String, dynamic> json) => UsageLog(
    id: json['id'] ?? 0,
    userId: json['userId'],
    query: json['query'],
    response: json['response'],
    responseLength: json['responseLength'] ?? 0,
    processingTimeMs: json['processingTimeMs'] ?? 0,
    llmModel: json['llmModel'],
    estimatedCost: json['estimatedCost']?.toDouble(),
    status: json['status'] ?? 'success',
    errorMessage: json['errorMessage'],
    userAgent: json['userAgent'] ?? 'AIssist-Web/1.0',
    ipAddress: json['ipAddress'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  /// Public version for user dashboard (no sensitive data)
  Map<String, dynamic> toPublicJson() => {
    'id': id,
    'query': query.length > 100 ? '${query.substring(0, 100)}...' : query,
    'responseLength': responseLength,
    'processingTimeMs': processingTimeMs,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Create usage log for successful query
  static UsageLog success({
    required int userId,
    required String query,
    required String response,
    required int processingTimeMs,
    String? llmModel,
    double? estimatedCost,
    String? userAgent,
    String? ipAddress,
  }) => UsageLog(
    userId: userId,
    query: query,
    response: response,
    responseLength: response.length,
    processingTimeMs: processingTimeMs,
    llmModel: llmModel ?? 'reviva:latest',
    estimatedCost: estimatedCost,
    status: 'success',
    userAgent: userAgent ?? 'AIssist-Web/1.0',
    ipAddress: ipAddress,
  );

  /// Create usage log for error
  static UsageLog error({
    required int userId,
    required String query,
    required String errorMessage,
    int processingTimeMs = 0,
    String? userAgent,
    String? ipAddress,
  }) => UsageLog(
    userId: userId,
    query: query,
    processingTimeMs: processingTimeMs,
    status: 'error',
    errorMessage: errorMessage,
    userAgent: userAgent ?? 'AIssist-Web/1.0',
    ipAddress: ipAddress,
  );

  /// Create usage log for rate limited
  static UsageLog rateLimited({
    required int userId,
    required String query,
    String? userAgent,
    String? ipAddress,
  }) => UsageLog(
    userId: userId,
    query: query,
    status: 'rate_limited',
    errorMessage: 'Daily query limit exceeded',
    userAgent: userAgent ?? 'AIssist-Web/1.0',
    ipAddress: ipAddress,
  );
}
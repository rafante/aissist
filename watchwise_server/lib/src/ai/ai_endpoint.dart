import 'package:serverpod/serverpod.dart';
import '../services/reviva_llm_service.dart';
import '../services/auth_service.dart';

/// AI-powered recommendations endpoint with authentication and rate limiting
class AiEndpoint extends Endpoint {
  late final RevivaLlmService _llmService;

  @override
  Future<void> initialize() async {
    _llmService = RevivaLlmService();
  }

  /// AI-powered movie and TV show recommendations (authenticated)
  Future<Map<String, dynamic>> chat(Session session, {
    required String query,
    String language = 'pt-BR',
  }) async {
    // Get user ID from JWT token
    final userId = _getUserIdFromSession(session);
    if (userId == null) {
      return {
        'success': false,
        'error': 'Authentication required',
        'requiresAuth': true,
      };
    }

    // Check rate limiting
    final limitCheck = await AuthService.checkQueryLimit(session, userId);
    if (!limitCheck['allowed']) {
      return {
        'success': false,
        'error': limitCheck['error'],
        'remainingQueries': limitCheck['remainingQueries'] ?? 0,
        'upgradeRequired': limitCheck['upgradeRequired'] ?? false,
        'rateLimited': true,
      };
    }

    try {
      // Record query start time
      final startTime = DateTime.now();

      // Call AI service
      final aiResponse = await _llmService.getRecommendations(
        query: query,
        language: language,
      );

      // Calculate processing time
      final processingTimeMs = DateTime.now().difference(startTime).inMilliseconds;

      // Record usage for the user
      await AuthService.recordQueryUsage(
        session,
        userId,
        query,
        aiResponse,
        processingTimeMs,
        userAgent: _getUserAgent(session),
        ipAddress: _getClientIP(session),
      );

      // Get updated limit info
      final updatedLimit = await AuthService.checkQueryLimit(session, userId);

      return {
        'success': true,
        'response': aiResponse,
        'processingTimeMs': processingTimeMs,
        'remainingQueries': updatedLimit['remainingQueries'] ?? 0,
        'query': query,
      };
    } catch (e) {
      // Log error usage
      await session.db.insertTableRow(UsageLog.error(
        userId: userId,
        query: query,
        errorMessage: e.toString(),
        userAgent: _getUserAgent(session),
        ipAddress: _getClientIP(session),
      ));

      return {
        'success': false,
        'error': 'AI service temporarily unavailable',
        'technical_error': e.toString(),
      };
    }
  }

  /// Public AI endpoint with fallback (no auth required, limited)
  Future<Map<String, dynamic>> chatPublic(Session session, {
    required String query,
    String language = 'pt-BR',
  }) async {
    try {
      // For public access, use fallback recommendations
      final fallbackResponse = _llmService.getFallbackRecommendations(query);
      
      return {
        'success': true,
        'response': fallbackResponse,
        'fallback': true,
        'message': 'Sign up for AI-powered recommendations!',
        'processingTimeMs': 50,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Service temporarily unavailable',
      };
    }
  }

  /// Get AI service status
  Future<Map<String, dynamic>> status(Session session) async {
    try {
      final isHealthy = await _llmService.healthCheck();
      
      return {
        'success': true,
        'service': 'ReVivaLLM',
        'healthy': isHealthy,
        'endpoint': _llmService.baseUrl,
        'model': 'reviva:latest',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Health check failed',
        'details': e.toString(),
      };
    }
  }

  /// Extract user ID from JWT token
  int? _getUserIdFromSession(Session session) {
    try {
      final authHeader = session.httpRequest.headers['authorization']?.first;
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return null;
      }

      final token = authHeader.substring(7);
      return AuthService.verifyJwtToken(token);
    } catch (e) {
      return null;
    }
  }

  /// Get user agent from request
  String _getUserAgent(Session session) {
    return session.httpRequest.headers['user-agent']?.first ?? 'AIssist-Unknown/1.0';
  }

  /// Get client IP address
  String? _getClientIP(Session session) {
    // Check for forwarded headers first (when behind proxy)
    final forwarded = session.httpRequest.headers['x-forwarded-for']?.first;
    if (forwarded != null && forwarded.isNotEmpty) {
      return forwarded.split(',').first.trim();
    }

    final realIP = session.httpRequest.headers['x-real-ip']?.first;
    if (realIP != null && realIP.isNotEmpty) {
      return realIP;
    }

    // Fallback to connection remote address
    return session.httpRequest.connectionInfo?.remoteAddress.address;
  }

  @override
  Future<void> close() async {
    _llmService.dispose();
  }
}
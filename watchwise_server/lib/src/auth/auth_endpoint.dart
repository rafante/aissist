import 'package:serverpod/serverpod.dart';
import '../services/auth_service.dart';

/// Authentication endpoints for AIssist
class AuthEndpoint extends Endpoint {
  
  /// Register new user
  Future<Map<String, dynamic>> signup(
    Session session,
    String email,
    String password,
  ) async {
    return AuthService.registerUser(session, email, password);
  }

  /// User login
  Future<Map<String, dynamic>> login(
    Session session,
    String email,
    String password,
  ) async {
    return AuthService.loginUser(session, email, password);
  }

  /// Get current user info (requires JWT)
  Future<Map<String, dynamic>> me(Session session) async {
    final userId = _getUserIdFromSession(session);
    if (userId == null) {
      return {'success': false, 'error': 'Authentication required'};
    }

    final user = await AuthService.getUserById(session, userId);
    if (user == null) {
      return {'success': false, 'error': 'User not found'};
    }

    // Get current subscription info
    final subscription = await session.db.findSingleRow(
      table: 'subscriptions',
      where: 'user_id = @userId AND status = @status',
      substitutionValues: {
        'userId': userId,
        'status': 'active',
      },
    );

    return {
      'success': true,
      'user': user.toPublicJson(),
      'subscription': subscription?.toJson(),
    };
  }

  /// Get user usage stats (requires JWT)
  Future<Map<String, dynamic>> usage(Session session) async {
    final userId = _getUserIdFromSession(session);
    if (userId == null) {
      return {'success': false, 'error': 'Authentication required'};
    }

    try {
      // Get recent usage logs
      final recentLogs = await session.db.find(
        table: 'usage_logs',
        where: 'user_id = @userId ORDER BY created_at DESC LIMIT 10',
        substitutionValues: {'userId': userId},
      );

      // Get today's usage count
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      final todayUsage = await session.db.find(
        table: 'usage_logs',
        where: 'user_id = @userId AND created_at >= @todayStart',
        substitutionValues: {
          'userId': userId,
          'todayStart': todayStart,
        },
      );

      // Get this week's usage
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekUsage = await session.db.find(
        table: 'usage_logs',
        where: 'user_id = @userId AND created_at >= @weekStart',
        substitutionValues: {
          'userId': userId,
          'weekStart': weekStart,
        },
      );

      return {
        'success': true,
        'stats': {
          'todayCount': todayUsage.length,
          'weekCount': weekUsage.length,
          'totalQueries': recentLogs.length,
          'recentQueries': recentLogs.map((log) => {
            'query': log['query'],
            'status': log['status'],
            'processingTime': log['processing_time_ms'],
            'createdAt': log['created_at'],
          }).toList(),
        },
      };
    } catch (e) {
      return {'success': false, 'error': 'Failed to fetch usage stats'};
    }
  }

  /// Check query limit for current user
  Future<Map<String, dynamic>> checkLimit(Session session) async {
    final userId = _getUserIdFromSession(session);
    if (userId == null) {
      return {'success': false, 'error': 'Authentication required'};
    }

    return AuthService.checkQueryLimit(session, userId);
  }

  /// Logout user (client-side token removal, server just validates)
  Future<Map<String, dynamic>> logout(Session session) async {
    // JWT tokens are stateless, so logout is handled client-side
    // This endpoint just validates the token is still valid
    final userId = _getUserIdFromSession(session);
    if (userId == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    return {'success': true, 'message': 'Logout successful'};
  }

  /// Extract user ID from JWT token in session
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
}

/// Authentication middleware for protected endpoints
class AuthMiddleware extends MiddlewareCancel {
  @override
  Future<bool> canProcess(
    Session session,
    String endpointName,
    String methodName,
    Map<String, dynamic> arguments,
    String serializationFormat,
  ) async {
    // Skip auth for public endpoints
    final publicEndpoints = [
      'auth/signup',
      'auth/login',
      'greeting/hello',
      'content/movies',
      'content/tv',
    ];

    final currentEndpoint = '$endpointName/$methodName';
    if (publicEndpoints.contains(currentEndpoint)) {
      return true;
    }

    // Check JWT token
    try {
      final authHeader = session.httpRequest.headers['authorization']?.first;
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return false;
      }

      final token = authHeader.substring(7);
      final userId = AuthService.verifyJwtToken(token);
      
      if (userId == null) {
        return false;
      }

      // Add user ID to session for use in endpoints
      session.setUserData('userId', userId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:jose/jose.dart';
import 'package:serverpod/serverpod.dart';
import '../protocol/user.dart';
import '../protocol/subscription.dart';
import '../protocol/usage_log.dart';

/// JWT Authentication Service for AIssist
class AuthService {
  static const String _jwtSecret = 'aissist_jwt_secret_2026_v1'; // TODO: Environment variable
  static const Duration _jwtExpiry = Duration(hours: 24);

  /// Hash password with salt
  static String hashPassword(String password) {
    final salt = _generateSalt();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '${digest.toString()}:$salt';
  }

  /// Verify password
  static bool verifyPassword(String password, String hash) {
    final parts = hash.split(':');
    if (parts.length != 2) return false;
    
    final storedHash = parts[0];
    final salt = parts[1];
    
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    
    return storedHash == digest.toString();
  }

  /// Generate JWT token
  static String generateJwtToken(User user) {
    final claims = JwtClaims.fromJson({
      'sub': user.id.toString(),
      'email': user.email,
      'tier': user.subscriptionTier,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(_jwtExpiry).millisecondsSinceEpoch ~/ 1000,
    });

    final builder = JsonWebSignatureBuilder()
      ..jsonContent = claims.toJson()
      ..addRecipient(JsonWebKey.fromJson({
        'kty': 'oct',
        'k': base64Url.encode(utf8.encode(_jwtSecret)),
      }), algorithm: 'HS256');

    return builder.build().toCompactSerialization();
  }

  /// Verify JWT token and return user ID
  static int? verifyJwtToken(String token) {
    try {
      final jws = JsonWebSignature.fromCompactSerialization(token);
      final keyStore = JsonWebKeyStore()
        ..addKey(JsonWebKey.fromJson({
          'kty': 'oct',
          'k': base64Url.encode(utf8.encode(_jwtSecret)),
        }));

      final verified = jws.verify(keyStore);
      if (!verified) return null;

      final payload = json.decode(jws.unverifiedPayload.stringContent);
      final exp = payload['exp'];
      
      if (exp != null && DateTime.fromMillisecondsSinceEpoch(exp * 1000).isBefore(DateTime.now())) {
        return null; // Token expired
      }

      return int.tryParse(payload['sub']);
    } catch (e) {
      return null;
    }
  }

  /// Register new user
  static Future<Map<String, dynamic>> registerUser(
    Session session,
    String email,
    String password,
  ) async {
    // Validate email format
    if (!_isValidEmail(email)) {
      return {'success': false, 'error': 'Invalid email format'};
    }

    // Validate password strength
    if (password.length < 6) {
      return {'success': false, 'error': 'Password must be at least 6 characters'};
    }

    try {
      // Check if user already exists
      final existing = await session.db.findSingleRow<User>(
        table: 'users',
        where: 'email = @email',
        substitutionValues: {'email': email},
      );

      if (existing != null) {
        return {'success': false, 'error': 'User already exists'};
      }

      // Create new user
      final user = User(
        email: email.toLowerCase().trim(),
        passwordHash: hashPassword(password),
      );

      final insertedUser = await session.db.insertTableRow(user);

      // Create free subscription
      final subscription = Subscription(
        userId: insertedUser.id,
        tier: 'free',
        status: 'active',
      );

      await session.db.insertTableRow(subscription);

      // Generate JWT token
      final token = generateJwtToken(insertedUser);

      return {
        'success': true,
        'user': insertedUser.toPublicJson(),
        'token': token,
      };
    } catch (e) {
      print('Registration error: $e');
      return {'success': false, 'error': 'Registration failed'};
    }
  }

  /// Login user
  static Future<Map<String, dynamic>> loginUser(
    Session session,
    String email,
    String password,
  ) async {
    try {
      final user = await session.db.findSingleRow<User>(
        table: 'users',
        where: 'email = @email AND is_active = true',
        substitutionValues: {'email': email.toLowerCase().trim()},
      );

      if (user == null || !verifyPassword(password, user.passwordHash)) {
        return {'success': false, 'error': 'Invalid credentials'};
      }

      // Generate JWT token
      final token = generateJwtToken(user);

      return {
        'success': true,
        'user': user.toPublicJson(),
        'token': token,
      };
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'error': 'Login failed'};
    }
  }

  /// Get user by ID
  static Future<User?> getUserById(Session session, int userId) async {
    try {
      return await session.db.findById<User>(userId);
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  /// Check if user can make query (rate limiting)
  static Future<Map<String, dynamic>> checkQueryLimit(
    Session session,
    int userId,
  ) async {
    try {
      final user = await getUserById(session, userId);
      if (user == null) {
        return {'allowed': false, 'error': 'User not found'};
      }

      user.resetDailyUsageIfNeeded();

      if (user.hasExceededDailyLimit) {
        return {
          'allowed': false,
          'error': 'Daily query limit exceeded',
          'remainingQueries': 0,
          'upgradeRequired': user.subscriptionTier == 'free',
        };
      }

      return {
        'allowed': true,
        'remainingQueries': user.remainingQueries,
      };
    } catch (e) {
      print('Check limit error: $e');
      return {'allowed': false, 'error': 'Rate limit check failed'};
    }
  }

  /// Record query usage
  static Future<void> recordQueryUsage(
    Session session,
    int userId,
    String query,
    String response,
    int processingTimeMs, {
    String? userAgent,
    String? ipAddress,
  }) async {
    try {
      // Update user usage count
      final user = await getUserById(session, userId);
      if (user != null) {
        user.incrementUsage();
        await session.db.updateTableRow(user);
      }

      // Log the usage
      final usageLog = UsageLog.success(
        userId: userId,
        query: query,
        response: response,
        processingTimeMs: processingTimeMs,
        userAgent: userAgent,
        ipAddress: ipAddress,
      );

      await session.db.insertTableRow(usageLog);
    } catch (e) {
      print('Record usage error: $e');
    }
  }

  /// Generate random salt
  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Validate email format
  static bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
}
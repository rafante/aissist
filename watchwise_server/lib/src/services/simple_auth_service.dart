import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../models/simple_user.dart';

/// Simple JWT Authentication Service (no Serverpod dependencies)
class SimpleAuthService {
  static const String _jwtSecret = 'aissist_jwt_secret_2026_v1';
  
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

  /// Generate simple JWT token (basic version)
  static String generateJwtToken(SimpleUser user) {
    final header = base64.encode(utf8.encode(json.encode({
      'typ': 'JWT',
      'alg': 'HS256'
    })));
    
    final payload = base64.encode(utf8.encode(json.encode({
      'sub': user.id.toString(),
      'email': user.email,
      'tier': user.subscriptionTier,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch ~/ 1000,
    })));
    
    final signature = base64.encode(
      Hmac(sha256, utf8.encode(_jwtSecret))
        .convert(utf8.encode('$header.$payload'))
        .bytes
    );
    
    return '$header.$payload.$signature';
  }

  /// Verify JWT token and return user ID
  static int? verifyJwtToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final header = parts[0];
      final payload = parts[1];
      final signature = parts[2];
      
      // Verify signature
      final expectedSignature = base64.encode(
        Hmac(sha256, utf8.encode(_jwtSecret))
          .convert(utf8.encode('$header.$payload'))
          .bytes
      );
      
      if (signature != expectedSignature) return null;
      
      // Decode payload
      final payloadJson = json.decode(utf8.decode(base64.decode(payload)));
      
      // Check expiration
      final exp = payloadJson['exp'] as int;
      if (DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp) {
        return null;
      }
      
      return int.parse(payloadJson['sub']);
    } catch (e) {
      return null;
    }
  }

  /// Generate salt
  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }
}
import 'package:postgres/postgres.dart';
import '../models/simple_user.dart';

/// PostgreSQL Database Service for AIssist
class DatabaseService {
  late Connection _connection;
  bool _initialized = false;

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;

  DatabaseService({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
  });

  /// Connect and initialize tables
  Future<void> initialize() async {
    print('🔌 Connecting to PostgreSQL at $host:$port/$database...');
    
    _connection = await Connection.open(
      Endpoint(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );

    print('✅ Connected to PostgreSQL!');

    // Create tables if not exist
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        subscription_tier VARCHAR(20) DEFAULT 'free',
        daily_usage_count INTEGER DEFAULT 0,
        daily_usage_date DATE DEFAULT CURRENT_DATE,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS query_logs (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        query TEXT NOT NULL,
        response TEXT,
        processing_time_ms INTEGER,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
      CREATE INDEX IF NOT EXISTS idx_query_logs_user_id ON query_logs(user_id);
      CREATE INDEX IF NOT EXISTS idx_query_logs_created_at ON query_logs(created_at);
    ''');

    print('✅ Database tables ready!');
    _initialized = true;
  }

  /// Create a new user
  Future<SimpleUser?> createUser({
    required String email,
    required String passwordHash,
    String subscriptionTier = 'free',
  }) async {
    try {
      final result = await _connection.execute(
        Sql.named('''
          INSERT INTO users (email, password_hash, subscription_tier)
          VALUES (@email, @passwordHash, @tier)
          RETURNING id, email, password_hash, subscription_tier, daily_usage_count, created_at, updated_at
        '''),
        parameters: {
          'email': email,
          'passwordHash': passwordHash,
          'tier': subscriptionTier,
        },
      );
      if (result.isEmpty) return null;
      return _rowToUser(result.first);
    } catch (e) {
      print('❌ Error creating user: $e');
      return null;
    }
  }

  /// Find user by email
  Future<SimpleUser?> findUserByEmail(String email) async {
    final result = await _connection.execute(
      Sql.named('SELECT * FROM users WHERE email = @email'),
      parameters: {'email': email},
    );
    if (result.isEmpty) return null;
    return _rowToUser(result.first);
  }

  /// Find user by ID
  Future<SimpleUser?> findUserById(int id) async {
    final result = await _connection.execute(
      Sql.named('SELECT * FROM users WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _rowToUser(result.first);
  }

  /// Get all users
  Future<List<SimpleUser>> getAllUsers() async {
    final result = await _connection.execute('SELECT * FROM users ORDER BY id');
    return result.map(_rowToUser).toList();
  }

  /// Update user
  Future<SimpleUser?> updateUser(int id, {String? email, String? subscriptionTier}) async {
    final sets = <String>[];
    final params = <String, dynamic>{'id': id};
    
    if (email != null) {
      sets.add('email = @email');
      params['email'] = email;
    }
    if (subscriptionTier != null) {
      sets.add('subscription_tier = @tier');
      params['tier'] = subscriptionTier;
    }
    sets.add('updated_at = NOW()');

    final result = await _connection.execute(
      Sql.named('UPDATE users SET ${sets.join(', ')} WHERE id = @id RETURNING *'),
      parameters: params,
    );
    if (result.isEmpty) return null;
    return _rowToUser(result.first);
  }

  /// Delete user
  Future<bool> deleteUser(int id) async {
    await _connection.execute(
      Sql.named('DELETE FROM query_logs WHERE user_id = @id'),
      parameters: {'id': id},
    );
    final result = await _connection.execute(
      Sql.named('DELETE FROM users WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }

  /// Increment daily usage, reset if new day
  Future<int> incrementUsage(int userId) async {
    // Reset count if it's a new day
    await _connection.execute(
      Sql.named('''
        UPDATE users SET daily_usage_count = 0, daily_usage_date = CURRENT_DATE
        WHERE id = @id AND daily_usage_date < CURRENT_DATE
      '''),
      parameters: {'id': userId},
    );

    // Increment
    final result = await _connection.execute(
      Sql.named('''
        UPDATE users SET daily_usage_count = daily_usage_count + 1, updated_at = NOW()
        WHERE id = @id
        RETURNING daily_usage_count
      '''),
      parameters: {'id': userId},
    );
    if (result.isEmpty) return 0;
    return result.first[0] as int;
  }

  /// Get current usage count (reset if new day)
  Future<int> getUsageCount(int userId) async {
    await _connection.execute(
      Sql.named('''
        UPDATE users SET daily_usage_count = 0, daily_usage_date = CURRENT_DATE
        WHERE id = @id AND daily_usage_date < CURRENT_DATE
      '''),
      parameters: {'id': userId},
    );
    
    final result = await _connection.execute(
      Sql.named('SELECT daily_usage_count FROM users WHERE id = @id'),
      parameters: {'id': userId},
    );
    if (result.isEmpty) return 0;
    return result.first[0] as int;
  }

  /// Log a query
  Future<void> logQuery({
    required int userId,
    required String query,
    String? response,
    int? processingTimeMs,
  }) async {
    await _connection.execute(
      Sql.named('''
        INSERT INTO query_logs (user_id, query, response, processing_time_ms)
        VALUES (@userId, @query, @response, @timeMs)
      '''),
      parameters: {
        'userId': userId,
        'query': query,
        'response': response,
        'timeMs': processingTimeMs,
      },
    );
  }

  /// Get query logs
  Future<List<Map<String, dynamic>>> getQueryLogs({int limit = 50, int? userId}) async {
    String sql = 'SELECT ql.*, u.email FROM query_logs ql JOIN users u ON ql.user_id = u.id';
    final params = <String, dynamic>{};
    
    if (userId != null) {
      sql += ' WHERE ql.user_id = @userId';
      params['userId'] = userId;
    }
    sql += ' ORDER BY ql.created_at DESC LIMIT @limit';
    params['limit'] = limit;

    final result = await _connection.execute(Sql.named(sql), parameters: params);
    return result.map((row) {
      final cols = row.toColumnMap();
      return {
        'id': cols['id'],
        'user_id': cols['user_id'],
        'email': cols['email'],
        'query': cols['query'],
        'response': cols['response'],
        'processing_time_ms': cols['processing_time_ms'],
        'created_at': cols['created_at']?.toString(),
      };
    }).toList();
  }

  /// Get stats
  Future<Map<String, dynamic>> getStats() async {
    final userCount = await _connection.execute('SELECT COUNT(*) FROM users');
    final queryCount = await _connection.execute('SELECT COUNT(*) FROM query_logs');
    final todayQueries = await _connection.execute(
      "SELECT COUNT(*) FROM query_logs WHERE created_at::date = CURRENT_DATE"
    );
    final tierCounts = await _connection.execute(
      "SELECT subscription_tier, COUNT(*) as cnt FROM users GROUP BY subscription_tier"
    );

    final tiers = <String, int>{};
    for (final row in tierCounts) {
      tiers[row[0] as String] = row[1] as int;
    }

    return {
      'totalUsers': userCount.first[0],
      'totalQueries': queryCount.first[0],
      'todayQueries': todayQueries.first[0],
      'tiers': tiers,
    };
  }

  /// Convert DB row to SimpleUser
  SimpleUser _rowToUser(ResultRow row) {
    final cols = row.toColumnMap();
    return SimpleUser(
      id: cols['id'] as int,
      email: cols['email'] as String,
      passwordHash: cols['password_hash'] as String,
      subscriptionTier: (cols['subscription_tier'] as String?) ?? 'free',
      dailyUsageCount: (cols['daily_usage_count'] as int?) ?? 0,
      createdAt: cols['created_at'] is DateTime 
          ? cols['created_at'] as DateTime 
          : DateTime.parse(cols['created_at'].toString()),
      updatedAt: cols['updated_at'] is DateTime
          ? cols['updated_at'] as DateTime
          : DateTime.parse(cols['updated_at'].toString()),
    );
  }

  /// Close connection
  Future<void> close() async {
    await _connection.close();
  }
}

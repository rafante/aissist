import 'dart:io';
import 'dart:convert';
import '../lib/src/services/tmdb_service.dart';
import '../lib/src/services/reviva_llm_service.dart';
import '../lib/src/services/auth_service.dart';
import '../lib/src/protocol/user.dart';

/// Ultra-simple HTTP server for AIssist MVP with REAL authentication
Future<void> main() async {
  print('🎬 Starting AIssist Complete Navigation System with REAL AUTH...');
  
  // Get TMDB API key
  const apiKey = String.fromEnvironment('TMDB_API_KEY', defaultValue: '466fd9ba21e369cd51e7743d32b7833f');
  final tmdb = TmdbService(apiKey: apiKey);
  
  // Initialize Reviva LLM service
  final llmService = RevivaLLMService();
  
  // Create HTTP server  
  final port = int.fromEnvironment('PORT', defaultValue: 8081);
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🚀 Server running on port $port');
  
  // In-memory user storage (TODO: Connect to real DB in production)
  final Map<String, User> _users = {};
  int _nextUserId = 1;
  
  await for (final request in server) {
    final path = request.uri.path;
    final query = request.uri.queryParameters;
    
    try {
      // Handle CORS preflight
      if (request.method == 'OPTIONS') {
        request.response
          ..headers.add('Access-Control-Allow-Origin', '*')
          ..headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
          ..headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization')
          ..statusCode = 200;
        await request.response.close();
        continue;
      }
      
      switch (path) {
        case '/':
        case '/index':
        case '/home':
        case '/site':
        case '/app':
          await _handleLandingPage(request);
          break;
        case '/login':
          await _handleLoginPage(request);
          break;
        case '/signup':
          await _handleSignupPage(request);
          break;
        case '/dashboard':
          await _handleDashboard(request);
          break;
        case '/admin':
          await _handleAdminPage(request);
          break;
        case '/health':
          await _handleHealth(request);
          break;
        case '/movies/popular':
          await _handlePopularMovies(request, tmdb, query);
          break;
        case '/movies/search':
          await _handleSearchMovies(request, tmdb, query);
          break;
        case '/tv/search':
          await _handleSearchTV(request, tmdb, query);
          break;
        case '/ai/chat':
          await _handleAIChat(request, tmdb, llmService, query, _users);
          break;
        case '/auth/signup':
          await _handleSignupReal(request, _users, _nextUserId++);
          break;
        case '/auth/login':
          await _handleLoginReal(request, _users);
          break;
        case '/auth/me':
          await _handleMeReal(request, _users);
          break;
        case '/auth/usage':
          await _handleUsageReal(request, _users);
          break;
        default:
          await _handle404(request);
      }
    } catch (e) {
      await _handleError(request, e);
    }
  }
}

// REAL Authentication Handlers (no more mocking!)

Future<void> _handleSignupReal(HttpRequest request, Map<String, User> users, int userId) async {
  if (request.method != 'POST') {
    request.response
      ..statusCode = 405
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({'success': false, 'error': 'Method not allowed'}));
    await request.response.close();
    return;
  }

  try {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    final email = data['email'] as String?;
    final password = data['password'] as String?;
    final planType = data['planType'] as String? ?? 'free';

    // Validation
    if (email == null || email.isEmpty) {
      throw Exception('Email é obrigatório');
    }
    if (password == null || password.length < 6) {
      throw Exception('Senha deve ter pelo menos 6 caracteres');
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      throw Exception('Email inválido');
    }

    // Check if user already exists
    if (users.values.any((u) => u.email == email)) {
      throw Exception('Email já está em uso');
    }

    // Create new user
    final user = User(
      id: userId,
      email: email,
      passwordHash: AuthService.hashPassword(password),
      subscriptionTier: planType,
      dailyUsageCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save user
    users[userId.toString()] = user;

    // Generate JWT token
    final token = AuthService.generateJwtToken(user);

    print('✅ NEW USER REGISTERED: $email (ID: $userId, Plan: $planType)');

    final response = {
      'success': true,
      'user': user.toPublicJson(),
      'token': token,
      'message': 'Conta criada com sucesso! Bem-vindo ao AIssist.',
    };

    request.response
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode(response));
    await request.response.close();
  } catch (e) {
    print('❌ Signup error: $e');
    request.response
      ..statusCode = 400
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({'success': false, 'error': e.toString()}));
    await request.response.close();
  }
}

Future<void> _handleLoginReal(HttpRequest request, Map<String, User> users) async {
  if (request.method != 'POST') {
    request.response
      ..statusCode = 405
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({'success': false, 'error': 'Method not allowed'}));
    await request.response.close();
    return;
  }

  try {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    final email = data['email'] as String?;
    final password = data['password'] as String?;

    // Validation
    if (email == null || email.isEmpty) {
      throw Exception('Email é obrigatório');
    }
    if (password == null || password.isEmpty) {
      throw Exception('Senha é obrigatória');
    }

    // Find user by email
    User? user;
    for (final u in users.values) {
      if (u.email == email) {
        user = u;
        break;
      }
    }

    if (user == null) {
      throw Exception('Usuário não encontrado');
    }

    // Verify password
    if (!AuthService.verifyPassword(password, user.passwordHash)) {
      throw Exception('Senha incorreta');
    }

    // Update last login
    user.updatedAt = DateTime.now();

    // Generate JWT token
    final token = AuthService.generateJwtToken(user);

    print('🔑 USER LOGGED IN: $email (ID: ${user.id})');

    final response = {
      'success': true,
      'user': user.toPublicJson(),
      'token': token,
      'message': 'Login realizado com sucesso!',
    };

    request.response
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode(response));
    await request.response.close();
  } catch (e) {
    print('❌ Login error: $e');
    request.response
      ..statusCode = 401
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({'success': false, 'error': e.toString()}));
    await request.response.close();
  }
}

Future<void> _handleMeReal(HttpRequest request, Map<String, User> users) async {
  try {
    final authHeader = request.headers.value('authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      throw Exception('Token de autorização necessário');
    }

    final token = authHeader.substring(7);
    final userId = AuthService.verifyJwtToken(token);
    
    if (userId == null) {
      throw Exception('Token inválido ou expirado');
    }

    final user = users[userId.toString()];
    if (user == null) {
      throw Exception('Usuário não encontrado');
    }

    final response = {
      'success': true,
      'user': user.toPublicJson(),
    };

    request.response
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode(response));
    await request.response.close();
  } catch (e) {
    print('❌ /me error: $e');
    request.response
      ..statusCode = 401
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({'success': false, 'error': e.toString()}));
    await request.response.close();
  }
}

Future<void> _handleUsageReal(HttpRequest request, Map<String, User> users) async {
  try {
    final authHeader = request.headers.value('authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      throw Exception('Token de autorização necessário');
    }

    final token = authHeader.substring(7);
    final userId = AuthService.verifyJwtToken(token);
    
    if (userId == null) {
      throw Exception('Token inválido ou expirado');
    }

    final user = users[userId.toString()];
    if (user == null) {
      throw Exception('Usuário não encontrado');
    }

    // Calculate limits based on plan
    final dailyLimit = user.subscriptionTier == 'pro' ? 500 
                     : user.subscriptionTier == 'premium' ? 100 
                     : 5;
    final remainingQueries = dailyLimit - user.dailyUsageCount;

    final response = {
      'success': true,
      'usage': {
        'todayQueries': user.dailyUsageCount,
        'dailyLimit': dailyLimit,
        'remainingQueries': remainingQueries,
        'resetTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'subscriptionTier': user.subscriptionTier,
      }
    };

    request.response
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode(response));
    await request.response.close();
  } catch (e) {
    print('❌ /usage error: $e');
    request.response
      ..statusCode = 401
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({'success': false, 'error': e.toString()}));
    await request.response.close();
  }
}

Future<void> _handleAIChat(HttpRequest request, TmdbService tmdb, RevivaLLMService llmService, Map<String, String> query, Map<String, User> users) async {
  if (request.method != 'POST') {
    request.response
      ..statusCode = 405
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({'error': 'Method not allowed. Use POST.'}));
    await request.response.close();
    return;
  }
  
  try {
    // Check authentication
    final authHeader = request.headers.value('authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      throw Exception('Autenticação necessária');
    }

    final token = authHeader.substring(7);
    final userId = AuthService.verifyJwtToken(token);
    
    if (userId == null) {
      throw Exception('Token inválido ou expirado');
    }

    final user = users[userId.toString()];
    if (user == null) {
      throw Exception('Usuário não encontrado');
    }

    // Check rate limits
    final dailyLimit = user.subscriptionTier == 'pro' ? 500 
                     : user.subscriptionTier == 'premium' ? 100 
                     : 5;
    
    if (user.dailyUsageCount >= dailyLimit) {
      throw Exception('Limite de consultas diárias atingido. Upgrade seu plano ou tente amanhã.');
    }

    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    final userQuery = data['query'] as String?;
    if (userQuery == null || userQuery.trim().isEmpty) {
      throw Exception('Query é obrigatória');
    }
    
    // Search for movies related to the query to give AI context
    List<Map<String, dynamic>> movieContext = [];
    try {
      final movies = await tmdb.searchMovies(
        query: userQuery,
        page: 1,
        language: 'pt-BR',
      );
      movieContext = movies.take(5).map((m) => m.toJson()).toList();
    } catch (e) {
      print('⚠️ Could not fetch movie context: $e');
    }
    
    // Generate AI response
    final aiResponse = await llmService.generateMovieRecommendation(
      userQuery: userQuery,
      movieContext: movieContext,
    );
    
    // Update usage count
    user.dailyUsageCount++;
    final queriesRemaining = dailyLimit - user.dailyUsageCount;

    print('🤖 AI QUERY: User ${user.id} (${user.email}): "$userQuery" - Remaining: $queriesRemaining');

    request.response
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS')
      ..headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization')
      ..write(jsonEncode({
        'success': true,
        'query': userQuery,
        'ai_response': aiResponse,
        'movie_suggestions': movieContext,
        'queriesRemaining': queriesRemaining,
        'dailyLimit': dailyLimit,
        'subscriptionTier': user.subscriptionTier,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    await request.response.close();
    
  } catch (e) {
    print('❌ Error in AI chat: $e');
    request.response
      ..statusCode = 400
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({
        'success': false,
        'error': e.toString(),
      }));
    await request.response.close();
  }
}

// Copy all other handlers from original file (landing, login page, signup page, dashboard, admin, etc.)
// ... [Include all the HTML handlers from the original file here]

Future<void> _handleHealth(HttpRequest request) async {
  request.response
    ..headers.contentType = ContentType.json
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..write(jsonEncode({
      'status': 'healthy',
      'service': 'AIssist API with REAL AUTH',
      'version': '2.0-FIXED',
      'auth': 'JWT enabled',
      'endpoints': [
        '/ - Landing Page',
        '/login - Login Page', 
        '/signup - Cadastro Page',
        '/dashboard - User Dashboard',
        '/admin - Admin Panel',
        '/health - API Health',
        'POST /auth/signup - Create Account (REAL)',
        'POST /auth/login - User Login (REAL)',
        'GET /auth/me - User Info (REAL)',
        'GET /auth/usage - Usage Stats (REAL)',
        'POST /ai/chat - AI Chat with Rate Limiting (REAL)',
        'GET /movies/popular - Popular Movies',
        'GET /movies/search - Search Movies',
        'GET /tv/search - Search TV Shows'
      ]
    }));
  await request.response.close();
}

Future<void> _handle404(HttpRequest request) async {
  request.response
    ..statusCode = 404
    ..headers.contentType = ContentType.json
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..write(jsonEncode({
      'error': 'Endpoint não encontrado',
      'path': request.uri.path,
      'available_pages': [
        '/ - Página inicial',
        '/login - Login',
        '/signup - Cadastro',
        '/dashboard - Dashboard do usuário',
        '/admin - Painel admin'
      ],
      'available_api_endpoints': [
        'POST /auth/signup - Criar conta (REAL)',
        'POST /auth/login - Fazer login (REAL)',
        'GET /auth/me - Dados do usuário (REAL)',
        'GET /auth/usage - Estatísticas de uso (REAL)',
        'POST /ai/chat - Chat com IA (REAL + Rate limiting)',
        'GET /movies/popular - Filmes populares',
        'GET /movies/search?query= - Buscar filmes',
        'GET /tv/search?query= - Buscar séries',
        'GET /health - Status da API'
      ]
    }));
  await request.response.close();
}

Future<void> _handleError(HttpRequest request, Object error) async {
  print('❌ Error: $error');
  request.response
    ..statusCode = 500
    ..headers.contentType = ContentType.json
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..write(jsonEncode({
      'error': 'Internal server error',
      'message': error.toString()
    }));
  await request.response.close();
}

// Placeholder handlers - need to copy from original
Future<void> _handleLandingPage(HttpRequest request) async {
  request.response
    ..headers.contentType = ContentType.html
    ..write('<h1>Landing Page - TODO: Copy from original</h1>');
  await request.response.close();
}

Future<void> _handleLoginPage(HttpRequest request) async {
  request.response
    ..headers.contentType = ContentType.html
    ..write('<h1>Login Page - TODO: Copy from original</h1>');
  await request.response.close();
}

Future<void> _handleSignupPage(HttpRequest request) async {
  request.response
    ..headers.contentType = ContentType.html
    ..write('<h1>Signup Page - TODO: Copy from original</h1>');
  await request.response.close();
}

Future<void> _handleDashboard(HttpRequest request) async {
  request.response
    ..headers.contentType = ContentType.html
    ..write('<h1>Dashboard - TODO: Copy from original</h1>');
  await request.response.close();
}

Future<void> _handleAdminPage(HttpRequest request) async {
  request.response
    ..headers.contentType = ContentType.html
    ..write('<h1>Admin - TODO: Copy from original</h1>');
  await request.response.close();
}

Future<void> _handlePopularMovies(HttpRequest request, TmdbService tmdb, Map<String, String> query) async {
  // TODO: Copy from original
}

Future<void> _handleSearchMovies(HttpRequest request, TmdbService tmdb, Map<String, String> query) async {
  // TODO: Copy from original  
}

Future<void> _handleSearchTV(HttpRequest request, TmdbService tmdb, Map<String, String> query) async {
  // TODO: Copy from original
}
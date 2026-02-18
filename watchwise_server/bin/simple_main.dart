import 'dart:io';
import 'dart:convert';
import '../lib/src/services/tmdb_service.dart';
import '../lib/src/services/reviva_llm_service.dart';

/// Ultra-simple HTTP server for AIssist MVP
Future<void> main() async {
  print('🎬 Starting AIssist Simple API Server...');
  
  // Get TMDB API key
  const apiKey = String.fromEnvironment('TMDB_API_KEY', defaultValue: '466fd9ba21e369cd51e7743d32b7833f');
  final tmdb = TmdbService(apiKey: apiKey);
  
  // Initialize Reviva LLM service
  final llmService = RevivaLLMService();
  
  // Create HTTP server  
  final port = int.fromEnvironment('PORT', defaultValue: 8081);
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🚀 Server running on port $port');
  
  await for (final request in server) {
    final path = request.uri.path;
    final query = request.uri.queryParameters;
    
    try {
      // Handle CORS preflight
      if (request.method == 'OPTIONS') {
        request.response
          ..headers.add('Access-Control-Allow-Origin', '*')
          ..headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
          ..headers.add('Access-Control-Allow-Headers', 'Content-Type')
          ..statusCode = 200;
        await request.response.close();
        return;
      }
      
      switch (path) {
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
        case '/demo.html':
        case '/demo':
          await _handleDemo(request);
          break;
        case '/ai/chat':
          await _handleAIChat(request, tmdb, llmService, query);
          break;
        case '/auth/signup':
          await _handleSignup(request);
          break;
        case '/auth/login':
          await _handleLogin(request);
          break;
        case '/auth/me':
          await _handleMe(request);
          break;
        case '/auth/usage':
          await _handleUsage(request);
          break;
        default:
          await _handle404(request);
      }
    } catch (e) {
      await _handleError(request, e);
    }
  }
}

Future<void> _handleHealth(HttpRequest request) async {
  request.response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({
      'status': 'healthy',
      'service': 'AIssist API',
      'version': '1.0',
      'endpoints': [
        '/health',
        '/auth/signup (POST)',
        '/auth/login (POST)',
        '/auth/me (GET)',
        '/auth/usage (GET)',
        '/movies/popular',
        '/movies/search?query=Matrix',
        '/tv/search?query=Friends',
        '/ai/chat (POST)',
        '/demo.html'
      ]
    }));
  await request.response.close();
}

Future<void> _handlePopularMovies(HttpRequest request, TmdbService tmdb, Map<String, String> query) async {
  final page = int.tryParse(query['page'] ?? '1') ?? 1;
  final language = query['language'] ?? 'pt-BR';
  
  final movies = await tmdb.getPopularMovies(page: page, language: language);
  
  request.response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({
      'success': true,
      'data': movies.map((m) => m.toJson()).toList(),
      'page': page,
      'total_results': movies.length
    }));
  await request.response.close();
}

Future<void> _handleSearchMovies(HttpRequest request, TmdbService tmdb, Map<String, String> query) async {
  final searchQuery = query['query'];
  if (searchQuery == null || searchQuery.isEmpty) {
    request.response
      ..statusCode = 400
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': 'query parameter required'}));
    await request.response.close();
    return;
  }
  
  final page = int.tryParse(query['page'] ?? '1') ?? 1;
  final language = query['language'] ?? 'pt-BR';
  
  final movies = await tmdb.searchMovies(
    query: searchQuery,
    page: page,
    language: language,
  );
  
  request.response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({
      'success': true,
      'data': movies.map((m) => m.toJson()).toList(),
      'query': searchQuery,
      'page': page,
      'total_results': movies.length
    }));
  await request.response.close();
}

Future<void> _handleSearchTV(HttpRequest request, TmdbService tmdb, Map<String, String> query) async {
  final searchQuery = query['query'];
  if (searchQuery == null || searchQuery.isEmpty) {
    request.response
      ..statusCode = 400
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': 'query parameter required'}));
    await request.response.close();
    return;
  }
  
  final page = int.tryParse(query['page'] ?? '1') ?? 1;
  final language = query['language'] ?? 'pt-BR';
  
  final shows = await tmdb.searchTvShows(
    query: searchQuery,
    page: page,
    language: language,
  );
  
  request.response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({
      'success': true,
      'data': shows.map((s) => s.toJson()).toList(),
      'query': searchQuery,
      'page': page,
      'total_results': shows.length
    }));
  await request.response.close();
}

Future<void> _handleAIChat(HttpRequest request, TmdbService tmdb, RevivaLLMService llmService, Map<String, String> query) async {
  if (request.method != 'POST') {
    request.response
      ..statusCode = 405
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': 'Method not allowed. Use POST.'}));
    await request.response.close();
    return;
  }
  
  try {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    final userQuery = data['query'] as String?;
    if (userQuery == null || userQuery.trim().isEmpty) {
      request.response
        ..statusCode = 400
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'query field required'}));
      await request.response.close();
      return;
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
    
    request.response
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS')
      ..headers.add('Access-Control-Allow-Headers', 'Content-Type')
      ..write(jsonEncode({
        'success': true,
        'query': userQuery,
        'ai_response': aiResponse,
        'movie_suggestions': movieContext,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    await request.response.close();
    
  } catch (e) {
    print('❌ Error in AI chat: $e');
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({
        'error': 'Failed to generate AI response',
        'message': e.toString()
      }));
    await request.response.close();
  }
}

Future<void> _handleDemo(HttpRequest request) async {
  try {
    final demoFile = File('web/static/demo.html');
    final htmlContent = await demoFile.readAsString();
    
    request.response
      ..headers.contentType = ContentType.html
      ..write(htmlContent);
    await request.response.close();
  } catch (e) {
    print('❌ Error serving demo.html: $e');
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': 'Could not load demo page'}));
    await request.response.close();
  }
}

Future<void> _handle404(HttpRequest request) async {
  request.response
    ..statusCode = 404
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({
      'error': 'Not found',
      'available_endpoints': [
        '/health',
        '/movies/popular',
        '/movies/search?query=...',
        '/tv/search?query=...'
      ]
    }));
  await request.response.close();
}

Future<void> _handleSignup(HttpRequest request) async {
  if (request.method != 'POST') {
    request.response
      ..statusCode = 405
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': 'Method not allowed. Use POST.'}));
    await request.response.close();
    return;
  }

  try {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    final email = data['email'] as String?;
    final password = data['password'] as String?;
    final planType = data['planType'] as String? ?? 'free';

    print('✅ Signup: $email, plan: $planType');

    final response = {
      'success': true,
      'user': {
        'id': DateTime.now().millisecondsSinceEpoch % 10000,
        'email': email,
        'subscriptionTier': planType,
        'remainingQueries': planType == 'pro' ? 500 : planType == 'premium' ? 100 : 5,
        'createdAt': DateTime.now().toIso8601String(),
      },
      'token': 'jwt_${DateTime.now().millisecondsSinceEpoch}_${email?.split('@')[0] ?? 'user'}',
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
      ..write(jsonEncode({'error': 'Invalid signup data', 'message': e.toString()}));
    await request.response.close();
  }
}

Future<void> _handleLogin(HttpRequest request) async {
  if (request.method != 'POST') {
    request.response
      ..statusCode = 405
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': 'Method not allowed. Use POST.'}));
    await request.response.close();
    return;
  }

  try {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    final email = data['email'] as String?;
    final password = data['password'] as String?;

    print('🔑 Login: $email');

    final response = {
      'success': true,
      'user': {
        'id': 1,
        'email': email,
        'subscriptionTier': 'premium',
        'remainingQueries': 95,
        'lastLoginAt': DateTime.now().toIso8601String(),
      },
      'token': 'jwt_login_${DateTime.now().millisecondsSinceEpoch}_${email?.split('@')[0] ?? 'user'}',
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
      ..statusCode = 400
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': 'Invalid login data', 'message': e.toString()}));
    await request.response.close();
  }
}

Future<void> _handleMe(HttpRequest request) async {
  final authHeader = request.headers.value('authorization');
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    request.response
      ..statusCode = 401
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': 'Authorization header required'}));
    await request.response.close();
    return;
  }

  final response = {
    'success': true,
    'user': {
      'id': 1,
      'email': 'demo@aissist.com',
      'subscriptionTier': 'premium',
      'remainingQueries': 95,
      'totalQueries': 5,
      'createdAt': '2026-02-18T00:00:00Z',
      'lastLoginAt': DateTime.now().toIso8601String(),
    }
  };

  request.response
    ..headers.contentType = ContentType.json
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..write(jsonEncode(response));
  await request.response.close();
}

Future<void> _handleUsage(HttpRequest request) async {
  final response = {
    'success': true,
    'usage': {
      'todayQueries': 3,
      'dailyLimit': 100,
      'remainingQueries': 97,
      'resetTime': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'subscriptionTier': 'premium',
    }
  };

  request.response
    ..headers.contentType = ContentType.json
    ..headers.add('Access-Control-Allow-Origin', '*')
    ..write(jsonEncode(response));
  await request.response.close();
}

Future<void> _handleError(HttpRequest request, Object error) async {
  print('❌ Error: $error');
  request.response
    ..statusCode = 500
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({
      'error': 'Internal server error',
      'message': error.toString()
    }));
  await request.response.close();
}
import 'dart:io';
import 'dart:convert';
import '../lib/src/services/tmdb_service.dart';
import '../lib/src/services/reviva_llm_service.dart';
import '../lib/src/services/simple_auth_service.dart';
import '../lib/src/models/simple_user.dart';

/// Ultra-simple HTTP server for AIssist MVP with REAL authentication
Future<void> main() async {
  print('🎬 Starting AIssist Complete Navigation System with REAL AUTH...');
  
  // Get TMDB API key
  const apiKey = String.fromEnvironment('TMDB_API_KEY', defaultValue: '466fd9ba21e369cd51e7743d32b7833f');
  final tmdb = TmdbService(apiKey: apiKey);
  
  // Initialize Reviva LLM service
  final llmService = RevivaLLMService();
  
  // In-memory user storage (TODO: Connect to real DB in production)
  final Map<String, SimpleUser> _users = {};
  int _nextUserId = 1;
  
  // In-memory query log
  final List<Map<String, dynamic>> _queryLog = [];
  
  // Create HTTP server  
  final port = int.fromEnvironment('PORT', defaultValue: 8081);
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🚀 Server running on port $port with JWT authentication');
  
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
        case '/admin/stats':
          await _handleAdminStats(request, _users);
          break;
        case '/admin/users':
          await _handleAdminUsers(request, _users, _nextUserId++);
          break;
        case '/admin/queries':
          await _handleAdminQueries(request, queryLog: _queryLog);
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
          await _handleAIChat(request, tmdb, llmService, query, _users, _queryLog);
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
          // Handle paths with parameters (like /admin/users/123)
          if (path.startsWith('/admin/users/')) {
            final userId = path.split('/').last;
            await _handleAdminUserById(request, _users, userId);
          } else {
            await _handle404(request);
          }
      }
    } catch (e) {
      await _handleError(request, e);
    }
  }
}

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

// Rate limiting cache for TMDB requests
final Map<String, DateTime> _tmdbCache = {};
final Duration _cacheExpiry = Duration(minutes: 15);

Future<void> _handlePopularMovies(HttpRequest request, TmdbService tmdb, Map<String, String> query) async {
  final page = int.tryParse(query['page'] ?? '1') ?? 1;
  final language = query['language'] ?? 'pt-BR';
  final cacheKey = 'popular_${page}_$language';
  
  // Check cache first to prevent API spam
  final now = DateTime.now();
  if (_tmdbCache.containsKey(cacheKey) && 
      now.difference(_tmdbCache[cacheKey]!) < _cacheExpiry) {
    // Return cached response indicator
    request.response
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({
        'success': true,
        'cached': true,
        'message': 'Using cached data to prevent API rate limiting'
      }));
    await request.response.close();
    return;
  }
  
  try {
    final movies = await tmdb.getPopularMovies(page: page, language: language);
    _tmdbCache[cacheKey] = now; // Update cache timestamp
    
    request.response
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({
        'success': true,
        'data': movies.map((m) => m.toJson()).toList(),
        'page': page,
        'total_results': movies.length
      }));
  } catch (e) {
    print('⚠️ TMDB API error: $e');
    request.response
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({
        'success': false,
        'error': 'TMDB API temporarily unavailable',
        'fallback': true
      }));
  }
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

Future<void> _handleAIChat(HttpRequest request, TmdbService tmdb, RevivaLLMService llmService, Map<String, String> query, Map<String, SimpleUser> users, List<Map<String, dynamic>> queryLog) async {
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
    final userId = SimpleAuthService.verifyJwtToken(token);
    
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
    final startTime = DateTime.now();
    final aiResponse = await llmService.generateMovieRecommendation(
      userQuery: userQuery,
      movieContext: movieContext,
    );
    final endTime = DateTime.now();
    final processingTime = endTime.difference(startTime).inMilliseconds;
    
    // Update usage count
    user.dailyUsageCount++;
    final queriesRemaining = dailyLimit - user.dailyUsageCount;

    // Log query for admin panel
    queryLog.add({
      'timestamp': DateTime.now().toIso8601String(),
      'userId': user.id,
      'userEmail': user.email,
      'query': userQuery,
      'response': aiResponse.length > 100 ? aiResponse.substring(0, 100) + '...' : aiResponse,
      'processingTime': processingTime,
      'success': true,
      'movieSuggestions': movieContext.length,
      'subscriptionTier': user.subscriptionTier,
    });

    // Keep only last 1000 queries to prevent memory issues
    if (queryLog.length > 1000) {
      queryLog.removeRange(0, queryLog.length - 1000);
    }

    print('🤖 AI QUERY: User ${user.id} (${user.email}): "$userQuery" - Remaining: $queriesRemaining - Time: ${processingTime}ms');

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
    
    // Try to get user info for error logging
    try {
      final authHeader = request.headers.value('authorization');
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7);
        final userId = SimpleAuthService.verifyJwtToken(token);
        if (userId != null) {
          final user = users[userId.toString()];
          if (user != null) {
            // Log error query
            queryLog.add({
              'timestamp': DateTime.now().toIso8601String(),
              'userId': user.id,
              'userEmail': user.email,
              'query': 'Error occurred',
              'response': 'Error: ${e.toString()}',
              'processingTime': 0,
              'success': false,
              'movieSuggestions': 0,
              'subscriptionTier': user.subscriptionTier,
            });
          }
        }
      }
    } catch (logError) {
      // Ignore logging errors
    }
    
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

Future<void> _handleLandingPage(HttpRequest request) async {
  const htmlContent = r'''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AIssist - Demonstração do Design</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            line-height: 1.6;
            color: #ffffff;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
            overflow-x: hidden;
        }
        
        .hero-section {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
            background: linear-gradient(135deg, #0f0f23 0%, #1a1a2e 50%, #16213e 100%);
        }
        
        .hero-particles {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            overflow: hidden;
            z-index: 1;
        }
        
        .particle {
            position: absolute;
            width: 4px;
            height: 4px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 50%;
            animation: float 20s infinite linear;
        }

        .movie-poster {
            position: absolute;
            width: 60px;
            height: 90px;
            border-radius: 8px;
            opacity: 0.15;
            animation: floatPosters 25s infinite linear;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
        }

        @keyframes floatPosters {
            0% { opacity: 0; transform: translateY(110vh) translateX(0) rotate(0deg); }
            5% { opacity: 0.15; }
            95% { opacity: 0.15; }
            100% { opacity: 0; transform: translateY(-10vh) translateX(50px) rotate(10deg); }
        }
        
        @keyframes float {
            0% { opacity: 0; transform: translateY(100vh) translateX(0); }
            10% { opacity: 1; }
            90% { opacity: 1; }
            100% { opacity: 0; transform: translateY(-10vh) translateX(100px); }
        }
        
        .hero-content {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 24px;
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 60px;
            align-items: center;
            z-index: 2;
            position: relative;
        }
        
        .hero-text {
            animation: fadeInUp 0.8s ease-out 0.3s both;
        }
        
        .hero-title {
            font-size: 3.5rem;
            font-weight: 800;
            line-height: 1.1;
            margin-bottom: 24px;
        }
        
        .hero-title .gradient-text {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            animation: shimmer 2s ease-in-out 1.5s;
        }
        
        @keyframes shimmer {
            0% { filter: brightness(1); }
            50% { filter: brightness(1.3); }
            100% { filter: brightness(1); }
        }
        
        .hero-subtitle {
            font-size: 1.25rem;
            color: rgba(255, 255, 255, 0.8);
            margin-bottom: 32px;
            line-height: 1.6;
            animation: fadeInUp 0.8s ease-out 0.5s both;
        }
        
        .demo-box {
            background: rgba(255, 255, 255, 0.1);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 16px;
            padding: 20px;
            margin-bottom: 32px;
            animation: fadeInUp 0.8s ease-out 0.7s both;
        }
        
        .demo-header {
            display: flex;
            align-items: center;
            margin-bottom: 12px;
            color: rgba(255, 255, 255, 0.7);
            font-size: 0.9rem;
        }
        
        .demo-text {
            color: white;
            font-style: italic;
            font-size: 1rem;
        }
        
        .cta-buttons {
            display: flex;
            gap: 16px;
            margin-bottom: 24px;
            animation: fadeInUp 0.8s ease-out 0.9s both;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 12px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 24px rgba(102, 126, 234, 0.3);
        }
        
        .btn-secondary {
            background: transparent;
            color: rgba(255, 255, 255, 0.8);
            padding: 12px 24px;
            border: none;
            border-radius: 12px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: color 0.2s;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn-secondary:hover {
            color: white;
        }
        
        .hero-visual {
            display: flex;
            align-items: center;
            justify-content: center;
            animation: fadeInUp 0.8s ease-out 0.4s both;
        }
        
        .ai-brain {
            width: 300px;
            height: 300px;
            border-radius: 50%;
            background: radial-gradient(circle, rgba(102, 126, 234, 0.3) 0%, rgba(118, 75, 162, 0.1) 50%, transparent 100%);
            position: relative;
            animation: pulse 3s ease-in-out infinite;
        }
        
        @keyframes pulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.05); }
        }
        
        .ai-brain::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 120px;
            height: 120px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 50%;
            box-shadow: 0 0 30px rgba(102, 126, 234, 0.5);
        }
        
        .floating-elements {
            position: absolute;
            width: 100%;
            height: 100%;
        }
        
        .floating-element {
            position: absolute;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            animation: orbit 8s linear infinite;
        }
        
        .floating-element:nth-child(1) { background: #667eea; animation-delay: 0s; }
        .floating-element:nth-child(2) { background: #764ba2; animation-delay: -1s; }
        .floating-element:nth-child(3) { background: #f093fb; animation-delay: -2s; }
        .floating-element:nth-child(4) { background: #667eea; animation-delay: -3s; }
        .floating-element:nth-child(5) { background: #764ba2; animation-delay: -4s; }
        .floating-element:nth-child(6) { background: #f093fb; animation-delay: -5s; }
        
        @keyframes orbit {
            0% { transform: rotate(0deg) translateX(120px) rotate(0deg); }
            100% { transform: rotate(360deg) translateX(120px) rotate(-360deg); }
        }
        
        .features-section {
            padding: 100px 24px;
            background: rgba(0, 0, 0, 0.2);
        }
        
        .features-grid {
            max-width: 1200px;
            margin: 0 auto;
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
            gap: 24px;
        }
        
        .feature-card {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 16px;
            padding: 24px;
            transition: transform 0.2s, background 0.2s;
        }
        
        .feature-card:hover {
            transform: translateY(-4px);
            background: rgba(255, 255, 255, 0.08);
        }
        
        .feature-icon {
            width: 56px;
            height: 56px;
            border-radius: 16px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 20px;
            font-size: 28px;
        }
        
        .feature-title {
            font-size: 1.5rem;
            font-weight: 700;
            margin-bottom: 8px;
        }
        
        .feature-description {
            color: rgba(255, 255, 255, 0.8);
            line-height: 1.6;
        }
        
        .scroll-indicator {
            position: absolute;
            bottom: 32px;
            left: 50%;
            transform: translateX(-50%);
            text-align: center;
            color: rgba(255, 255, 255, 0.6);
            animation: bounce 2s infinite;
        }
        
        @keyframes bounce {
            0%, 100% { transform: translateX(-50%) translateY(0); }
            50% { transform: translateX(-50%) translateY(-10px); }
        }
        
        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        /* Mobile responsiveness */
        @media (max-width: 768px) {
            .hero-content {
                grid-template-columns: 1fr;
                gap: 40px;
                text-align: center;
            }
            
            .hero-title {
                font-size: 2.5rem;
            }
            
            .hero-subtitle {
                font-size: 1.1rem;
            }
            
            .cta-buttons {
                justify-content: center;
                flex-wrap: wrap;
            }
            
            .ai-brain {
                width: 250px;
                height: 250px;
            }
        }
        
        .typing-cursor {
            animation: blink 1s infinite;
        }
        
        @keyframes blink {
            0%, 50% { opacity: 1; }
            51%, 100% { opacity: 0; }
        }
    </style>
</head>
<body>
    <div class="hero-section">
        <!-- Animated particles background -->
        <div class="hero-particles" id="particles"></div>
        
        <div class="hero-content">
            <div class="hero-text">
                <h1 class="hero-title">
                    Descubra filmes<br>
                    perfeitos com<br>
                    <span class="gradient-text">Inteligência Artificial</span>
                </h1>
                
                <p class="hero-subtitle">
                    Nossa IA conversacional entende exatamente o que você quer assistir.
                    Sem spoilers, com recomendações precisas e uma experiência única.
                </p>
                
                <div class="demo-box">
                    <div class="demo-header">
                        🔍 Experimente perguntar:
                    </div>
                    <div class="demo-text" id="typing-text">
                        Filmes como Inception mas menos confuso<span class="typing-cursor">|</span>
                    </div>
                </div>
                
                <div class="cta-buttons">
                    <a href="/signup" class="btn-primary">
                        🚀 Começar Grátis
                    </a>
                    <a href="/login" class="btn-secondary">
                        🔑 Fazer Login
                    </a>
                </div>
            </div>
            
            <div class="hero-visual">
                <div class="ai-brain">
                    <div class="floating-elements">
                        <div class="floating-element"></div>
                        <div class="floating-element"></div>
                        <div class="floating-element"></div>
                        <div class="floating-element"></div>
                        <div class="floating-element"></div>
                        <div class="floating-element"></div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="scroll-indicator">
            <div>Role para descobrir mais</div>
            <div>↓</div>
        </div>
    </div>
    
    <div class="features-section">
        <div class="features-grid">
            <div class="feature-card">
                <div class="feature-icon">🧠</div>
                <h3 class="feature-title">IA Conversacional</h3>
                <p class="feature-description">
                    Converse naturalmente sobre o que você quer assistir. Nossa IA entende contexto, humor e preferências.
                </p>
            </div>
            
            <div class="feature-card">
                <div class="feature-icon">🔒</div>
                <h3 class="feature-title">Zero Spoilers</h3>
                <p class="feature-description">
                    Sistema inteligente que protege você de spoilers, mantendo apenas informações seguras.
                </p>
            </div>
            
            <div class="feature-card">
                <div class="feature-icon">🎮</div>
                <h3 class="feature-title">Gamificação RPG</h3>
                <p class="feature-description">
                    Ganhe XP, conquiste badges e evolua seu perfil de gosto cinematográfico.
                </p>
            </div>
            
            <div class="feature-card">
                <div class="feature-icon">✨</div>
                <h3 class="feature-title">Recomendações Precisas</h3>
                <p class="feature-description">
                    Algoritmo que aprende com suas avaliações para sugestões cada vez melhores.
                </p>
            </div>
            
            <div class="feature-card">
                <div class="feature-icon">👥</div>
                <h3 class="feature-title">Social & Colaborativo</h3>
                <p class="feature-description">
                    Compartilhe listas, veja o que amigos estão assistindo e descubra novos conteúdos.
                </p>
            </div>
            
            <div class="feature-card">
                <div class="feature-icon">⚡</div>
                <h3 class="feature-title">Busca Ultrarrápida</h3>
                <p class="feature-description">
                    Resultados instantâneos em nossa base com milhões de filmes e séries atualizados.
                </p>
            </div>
        </div>
    </div>

    <script>
        // Language and content configuration
        const isPortuguese = navigator.language.startsWith('pt') || 
                            navigator.languages.some(lang => lang.startsWith('pt'));
        
        const content = {
            pt: {
                heroTitle1: 'Descubra filmes',
                heroTitle2: 'perfeitos com',
                heroTitle3: 'Inteligência Artificial',
                heroSubtitle: 'Nossa IA conversacional entende exatamente o que você quer assistir. Sem spoilers, com recomendações precisas e uma experiência única.',
                demoHeader: '🔍 Experimente perguntar:',
                btnStart: '🚀 Começar Grátis',
                btnLogin: '🔑 Fazer Login',
                scrollText: 'Role para descobrir mais',
                typingTexts: [
                    'Filmes como Inception mas menos confuso',
                    'Algo romântico que não seja piegas',
                    'Terror psicológico tipo Black Mirror',
                    'Comédia inteligente estilo Brooklyn 99',
                    'Ficção científica com ação e drama'
                ],
                features: [
                    {
                        icon: '🧠',
                        title: 'IA Conversacional',
                        description: 'Converse naturalmente sobre o que você quer assistir. Nossa IA entende contexto, humor e preferências.'
                    },
                    {
                        icon: '🔒',
                        title: 'Zero Spoilers',
                        description: 'Sistema inteligente que protege você de spoilers, mantendo apenas informações seguras.'
                    },
                    {
                        icon: '🎮',
                        title: 'Gamificação RPG',
                        description: 'Ganhe XP, conquiste badges e evolua seu perfil de gosto cinematográfico.'
                    },
                    {
                        icon: '✨',
                        title: 'Recomendações Precisas',
                        description: 'Algoritmo que aprende com suas avaliações para sugestões cada vez melhores.'
                    },
                    {
                        icon: '👥',
                        title: 'Social & Colaborativo',
                        description: 'Compartilhe listas, veja o que amigos estão assistindo e descubra novos conteúdos.'
                    },
                    {
                        icon: '⚡',
                        title: 'Busca Ultrarrápida',
                        description: 'Resultados instantâneos em nossa base com milhões de filmes e séries atualizados.'
                    }
                ]
            },
            en: {
                heroTitle1: 'Discover perfect',
                heroTitle2: 'movies with',
                heroTitle3: 'Artificial Intelligence',
                heroSubtitle: 'Our conversational AI understands exactly what you want to watch. No spoilers, precise recommendations and a unique experience.',
                demoHeader: '🔍 Try asking:',
                btnStart: '🚀 Get Started Free',
                btnLogin: '🔑 Sign In',
                scrollText: 'Scroll to discover more',
                typingTexts: [
                    'Movies like Inception but less confusing',
                    'Something romantic that isn\'t cheesy',
                    'Psychological horror like Black Mirror',
                    'Smart comedy like Brooklyn Nine-Nine',
                    'Sci-fi with action and drama'
                ],
                features: [
                    {
                        icon: '🧠',
                        title: 'Conversational AI',
                        description: 'Chat naturally about what you want to watch. Our AI understands context, mood and preferences.'
                    },
                    {
                        icon: '🔒',
                        title: 'Zero Spoilers',
                        description: 'Smart system that protects you from spoilers, keeping only safe information.'
                    },
                    {
                        icon: '🎮',
                        title: 'RPG Gamification',
                        description: 'Earn XP, unlock badges and evolve your cinematic taste profile.'
                    },
                    {
                        icon: '✨',
                        title: 'Precise Recommendations',
                        description: 'Algorithm that learns from your ratings for increasingly better suggestions.'
                    },
                    {
                        icon: '👥',
                        title: 'Social & Collaborative',
                        description: 'Share lists, see what friends are watching and discover new content.'
                    },
                    {
                        icon: '⚡',
                        title: 'Ultra-fast Search',
                        description: 'Instant results in our database with millions of updated movies and series.'
                    }
                ]
            }
        };

        const lang = isPortuguese ? 'pt' : 'en';

        // Create floating particles
        function createParticles() {
            const container = document.getElementById('particles');
            const particleCount = 30; // Reduced for movie posters
            
            for (let i = 0; i < particleCount; i++) {
                const particle = document.createElement('div');
                particle.className = 'particle';
                particle.style.left = Math.random() * 100 + '%';
                particle.style.animationDelay = Math.random() * 20 + 's';
                particle.style.animationDuration = (Math.random() * 10 + 10) + 's';
                container.appendChild(particle);
            }
        }

        // Create floating movie posters
        async function createMoviePosters() {
            try {
                const response = await fetch('/movies/popular?page=' + (Math.floor(Math.random() * 5) + 1));
                const data = await response.json();
                
                if (data.success && data.data && data.data.length > 0) {
                    const container = document.getElementById('particles');
                    const posterCount = 12;
                    
                    for (let i = 0; i < posterCount; i++) {
                        const movie = data.data[Math.floor(Math.random() * data.data.length)];
                        if (movie.poster_path) {
                            const poster = document.createElement('div');
                            poster.className = 'movie-poster';
                            poster.style.backgroundImage = 'url(https://image.tmdb.org/t/p/w200' + movie.poster_path + ')';
                            poster.style.backgroundSize = 'cover';
                            poster.style.backgroundPosition = 'center';
                            poster.style.left = Math.random() * 95 + '%';
                            poster.style.animationDelay = Math.random() * 25 + 's';
                            poster.style.animationDuration = (Math.random() * 10 + 20) + 's';
                            container.appendChild(poster);
                        }
                    }
                }
            } catch (error) {
                console.log('Movie posters not loaded, using particles only');
            }
        }

        // Typing animation
        function startTypingAnimation() {
            const texts = content[lang].typingTexts;
            let textIndex = 0;
            const typingElement = document.getElementById('typing-text');
            
            function typeText(text, callback) {
                let charIndex = 0;
                const typingInterval = setInterval(() => {
                    if (charIndex < text.length) {
                        typingElement.innerHTML = text.substring(0, charIndex + 1) + '<span class="typing-cursor">|</span>';
                        charIndex++;
                    } else {
                        clearInterval(typingInterval);
                        setTimeout(callback, 2000);
                    }
                }, 80);
            }
            
            function deleteText(callback) {
                let currentText = texts[textIndex];
                let charIndex = currentText.length;
                const deletingInterval = setInterval(() => {
                    if (charIndex > 0) {
                        typingElement.innerHTML = currentText.substring(0, charIndex - 1) + '<span class="typing-cursor">|</span>';
                        charIndex--;
                    } else {
                        clearInterval(deletingInterval);
                        textIndex = (textIndex + 1) % texts.length;
                        setTimeout(callback, 500);
                    }
                }, 40);
            }
            
            function cycle() {
                typeText(texts[textIndex], () => {
                    deleteText(cycle);
                });
            }
            
            cycle();
        }

        // Update page content based on language
        function updateContent() {
            const c = content[lang];
            
            // Update hero section
            document.querySelector('.hero-title').innerHTML = 
                c.heroTitle1 + '<br>' + c.heroTitle2 + '<br>' + 
                '<span class="gradient-text">' + c.heroTitle3 + '</span>';
            
            document.querySelector('.hero-subtitle').textContent = c.heroSubtitle;
            document.querySelector('.demo-header').textContent = c.demoHeader;
            document.querySelector('.btn-primary').textContent = c.btnStart;
            document.querySelector('.btn-secondary').textContent = c.btnLogin;
            document.querySelector('.scroll-indicator div:first-child').textContent = c.scrollText;

            // Update features
            const featureCards = document.querySelectorAll('.feature-card');
            featureCards.forEach((card, index) => {
                if (c.features[index]) {
                    card.querySelector('.feature-icon').textContent = c.features[index].icon;
                    card.querySelector('.feature-title').textContent = c.features[index].title;
                    card.querySelector('.feature-description').textContent = c.features[index].description;
                }
            });
        }

        // Initialize animations
        document.addEventListener('DOMContentLoaded', () => {
            updateContent();
            createParticles();
            createMoviePosters();
            setTimeout(startTypingAnimation, 1000);
        });
    </script>
</body>
</html>
  ''';
  
  request.response
    ..headers.contentType = ContentType.html
    ..write(htmlContent);
  await request.response.close();
}

Future<void> _handleLoginPage(HttpRequest request) async {
  const htmlContent = r'''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - AIssist</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: linear-gradient(135deg, #0f1419 0%, #1a2332 50%, #2d3748 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 2rem;
        }
        .login-container {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            padding: 3rem;
            width: 100%;
            max-width: 420px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
        }
        .logo {
            text-align: center;
            font-size: 2.5rem;
            font-weight: 900;
            margin-bottom: 2rem;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .form-group {
            margin-bottom: 1.5rem;
        }
        .form-group label {
            display: block;
            margin-bottom: 0.5rem;
            font-weight: 600;
            color: rgba(255, 255, 255, 0.9);
        }
        .form-group input {
            width: 100%;
            padding: 1rem;
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 8px;
            background: rgba(255, 255, 255, 0.05);
            color: white;
            font-size: 1rem;
            transition: all 0.3s ease;
        }
        .form-group input:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.2);
        }
        .form-group input::placeholder {
            color: rgba(255, 255, 255, 0.5);
        }
        .btn {
            width: 100%;
            padding: 1rem;
            border: none;
            border-radius: 8px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            font-size: 1.1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            margin-bottom: 1rem;
        }
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(102, 126, 234, 0.3);
        }
        .btn:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
        }
        .links {
            text-align: center;
            margin-top: 1.5rem;
        }
        .links a {
            color: #667eea;
            text-decoration: none;
            transition: all 0.3s ease;
        }
        .links a:hover {
            color: #764ba2;
        }
        .message {
            padding: 1rem;
            border-radius: 8px;
            margin-bottom: 1rem;
            text-align: center;
        }
        .message.success {
            background: rgba(72, 187, 120, 0.2);
            border: 1px solid rgba(72, 187, 120, 0.3);
            color: #68d391;
        }
        .message.error {
            background: rgba(245, 101, 101, 0.2);
            border: 1px solid rgba(245, 101, 101, 0.3);
            color: #fc8181;
        }
        .loading {
            display: none;
            text-align: center;
            margin: 1rem 0;
        }
        .spinner {
            border: 2px solid rgba(255, 255, 255, 0.3);
            border-top: 2px solid #667eea;
            border-radius: 50%;
            width: 24px;
            height: 24px;
            animation: spin 1s linear infinite;
            display: inline-block;
            margin-right: 0.5rem;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="login-container">
        <h1 class="logo">AIssist</h1>
        
        <div id="message" class="message" style="display: none;"></div>
        
        <form id="loginForm">
            <div class="form-group">
                <label for="email" id="emailLabel">E-mail:</label>
                <input type="email" id="email" name="email" placeholder="seu@email.com" required>
            </div>
            
            <div class="form-group">
                <label for="password" id="passwordLabel">Senha:</label>
                <input type="password" id="password" name="password" placeholder="Sua senha" required>
            </div>
            
            <button type="submit" class="btn" id="loginBtn">
                🔑 Entrar
            </button>
            
            <div class="loading" id="loading">
                <div class="spinner"></div>
                <span id="loadingText">Fazendo login...</span>
            </div>
        </form>
        
        <div class="links">
            <a href="/signup" id="signupLink">Não tem conta? Cadastre-se</a><br><br>
            <a href="/" id="homeLink">← Voltar ao início</a>
        </div>
    </div>

    <script>
        // Language detection and content
        const isPortuguese = navigator.language.startsWith('pt') || 
                            navigator.languages.some(lang => lang.startsWith('pt'));
        
        const content = {
            pt: {
                title: 'Login - AIssist',
                emailLabel: 'E-mail:',
                emailPlaceholder: 'seu@email.com',
                passwordLabel: 'Senha:',
                passwordPlaceholder: 'Sua senha',
                loginBtn: '🔑 Entrar',
                loadingText: 'Fazendo login...',
                signupLink: 'Não tem conta? Cadastre-se',
                homeLink: '← Voltar ao início',
                successMsg: '✅ Login realizado com sucesso!',
                errorPrefix: '❌ '
            },
            en: {
                title: 'Login - AIssist',
                emailLabel: 'Email:',
                emailPlaceholder: 'your@email.com',
                passwordLabel: 'Password:',
                passwordPlaceholder: 'Your password',
                loginBtn: '🔑 Sign In',
                loadingText: 'Signing in...',
                signupLink: 'Don\'t have an account? Sign up',
                homeLink: '← Back to home',
                successMsg: '✅ Successfully signed in!',
                errorPrefix: '❌ '
            }
        };

        const lang = isPortuguese ? 'pt' : 'en';

        function updateContent() {
            const c = content[lang];
            document.title = c.title;
            document.documentElement.lang = lang;
            document.getElementById('emailLabel').textContent = c.emailLabel;
            document.getElementById('email').placeholder = c.emailPlaceholder;
            document.getElementById('passwordLabel').textContent = c.passwordLabel;
            document.getElementById('password').placeholder = c.passwordPlaceholder;
            document.getElementById('loginBtn').textContent = c.loginBtn;
            document.getElementById('loadingText').textContent = c.loadingText;
            document.getElementById('signupLink').textContent = c.signupLink;
            document.getElementById('homeLink').textContent = c.homeLink;
        }

        document.addEventListener('DOMContentLoaded', updateContent);

        document.getElementById('loginForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const loginBtn = document.getElementById('loginBtn');
            const loading = document.getElementById('loading');
            const message = document.getElementById('message');
            
            // Show loading
            loginBtn.disabled = true;
            loading.style.display = 'block';
            message.style.display = 'none';
            
            try {
                const response = await fetch('/auth/login', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ email, password })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    // Save token
                    localStorage.setItem('auth_token', data.token);
                    localStorage.setItem('user_data', JSON.stringify(data.user));
                    
                    // Show success message
                    message.className = 'message success';
                    message.textContent = content[lang].successMsg;
                    message.style.display = 'block';
                    
                    // Redirect to dashboard
                    setTimeout(() => {
                        window.location.href = '/dashboard';
                    }, 1500);
                } else {
                    throw new Error(data.message || 'Login error');
                }
            } catch (error) {
                message.className = 'message error';
                message.textContent = content[lang].errorPrefix + error.message;
                message.style.display = 'block';
            } finally {
                loginBtn.disabled = false;
                loading.style.display = 'none';
            }
        });
    </script>
</body>
</html>
  ''';
  
  request.response
    ..headers.contentType = ContentType.html
    ..write(htmlContent);
  await request.response.close();
}

Future<void> _handleSignupPage(HttpRequest request) async {
  const htmlContent = r'''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cadastro - AIssist</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: linear-gradient(135deg, #0f1419 0%, #1a2332 50%, #2d3748 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 2rem;
        }
        .signup-container {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            padding: 3rem;
            width: 100%;
            max-width: 420px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
        }
        .logo {
            text-align: center;
            font-size: 2.5rem;
            font-weight: 900;
            margin-bottom: 2rem;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .form-group {
            margin-bottom: 1.5rem;
        }
        .form-group label {
            display: block;
            margin-bottom: 0.5rem;
            font-weight: 600;
            color: rgba(255, 255, 255, 0.9);
        }
        .form-group input, .form-group select {
            width: 100%;
            padding: 1rem;
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 8px;
            background: rgba(255, 255, 255, 0.05);
            color: white;
            font-size: 1rem;
            transition: all 0.3s ease;
        }
        .form-group input:focus, .form-group select:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.2);
        }
        .form-group input::placeholder {
            color: rgba(255, 255, 255, 0.5);
        }
        .form-group select option {
            background: #1a2332;
            color: white;
        }
        .plan-info {
            background: rgba(102, 126, 234, 0.1);
            border: 1px solid rgba(102, 126, 234, 0.3);
            border-radius: 8px;
            padding: 1rem;
            margin-top: 0.5rem;
            font-size: 0.9rem;
        }
        .btn {
            width: 100%;
            padding: 1rem;
            border: none;
            border-radius: 8px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            font-size: 1.1rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            margin-bottom: 1rem;
        }
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(102, 126, 234, 0.3);
        }
        .btn:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
        }
        .links {
            text-align: center;
            margin-top: 1.5rem;
        }
        .links a {
            color: #667eea;
            text-decoration: none;
            transition: all 0.3s ease;
        }
        .links a:hover {
            color: #764ba2;
        }
        .message {
            padding: 1rem;
            border-radius: 8px;
            margin-bottom: 1rem;
            text-align: center;
        }
        .message.success {
            background: rgba(72, 187, 120, 0.2);
            border: 1px solid rgba(72, 187, 120, 0.3);
            color: #68d391;
        }
        .message.error {
            background: rgba(245, 101, 101, 0.2);
            border: 1px solid rgba(245, 101, 101, 0.3);
            color: #fc8181;
        }
        .loading {
            display: none;
            text-align: center;
            margin: 1rem 0;
        }
        .spinner {
            border: 2px solid rgba(255, 255, 255, 0.3);
            border-top: 2px solid #667eea;
            border-radius: 50%;
            width: 24px;
            height: 24px;
            animation: spin 1s linear infinite;
            display: inline-block;
            margin-right: 0.5rem;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="signup-container">
        <h1 class="logo">AIssist</h1>
        
        <div id="message" class="message" style="display: none;"></div>
        
        <form id="signupForm">
            <div class="form-group">
                <label for="email" id="emailLabel">E-mail:</label>
                <input type="email" id="email" name="email" placeholder="seu@email.com" required>
            </div>
            
            <div class="form-group">
                <label for="password" id="passwordLabel">Senha:</label>
                <input type="password" id="password" name="password" placeholder="Mínimo 6 caracteres" required minlength="6">
            </div>
            
            <div class="form-group">
                <label for="planType" id="planLabel">Plano:</label>
                <select id="planType" name="planType" required>
                    <option value="free" id="freePlan">Free - 5 consultas/dia</option>
                    <option value="premium" id="premiumPlan">Premium - 100 consultas/dia (R\$ 19,90/mês)</option>
                    <option value="pro" id="proPlan">Pro - 500 consultas/dia (R\$ 39,90/mês)</option>
                </select>
                <div class="plan-info" id="planInfo">
                    ✅ Plano Free: 5 consultas por dia, sem custo
                </div>
            </div>
            
            <button type="submit" class="btn" id="signupBtn">
                🚀 Criar Conta
            </button>
            
            <div class="loading" id="loading">
                <div class="spinner"></div>
                <span id="loadingText">Criando sua conta...</span>
            </div>
        </form>
        
        <div class="links">
            <a href="/login" id="loginLink">Já tem conta? Faça login</a><br><br>
            <a href="/" id="homeLink">← Voltar ao início</a>
        </div>
    </div>

    <script>
        // Language detection and content
        const isPortuguese = navigator.language.startsWith('pt') || 
                            navigator.languages.some(lang => lang.startsWith('pt'));
        
        const content = {
            pt: {
                title: 'Cadastro - AIssist',
                emailLabel: 'E-mail:',
                emailPlaceholder: 'seu@email.com',
                passwordLabel: 'Senha:',
                passwordPlaceholder: 'Mínimo 6 caracteres',
                planLabel: 'Plano:',
                freePlan: 'Free - 5 consultas/dia',
                premiumPlan: 'Premium - 100 consultas/dia (R$ 19,90/mês)',
                proPlan: 'Pro - 500 consultas/dia (R$ 39,90/mês)',
                signupBtn: '🚀 Criar Conta',
                loadingText: 'Criando sua conta...',
                loginLink: 'Já tem conta? Faça login',
                homeLink: '← Voltar ao início',
                planInfos: {
                    free: '✅ Plano Free: 5 consultas por dia, sem custo',
                    premium: '💎 Plano Premium: 100 consultas por dia, R$ 19,90/mês',
                    pro: '🚀 Plano Pro: 500 consultas por dia, R$ 39,90/mês'
                },
                successMsg: '✅ Conta criada com sucesso! Bem-vindo ao AIssist.',
                errorPrefix: '❌ '
            },
            en: {
                title: 'Sign Up - AIssist',
                emailLabel: 'Email:',
                emailPlaceholder: 'your@email.com',
                passwordLabel: 'Password:',
                passwordPlaceholder: 'Minimum 6 characters',
                planLabel: 'Plan:',
                freePlan: 'Free - 5 queries/day',
                premiumPlan: 'Premium - 100 queries/day ($19.90/month)',
                proPlan: 'Pro - 500 queries/day ($39.90/month)',
                signupBtn: '🚀 Create Account',
                loadingText: 'Creating your account...',
                loginLink: 'Already have an account? Sign in',
                homeLink: '← Back to home',
                planInfos: {
                    free: '✅ Free Plan: 5 queries per day, no cost',
                    premium: '💎 Premium Plan: 100 queries per day, $19.90/month',
                    pro: '🚀 Pro Plan: 500 queries per day, $39.90/month'
                },
                successMsg: '✅ Account created successfully! Welcome to AIssist.',
                errorPrefix: '❌ '
            }
        };

        const lang = isPortuguese ? 'pt' : 'en';

        function updateContent() {
            const c = content[lang];
            document.title = c.title;
            document.documentElement.lang = lang;
            document.getElementById('emailLabel').textContent = c.emailLabel;
            document.getElementById('email').placeholder = c.emailPlaceholder;
            document.getElementById('passwordLabel').textContent = c.passwordLabel;
            document.getElementById('password').placeholder = c.passwordPlaceholder;
            document.getElementById('planLabel').textContent = c.planLabel;
            document.getElementById('freePlan').textContent = c.freePlan;
            document.getElementById('premiumPlan').textContent = c.premiumPlan;
            document.getElementById('proPlan').textContent = c.proPlan;
            document.getElementById('signupBtn').textContent = c.signupBtn;
            document.getElementById('loadingText').textContent = c.loadingText;
            document.getElementById('loginLink').textContent = c.loginLink;
            document.getElementById('homeLink').textContent = c.homeLink;
            document.getElementById('planInfo').innerHTML = c.planInfos.free;
        }

        // Update plan info
        document.getElementById('planType').addEventListener('change', (e) => {
            const planInfo = document.getElementById('planInfo');
            const value = e.target.value;
            const c = content[lang];
            planInfo.innerHTML = c.planInfos[value];
        });

        document.addEventListener('DOMContentLoaded', updateContent);
        
        document.getElementById('signupForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const planType = document.getElementById('planType').value;
            const signupBtn = document.getElementById('signupBtn');
            const loading = document.getElementById('loading');
            const message = document.getElementById('message');
            
            // Show loading
            signupBtn.disabled = true;
            loading.style.display = 'block';
            message.style.display = 'none';
            
            try {
                const response = await fetch('/auth/signup', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ email, password, planType })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    // Save token
                    localStorage.setItem('auth_token', data.token);
                    localStorage.setItem('user_data', JSON.stringify(data.user));
                    
                    // Show success message
                    message.className = 'message success';
                    message.textContent = content[lang].successMsg;
                    message.style.display = 'block';
                    
                    // Redirect to dashboard
                    setTimeout(() => {
                        window.location.href = '/dashboard';
                    }, 2000);
                } else {
                    throw new Error(data.message || 'Signup error');
                }
            } catch (error) {
                message.className = 'message error';
                message.textContent = content[lang].errorPrefix + error.message;
                message.style.display = 'block';
            } finally {
                signupBtn.disabled = false;
                loading.style.display = 'none';
            }
        });
    </script>
</body>
</html>
  ''';
  
  request.response
    ..headers.contentType = ContentType.html
    ..write(htmlContent);
  await request.response.close();
}

Future<void> _handle404(HttpRequest request) async {
  request.response
    ..statusCode = 404
    ..headers.contentType = ContentType.json
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
        'POST /auth/signup - Criar conta',
        'POST /auth/login - Fazer login',
        'GET /auth/me - Dados do usuário',
        'GET /auth/usage - Estatísticas de uso',
        'POST /ai/chat - Chat com IA',
        'GET /movies/popular - Filmes populares',
        'GET /movies/search?query= - Buscar filmes',
        'GET /tv/search?query= - Buscar séries',
        'GET /health - Status da API'
      ]
    }));
  await request.response.close();
}

Future<void> _handleSignupReal(HttpRequest request, Map<String, SimpleUser> users, int userId) async {
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
    final user = SimpleUser(
      id: userId,
      email: email,
      passwordHash: SimpleAuthService.hashPassword(password),
      subscriptionTier: planType,
      dailyUsageCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save user
    users[userId.toString()] = user;

    // Generate JWT token
    final token = SimpleAuthService.generateJwtToken(user);

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

Future<void> _handleLoginReal(HttpRequest request, Map<String, SimpleUser> users) async {
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
    SimpleUser? user;
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
    if (!SimpleAuthService.verifyPassword(password, user.passwordHash)) {
      throw Exception('Senha incorreta');
    }

    // Update last login
    user.updatedAt = DateTime.now();

    // Generate JWT token
    final token = SimpleAuthService.generateJwtToken(user);

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

Future<void> _handleMeReal(HttpRequest request, Map<String, SimpleUser> users) async {
  try {
    final authHeader = request.headers.value('authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      throw Exception('Token de autorização necessário');
    }

    final token = authHeader.substring(7);
    final userId = SimpleAuthService.verifyJwtToken(token);
    
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

Future<void> _handleUsageReal(HttpRequest request, Map<String, SimpleUser> users) async {
  try {
    final authHeader = request.headers.value('authorization');
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      throw Exception('Token de autorização necessário');
    }

    final token = authHeader.substring(7);
    final userId = SimpleAuthService.verifyJwtToken(token);
    
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

Future<void> _handleDashboard(HttpRequest request) async {
  const htmlContent = r'''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard - AIssist</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: linear-gradient(135deg, #0f1419 0%, #1a2332 50%, #2d3748 100%);
            color: white;
            min-height: 100vh;
        }
        .header {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(20px);
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
            padding: 1rem 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .logo {
            font-size: 1.8rem;
            font-weight: 900;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .user-info {
            display: flex;
            align-items: center;
            gap: 1rem;
        }
        .user-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
        }
        .logout-btn {
            background: rgba(245, 101, 101, 0.2);
            border: 1px solid rgba(245, 101, 101, 0.3);
            color: #fc8181;
            padding: 0.5rem 1rem;
            border-radius: 6px;
            text-decoration: none;
            font-size: 0.9rem;
            transition: all 0.3s ease;
        }
        .logout-btn:hover {
            background: rgba(245, 101, 101, 0.3);
        }
        .main {
            padding: 2rem;
            max-width: 1200px;
            margin: 0 auto;
        }
        .welcome {
            text-align: center;
            margin-bottom: 3rem;
        }
        .welcome h1 {
            font-size: 2.5rem;
            margin-bottom: 1rem;
        }
        .welcome p {
            font-size: 1.2rem;
            opacity: 0.8;
        }
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
            gap: 2rem;
            margin-bottom: 3rem;
        }
        .card {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 16px;
            padding: 2rem;
        }
        .card h3 {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            margin-bottom: 1rem;
            font-size: 1.3rem;
        }
        .stat-number {
            font-size: 2.5rem;
            font-weight: 900;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 0.5rem;
        }
        .stat-label {
            opacity: 0.8;
            font-size: 0.9rem;
        }
        .progress-bar {
            width: 100%;
            height: 8px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 4px;
            overflow: hidden;
            margin: 1rem 0;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            transition: width 0.3s ease;
        }
        .chat-container {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            border-radius: 16px;
            padding: 2rem;
            margin-top: 2rem;
        }
        .chat-messages {
            min-height: 300px;
            max-height: 400px;
            overflow-y: auto;
            margin-bottom: 1rem;
            padding: 1rem;
            background: rgba(0, 0, 0, 0.2);
            border-radius: 12px;
        }
        .message {
            margin-bottom: 1rem;
            padding: 1rem;
            border-radius: 12px;
            max-width: 80%;
        }
        .message.user {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin-left: auto;
            text-align: right;
        }
        .message.ai {
            background: rgba(255, 255, 255, 0.1);
        }
        .chat-input {
            display: flex;
            gap: 1rem;
        }
        .chat-input input {
            flex: 1;
            padding: 1rem;
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 12px;
            background: rgba(255, 255, 255, 0.05);
            color: white;
            font-size: 1rem;
        }
        .chat-input input:focus {
            outline: none;
            border-color: #667eea;
        }
        .chat-input input::placeholder {
            color: rgba(255, 255, 255, 0.5);
        }
        .send-btn {
            padding: 1rem 1.5rem;
            border: none;
            border-radius: 12px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        .send-btn:hover {
            transform: translateY(-2px);
        }
        .send-btn:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
        }
        @media (max-width: 768px) {
            .header { padding: 1rem; flex-direction: column; gap: 1rem; }
            .main { padding: 1rem; }
            .welcome h1 { font-size: 2rem; }
            .dashboard-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">AIssist</div>
        <div class="user-info">
            <div class="user-avatar" id="userAvatar">?</div>
            <div>
                <div id="userName">Carregando...</div>
                <div id="userPlan" style="font-size: 0.8rem; opacity: 0.7;">...</div>
            </div>
            <a href="#" class="logout-btn" onclick="logout()" id="logoutBtn">🚪 Sair</a>
        </div>
    </div>

    <div class="main">
        <div class="welcome">
            <h1 id="welcomeMessage">Bem-vindo ao AIssist! 👋</h1>
            <p id="welcomeSubtitle">Seu assistente inteligente para descobrir entretenimento personalizado</p>
        </div>

        <div class="dashboard-grid">
            <div class="card">
                <h3 id="statsTitle">📊 Suas Estatísticas</h3>
                <div class="stat-number" id="remainingQueries">--</div>
                <div class="stat-label" id="remainingLabel">Consultas restantes hoje</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="progressFill" style="width: 0%"></div>
                </div>
                <div class="stat-label" id="planDetails">Plano: ...</div>
            </div>

            <div class="card">
                <h3 id="recommendationsTitle">🎬 Recomendações</h3>
                <p id="recommendationsSubtitle">Baseadas no seu histórico e preferências:</p>
                <div id="recommendations" style="margin-top: 1rem;">
                    <div style="opacity: 0.7;" id="noRecommendations">Faça sua primeira consulta para receber recomendações personalizadas!</div>
                </div>
            </div>

            <div class="card">
                <h3 id="activityTitle">📈 Atividade Recente</h3>
                <div id="recentActivity">
                    <div style="opacity: 0.7;" id="noActivity">Nenhuma atividade recente</div>
                </div>
            </div>
        </div>

        <div class="chat-container">
            <h3 id="chatTitle">🤖 Chat com IA - Pergunte sobre filmes e séries</h3>
            <div class="chat-messages" id="chatMessages">
                <div class="message ai">
                    <strong>AIssist:</strong> <span id="aiWelcome">Olá! Sou seu assistente de entretenimento. Pergunte sobre filmes, séries, ou peça recomendações personalizadas! 🎬✨</span>
                </div>
            </div>
            <div class="chat-input">
                <input type="text" id="messageInput" placeholder="Ex: 'Quero um filme de ficção científica para hoje à noite'" maxlength="500">
                <button class="send-btn" id="sendBtn" onclick="sendMessage()">🚀 Enviar</button>
            </div>
        </div>
    </div>

    <script>
        // Language detection and content
        const isPortuguese = navigator.language.startsWith('pt') || 
                            navigator.languages.some(lang => lang.startsWith('pt'));
        
        const content = {
            pt: {
                title: 'Dashboard - AIssist',
                logoutBtn: '🚪 Sair',
                welcomeMessage: 'Bem-vindo ao AIssist! 👋',
                welcomeSubtitle: 'Seu assistente inteligente para descobrir entretenimento personalizado',
                statsTitle: '📊 Suas Estatísticas',
                remainingLabel: 'Consultas restantes hoje',
                recommendationsTitle: '🎬 Recomendações',
                recommendationsSubtitle: 'Baseadas no seu histórico e preferências:',
                noRecommendations: 'Faça sua primeira consulta para receber recomendações personalizadas!',
                activityTitle: '📈 Atividade Recente',
                noActivity: 'Nenhuma atividade recente',
                chatTitle: '🤖 Chat com IA - Pergunte sobre filmes e séries',
                chatPlaceholder: 'Ex: \'Quero um filme de ficção científica para hoje à noite\'',
                sendBtn: '🚀 Enviar',
                sendingBtn: '⏳ Pensando...',
                aiWelcome: 'Olá! Sou seu assistente de entretenimento. Pergunte sobre filmes, séries, ou peça recomendações personalizadas! 🎬✨',
                errorMsg: '❌ Desculpe, ocorreu um erro: ',
                planPrefix: 'Plano '
            },
            en: {
                title: 'Dashboard - AIssist',
                logoutBtn: '🚪 Sign Out',
                welcomeMessage: 'Welcome to AIssist! 👋',
                welcomeSubtitle: 'Your smart assistant to discover personalized entertainment',
                statsTitle: '📊 Your Statistics',
                remainingLabel: 'Queries remaining today',
                recommendationsTitle: '🎬 Recommendations',
                recommendationsSubtitle: 'Based on your history and preferences:',
                noRecommendations: 'Make your first query to receive personalized recommendations!',
                activityTitle: '📈 Recent Activity',
                noActivity: 'No recent activity',
                chatTitle: '🤖 AI Chat - Ask about movies and series',
                chatPlaceholder: 'Ex: \'I want a sci-fi movie for tonight\'',
                sendBtn: '🚀 Send',
                sendingBtn: '⏳ Thinking...',
                aiWelcome: 'Hello! I\'m your entertainment assistant. Ask about movies, series, or request personalized recommendations! 🎬✨',
                errorMsg: '❌ Sorry, an error occurred: ',
                planPrefix: 'Plan '
            }
        };

        const lang = isPortuguese ? 'pt' : 'en';

        // Check authentication
        const token = localStorage.getItem('auth_token');
        const userData = localStorage.getItem('user_data');
        
        if (!token || !userData) {
            window.location.href = '/login';
        }
        
        const user = JSON.parse(userData);

        function updateContent() {
            const c = content[lang];
            document.title = c.title;
            document.documentElement.lang = lang;
            document.getElementById('logoutBtn').textContent = c.logoutBtn;
            document.getElementById('welcomeSubtitle').textContent = c.welcomeSubtitle;
            document.getElementById('statsTitle').textContent = c.statsTitle;
            document.getElementById('remainingLabel').textContent = c.remainingLabel;
            document.getElementById('recommendationsTitle').textContent = c.recommendationsTitle;
            document.getElementById('recommendationsSubtitle').textContent = c.recommendationsSubtitle;
            document.getElementById('noRecommendations').textContent = c.noRecommendations;
            document.getElementById('activityTitle').textContent = c.activityTitle;
            document.getElementById('noActivity').textContent = c.noActivity;
            document.getElementById('chatTitle').textContent = c.chatTitle;
            document.getElementById('messageInput').placeholder = c.chatPlaceholder;
            document.getElementById('sendBtn').textContent = c.sendBtn;
            document.getElementById('aiWelcome').textContent = c.aiWelcome;
        }
        
        // Update user info
        document.getElementById('userAvatar').textContent = user.email.charAt(0).toUpperCase();
        document.getElementById('userName').textContent = user.email.split('@')[0];
        document.getElementById('userPlan').textContent = user.subscriptionTier.charAt(0).toUpperCase() + user.subscriptionTier.slice(1);
        
        // Update content based on language
        updateContent();
        
        // Set welcome message with username
        const welcomeText = lang === 'pt' ? 
            'Bem-vindo, ' + user.email.split('@')[0] + '! 👋' : 
            'Welcome, ' + user.email.split('@')[0] + '! 👋';
        document.getElementById('welcomeMessage').textContent = welcomeText;
        
        // Update stats
        document.getElementById('remainingQueries').textContent = user.remainingQueries;
        
        const totalQueries = user.subscriptionTier === 'pro' ? 500 : user.subscriptionTier === 'premium' ? 100 : 5;
        const usedQueries = totalQueries - user.remainingQueries;
        const progressPercent = (usedQueries / totalQueries) * 100;
        
        document.getElementById('progressFill').style.width = progressPercent + '%';
        const usedText = lang === 'pt' ? ' consultas usadas' : ' queries used';
        document.getElementById('planDetails').textContent = content[lang].planPrefix + user.subscriptionTier + ': ' + usedQueries + '/' + totalQueries + usedText;
        
        // Chat functionality
        document.getElementById('messageInput').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                sendMessage();
            }
        });
        
        async function sendMessage() {
            const input = document.getElementById('messageInput');
            const message = input.value.trim();
            
            if (!message) return;
            
            const chatMessages = document.getElementById('chatMessages');
            const sendBtn = document.getElementById('sendBtn');
            
            // Add user message
            const userMessage = document.createElement('div');
            userMessage.className = 'message user';
            const youLabel = lang === 'pt' ? 'Você:' : 'You:';
            userMessage.innerHTML = '<strong>' + youLabel + '</strong> ' + message;
            chatMessages.appendChild(userMessage);
            
            // Clear input and disable button
            input.value = '';
            sendBtn.disabled = true;
            sendBtn.textContent = content[lang].sendingBtn;
            
            try {
                const response = await fetch('/ai/chat', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer ' + token
                    },
                    body: JSON.stringify({ query: message })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    // Add AI response
                    const aiMessage = document.createElement('div');
                    aiMessage.className = 'message ai';
                    aiMessage.innerHTML = '<strong>AIssist:</strong> ' + data.ai_response;
                    chatMessages.appendChild(aiMessage);
                    
                    // Update remaining queries
                    if (data.queriesRemaining !== undefined) {
                        user.remainingQueries = data.queriesRemaining;
                        localStorage.setItem('user_data', JSON.stringify(user));
                        document.getElementById('remainingQueries').textContent = data.queriesRemaining;
                        
                        const newUsedQueries = totalQueries - data.queriesRemaining;
                        const newProgressPercent = (newUsedQueries / totalQueries) * 100;
                        document.getElementById('progressFill').style.width = newProgressPercent + '%';
                        const usedText = lang === 'pt' ? ' consultas usadas' : ' queries used';
                        document.getElementById('planDetails').textContent = content[lang].planPrefix + user.subscriptionTier + ': ' + newUsedQueries + '/' + totalQueries + usedText;
                    }
                } else {
                    throw new Error(data.error || 'Query error');
                }
            } catch (error) {
                const errorMessage = document.createElement('div');
                errorMessage.className = 'message ai';
                errorMessage.innerHTML = '<strong>AIssist:</strong> ' + content[lang].errorMsg + error.message;
                chatMessages.appendChild(errorMessage);
            } finally {
                sendBtn.disabled = false;
                sendBtn.textContent = content[lang].sendBtn;
                chatMessages.scrollTop = chatMessages.scrollHeight;
            }
        }
        
        function logout() {
            localStorage.removeItem('auth_token');
            localStorage.removeItem('user_data');
            window.location.href = '/';
        }
    </script>
</body>
</html>
  ''';
  
  request.response
    ..headers.contentType = ContentType.html
    ..write(htmlContent);
  await request.response.close();
}

Future<void> _handleAdminPage(HttpRequest request) async {
  // Force load the complete admin panel inline to ensure deployment works
  const adminPanelHtml = r'''<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Panel - AIssist</title>
    <style>
        :root {
            --primary-color: #667eea;
            --primary-dark: #5a67d8;
            --secondary-color: #764ba2;
            --success-color: #48bb78;
            --warning-color: #ed8936;
            --danger-color: #f56565;
            --dark-bg: #0f1419;
            --card-bg: rgba(255, 255, 255, 0.05);
            --border-color: rgba(255, 255, 255, 0.1);
            --text-primary: #ffffff;
            --text-secondary: rgba(255, 255, 255, 0.8);
            --text-muted: rgba(255, 255, 255, 0.6);
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: linear-gradient(135deg, var(--dark-bg) 0%, #1a2332 50%, #2d3748 100%);
            color: var(--text-primary);
            min-height: 100vh;
        }
        .header {
            background: var(--card-bg);
            backdrop-filter: blur(20px);
            border-bottom: 1px solid var(--border-color);
            padding: 1rem 2rem;
            position: sticky;
            top: 0;
            z-index: 100;
        }
        .header-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
            max-width: 1400px;
            margin: 0 auto;
        }
        .logo {
            font-size: 1.8rem;
            font-weight: 900;
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .nav-links {
            display: flex;
            gap: 2rem;
        }
        .nav-links a {
            color: var(--text-secondary);
            text-decoration: none;
            padding: 0.5rem 1rem;
            border-radius: 8px;
            transition: all 0.3s ease;
        }
        .nav-links a:hover, .nav-links a.active {
            background: var(--card-bg);
            color: var(--text-primary);
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 2rem;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }
        .stat-card {
            background: var(--card-bg);
            backdrop-filter: blur(20px);
            border: 1px solid var(--border-color);
            border-radius: 16px;
            padding: 1.5rem;
            text-align: center;
            transition: transform 0.2s ease;
        }
        .stat-card:hover { transform: translateY(-2px); }
        .stat-number {
            font-size: 2.5rem;
            font-weight: 900;
            margin-bottom: 0.5rem;
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .stat-label {
            color: var(--text-secondary);
            font-size: 0.9rem;
        }
        .content-section {
            background: var(--card-bg);
            backdrop-filter: blur(20px);
            border: 1px solid var(--border-color);
            border-radius: 16px;
            padding: 2rem;
            margin-bottom: 2rem;
        }
        .section-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1.5rem;
            padding-bottom: 1rem;
            border-bottom: 1px solid var(--border-color);
        }
        .section-title {
            font-size: 1.5rem;
            font-weight: 700;
            color: var(--text-primary);
        }
        .btn {
            padding: 0.5rem 1rem;
            border: none;
            border-radius: 8px;
            font-size: 0.9rem;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
        }
        .btn-primary {
            background: linear-gradient(135deg, var(--primary-color) 0%, var(--primary-dark) 100%);
            color: white;
        }
        .btn-primary:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
        }
        .btn-secondary {
            background: var(--card-bg);
            border: 1px solid var(--border-color);
            color: var(--text-secondary);
        }
        .data-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 1rem;
        }
        .data-table th, .data-table td {
            padding: 1rem;
            text-align: left;
            border-bottom: 1px solid var(--border-color);
        }
        .data-table th {
            background: rgba(255, 255, 255, 0.02);
            font-weight: 600;
            color: var(--text-primary);
        }
        .data-table td {
            color: var(--text-secondary);
        }
        .data-table tr:hover {
            background: rgba(255, 255, 255, 0.02);
        }
        .badge {
            padding: 0.25rem 0.75rem;
            border-radius: 12px;
            font-size: 0.8rem;
            font-weight: 600;
            text-transform: uppercase;
        }
        .badge-free {
            background: rgba(156, 163, 175, 0.2);
            color: #d1d5db;
        }
        .badge-premium {
            background: rgba(102, 126, 234, 0.2);
            color: var(--primary-color);
        }
        .badge-pro {
            background: rgba(118, 75, 162, 0.2);
            color: var(--secondary-color);
        }
        .search-container {
            display: flex;
            gap: 1rem;
            margin-bottom: 1.5rem;
            align-items: center;
        }
        .search-input {
            flex: 1;
            padding: 0.75rem;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            background: rgba(255, 255, 255, 0.05);
            color: var(--text-primary);
            font-size: 1rem;
        }
        .search-input:focus {
            outline: none;
            border-color: var(--primary-color);
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        .filter-select {
            padding: 0.75rem;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            background: rgba(255, 255, 255, 0.05);
            color: var(--text-primary);
        }
        .loading {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
        }
        .spinner {
            width: 16px;
            height: 16px;
            border: 2px solid rgba(255, 255, 255, 0.3);
            border-top: 2px solid var(--primary-color);
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        @media (max-width: 768px) {
            .container { padding: 1rem; }
            .stats-grid { grid-template-columns: 1fr; }
            .search-container { flex-direction: column; }
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <div class="logo">🔧 Admin Panel - AIssist</div>
            <nav class="nav-links">
                <a href="/" class="nav-link">🏠 Home</a>
                <a href="/dashboard" class="nav-link">📊 Dashboard</a>
                <a href="#" class="nav-link active">🔧 Admin</a>
            </nav>
        </div>
    </div>
    <div class="container">
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-number" id="totalUsers">-</div>
                <div class="stat-label">Total de Usuários</div>
            </div>
            <div class="stat-card">
                <div class="stat-number" id="totalQueries">-</div>
                <div class="stat-label">Consultas Hoje</div>
            </div>
            <div class="stat-card">
                <div class="stat-number" id="activeUsers">-</div>
                <div class="stat-label">Usuários Ativos</div>
            </div>
            <div class="stat-card">
                <div class="stat-number" id="revenue">R$ -</div>
                <div class="stat-label">Receita Estimada</div>
            </div>
        </div>
        <div class="content-section">
            <div class="section-header">
                <h2 class="section-title">👥 Usuários do Sistema</h2>
                <button class="btn btn-primary" onclick="createUser()">➕ Novo Usuário</button>
            </div>
            <div class="search-container">
                <input type="text" class="search-input" id="userSearch" placeholder="Buscar usuários por email...">
                <select class="filter-select" id="planFilter">
                    <option value="">Todos os Planos</option>
                    <option value="free">Free</option>
                    <option value="premium">Premium</option>
                    <option value="pro">Pro</option>
                </select>
                <button class="btn btn-secondary" onclick="loadUsers()">🔄 Atualizar</button>
            </div>
            <table class="data-table" id="usersTable">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Email</th>
                        <th>Plano</th>
                        <th>Consultas Hoje</th>
                        <th>Criado em</th>
                        <th>Ações</th>
                    </tr>
                </thead>
                <tbody id="usersTableBody">
                    <tr>
                        <td colspan="6" style="text-align: center; padding: 2rem;">
                            <div class="loading">
                                <div class="spinner"></div>
                                Carregando usuários...
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    <script>
        let users = [];
        document.addEventListener('DOMContentLoaded', function() {
            loadStats();
            loadUsers();
        });
        async function loadStats() {
            try {
                const response = await fetch('/admin/stats');
                const stats = await response.json();
                document.getElementById('totalUsers').textContent = stats.totalUsers || 0;
                document.getElementById('totalQueries').textContent = stats.totalQueries || 0;
                document.getElementById('activeUsers').textContent = stats.activeUsers || 0;
                document.getElementById('revenue').textContent = 'R$ ' + (stats.revenue || '0.00');
            } catch (error) {
                console.error('Erro ao carregar stats:', error);
            }
        }
        async function loadUsers() {
            try {
                const response = await fetch('/admin/users');
                const data = await response.json();
                users = data.users || [];
                updateUsersTable();
            } catch (error) {
                console.error('Erro ao carregar usuários:', error);
                document.getElementById('usersTableBody').innerHTML = `
                    <tr><td colspan="6" style="text-align: center; padding: 2rem; color: #fc8181;">
                        ❌ Erro ao carregar usuários: ${error.message}
                    </td></tr>`;
            }
        }
        function updateUsersTable() {
            const tbody = document.getElementById('usersTableBody');
            if (users.length === 0) {
                tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; padding: 2rem;">
                    Nenhum usuário cadastrado ainda. Crie o primeiro usuário!
                </td></tr>`;
                return;
            }
            tbody.innerHTML = users.map(user => `
                <tr>
                    <td>#${user.id}</td>
                    <td>${user.email}</td>
                    <td><span class="badge badge-${user.subscriptionTier}">${user.subscriptionTier.toUpperCase()}</span></td>
                    <td>${user.dailyUsageCount}/${user.dailyLimit || 5}</td>
                    <td>${new Date(user.createdAt).toLocaleDateString('pt-BR')}</td>
                    <td>
                        <button class="btn btn-secondary" onclick="editUser(${user.id})" style="margin-right: 0.5rem;">✏️ Editar</button>
                        <button class="btn btn-danger" onclick="deleteUser(${user.id})" style="background: #f56565; color: white;">🗑️ Excluir</button>
                    </td>
                </tr>
            `).join('');
        }
        function createUser() {
            const email = prompt('Email do novo usuário:');
            if (!email) return;
            const password = prompt('Senha (mínimo 6 caracteres):');
            if (!password || password.length < 6) {
                alert('Senha deve ter pelo menos 6 caracteres');
                return;
            }
            const plan = prompt('Plano (free/premium/pro):', 'free');
            if (!['free', 'premium', 'pro'].includes(plan)) {
                alert('Plano deve ser: free, premium ou pro');
                return;
            }
            createUserAPI(email, password, plan);
        }
        async function createUserAPI(email, password, plan) {
            try {
                const response = await fetch('/admin/users', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        email: email,
                        password: password,
                        subscriptionTier: plan
                    })
                });
                const result = await response.json();
                if (result.success) {
                    alert('✅ Usuário criado com sucesso!');
                    loadUsers();
                    loadStats();
                } else {
                    alert('❌ Erro: ' + result.error);
                }
            } catch (error) {
                alert('❌ Erro ao criar usuário: ' + error.message);
            }
        }
        async function deleteUser(userId) {
            if (!confirm('Tem certeza que deseja excluir este usuário?')) return;
            try {
                const response = await fetch(`/admin/users/${userId}`, { method: 'DELETE' });
                const result = await response.json();
                if (result.success) {
                    alert('✅ Usuário excluído com sucesso!');
                    loadUsers();
                    loadStats();
                } else {
                    alert('❌ Erro: ' + result.error);
                }
            } catch (error) {
                alert('❌ Erro ao excluir usuário: ' + error.message);
            }
        }
    </script>
</body>
</html>''';
  
  try {
    print('✅ Serving complete admin panel inline');
    request.response
      ..headers.contentType = ContentType.html
      ..write(adminPanelHtml);
    await request.response.close();
  } catch (e) {
    print('❌ Error serving admin page: $e');
    
    // Admin panel with user management functionality
    const adminContent = '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Panel - AIssist</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: #0f1419;
            color: white;
            min-height: 100vh;
            padding: 2rem;
        }
        .header {
            background: rgba(255, 255, 255, 0.1);
            padding: 1.5rem;
            border-radius: 12px;
            margin-bottom: 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .logo {
            font-size: 1.8rem;
            font-weight: 900;
            color: #667eea;
        }
        .nav {
            display: flex;
            gap: 1rem;
        }
        .nav a {
            color: rgba(255, 255, 255, 0.8);
            text-decoration: none;
            padding: 0.5rem 1rem;
            border-radius: 6px;
            transition: all 0.3s ease;
        }
        .nav a:hover {
            background: rgba(255, 255, 255, 0.1);
            color: white;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }
        .stat-card {
            background: rgba(255, 255, 255, 0.1);
            padding: 1.5rem;
            border-radius: 12px;
            text-align: center;
        }
        .stat-number {
            font-size: 2.5rem;
            font-weight: 900;
            color: #667eea;
            margin-bottom: 0.5rem;
        }
        .stat-label {
            opacity: 0.8;
        }
        .content {
            background: rgba(255, 255, 255, 0.05);
            border-radius: 12px;
            padding: 2rem;
        }
        h2 {
            margin-bottom: 1rem;
            color: #667eea;
        }
        .info {
            background: rgba(102, 126, 234, 0.1);
            border: 1px solid rgba(102, 126, 234, 0.3);
            padding: 1rem;
            border-radius: 8px;
            margin-bottom: 1rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">🔧 Admin Panel - AIssist</div>
            <div class="nav">
                <a href="/">🏠 Home</a>
                <a href="/dashboard">📊 Dashboard</a>
            </div>
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-number" id="totalUsers">--</div>
                <div class="stat-label">Total de Usuários</div>
            </div>
            <div class="stat-card">
                <div class="stat-number" id="todayQueries">--</div>
                <div class="stat-label">Consultas Hoje</div>
            </div>
            <div class="stat-card">
                <div class="stat-number" id="activeUsers">--</div>
                <div class="stat-label">Usuários Ativos</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">100%</div>
                <div class="stat-label">Sistema Online</div>
            </div>
        </div>

        <div class="content">
            <h2>Painel Administrativo</h2>
            <div class="info">
                <strong>ℹ️ Informações do Sistema:</strong><br>
                • Autenticação JWT: ✅ Ativa<br>
                • Rate Limiting: ✅ Ativo<br>
                • Validação de usuários: ✅ Ativa<br>
                • Database em memória: ⚠️ Temporário<br>
                • Admin Panel completo: 🚧 Carregando admin-corrigido.html...
            </div>
            
            <p>Sistema de administração completo está sendo carregado do arquivo admin-corrigido.html.</p>
            <p>Se esta mensagem persiste, verifique se o arquivo existe no diretório correto.</p>
            
            <div style="margin-top: 2rem;">
                <strong>Caminhos tentados:</strong><br>
                • admin-corrigido.html<br>
                • /data/workspace/aissist/admin-corrigido.html<br>
                • watchwise_server/web/static/demo.html
            </div>
        </div>
    </div>

    <script>
        // Mock stats for now
        document.getElementById('totalUsers').textContent = '0';
        document.getElementById('todayQueries').textContent = '0';
        document.getElementById('activeUsers').textContent = '0';
    </script>
</body>
</html>
    ''';
    
    request.response
      ..headers.contentType = ContentType.html
      ..write(adminContent);
    await request.response.close();
  }
}

// ADMIN ENDPOINTS

Future<void> _handleAdminStats(HttpRequest request, Map<String, SimpleUser> users) async {
  if (request.method != 'GET') {
    request.response
      ..statusCode = 405
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({'error': 'Method not allowed'}));
    await request.response.close();
    return;
  }

  try {
    final totalUsers = users.length;
    final totalQueries = users.values.fold(0, (sum, user) => sum + user.dailyUsageCount);
    final activeUsers = users.values.where((user) => user.dailyUsageCount > 0).length;
    
    // Calculate estimated revenue
    final premiumUsers = users.values.where((user) => user.subscriptionTier == 'premium').length;
    final proUsers = users.values.where((user) => user.subscriptionTier == 'pro').length;
    final estimatedRevenue = (premiumUsers * 19.90) + (proUsers * 39.90);

    final stats = {
      'totalUsers': totalUsers,
      'totalQueries': totalQueries,
      'activeUsers': activeUsers,
      'revenue': estimatedRevenue.toStringAsFixed(2),
      'usersByPlan': {
        'free': users.values.where((user) => user.subscriptionTier == 'free').length,
        'premium': premiumUsers,
        'pro': proUsers,
      }
    };

    request.response
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode(stats));
    await request.response.close();
  } catch (e) {
    print('❌ Error in admin stats: $e');
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({'error': e.toString()}));
    await request.response.close();
  }
}

Future<void> _handleAdminUsers(HttpRequest request, Map<String, SimpleUser> users, int nextUserId) async {
  request.response.headers.add('Access-Control-Allow-Origin', '*');

  try {
    if (request.method == 'GET') {
      // List all users
      final userList = users.values.map((user) => {
        ...user.toPublicJson(),
        'passwordHash': null, // Don't expose password hashes
      }).toList();

      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'users': userList}));
      await request.response.close();

    } else if (request.method == 'POST') {
      // Create new user
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final email = data['email'] as String?;
      final password = data['password'] as String?;
      final subscriptionTier = data['subscriptionTier'] as String? ?? 'free';
      final dailyUsageCount = data['dailyUsageCount'] as int? ?? 0;

      // Validation
      if (email == null || email.isEmpty) {
        throw Exception('Email é obrigatório');
      }
      if (password == null || password.length < 6) {
        throw Exception('Senha deve ter pelo menos 6 caracteres');
      }

      // Check if user already exists
      if (users.values.any((u) => u.email == email)) {
        throw Exception('Email já está em uso');
      }

      // Create new user
      final user = SimpleUser(
        id: nextUserId,
        email: email,
        passwordHash: SimpleAuthService.hashPassword(password),
        subscriptionTier: subscriptionTier,
        dailyUsageCount: dailyUsageCount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save user
      users[nextUserId.toString()] = user;

      print('✅ ADMIN: Created user $email (ID: $nextUserId)');

      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'success': true,
          'user': user.toPublicJson(),
          'message': 'Usuário criado com sucesso'
        }));
      await request.response.close();

    } else {
      request.response
        ..statusCode = 405
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Method not allowed'}));
      await request.response.close();
    }
  } catch (e) {
    print('❌ Error in admin users: $e');
    request.response
      ..statusCode = 400
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': e.toString()}));
    await request.response.close();
  }
}

Future<void> _handleAdminUserById(HttpRequest request, Map<String, SimpleUser> users, String userIdStr) async {
  request.response.headers.add('Access-Control-Allow-Origin', '*');

  try {
    final userId = int.tryParse(userIdStr);
    if (userId == null) {
      throw Exception('ID de usuário inválido');
    }

    final user = users[userId.toString()];
    if (user == null) {
      request.response
        ..statusCode = 404
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Usuário não encontrado'}));
      await request.response.close();
      return;
    }

    if (request.method == 'GET') {
      // Get specific user
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'user': user.toPublicJson()}));
      await request.response.close();

    } else if (request.method == 'PUT') {
      // Update user
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      // Update allowed fields
      if (data.containsKey('subscriptionTier')) {
        user.subscriptionTier = data['subscriptionTier'];
      }
      if (data.containsKey('dailyUsageCount')) {
        user.dailyUsageCount = data['dailyUsageCount'];
      }
      if (data.containsKey('email')) {
        // Check if new email is already in use
        final newEmail = data['email'] as String;
        if (users.values.any((u) => u.email == newEmail && u.id != userId)) {
          throw Exception('Email já está em uso');
        }
        user.email = newEmail;
      }

      user.updatedAt = DateTime.now();

      print('✅ ADMIN: Updated user ${user.email} (ID: $userId)');

      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'success': true,
          'user': user.toPublicJson(),
          'message': 'Usuário atualizado com sucesso'
        }));
      await request.response.close();

    } else if (request.method == 'DELETE') {
      // Delete user
      users.remove(userId.toString());

      print('✅ ADMIN: Deleted user ${user.email} (ID: $userId)');

      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'success': true,
          'message': 'Usuário excluído com sucesso'
        }));
      await request.response.close();

    } else {
      request.response
        ..statusCode = 405
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': 'Method not allowed'}));
      await request.response.close();
    }
  } catch (e) {
    print('❌ Error in admin user by ID: $e');
    request.response
      ..statusCode = 400
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': e.toString()}));
    await request.response.close();
  }
}

Future<void> _handleAdminQueries(HttpRequest request, {List<Map<String, dynamic>>? queryLog}) async {
  if (request.method != 'GET') {
    request.response
      ..statusCode = 405
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({'error': 'Method not allowed'}));
    await request.response.close();
    return;
  }

  try {
    // For now, return empty list since we don't have query logging yet
    // TODO: Implement actual query logging in _handleAIChat
    final queries = queryLog ?? [];

    request.response
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({
        'queries': queries,
        'total': queries.length
      }));
    await request.response.close();
  } catch (e) {
    print('❌ Error in admin queries: $e');
    request.response
      ..statusCode = 500
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode({'error': e.toString()}));
    await request.response.close();
  }
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
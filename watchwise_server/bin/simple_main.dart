import 'dart:io';
import 'dart:convert';
import '../lib/src/services/tmdb_service.dart';
import '../lib/src/services/reviva_llm_service.dart';

/// Ultra-simple HTTP server for AIssist MVP
Future<void> main() async {
  print('🎬 Starting AIssist Complete Navigation System...');
  
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
        '/ - Landing Page',
        '/login - Login Page', 
        '/signup - Cadastro Page',
        '/dashboard - User Dashboard',
        '/admin - Admin Panel',
        '/health - API Health',
        '/auth/signup (POST) - Create Account',
        '/auth/login (POST) - User Login',
        '/auth/me (GET) - User Info',
        '/auth/usage (GET) - Usage Stats',
        '/ai/chat (POST) - AI Chat',
        '/movies/popular - Popular Movies',
        '/movies/search - Search Movies',
        '/tv/search - Search TV Shows'
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
    
    // Simulate decrementing queries for demo
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final queriesRemaining = random > 50 ? 94 : 93;

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
  const htmlContent = '''
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
                <label for="email">E-mail:</label>
                <input type="email" id="email" name="email" placeholder="seu@email.com" required>
            </div>
            
            <div class="form-group">
                <label for="password">Senha:</label>
                <input type="password" id="password" name="password" placeholder="Sua senha" required>
            </div>
            
            <button type="submit" class="btn" id="loginBtn">
                🔑 Entrar
            </button>
            
            <div class="loading" id="loading">
                <div class="spinner"></div>
                Fazendo login...
            </div>
        </form>
        
        <div class="links">
            <a href="/signup">Não tem conta? Cadastre-se</a><br><br>
            <a href="/">← Voltar ao início</a>
        </div>
    </div>

    <script>
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
                    message.textContent = '✅ ' + data.message;
                    message.style.display = 'block';
                    
                    // Redirect to dashboard
                    setTimeout(() => {
                        window.location.href = '/dashboard';
                    }, 1500);
                } else {
                    throw new Error(data.message || 'Erro no login');
                }
            } catch (error) {
                message.className = 'message error';
                message.textContent = '❌ ' + error.message;
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
  const htmlContent = '''
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
                <label for="email">E-mail:</label>
                <input type="email" id="email" name="email" placeholder="seu@email.com" required>
            </div>
            
            <div class="form-group">
                <label for="password">Senha:</label>
                <input type="password" id="password" name="password" placeholder="Mínimo 6 caracteres" required minlength="6">
            </div>
            
            <div class="form-group">
                <label for="planType">Plano:</label>
                <select id="planType" name="planType" required>
                    <option value="free">Free - 5 consultas/dia</option>
                    <option value="premium">Premium - 100 consultas/dia (R\$ 19,90/mês)</option>
                    <option value="pro">Pro - 500 consultas/dia (R\$ 39,90/mês)</option>
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
                Criando sua conta...
            </div>
        </form>
        
        <div class="links">
            <a href="/login">Já tem conta? Faça login</a><br><br>
            <a href="/">← Voltar ao início</a>
        </div>
    </div>

    <script>
        // Update plan info
        document.getElementById('planType').addEventListener('change', (e) => {
            const planInfo = document.getElementById('planInfo');
            const value = e.target.value;
            
            switch(value) {
                case 'free':
                    planInfo.innerHTML = '✅ Plano Free: 5 consultas por dia, sem custo';
                    break;
                case 'premium':
                    planInfo.innerHTML = '💎 Plano Premium: 100 consultas por dia, R\$ 19,90/mês';
                    break;
                case 'pro':
                    planInfo.innerHTML = '🚀 Plano Pro: 500 consultas por dia, R\$ 39,90/mês';
                    break;
            }
        });
        
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
                    message.textContent = '✅ ' + data.message;
                    message.style.display = 'block';
                    
                    // Redirect to dashboard
                    setTimeout(() => {
                        window.location.href = '/dashboard';
                    }, 2000);
                } else {
                    throw new Error(data.message || 'Erro no cadastro');
                }
            } catch (error) {
                message.className = 'message error';
                message.textContent = '❌ ' + error.message;
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

Future<void> _handleDashboard(HttpRequest request) async {
  const htmlContent = '''
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
            <a href="#" class="logout-btn" onclick="logout()">🚪 Sair</a>
        </div>
    </div>

    <div class="main">
        <div class="welcome">
            <h1 id="welcomeMessage">Bem-vindo ao AIssist! 👋</h1>
            <p>Seu assistente inteligente para descobrir entretenimento personalizado</p>
        </div>

        <div class="dashboard-grid">
            <div class="card">
                <h3>📊 Suas Estatísticas</h3>
                <div class="stat-number" id="remainingQueries">--</div>
                <div class="stat-label">Consultas restantes hoje</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="progressFill" style="width: 0%"></div>
                </div>
                <div class="stat-label" id="planDetails">Plano: ...</div>
            </div>

            <div class="card">
                <h3>🎬 Recomendações</h3>
                <p>Baseadas no seu histórico e preferências:</p>
                <div id="recommendations" style="margin-top: 1rem;">
                    <div style="opacity: 0.7;">Faça sua primeira consulta para receber recomendações personalizadas!</div>
                </div>
            </div>

            <div class="card">
                <h3>📈 Atividade Recente</h3>
                <div id="recentActivity">
                    <div style="opacity: 0.7;">Nenhuma atividade recente</div>
                </div>
            </div>
        </div>

        <div class="chat-container">
            <h3>🤖 Chat com IA - Pergunte sobre filmes e séries</h3>
            <div class="chat-messages" id="chatMessages">
                <div class="message ai">
                    <strong>AIssist:</strong> Olá! Sou seu assistente de entretenimento. Pergunte sobre filmes, séries, ou peça recomendações personalizadas! 🎬✨
                </div>
            </div>
            <div class="chat-input">
                <input type="text" id="messageInput" placeholder="Ex: 'Quero um filme de ficção científica para hoje à noite'" maxlength="500">
                <button class="send-btn" id="sendBtn" onclick="sendMessage()">🚀 Enviar</button>
            </div>
        </div>
    </div>

    <script>
        // Check authentication
        const token = localStorage.getItem('auth_token');
        const userData = localStorage.getItem('user_data');
        
        if (!token || !userData) {
            window.location.href = '/login';
        }
        
        const user = JSON.parse(userData);
        
        // Update user info
        document.getElementById('userAvatar').textContent = user.email.charAt(0).toUpperCase();
        document.getElementById('userName').textContent = user.email.split('@')[0];
        document.getElementById('userPlan').textContent = user.subscriptionTier.charAt(0).toUpperCase() + user.subscriptionTier.slice(1);
        document.getElementById('welcomeMessage').textContent = 'Bem-vindo, ' + user.email.split('@')[0] + '! 👋';
        
        // Update stats
        document.getElementById('remainingQueries').textContent = user.remainingQueries;
        
        const totalQueries = user.subscriptionTier === 'pro' ? 500 : user.subscriptionTier === 'premium' ? 100 : 5;
        const usedQueries = totalQueries - user.remainingQueries;
        const progressPercent = (usedQueries / totalQueries) * 100;
        
        document.getElementById('progressFill').style.width = progressPercent + '%';
        document.getElementById('planDetails').textContent = 'Plano ' + user.subscriptionTier + ': ' + usedQueries + '/' + totalQueries + ' consultas usadas';
        
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
            userMessage.innerHTML = '<strong>Você:</strong> ' + message;
            chatMessages.appendChild(userMessage);
            
            // Clear input and disable button
            input.value = '';
            sendBtn.disabled = true;
            sendBtn.textContent = '⏳ Pensando...';
            
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
                        document.getElementById('planDetails').textContent = 'Plano ' + user.subscriptionTier + ': ' + newUsedQueries + '/' + totalQueries + ' consultas usadas';
                    }
                } else {
                    throw new Error(data.error || 'Erro na consulta');
                }
            } catch (error) {
                const errorMessage = document.createElement('div');
                errorMessage.className = 'message ai';
                errorMessage.innerHTML = '<strong>AIssist:</strong> ❌ Desculpe, ocorreu um erro: ' + error.message;
                chatMessages.appendChild(errorMessage);
            } finally {
                sendBtn.disabled = false;
                sendBtn.textContent = '🚀 Enviar';
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
  try {
    final adminFile = File('admin-corrigido.html');
    final htmlContent = await adminFile.readAsString();
    
    request.response
      ..headers.contentType = ContentType.html
      ..write(htmlContent);
    await request.response.close();
  } catch (e) {
    print('❌ Error serving admin.html: $e');
    
    // Fallback simple admin page
    const fallbackContent = '''
<!DOCTYPE html>
<html>
<head><title>Admin - AIssist</title></head>
<body style="font-family: Arial; padding: 2rem; background: #1a1a1a; color: white;">
    <h1>🔧 Admin Panel - AIssist</h1>
    <p>Área administrativa em desenvolvimento.</p>
    <p><a href="/" style="color: #667eea;">← Voltar ao início</a></p>
</body>
</html>
    ''';
    
    request.response
      ..headers.contentType = ContentType.html
      ..write(fallbackContent);
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
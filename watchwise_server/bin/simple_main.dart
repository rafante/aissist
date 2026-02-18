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
        case '/':
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
  const htmlContent = '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AIssist - Seu Assistente de Entretenimento</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
            background: linear-gradient(135deg, #0f1419 0%, #1a2332 50%, #2d3748 100%);
            color: white;
            min-height: 100vh;
            overflow-x: hidden;
        }
        .hero {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            text-align: center;
            padding: 2rem;
            position: relative;
        }
        .hero::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grain" width="100" height="100" patternUnits="userSpaceOnUse"><circle cx="20" cy="20" r="1" fill="%23ffffff" opacity="0.05"/><circle cx="80" cy="40" r="0.5" fill="%23ffffff" opacity="0.1"/><circle cx="40" cy="80" r="1.5" fill="%23ffffff" opacity="0.05"/><circle cx="90" cy="10" r="0.5" fill="%23ffffff" opacity="0.1"/><circle cx="10" cy="90" r="1" fill="%23ffffff" opacity="0.05"/></pattern></defs><rect width="100" height="100" fill="url(%23grain)"/></svg>');
            pointer-events: none;
        }
        .hero-content {
            max-width: 800px;
            z-index: 1;
            position: relative;
        }
        .logo {
            font-size: 4rem;
            font-weight: 900;
            margin-bottom: 1rem;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .tagline {
            font-size: 1.5rem;
            margin-bottom: 2rem;
            opacity: 0.9;
            line-height: 1.6;
        }
        .cta-buttons {
            display: flex;
            gap: 1rem;
            justify-content: center;
            margin-bottom: 3rem;
            flex-wrap: wrap;
        }
        .btn {
            padding: 1rem 2rem;
            border: none;
            border-radius: 8px;
            font-size: 1.1rem;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.3s ease;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
        }
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 25px rgba(102, 126, 234, 0.3);
        }
        .btn-secondary {
            background: rgba(255, 255, 255, 0.1);
            color: white;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        .btn-secondary:hover {
            background: rgba(255, 255, 255, 0.2);
            transform: translateY(-2px);
        }
        .features {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 2rem;
            margin-top: 3rem;
        }
        .feature {
            text-align: center;
            padding: 1.5rem;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 12px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        .feature-icon {
            font-size: 3rem;
            margin-bottom: 1rem;
        }
        .feature h3 {
            margin-bottom: 1rem;
            font-size: 1.3rem;
        }
        .feature p {
            opacity: 0.8;
            line-height: 1.6;
        }
        @media (max-width: 768px) {
            .logo { font-size: 2.5rem; }
            .tagline { font-size: 1.2rem; }
            .cta-buttons { flex-direction: column; align-items: center; }
            .btn { width: 100%; max-width: 300px; justify-content: center; }
        }
    </style>
</head>
<body>
    <div class="hero">
        <div class="hero-content">
            <h1 class="logo">AIssist</h1>
            <p class="tagline">
                Seu assistente inteligente para descobrir filmes, séries e entretenimento personalizado. 
                Alimentado por IA avançada.
            </p>
            
            <div class="cta-buttons">
                <a href="/signup" class="btn btn-primary">
                    🚀 Começar Grátis
                </a>
                <a href="/login" class="btn btn-secondary">
                    🔑 Fazer Login
                </a>
            </div>
            
            <div class="features">
                <div class="feature">
                    <div class="feature-icon">🤖</div>
                    <h3>IA Personalizada</h3>
                    <p>Recomendações inteligentes baseadas no seu gosto e histórico</p>
                </div>
                <div class="feature">
                    <div class="feature-icon">🎬</div>
                    <h3>Catálogo Gigante</h3>
                    <p>Milhões de filmes e séries com informações detalhadas</p>
                </div>
                <div class="feature">
                    <div class="feature-icon">⚡</div>
                    <h3>Busca Instantânea</h3>
                    <p>Encontre o que procura em segundos com busca inteligente</p>
                </div>
            </div>
        </div>
    </div>
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
                    <option value="premium">Premium - 100 consultas/dia (R$ 19,90/mês)</option>
                    <option value="pro">Pro - 500 consultas/dia (R$ 39,90/mês)</option>
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
                    planInfo.innerHTML = '💎 Plano Premium: 100 consultas por dia, R$ 19,90/mês';
                    break;
                case 'pro':
                    planInfo.innerHTML = '🚀 Plano Pro: 500 consultas por dia, R$ 39,90/mês';
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
        document.getElementById('welcomeMessage').textContent = `Bem-vindo, ${user.email.split('@')[0]}! 👋`;
        
        // Update stats
        document.getElementById('remainingQueries').textContent = user.remainingQueries;
        
        const totalQueries = user.subscriptionTier === 'pro' ? 500 : user.subscriptionTier === 'premium' ? 100 : 5;
        const usedQueries = totalQueries - user.remainingQueries;
        const progressPercent = (usedQueries / totalQueries) * 100;
        
        document.getElementById('progressFill').style.width = progressPercent + '%';
        document.getElementById('planDetails').textContent = `Plano ${user.subscriptionTier}: ${usedQueries}/${totalQueries} consultas usadas`;
        
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
            userMessage.innerHTML = `<strong>Você:</strong> ${message}`;
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
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify({ query: message })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    // Add AI response
                    const aiMessage = document.createElement('div');
                    aiMessage.className = 'message ai';
                    aiMessage.innerHTML = `<strong>AIssist:</strong> ${data.ai_response}`;
                    chatMessages.appendChild(aiMessage);
                    
                    // Update remaining queries
                    if (data.queriesRemaining !== undefined) {
                        user.remainingQueries = data.queriesRemaining;
                        localStorage.setItem('user_data', JSON.stringify(user));
                        document.getElementById('remainingQueries').textContent = data.queriesRemaining;
                        
                        const newUsedQueries = totalQueries - data.queriesRemaining;
                        const newProgressPercent = (newUsedQueries / totalQueries) * 100;
                        document.getElementById('progressFill').style.width = newProgressPercent + '%';
                        document.getElementById('planDetails').textContent = `Plano ${user.subscriptionTier}: ${newUsedQueries}/${totalQueries} consultas usadas`;
                    }
                } else {
                    throw new Error(data.error || 'Erro na consulta');
                }
            } catch (error) {
                const errorMessage = document.createElement('div');
                errorMessage.className = 'message ai';
                errorMessage.innerHTML = `<strong>AIssist:</strong> ❌ Desculpe, ocorreu um erro: ${error.message}`;
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
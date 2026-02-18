import 'dart:io';
import 'dart:convert';

void main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 3030);
  print('🚀 AIssist Dashboard Server running on http://localhost:3030');
  print('📋 Admin Dashboard: http://localhost:3030/admin');
  print('🎬 Demo Page: http://localhost:3030/demo');
  
  await for (HttpRequest request in server) {
    await handleRequest(request);
  }
}

Future<void> handleRequest(HttpRequest request) async {
  try {
    final uri = request.uri;
    print('📡 ${request.method} ${uri.path}');

    // CORS Headers
    request.response.headers
      ..add('Access-Control-Allow-Origin', '*')
      ..add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
      ..add('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    switch (uri.path) {
      case '/':
      case '/admin':
        await serveFile(request, 'watchwise_server/web/static/admin.html');
        break;
      case '/demo':
        await serveFile(request, 'watchwise_server/web/static/demo.html');
        break;
      case '/ai/status':
        await handleAiStatus(request);
        break;
      case '/auth/signup':
        await handleSignup(request);
        break;
      case '/auth/login':
        await handleLogin(request);
        break;
      default:
        await handle404(request);
    }
  } catch (e) {
    print('❌ Error handling request: $e');
    request.response.statusCode = HttpStatus.internalServerError;
    request.response.write('Internal Server Error');
    await request.response.close();
  }
}

Future<void> serveFile(HttpRequest request, String filePath) async {
  try {
    final file = File(filePath);
    if (await file.exists()) {
      final content = await file.readAsString();
      request.response.headers.contentType = ContentType.html;
      request.response.write(content);
      await request.response.close();
    } else {
      await handle404(request);
    }
  } catch (e) {
    print('❌ Error serving file $filePath: $e');
    await handle404(request);
  }
}

Future<void> handleAiStatus(HttpRequest request) async {
  final response = {
    'success': true,
    'service': 'ReVivaLLM',
    'healthy': true,
    'endpoint': 'llm.rafante-tec.online',
    'model': 'reviva:latest',
    'timestamp': DateTime.now().toIso8601String(),
  };
  
  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(response));
  await request.response.close();
}

Future<void> handleSignup(HttpRequest request) async {
  if (request.method != 'POST') {
    request.response.statusCode = HttpStatus.methodNotAllowed;
    await request.response.close();
    return;
  }

  // Mock signup response
  final response = {
    'success': true,
    'user': {
      'id': 123,
      'email': 'demo@aissist.com',
      'subscriptionTier': 'free',
      'remainingQueries': 5,
    },
    'token': 'mock_jwt_token_for_demo',
    'message': 'Account created successfully!',
  };

  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(response));
  await request.response.close();
}

Future<void> handleLogin(HttpRequest request) async {
  if (request.method != 'POST') {
    request.response.statusCode = HttpStatus.methodNotAllowed;
    await request.response.close();
    return;
  }

  // Mock login response
  final response = {
    'success': true,
    'user': {
      'id': 1,
      'email': 'admin@aissist.com',
      'subscriptionTier': 'pro',
      'remainingQueries': 500,
    },
    'token': 'mock_admin_jwt_token',
    'message': 'Login successful!',
  };

  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(response));
  await request.response.close();
}

Future<void> handle404(HttpRequest request) async {
  request.response.statusCode = HttpStatus.notFound;
  request.response.headers.contentType = ContentType.html;
  request.response.write('''
<!DOCTYPE html>
<html>
<head>
    <title>404 - Not Found</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .error { color: #dc3545; }
        .links { margin-top: 30px; }
        .links a { margin: 0 15px; color: #007bff; text-decoration: none; }
    </style>
</head>
<body>
    <h1 class="error">404 - Página não encontrada</h1>
    <p>A página solicitada não existe.</p>
    <div class="links">
        <a href="/admin">📊 Admin Dashboard</a>
        <a href="/demo">🎬 Demo Page</a>
    </div>
</body>
</html>
  ''');
  await request.response.close();
}
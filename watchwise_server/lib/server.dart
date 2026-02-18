import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'src/generated/protocol.dart';
import 'src/generated/endpoints_with_auth.dart';
import 'src/auth/auth_endpoint.dart';

/// Serverpod server for AIssist with Authentication
void run(List<String> args) async {
  // Initialize Serverpod with authenticated endpoints
  final pod = Serverpod(args, Protocol(), AuthenticatedEndpoints());

  // Add authentication middleware
  // pod.addMiddleware(AuthMiddleware());

  // Setup a default page at the web root
  pod.webServer.addRoute(RootRoute(), '/');
  pod.webServer.addRoute(RootRoute(), '/index.html');

  // Setup demo route
  pod.webServer.addRoute(FileRoute('/demo.html', File('web/static/demo.html')), '/demo.html');

  // Serve all files in the web/static directory 
  final root = Directory(Uri(path: 'web/static').toFilePath());
  pod.webServer.addRoute(StaticRoute.directory(root));

  // Add CORS headers for development
  pod.webServer.addRoute(
    Route.all('*', (request, params) async {
      final origin = request.headers.value('origin') ?? '*';
      final response = Response.ok(
        '{"error": "Not found"}',
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': origin,
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          'Access-Control-Allow-Credentials': 'true',
        },
      );
      return response;
    }),
    priority: -1,
  );

  print('🎬 AIssist API Server starting...');
  print('📋 Available endpoints:');
  print('   🔐 Auth: /auth/signup, /auth/login, /auth/me, /auth/usage');
  print('   🤖 AI: /ai/chat, /ai/chatPublic, /ai/status');
  print('   🎥 Content: /content/searchMovies, /content/searchTvShows');
  print('   👋 Greeting: /greeting/hello');
  print('   🌐 Demo: /demo.html');
  
  // Start the server
  await pod.start();
  
  print('🚀 AIssist API with Authentication running on port 8080!');
  print('💾 Database: PostgreSQL with user management');
  print('🔑 Auth: JWT-based authentication with rate limiting');
  print('💰 Monetization: Ready for Free/Premium/Pro tiers');
}
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'src/minimal_endpoints.dart';
import 'src/generated/protocol.dart';

/// Minimal Serverpod server for AIssist MVP
void run(List<String> args) async {
  // Initialize Serverpod with minimal configuration
  final pod = Serverpod(
    args,
    Protocol(),
    MinimalEndpoints(),
  );

  // Setup basic routes
  final root = Directory(Uri(path: 'web/static').toFilePath());
  if (root.existsSync()) {
    pod.webServer.addRoute(StaticRoute.directory(root), '/');
  }

  // Add health check
  pod.webServer.addRoute(
    StaticRoute.json({'status': 'healthy', 'service': 'AIssist API v1.0'}),
    '/health',
  );

  print('🎬 AIssist API Server starting...');
  print('📋 Available endpoints:');
  print('   GET  /health - Health check');
  print('   POST /content/searchMovies - Search movies via TMDB');
  print('   POST /content/getPopularMovies - Get popular movies');
  
  // Start the server
  await pod.start();
  
  print('🚀 AIssist API Server running on port 8080');
}
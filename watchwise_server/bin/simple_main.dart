import 'dart:io';
import 'dart:convert';
import '../lib/src/services/tmdb_service.dart';

/// Ultra-simple HTTP server for AIssist MVP
Future<void> main() async {
  print('🎬 Starting AIssist Simple API Server...');
  
  // Get TMDB API key
  const apiKey = String.fromEnvironment('TMDB_API_KEY', defaultValue: '466fd9ba21e369cd51e7743d32b7833f');
  final tmdb = TmdbService(apiKey: apiKey);
  
  // Create HTTP server  
  final port = int.fromEnvironment('PORT', defaultValue: 8081);
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🚀 Server running on port $port');
  
  await for (final request in server) {
    final path = request.uri.path;
    final query = request.uri.queryParameters;
    
    try {
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
        '/movies/popular',
        '/movies/search?query=Matrix',
        '/tv/search?query=Friends'
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
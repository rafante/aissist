import 'dart:convert';
import 'package:http/http.dart' as http;
import '../protocol/movie.dart';
import '../protocol/tv_show.dart';

/// Service for interacting with TMDB (The Movie Database) API
class TmdbService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p';
  
  final String apiKey;
  final http.Client _client;

  TmdbService({required this.apiKey, http.Client? client}) 
    : _client = client ?? http.Client();

  /// Search for movies by query
  Future<List<Movie>> searchMovies({
    required String query,
    int page = 1,
    String language = 'pt-BR',
    bool includeAdult = false,
  }) async {
    final url = Uri.parse('$_baseUrl/search/movie').replace(queryParameters: {
      'api_key': apiKey,
      'query': query,
      'page': page.toString(),
      'language': language,
      'include_adult': includeAdult.toString(),
    });

    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to search movies: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final results = data['results'] as List;
    return results.map((json) => Movie.fromJson(json)).toList();
  }

  /// Search for TV shows by query
  Future<List<TvShow>> searchTvShows({
    required String query,
    int page = 1,
    String language = 'pt-BR',
    bool includeAdult = false,
  }) async {
    final url = Uri.parse('$_baseUrl/search/tv').replace(queryParameters: {
      'api_key': apiKey,
      'query': query,
      'page': page.toString(),
      'language': language,
      'include_adult': includeAdult.toString(),
    });

    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to search TV shows: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final results = data['results'] as List;
    return results.map((json) => TvShow.fromJson(json)).toList();
  }

  /// Get movie details by ID
  Future<Movie?> getMovie({
    required int movieId,
    String language = 'pt-BR',
  }) async {
    final url = Uri.parse('$_baseUrl/movie/$movieId').replace(queryParameters: {
      'api_key': apiKey,
      'language': language,
    });

    final response = await _client.get(url);
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('Failed to get movie details: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return Movie.fromJson(data);
  }

  /// Get TV show details by ID
  Future<TvShow?> getTvShow({
    required int tvId,
    String language = 'pt-BR',
  }) async {
    final url = Uri.parse('$_baseUrl/tv/$tvId').replace(queryParameters: {
      'api_key': apiKey,
      'language': language,
    });

    final response = await _client.get(url);
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('Failed to get TV show details: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return TvShow.fromJson(data);
  }

  /// Get popular movies
  Future<List<Movie>> getPopularMovies({
    int page = 1,
    String language = 'pt-BR',
  }) async {
    final url = Uri.parse('$_baseUrl/movie/popular').replace(queryParameters: {
      'api_key': apiKey,
      'page': page.toString(),
      'language': language,
    });

    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to get popular movies: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final results = data['results'] as List;
    return results.map((json) => Movie.fromJson(json)).toList();
  }

  /// Get popular TV shows
  Future<List<TvShow>> getPopularTvShows({
    int page = 1,
    String language = 'pt-BR',
  }) async {
    final url = Uri.parse('$_baseUrl/tv/popular').replace(queryParameters: {
      'api_key': apiKey,
      'page': page.toString(),
      'language': language,
    });

    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to get popular TV shows: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final results = data['results'] as List;
    return results.map((json) => TvShow.fromJson(json)).toList();
  }

  /// Get trending movies/TV (day or week)
  Future<List<dynamic>> getTrending({
    String mediaType = 'all', // 'movie', 'tv', or 'all'
    String timeWindow = 'day', // 'day' or 'week'
    String language = 'pt-BR',
  }) async {
    final url = Uri.parse('$_baseUrl/trending/$mediaType/$timeWindow').replace(queryParameters: {
      'api_key': apiKey,
      'language': language,
    });

    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to get trending content: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final results = data['results'] as List;
    
    return results.map((json) {
      final mediaType = json['media_type'] as String?;
      if (mediaType == 'movie') {
        return Movie.fromJson(json);
      } else if (mediaType == 'tv') {
        return TvShow.fromJson(json);
      }
      return json; // Unknown type, return raw JSON
    }).toList();
  }

  /// Build full image URL
  static String getImageUrl(String? imagePath, {String size = 'w500'}) {
    if (imagePath == null || imagePath.isEmpty) {
      return ''; // Return empty string or placeholder URL
    }
    return '$_imageBaseUrl/$size$imagePath';
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// TMDB API response wrapper
class TmdbResponse<T> {
  final int page;
  final List<T> results;
  final int totalPages;
  final int totalResults;

  TmdbResponse({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory TmdbResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    return TmdbResponse(
      page: json['page'] as int,
      results: (json['results'] as List).map((item) => fromJson(item)).toList(),
      totalPages: json['total_pages'] as int,
      totalResults: json['total_results'] as int,
    );
  }
}
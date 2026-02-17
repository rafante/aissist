import 'package:serverpod/serverpod.dart';
import '../protocol/movie.dart';
import '../protocol/tv_show.dart';
import '../services/tmdb_service.dart';

/// Endpoint for content-related operations (movies, TV shows, etc.)
class ContentEndpoint extends Endpoint {
  late final TmdbService _tmdbService;

  @override
  Future<void> initialize() async {
    final apiKey = session.serverpod.getPassword('TMDB_API_KEY') ?? 
                   const String.fromEnvironment('TMDB_API_KEY', defaultValue: '466fd9ba21e369cd51e7743d32b7833f');
    
    if (apiKey.isEmpty) {
      throw Exception('TMDB_API_KEY not configured');
    }
    
    _tmdbService = TmdbService(apiKey: apiKey);
  }

  /// Search for movies by query
  Future<List<Movie>> searchMovies(Session session, {
    required String query,
    int page = 1,
    String language = 'pt-BR',
  }) async {
    try {
      return await _tmdbService.searchMovies(
        query: query,
        page: page,
        language: language,
      );
    } catch (e) {
      throw Exception('Failed to search movies: $e');
    }
  }

  /// Search for TV shows by query  
  Future<List<TvShow>> searchTvShows(Session session, {
    required String query,
    int page = 1,
    String language = 'pt-BR',
  }) async {
    try {
      return await _tmdbService.searchTvShows(
        query: query,
        page: page,
        language: language,
      );
    } catch (e) {
      throw Exception('Failed to search TV shows: $e');
    }
  }

  /// Get movie details by ID
  Future<Movie?> getMovie(Session session, {
    required int movieId,
    String language = 'pt-BR',
  }) async {
    try {
      return await _tmdbService.getMovie(
        movieId: movieId,
        language: language,
      );
    } catch (e) {
      throw Exception('Failed to get movie: $e');
    }
  }

  /// Get TV show details by ID
  Future<TvShow?> getTvShow(Session session, {
    required int tvId,
    String language = 'pt-BR',
  }) async {
    try {
      return await _tmdbService.getTvShow(
        tvId: tvId,
        language: language,
      );
    } catch (e) {
      throw Exception('Failed to get TV show: $e');
    }
  }

  /// Get popular movies
  Future<List<Movie>> getPopularMovies(Session session, {
    int page = 1,
    String language = 'pt-BR',
  }) async {
    try {
      return await _tmdbService.getPopularMovies(
        page: page,
        language: language,
      );
    } catch (e) {
      throw Exception('Failed to get popular movies: $e');
    }
  }

  /// Get popular TV shows
  Future<List<TvShow>> getPopularTvShows(Session session, {
    int page = 1,
    String language = 'pt-BR',
  }) async {
    try {
      return await _tmdbService.getPopularTvShows(
        page: page,
        language: language,
      );
    } catch (e) {
      throw Exception('Failed to get popular TV shows: $e');
    }
  }

  /// Get trending content (movies and TV shows)
  Future<List<dynamic>> getTrending(Session session, {
    String mediaType = 'all',
    String timeWindow = 'day',
    String language = 'pt-BR',
  }) async {
    try {
      return await _tmdbService.getTrending(
        mediaType: mediaType,
        timeWindow: timeWindow,
        language: language,
      );
    } catch (e) {
      throw Exception('Failed to get trending content: $e');
    }
  }

  /// Search mixed content (movies + TV shows)
  Future<Map<String, dynamic>> searchMixed(Session session, {
    required String query,
    int page = 1,
    String language = 'pt-BR',
  }) async {
    try {
      // Run both searches in parallel
      final futures = await Future.wait([
        _tmdbService.searchMovies(query: query, page: page, language: language),
        _tmdbService.searchTvShows(query: query, page: page, language: language),
      ]);

      return {
        'movies': futures[0],
        'tvShows': futures[1],
        'query': query,
        'page': page,
      };
    } catch (e) {
      throw Exception('Failed to search mixed content: $e');
    }
  }

  @override
  Future<void> close() async {
    _tmdbService.dispose();
  }
}
// Teste rápido da integração TMDB
import 'watchwise_server/lib/src/services/tmdb_service.dart';

Future<void> main() async {
  final apiKey = '466fd9ba21e369cd51e7743d32b7833f';
  final tmdb = TmdbService(apiKey: apiKey);

  try {
    print('🎬 Testando TMDB API...\n');

    // Teste 1: Buscar filmes populares
    print('📋 Filmes populares:');
    final popular = await tmdb.getPopularMovies(language: 'pt-BR');
    for (int i = 0; i < 5 && i < popular.length; i++) {
      final movie = popular[i];
      print(
        '${i + 1}. ${movie.title} (${movie.releaseDate?.substring(0, 4) ?? 'N/A'})',
      );
      final overview = movie.overview ?? 'Sem descrição';
      final shortOverview = overview.length > 100
          ? overview.substring(0, 100) + '...'
          : overview;
      print(
        '   ⭐ ${movie.voteAverage?.toStringAsFixed(1) ?? 'N/A'} - $shortOverview',
      );
    }

    print('\n🔍 Testando busca:');
    // Teste 2: Buscar filme específico
    final search = await tmdb.searchMovies(query: 'Matrix', language: 'pt-BR');
    if (search.isNotEmpty) {
      final matrix = search.first;
      print(
        'Encontrado: ${matrix.title} (${matrix.releaseDate?.substring(0, 4)})',
      );
      print('Poster: ${matrix.fullPosterUrl ?? 'N/A'}');
    }

    print('\n📺 Séries populares:');
    // Teste 3: Séries populares
    final tvShows = await tmdb.getPopularTvShows(language: 'pt-BR');
    for (int i = 0; i < 3 && i < tvShows.length; i++) {
      final show = tvShows[i];
      print(
        '${i + 1}. ${show.name} (${show.firstAirDate?.substring(0, 4) ?? 'N/A'})',
      );
    }

    print('\n✅ TMDB API funcionando perfeitamente!');
    print('🚀 Pronto para integrar no Serverpod');
  } catch (e) {
    print('❌ Erro na API: $e');
  } finally {
    tmdb.dispose();
  }
}

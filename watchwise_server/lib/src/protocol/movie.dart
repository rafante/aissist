/// Represents a movie from TMDB (standalone class)
class Movie {
  Movie({
    required this.id,
    required this.title,
    this.originalTitle,
    this.overview,
    this.releaseDate,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.voteCount,
    this.popularity,
    this.adult = false,
    this.originalLanguage,
    this.genreIds = const [],
  });

  /// TMDB movie ID
  int id;
  
  /// Movie title  
  String title;
  
  /// Original title (if different from title)
  String? originalTitle;
  
  /// Movie overview/synopsis
  String? overview;
  
  /// Release date (YYYY-MM-DD format)
  String? releaseDate;
  
  /// Poster image path (append to TMDB image base URL)
  String? posterPath;
  
  /// Backdrop image path
  String? backdropPath;
  
  /// Average vote rating (0-10)
  double? voteAverage;
  
  /// Total vote count
  int? voteCount;
  
  /// TMDB popularity score
  double? popularity;
  
  /// Adult content flag
  bool adult;
  
  /// Original language code (e.g., "en", "pt")
  String? originalLanguage;
  
  /// List of genre IDs
  List<int> genreIds;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'originalTitle': originalTitle,
    'overview': overview,
    'releaseDate': releaseDate,
    'posterPath': posterPath,
    'backdropPath': backdropPath,
    'voteAverage': voteAverage,
    'voteCount': voteCount,
    'popularity': popularity,
    'adult': adult,
    'originalLanguage': originalLanguage,
    'genreIds': genreIds,
  };

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
    id: json['id'] as int,
    title: json['title'] as String,
    originalTitle: json['original_title'] as String?,
    overview: json['overview'] as String?,
    releaseDate: json['release_date'] as String?,
    posterPath: json['poster_path'] as String?,
    backdropPath: json['backdrop_path'] as String?,
    voteAverage: (json['vote_average'] as num?)?.toDouble(),
    voteCount: json['vote_count'] as int?,
    popularity: (json['popularity'] as num?)?.toDouble(),
    adult: json['adult'] as bool? ?? false,
    originalLanguage: json['original_language'] as String?,
    genreIds: (json['genre_ids'] as List?)?.cast<int>() ?? [],
  );

  /// Get full poster URL
  String? get fullPosterUrl {
    if (posterPath == null) return null;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  /// Get full backdrop URL
  String? get fullBackdropUrl {
    if (backdropPath == null) return null;
    return 'https://image.tmdb.org/t/p/w1280$backdropPath';
  }
}
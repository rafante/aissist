/// Represents a TV show from TMDB (standalone class)
class TvShow {
  TvShow({
    required this.id,
    required this.name,
    this.originalName,
    this.overview,
    this.firstAirDate,
    this.posterPath,
    this.backdropPath,
    this.voteAverage,
    this.voteCount,
    this.popularity,
    this.originalLanguage,
    this.genreIds = const [],
    this.originCountry = const [],
  });

  /// TMDB TV show ID
  int id;
  
  /// TV show name
  String name;
  
  /// Original name (if different from name)
  String? originalName;
  
  /// TV show overview/synopsis
  String? overview;
  
  /// First air date (YYYY-MM-DD format)
  String? firstAirDate;
  
  /// Poster image path
  String? posterPath;
  
  /// Backdrop image path
  String? backdropPath;
  
  /// Average vote rating (0-10)
  double? voteAverage;
  
  /// Total vote count
  int? voteCount;
  
  /// TMDB popularity score
  double? popularity;
  
  /// Original language code
  String? originalLanguage;
  
  /// List of genre IDs
  List<int> genreIds;
  
  /// Origin country codes
  List<String> originCountry;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'originalName': originalName,
    'overview': overview,
    'firstAirDate': firstAirDate,
    'posterPath': posterPath,
    'backdropPath': backdropPath,
    'voteAverage': voteAverage,
    'voteCount': voteCount,
    'popularity': popularity,
    'originalLanguage': originalLanguage,
    'genreIds': genreIds,
    'originCountry': originCountry,
  };

  factory TvShow.fromJson(Map<String, dynamic> json) => TvShow(
    id: json['id'] as int,
    name: json['name'] as String,
    originalName: json['original_name'] as String?,
    overview: json['overview'] as String?,
    firstAirDate: json['first_air_date'] as String?,
    posterPath: json['poster_path'] as String?,
    backdropPath: json['backdrop_path'] as String?,
    voteAverage: (json['vote_average'] as num?)?.toDouble(),
    voteCount: json['vote_count'] as int?,
    popularity: (json['popularity'] as num?)?.toDouble(),
    originalLanguage: json['original_language'] as String?,
    genreIds: (json['genre_ids'] as List?)?.cast<int>() ?? [],
    originCountry: (json['origin_country'] as List?)?.cast<String>() ?? [],
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
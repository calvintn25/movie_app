class Movie {
  final int id;
  final String title;
  final String summary;
  final String? imageUrl;
  final double? rating;
  final List<String> genres;
  final DateTime? releaseDate;

  const Movie({
    required this.id,
    required this.title,
    required this.summary,
    required this.imageUrl,
    required this.rating,
    required this.genres,
    required this.releaseDate,
  });

  factory Movie.fromTvMaze(Map<String, dynamic> json) {
    final show = (json['show'] as Map<String, dynamic>? ?? <String, dynamic>{});
    final image =
        (show['image'] as Map<String, dynamic>? ?? <String, dynamic>{});
    final ratingObj =
        (show['rating'] as Map<String, dynamic>? ?? <String, dynamic>{});

    return Movie(
      id: show['id'] as int? ?? 0,
      title: show['name'] as String? ?? 'Untitled',
      summary: _cleanHtml(
        show['summary'] as String? ?? 'No summary available.',
      ),
      imageUrl: image['medium'] as String?,
      rating: (ratingObj['average'] as num?)?.toDouble(),
      genres: (show['genres'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      releaseDate: null,
    );
  }

  factory Movie.fromItunes(Map<String, dynamic> json) {
    final trackId = json['trackId'] as int?;
    final title = json['trackName'] as String?;
    final longDescription = json['longDescription'] as String?;
    final shortDescription = json['shortDescription'] as String?;
    final artwork = json['artworkUrl100'] as String?;
    final primaryGenre = json['primaryGenreName'] as String?;

    return Movie(
      id: trackId ?? 0,
      title: title ?? 'Untitled',
      summary: (longDescription ?? shortDescription ?? 'No summary available.')
          .trim(),
      imageUrl: _toHighResItunesImage(artwork),
      rating: null,
      genres: [
        if (primaryGenre != null && primaryGenre.trim().isNotEmpty)
          primaryGenre.trim(),
      ],
      releaseDate: _parseDate(json['releaseDate'] as String?),
    );
  }

  factory Movie.fromYts(Map<String, dynamic> json) {
    final rawDate = json['date_uploaded'] as String?;
    final normalizedDate = rawDate?.replaceFirst(' ', 'T');
    final parsedDate = _parseDate(normalizedDate);
    final year = json['year'] as int?;

    return Movie(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled',
      summary: (json['summary'] as String? ?? 'No summary available.').trim(),
      imageUrl: json['medium_cover_image'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      genres: (json['genres'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      releaseDate:
          parsedDate ??
          (year != null ? DateTime.tryParse('$year-01-01') : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'imageUrl': imageUrl,
      'rating': rating,
      'genres': genres,
      'releaseDate': releaseDate?.toIso8601String(),
    };
  }

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled',
      summary: json['summary'] as String? ?? 'No summary available.',
      imageUrl: json['imageUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      genres: (json['genres'] as List<dynamic>? ?? <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      releaseDate: _parseDate(json['releaseDate'] as String?),
    );
  }

  static String _cleanHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.trim());
  }

  static String? _toHighResItunesImage(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }

    return url.replaceAll('100x100bb.jpg', '600x600bb.jpg');
  }
}

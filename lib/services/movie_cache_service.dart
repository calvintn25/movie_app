import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie.dart';

class MovieCacheService {
  static const String _cacheKey = 'cached_movies';

  Future<void> saveMovies(List<Movie> movies) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(movies.map((m) => m.toJson()).toList());
    await prefs.setString(_cacheKey, encoded);
  }

  Future<List<Movie>> getMovies() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) {
      return <Movie>[];
    }

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Movie.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
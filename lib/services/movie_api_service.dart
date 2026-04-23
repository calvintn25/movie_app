import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie.dart';

class MovieApiService {
  static const String _url =
      'https://yts.mx/api/v2/list_movies.json?limit=60&sort_by=download_count';

  Future<List<Movie>> fetchMovies() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode != 200) {
      throw Exception('Failed to load movies from API.');
    }

    final Map<String, dynamic> payload =
        jsonDecode(response.body) as Map<String, dynamic>;
    final Map<String, dynamic> dataObj =
        payload['data'] as Map<String, dynamic>? ?? {};
    final List<dynamic> data = dataObj['movies'] as List<dynamic>? ?? [];

    if (data.isEmpty) {
      throw Exception('Movie list is empty from API.');
    }

    return data
        .map((item) => Movie.fromYts(item as Map<String, dynamic>))
        .toList();
  }
}

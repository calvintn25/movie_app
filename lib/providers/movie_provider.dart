import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/movie.dart';
import '../services/movie_api_service.dart';
import '../services/movie_cache_service.dart';

class MovieProvider extends ChangeNotifier {
  MovieProvider({MovieApiService? apiService, MovieCacheService? cacheService})
    : _apiService = apiService ?? MovieApiService(),
      _cacheService = cacheService ?? MovieCacheService();

  final MovieApiService _apiService;
  final MovieCacheService _cacheService;

  List<Movie> _movies = <Movie>[];
  bool _isLoading = false;
  bool _isOfflineData = false;
  String? _errorMessage;
  int _dataVersion = 0;

  List<Movie> get movies => _movies;
  bool get isLoading => _isLoading;
  bool get isOfflineData => _isOfflineData;
  String? get errorMessage => _errorMessage;
  int get dataVersion => _dataVersion;

  List<String> get availableGenres {
    final genres = <String>{};
    for (final movie in _movies) {
      genres.addAll(movie.genres.where((genre) => genre.trim().isNotEmpty));
    }

    final sorted = genres.toList()..sort();
    return sorted;
  }

  Future<void> fetchMovies() async {
    _isLoading = true;
    _errorMessage = null;
    _isOfflineData = false;
    notifyListeners();

    try {
      final freshMovies = await _apiService.fetchMovies();
      _movies = freshMovies;
      await _cacheService.saveMovies(freshMovies);
    } catch (_) {
      final cachedMovies = await _cacheService.getMovies();
      final hasInternet = await _hasInternetConnection();

      if (cachedMovies.isNotEmpty) {
        _movies = cachedMovies;

        if (!hasInternet) {
          _isOfflineData = true;
          _errorMessage =
              'You are offline right now. Showing your last saved movie list.';
        } else {
          _isOfflineData = false;
          _errorMessage = null;
        }
      } else {
        _movies = <Movie>[];
        _errorMessage = hasInternet
            ? 'Server is unavailable right now. Please try again.'
            : 'Unable to load movie data right now. Check your connection and tap retry.';
      }
    } finally {
      _dataVersion++;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<Movie>> searchMovies({
    required String query,
    required String genre,
    required String sortBy,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final normalizedQuery = query.trim().toLowerCase();
    final normalizedGenre = genre.trim().toLowerCase();

    final filtered = _movies.where((movie) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          movie.title.toLowerCase().contains(normalizedQuery) ||
          movie.summary.toLowerCase().contains(normalizedQuery);

      final matchesGenre =
          normalizedGenre == 'all' ||
          movie.genres.any((item) => item.toLowerCase() == normalizedGenre);

      return matchesQuery && matchesGenre;
    }).toList();

    switch (sortBy.toLowerCase()) {
      case 'top rating':
        filtered.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'latest':
        filtered.sort(
          (a, b) => (b.releaseDate ?? DateTime(1900)).compareTo(
            a.releaseDate ?? DateTime(1900),
          ),
        );
        break;
      default:
        break;
    }

    return filtered;
  }
}

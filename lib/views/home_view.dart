import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../providers/movie_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_loading_shimmer.dart';
import '../widgets/search_filter_bar.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _selectedGenre = 'All';
  String _selectedSort = 'Default';
  Future<List<Movie>>? _searchFuture;
  Timer? _searchDebounceTimer;
  Timer? _reconnectRetryTimer;
  MovieProvider? _provider;
  int _lastDataVersion = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _provider = context.read<MovieProvider>();
      _provider?.addListener(_handleProviderChange);
      _syncSearchFuture();
      _syncReconnectRetry();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _provider?.removeListener(_handleProviderChange);
    _searchDebounceTimer?.cancel();
    _reconnectRetryTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_retryRefreshWhenRecovered(force: true));
    }
  }

  void _handleProviderChange() {
    final provider = _provider;
    if (provider == null || provider.dataVersion == _lastDataVersion) {
      return;
    }

    _syncSearchFuture();
    _syncReconnectRetry();
  }

  void _syncReconnectRetry() {
    final provider = _provider;
    if (provider == null) {
      return;
    }

    if (!provider.isOfflineData) {
      _reconnectRetryTimer?.cancel();
      _reconnectRetryTimer = null;
      return;
    }

    _reconnectRetryTimer ??= Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_retryRefreshWhenRecovered());
    });
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

  Future<void> _retryRefreshWhenRecovered({bool force = false}) async {
    final provider = _provider;
    if (!mounted ||
        provider == null ||
        !provider.isOfflineData ||
        provider.isLoading) {
      return;
    }

    if (!force && !await _hasInternetConnection()) {
      return;
    }

    await provider.fetchMovies();
    _syncSearchFuture();
    _syncReconnectRetry();
  }

  void _syncSearchFuture() {
    final provider = _provider;
    if (provider == null || !mounted) {
      return;
    }

    _lastDataVersion = provider.dataVersion;
    setState(() {
      _searchFuture = provider.searchMovies(
        query: _searchController.text,
        genre: _selectedGenre,
        sortBy: _selectedSort,
      );
    });
  }

  Future<void> _refreshMovies() async {
    final provider = context.read<MovieProvider>();
    await provider.fetchMovies();
    _syncSearchFuture();
  }

  void _updateQuery(String value) {
    _scheduleSearch();
  }

  void _updateGenre(String value) {
    setState(() {
      _selectedGenre = value;
    });
    _scheduleSearch();
  }

  void _updateSort(String value) {
    setState(() {
      _selectedSort = value;
    });
    _scheduleSearch();
  }

  void _scheduleSearch() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) {
        return;
      }

      _syncSearchFuture();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieProvider>();
    final genres = provider.availableGenres;

    return Scaffold(
      appBar: AppBar(toolbarHeight: 74, title: const _AppHeader()),
      body: RefreshIndicator(
        onRefresh: _refreshMovies,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: SearchFilterBar(
                  controller: _searchController,
                  genres: genres,
                  selectedGenre: _selectedGenre,
                  selectedSort: _selectedSort,
                  onSearchChanged: _updateQuery,
                  onGenreChanged: _updateGenre,
                  onSortChanged: _updateSort,
                ),
              ),
            ),
            if (provider.isOfflineData)
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    provider.errorMessage ?? 'Showing offline data.',
                    style: TextStyle(color: Colors.brown.shade800),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (provider.isLoading)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverToBoxAdapter(child: MovieLoadingShimmer()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: FutureBuilder<List<Movie>>(
                  future: _searchFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _FriendlyMessage(
                          icon: Icons.error_outline_rounded,
                          title: 'A small scene glitch happened.',
                          message:
                              'The movie reel stopped unexpectedly. Please try again.',
                          buttonLabel: 'Retry Search',
                          onPressed: _syncSearchFuture,
                        ),
                      );
                    }

                    final movies = snapshot.data ?? const <Movie>[];
                    if (provider.errorMessage != null &&
                        !provider.isOfflineData &&
                        provider.movies.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _FriendlyMessage(
                          icon: Icons.wifi_off_rounded,
                          title: 'The projector cannot find the server.',
                          message:
                              provider.errorMessage ??
                              'Please check your connection and try again.',
                          buttonLabel: 'Reload Movies',
                          onPressed: _refreshMovies,
                        ),
                      );
                    }

                    if (movies.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: SizedBox.shrink(),
                      );
                    }

                    return SliverList.separated(
                      itemCount: movies.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return MovieCard(movie: movies[index]);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refreshMovies,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.deepOrange.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.movie_filter_rounded,
            color: Colors.deepOrange.shade700,
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MovieNest',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Text(
              'Discover your next movie',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }
}

class _FriendlyMessage extends StatelessWidget {
  const _FriendlyMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.orange.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.refresh),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

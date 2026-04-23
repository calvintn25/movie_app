import 'package:flutter/material.dart';

import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Poster(imageUrl: movie.imageUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          movie.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (movie.rating != null)
                        _RatingChip(value: movie.rating!.toStringAsFixed(1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (movie.genres.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: movie.genres
                          .take(3)
                          .map(
                            (genre) => Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(genre),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: 72,
        height: 108,
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.movie_creation_outlined),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl!,
        width: 72,
        height: 108,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 72,
          height: 108,
          color: Colors.black12,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.orange.shade900,
        ),
      ),
    );
  }
}

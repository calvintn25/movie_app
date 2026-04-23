import 'package:flutter/material.dart';

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.controller,
    required this.genres,
    required this.selectedGenre,
    required this.selectedSort,
    required this.onSearchChanged,
    required this.onGenreChanged,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final List<String> genres;
  final String selectedGenre;
  final String selectedSort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final genreValues = <String>['All', ...genres];
    final safeSelectedGenre = genreValues.contains(selectedGenre)
        ? selectedGenre
        : 'All';

    const sortValues = <String>['Default', 'Top Rating', 'Latest'];
    final safeSelectedSort = sortValues.contains(selectedSort)
        ? selectedSort
        : 'Default';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search by title or description',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(safeSelectedGenre),
          initialValue: safeSelectedGenre,
          items: [
            const DropdownMenuItem(value: 'All', child: Text('All genres')),
            ...genres.map(
              (genre) => DropdownMenuItem(value: genre, child: Text(genre)),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onGenreChanged(value);
            }
          },
          decoration: InputDecoration(
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(safeSelectedSort),
          initialValue: safeSelectedSort,
          items: const [
            DropdownMenuItem(value: 'Default', child: Text('Sort: Default')),
            DropdownMenuItem(
              value: 'Top Rating',
              child: Text('Sort: Top Rating'),
            ),
            DropdownMenuItem(value: 'Latest', child: Text('Sort: Latest')),
          ],
          onChanged: (value) {
            if (value != null) {
              onSortChanged(value);
            }
          },
          decoration: InputDecoration(
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

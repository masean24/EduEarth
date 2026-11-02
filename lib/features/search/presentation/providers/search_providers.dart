import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return const SearchRepository();
});

/// Kata kunci pencarian global saat ini.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Hasil pencarian global berdasarkan `searchQueryProvider`.
final globalSearchResultsProvider =
    FutureProvider<GlobalSearchResults>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) {
    return const GlobalSearchResults();
  }
  final repo = ref.watch(searchRepositoryProvider);
  return repo.search(query);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/vocabulary_word.dart';
import '../../data/vocabulary_repository.dart';

final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  return VocabularyRepository();
});

final vocabularyControllerProvider =
    StateNotifierProvider<VocabularyController, VocabularyState>((ref) {
      return VocabularyController(ref.read(vocabularyRepositoryProvider));
    });

class VocabularyState {
  final bool isLoading;
  final bool hasError;
  final String? error;

  VocabularyState({
    required this.isLoading,
    required this.hasError,
    this.error,
  });

  factory VocabularyState.initial() =>
      VocabularyState(isLoading: false, hasError: false);

  VocabularyState copyWith({bool? isLoading, bool? hasError, String? error}) {
    return VocabularyState(
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      error: error,
    );
  }
}

class VocabularyController extends StateNotifier<VocabularyState> {
  final VocabularyRepository repo;

  final List<VocabularyWord> loaded = [];
  static const int pageSize = 10;
  bool hasMore = true;
  bool _loadingMore = false;

  VocabularyController(this.repo) : super(VocabularyState.initial());

  Future<void> init() async {
    state = state.copyWith(isLoading: true);

    await repo.openBox();

    loaded.clear();
    hasMore = true;

    final chunk = repo.getRange(start: 0, limit: pageSize);
    loaded.addAll(chunk);

    hasMore = chunk.length == pageSize;

    state = state.copyWith(isLoading: false);
  }

  Future<void> loadMore() async {
    if (!hasMore) return;
    if (_loadingMore) return;

    _loadingMore = true;

    final start = loaded.length;
    final chunk = repo.getRange(start: start, limit: pageSize);

    if (chunk.isEmpty) {
      hasMore = false;
    } else {
      loaded.addAll(chunk);
      hasMore = chunk.length == pageSize;
    }

    state = state.copyWith(); // notify UI
    _loadingMore = false;
  }

  Future<void> addWord(VocabularyWord w) async {
    await repo.add(w);
    await init(); // refresh
  }

  Future<void> deleteAtListIndex(int index) async {
    await repo.deleteByGlobalIndex(index);
    await init(); // refresh
  }

  /// Yeni: update işlemini controller üzerinden yap
  Future<void> updateAtListIndex(int index, VocabularyWord updated) async {
    await repo.update(index, updated);
    // update in-memory copy if the index is within loaded range
    if (index >= 0 && index < loaded.length) {
      loaded[index] = updated;
    }
    state = state.copyWith(); // notify UI
  }
}

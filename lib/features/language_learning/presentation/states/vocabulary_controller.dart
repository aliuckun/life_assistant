// life_assistant/lib/features/language_learning/presentation/states/vocabulary_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/vocabulary_word.dart';
import '../../data/vocabulary_repository.dart';

final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  return VocabularyRepository();
});

// Page-level provider: manages loading box only when page requested
final vocabularyControllerProvider =
    AsyncNotifierProvider<VocabularyController, void>(
      () => VocabularyController(),
    );

class VocabularyController extends AsyncNotifier<void> {
  late final VocabularyRepository repo;

  // in-memory paginated list
  final List<VocabularyWord> loaded = [];
  static const int pageSize = 5;
  int cursor = 0;
  bool hasMore = true;
  bool loadingMore = false;

  @override
  Future<void> build() async {
    repo = ref.read(vocabularyRepositoryProvider);
    // Do not open box here automatically; open when page calls init()
  }

  Future<void> init() async {
    state = const AsyncValue.loading();
    try {
      await repo.openBox();
      // reset pagination
      loaded.clear();
      cursor = 0;
      hasMore = true;
      await loadMore(); // load first chunk
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> disposeBox() async {
    await repo.closeBox();
    loaded.clear();
    cursor = 0;
    hasMore = true;
  }

  Future<void> loadMore() async {
    if (!repo.isOpen) return;
    if (!hasMore || loadingMore) return;
    loadingMore = true;
    final newItems = repo.getRange(start: cursor, limit: pageSize);
    if (newItems.isEmpty) {
      hasMore = false;
    } else {
      loaded.addAll(newItems);
      cursor += newItems.length;
      if (newItems.length < pageSize) hasMore = false;
    }
    loadingMore = false;
    // notify listeners by marking state (data)
    state = const AsyncValue.data(null);
  }

  Future<void> addWord(VocabularyWord word) async {
    await repo.add(word);
    // If happens to be early in list, we may want to refresh pagination:
    // simple approach: re-init to reflect order/length
    await init();
  }

  Future<void> deleteAtListIndex(int listIndex) async {
    // listIndex is index in loaded list; need to map to repo index = listIndex (since we load sequentially)
    final globalIndex =
        listIndex; // because we loaded sequential chunk starting at 0
    await repo.delete(globalIndex);
    await init(); // reload to keep indices consistent
  }
}

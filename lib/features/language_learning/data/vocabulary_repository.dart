import 'package:hive/hive.dart';
import '../domain/vocabulary_word.dart';

class VocabularyRepository {
  static const boxName = 'vocabulary_box';
  Box<VocabularyWord>? _box;

  Future<void> openBox() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<VocabularyWord>(boxName);
  }

  bool get isOpen => _box?.isOpen ?? false;

  int get length => _box?.length ?? 0;

  /// Yeni: index ile güncelleme (global index yani Hive içindeki sıralı index)
  Future<void> update(int index, VocabularyWord updated) async {
    if (_box == null) return;
    final key = _box!.keyAt(index);
    await _box!.put(key, updated);
  }

  // Lazy range read
  List<VocabularyWord> getRange({required int start, required int limit}) {
    if (!isOpen) return [];

    final total = length;
    if (start >= total) return [];

    final end = (start + limit).clamp(0, total);
    List<VocabularyWord> out = [];

    for (int i = start; i < end; i++) {
      final item = _box!.getAt(i);
      if (item != null) out.add(item);
    }
    return out;
  }

  Future<void> add(VocabularyWord word) async {
    await _box?.add(word);
  }

  Future<void> deleteByGlobalIndex(int index) async {
    final key = _box!.keyAt(index);
    await _box!.delete(key);
  }
}

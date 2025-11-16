// life_assistant/lib/features/language_learning/data/vocabulary_repository.dart
import 'package:hive/hive.dart';
import '../domain/vocabulary_word.dart';

class VocabularyRepository {
  static const String boxName = 'vocabulary_box';
  Box<VocabularyWord>? _box;

  Future<void> openBox() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<VocabularyWord>(boxName);
  }

  Future<void> closeBox() async {
    await _box?.close();
    _box = null;
  }

  bool get isOpen => _box?.isOpen ?? false;

  List<VocabularyWord> getAll() {
    if (_box == null) return [];
    return _box!.values.toList().cast<VocabularyWord>();
  }

  Future<void> add(VocabularyWord word) async {
    await _box?.add(word);
  }

  Future<void> delete(int index) async {
    final key = _box!.keyAt(index);
    await _box!.delete(key);
  }

  Future<void> update(int index, VocabularyWord updated) async {
    final key = _box!.keyAt(index);
    await _box!.put(key, updated);
  }

  int get length => _box?.length ?? 0;

  VocabularyWord? getAt(int index) {
    if (_box == null || index >= length) return null;
    return _box!.getAt(index) as VocabularyWord?;
  }

  // For pagination: get sublist (safe)
  List<VocabularyWord> getRange({required int start, required int limit}) {
    final total = length;
    if (start >= total) return [];
    final end = (start + limit).clamp(0, total);
    final List<VocabularyWord> out = [];
    for (int i = start; i < end; i++) {
      final item = getAt(i);
      if (item != null) out.add(item);
    }
    return out;
  }
}

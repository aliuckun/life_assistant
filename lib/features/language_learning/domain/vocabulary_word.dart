// life_assistant/lib/features/language_learning/domain/vocabulary_word.dart
import 'package:hive/hive.dart';

part 'vocabulary_word.g.dart'; // not used (we provide manual adapter below) - safe to ignore

@HiveType(
  typeId: 120,
) // typeId seçtim, diğer adapterlarla çakışmamasına dikkat et
class VocabularyWord {
  @HiveField(0)
  final String german;

  @HiveField(1)
  final String turkish;

  @HiveField(2)
  final DateTime lastReviewed;

  @HiveField(3)
  final VocabularyType type;

  @HiveField(4)
  final Map<String, String>? conjugations; // optional, verb çekimleri için

  VocabularyWord({
    required this.german,
    required this.turkish,
    required this.lastReviewed,
    required this.type,
    this.conjugations,
  });

  VocabularyWord copyWith({
    String? german,
    String? turkish,
    DateTime? lastReviewed,
    VocabularyType? type,
    Map<String, String>? conjugations,
  }) => VocabularyWord(
    german: german ?? this.german,
    turkish: turkish ?? this.turkish,
    lastReviewed: lastReviewed ?? this.lastReviewed,
    type: type ?? this.type,
    conjugations: conjugations ?? this.conjugations,
  );
}

enum VocabularyType { noun, verb, adjective }

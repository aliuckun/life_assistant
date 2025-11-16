// life_assistant/lib/features/language_learning/domain/vocabulary_word_adapter.dart
import 'package:hive/hive.dart';
import 'vocabulary_word.dart';

class VocabularyWordAdapter extends TypeAdapter<VocabularyWord> {
  @override
  final int typeId = 120;

  @override
  VocabularyWord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }

    return VocabularyWord(
      german: fields[0] as String,
      turkish: fields[1] as String,
      lastReviewed: fields[2] as DateTime,
      type: VocabularyType.values[fields[3] as int],
      conjugations: (fields[4] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, VocabularyWord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.german)
      ..writeByte(1)
      ..write(obj.turkish)
      ..writeByte(2)
      ..write(obj.lastReviewed)
      ..writeByte(3)
      ..write(obj.type.index)
      ..writeByte(4)
      ..write(obj.conjugations);
  }
}

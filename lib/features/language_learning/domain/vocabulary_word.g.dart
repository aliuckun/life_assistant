// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocabulary_word.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VocabularyWordAdapter extends TypeAdapter<VocabularyWord> {
  @override
  final int typeId = 120;

  @override
  VocabularyWord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VocabularyWord(
      german: fields[0] as String,
      turkish: fields[1] as String,
      lastReviewed: fields[2] as DateTime,
      type: fields[3] as VocabularyType,
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
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.conjugations);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyWordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

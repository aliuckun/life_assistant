// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fitness_entities.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodEntryAdapter extends TypeAdapter<FoodEntry> {
  @override
  final int typeId = 1;

  @override
  FoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      mealType: fields[2] as MealType,
      description: fields[3] as String,
      calories: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, FoodEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.mealType)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.calories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutEntryAdapter extends TypeAdapter<WorkoutEntry> {
  @override
  final int typeId = 2;

  @override
  WorkoutEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      region: fields[2] as String,
      exercise: fields[3] as String,
      sets: fields[4] as int,
      reps: fields[5] as int,
      weight: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.region)
      ..writeByte(3)
      ..write(obj.exercise)
      ..writeByte(4)
      ..write(obj.sets)
      ..writeByte(5)
      ..write(obj.reps)
      ..writeByte(6)
      ..write(obj.weight);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeightEntryAdapter extends TypeAdapter<WeightEntry> {
  @override
  final int typeId = 3;

  @override
  WeightEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeightEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      weightKg: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, WeightEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.weightKg);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MealTypeAdapter extends TypeAdapter<MealType> {
  @override
  final int typeId = 0;

  @override
  MealType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MealType.sabah;
      case 1:
        return MealType.ogle;
      case 2:
        return MealType.aksam;
      case 3:
        return MealType.ekstra;
      default:
        return MealType.sabah;
    }
  }

  @override
  void write(BinaryWriter writer, MealType obj) {
    switch (obj) {
      case MealType.sabah:
        writer.writeByte(0);
        break;
      case MealType.ogle:
        writer.writeByte(1);
        break;
      case MealType.aksam:
        writer.writeByte(2);
        break;
      case MealType.ekstra:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

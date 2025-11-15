// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 5;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as HabitType,
      targetCount: fields[3] as int,
      enableNotification: fields[4] as bool,
      notificationTimeString: fields[5] as String?,
      progressJson: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.targetCount)
      ..writeByte(4)
      ..write(obj.enableNotification)
      ..writeByte(5)
      ..write(obj.notificationTimeString)
      ..writeByte(6)
      ..write(obj.progressJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HabitTypeAdapter extends TypeAdapter<HabitType> {
  @override
  final int typeId = 4;

  @override
  HabitType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HabitType.gain;
      case 1:
        return HabitType.quit;
      default:
        return HabitType.gain;
    }
  }

  @override
  void write(BinaryWriter writer, HabitType obj) {
    switch (obj) {
      case HabitType.gain:
        writer.writeByte(0);
        break;
      case HabitType.quit:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agenda_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AgendaItemAdapter extends TypeAdapter<AgendaItem> {
  @override
  final int typeId = 10;

  @override
  AgendaItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AgendaItem(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      dueDate: fields[3] as DateTime,
      isCompleted: fields[4] as bool,
      hasNotification: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AgendaItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.hasNotification);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgendaItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

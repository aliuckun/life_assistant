import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// Manuel Hive Type ID'leri
const int kPlanTypeId = 12;
const int kPriorityTypeId = 13;

// --- ENUMLAR ---

enum PlanPriority { low, medium, high }

// --- UI MODELLERİ (Veritabanına kaydedilmeyen, UI için kullanılanlar) ---

class PlanCategory {
  final String name;
  final IconData icon;
  final Color color;

  const PlanCategory(this.name, this.icon, this.color);
}

// --- DB MODELLERİ (Hive ile kaydedilenler) ---

@HiveType(typeId: kPlanTypeId)
class PlanItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime date;

  // TimeOfDay Hive tarafından desteklenmez, dakika cinsinden int saklayacağız
  @HiveField(4)
  int startTimeInMinutes;

  @HiveField(5)
  int endTimeInMinutes;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  String categoryName; // Kategoriyi isim olarak saklayıp UI'da eşleştireceğiz

  @HiveField(8)
  int priorityIndex; // Enum'ı index olarak saklayacağız

  PlanItem({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.startTimeInMinutes,
    required this.endTimeInMinutes,
    this.isCompleted = false,
    required this.categoryName,
    required this.priorityIndex,
  });

  // Helper getters
  TimeOfDay get startTime => TimeOfDay(
    hour: startTimeInMinutes ~/ 60,
    minute: startTimeInMinutes % 60,
  );
  TimeOfDay get endTime =>
      TimeOfDay(hour: endTimeInMinutes ~/ 60, minute: endTimeInMinutes % 60);
  PlanPriority get priority => PlanPriority.values[priorityIndex];
}

// --- HIVE ADAPTERS (build_runner kullanmadan manuel tanımlama) ---
class PlanItemAdapter extends TypeAdapter<PlanItem> {
  @override
  final int typeId = kPlanTypeId;

  @override
  PlanItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanItem(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      date: fields[3] as DateTime,
      startTimeInMinutes: fields[4] as int,
      endTimeInMinutes: fields[5] as int,
      isCompleted: fields[6] as bool,
      categoryName: fields[7] as String,
      priorityIndex: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PlanItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.startTimeInMinutes)
      ..writeByte(5)
      ..write(obj.endTimeInMinutes)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.categoryName)
      ..writeByte(8)
      ..write(obj.priorityIndex);
  }
}

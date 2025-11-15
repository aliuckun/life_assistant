// lib/features/habit_tracker/domain/entities/habit.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'habit.g.dart'; // 🔥 Code generation için

@HiveType(typeId: 4)
enum HabitType {
  @HiveField(0)
  gain,
  @HiveField(1)
  quit,
}

// 🔥 @immutable kaldırıldı - HiveObject zaten immutable değil
@HiveType(typeId: 5)
class Habit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final HabitType type;

  @HiveField(3)
  final int targetCount;

  @HiveField(4)
  final bool enableNotification;

  @HiveField(5)
  final String? notificationTimeString; // 🔥 TimeOfDay'i String olarak sakla

  @HiveField(6)
  final String progressJson; // 🔥 Map<String, int>'i JSON String olarak sakla

  Habit({
    required this.id,
    required this.name,
    required this.type,
    this.targetCount = 1,
    this.enableNotification = true,
    this.notificationTimeString,
    required this.progressJson,
  });

  // 🔥 Helper: TimeOfDay getter
  TimeOfDay? get notificationTime {
    if (notificationTimeString == null) return null;
    final parts = notificationTimeString!.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // 🔥 Helper: progress Map getter
  Map<String, int> get progress {
    try {
      final decoded = jsonDecode(progressJson) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      return {};
    }
  }

  // 🔥 Factory: Normal constructor'dan oluştur
  factory Habit.create({
    required String id,
    required String name,
    required HabitType type,
    int targetCount = 1,
    bool enableNotification = true,
    TimeOfDay? notificationTime,
    Map<String, int>? progress,
  }) {
    return Habit(
      id: id,
      name: name,
      type: type,
      targetCount: targetCount,
      enableNotification: enableNotification,
      notificationTimeString: notificationTime != null
          ? '${notificationTime.hour}:${notificationTime.minute}'
          : null,
      progressJson: jsonEncode(progress ?? {}),
    );
  }

  // copyWith metodu
  Habit copyWith({
    String? id,
    String? name,
    HabitType? type,
    int? targetCount,
    bool? enableNotification,
    TimeOfDay? notificationTime,
    Map<String, int>? progress,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      enableNotification: enableNotification ?? this.enableNotification,
      notificationTimeString: notificationTime != null
          ? '${notificationTime.hour}:${notificationTime.minute}'
          : (this.notificationTimeString),
      progressJson: progress != null ? jsonEncode(progress) : this.progressJson,
    );
  }

  // Belirli bir güne ait ilerlemeyi alır
  int getProgressForDate(DateTime date) {
    final dateKey = DateUtils.dateOnly(date).toIso8601String();
    return progress[dateKey] ?? 0;
  }

  // Belirli bir gün için tamamlanma durumunu kontrol eder
  bool isCompletedForDate(DateTime date) {
    if (type == HabitType.quit) {
      return getProgressForDate(date) < targetCount;
    }
    return getProgressForDate(date) >= targetCount;
  }
}

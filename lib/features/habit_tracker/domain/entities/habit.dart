// lib/features/habit_tracker/domain/entities/habit.dart
import 'package:flutter/material.dart';

enum HabitType { gain, quit } // Kazanılacak mı, bırakılacak mı

@immutable
class Habit {
  final String id;
  final String name;
  final HabitType type;
  final int targetCount; // Günlük hedef (kaç defa yapılacağı)
  final bool enableNotification; // Bildirim açık mı?
  final TimeOfDay? notificationTime; // Bildirim saati

  // Günlük ilerlemeyi tutacak bir Map: {tarihString: kaç_kere_yapıldı}
  final Map<String, int> progress;

  const Habit({
    required this.id,
    required this.name,
    required this.type,
    this.targetCount = 1,
    this.enableNotification = true,
    this.notificationTime,
    required this.progress, // Constructor'da required yaptık
  });

  // copyWith metodu (StateNotifier için zorunlu)
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
      notificationTime: notificationTime ?? this.notificationTime,
      // Progress Map'ini kopyalamayı unutmayın!
      progress: progress ?? Map<String, int>.from(this.progress),
    );
  }

  // Belirli bir güne ait ilerlemeyi alır
  int getProgressForDate(DateTime date) {
    final dateKey = DateUtils.dateOnly(date).toIso8601String();
    return progress[dateKey] ?? 0;
  }

  // Belirli bir gün için tamamlanma durumunu kontrol eder
  bool isCompletedForDate(DateTime date) {
    // Quit tipi için hedef 1'dir ve 0 başarı demektir.
    if (type == HabitType.quit) {
      return getProgressForDate(date) <
          targetCount; // Progress 1'e ulaşmadıysa başarılıdır (yani 0'dır)
    }
    return getProgressForDate(date) >= targetCount;
  }
}

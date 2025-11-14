import 'package:flutter/material.dart';

enum HabitType { gain, quit } // Kazanılacak mı, bırakılacak mı

class Habit {
  final String id;
  String name;
  HabitType type;
  int targetCount; // Günlük hedef (kaç defa yapılacağı)
  bool enableNotification; // Bildirim açık mı?
  TimeOfDay? notificationTime; // Bildirim saati

  // Günlük ilerlemeyi tutacak bir Map: {tarihString: kaç_kere_yapıldı}
  final Map<String, int> progress;

  Habit({
    required this.id,
    required this.name,
    required this.type,
    this.targetCount = 1,
    this.enableNotification = true,
    this.notificationTime,
    Map<String, int>? initialProgress,
  }) : progress = initialProgress ?? {};

  // O anki günün ilerlemesini alır
  int get currentDayProgress {
    final todayKey = DateUtils.dateOnly(DateTime.now()).toIso8601String();
    return progress[todayKey] ?? 0;
  }

  // Alışkanlığın tamamlanıp tamamlanmadığını kontrol eder
  bool get isCompletedToday {
    return currentDayProgress >= targetCount;
  }

  // Belirli bir güne ait ilerlemeyi alır
  int getProgressForDate(DateTime date) {
    final dateKey = DateUtils.dateOnly(date).toIso8601String();
    return progress[dateKey] ?? 0;
  }

  // Belirli bir gün için tamamlanma durumunu kontrol eder
  bool isCompletedForDate(DateTime date) {
    return getProgressForDate(date) >= targetCount;
  }
}

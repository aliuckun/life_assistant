// lib/features/habit_tracker/data/habit_repository_impl.dart
import 'package:flutter/material.dart';
import '../domain/entities/habit.dart';
import './habit_repository.dart';

// 🚨 LOKAL VERİ KAYNAĞI (Simüle Edilmiş Veritabanı)
// Bu liste, HabitNotifier'daki demo verilerini içermelidir (Lazy Loading için)
List<Habit> _localHabits = [
  Habit(
    id: 'h1',
    name: 'Su İç',
    type: HabitType.gain,
    targetCount: 8,
    notificationTime: const TimeOfDay(hour: 10, minute: 0),
    progress: {
      DateUtils.dateOnly(
        DateTime.now().subtract(const Duration(days: 1)),
      ).toIso8601String(): 8,
      DateUtils.dateOnly(DateTime.now()).toIso8601String(): 3,
    },
  ),
  Habit(
    id: 'h2',
    name: 'Şekerli İçecek Yok',
    type: HabitType.quit,
    targetCount: 1, // Bırakılacak alışkanlıklar için hedef 1
    notificationTime: const TimeOfDay(hour: 15, minute: 30),
    progress: {},
  ),
];

class HabitRepositoryImpl implements HabitRepository {
  // ------------------------------------------------------------------------
  // 💰 LAZY LOADING / INFINITE SCROLL İşlemi (getHabits)
  // ------------------------------------------------------------------------
  @override
  Future<List<Habit>> getHabits({
    required int limit,
    required int offset,
  }) async {
    // Lokal listeyi tarihe göre değil, sadece eklenme sırasına göre alalım
    final sortedList = _localHabits.toList();

    // Belirtilen offset ve limitle veriyi parçala
    int start = offset;
    int end = (offset + limit);
    if (start >= sortedList.length) {
      return []; // Daha fazla veri yok
    }
    if (end > sortedList.length) {
      end = sortedList.length;
    }

    // Gecikmeyi simüle et (Lazy Loading'i görmek için)
    await Future.delayed(const Duration(milliseconds: 700));

    return sortedList.sublist(start, end);
  }

  // ------------------------------------------------------------------------
  // ➕ CRUD ve getAllHabits
  // ------------------------------------------------------------------------

  @override
  Future<List<Habit>> getAllHabits() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _localHabits.toList();
  }

  @override
  Future<void> addHabit(Habit habit) async {
    // Yeni bir ID oluştur ve listeye ekle
    final newId = 'H${DateTime.now().millisecondsSinceEpoch}';
    final newHabit = habit.copyWith(id: newId);
    _localHabits.add(newHabit);
    debugPrint('Habit added: $newId');
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final index = _localHabits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _localHabits[index] = habit;
    }
    debugPrint('Habit updated: ${habit.id}');
  }

  @override
  Future<void> deleteHabit(String id) async {
    _localHabits.removeWhere((h) => h.id == id);
    debugPrint('Habit deleted: $id');
  }
}

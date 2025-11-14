import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod import edildi
import 'package:life_assistant/features/habit_tracker/domain/models/habit.dart';

// --- (1) Sizin istediğiniz ChangeNotifier sınıfı ---
class HabitNotifier extends ChangeNotifier {
  final List<Habit> _habits = [];
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  List<Habit> get habits => _habits;
  DateTime get selectedDate => _selectedDate;

  HabitNotifier() {
    // Demo verileri
    _habits.add(
      Habit(
        id: 'h1',
        name: 'Su İç',
        type: HabitType.gain,
        targetCount: 8,
        notificationTime: const TimeOfDay(hour: 10, minute: 0),
        initialProgress: {
          DateUtils.dateOnly(
            DateTime.now().subtract(const Duration(days: 1)),
          ).toIso8601String(): 8,
          DateUtils.dateOnly(DateTime.now()).toIso8601String(): 3,
        },
      ),
    );
    _habits.add(
      Habit(
        id: 'h2',
        name: 'Şekerli İçecek Yok',
        type: HabitType.quit,
        targetCount:
            1, // Bırakılacak alışkanlıklar için 1 (başarısız olma sayısı)
        notificationTime: const TimeOfDay(hour: 15, minute: 30),
      ),
    );
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = DateUtils.dateOnly(date);
    notifyListeners();
  }

  void addHabit(Habit habit) {
    _habits.add(habit);
    notifyListeners();
  }

  // Alışkanlığı artırma/tamamlama
  void incrementHabit(Habit habit, [DateTime? date]) {
    final targetDate = date ?? _selectedDate;
    final dateKey = targetDate.toIso8601String();

    // Gelecek günler için işlem yapma
    if (targetDate.isAfter(DateUtils.dateOnly(DateTime.now()))) {
      return;
    }

    // Hem Kazanılacak (gain) hem de Bırakılacak (quit) için artırma
    // Bırakılacak alışkanlıkta artırma, başarısızlık anlamına gelir (hedef 1)
    int currentProgress = habit.progress[dateKey] ?? 0;
    if (currentProgress < habit.targetCount) {
      habit.progress[dateKey] = currentProgress + 1;
      notifyListeners();
    }
  }

  // Özet verisi metodu
  Map<String, dynamic> getSummaryData() {
    if (_habits.isEmpty) return {'totalHabits': 0, 'completionRate': 0.0};

    int totalCompletionDays = 0;
    int totalPossibleDays = 0;

    // Son 7 güne odaklanalım
    for (int i = 0; i < 7; i++) {
      final date = DateUtils.dateOnly(
        DateTime.now().subtract(Duration(days: i)),
      );
      for (final habit in _habits) {
        if (habit.isCompletedForDate(date)) {
          totalCompletionDays++;
        }
        totalPossibleDays++;
      }
    }

    double completionRate = totalPossibleDays > 0
        ? (totalCompletionDays / totalPossibleDays) * 100
        : 0.0;

    return {'totalHabits': _habits.length, 'completionRate': completionRate};
  }
}

// -------------------------------------------------------------
// --- (2) Riverpod Provider Tanımları (main.dart'a gerek kalmaması için) ---
// -------------------------------------------------------------

// ChangeNotifierProvider, HabitNotifier'ı Riverpod aracılığıyla tüm uygulamaya sunar.
final habitListProvider = ChangeNotifierProvider<HabitNotifier>((ref) {
  return HabitNotifier();
});

// Seçili tarihi tutan basit State Provider (Bu da ChangeNotifier'dan alındı)
final selectedDateProvider = Provider<DateTime>((ref) {
  // HabitNotifier'ın kendisini izle ve içindeki selectedDate'i al
  return ref.watch(habitListProvider).selectedDate;
});

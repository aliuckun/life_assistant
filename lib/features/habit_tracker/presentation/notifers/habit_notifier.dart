// lib/features/habit_tracker/presentation/state/habit_notifier.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 🚨 İlerideki hataları önlemek için tam import yolu kullanıldı:
import 'package:life_assistant/features/habit_tracker/domain/entities/habit.dart';
import '../../data/habit_repository.dart';
import '../../data/habit_repository_imlp.dart';

// State yapısı
@immutable
class HabitTrackerState {
  // ... (State sınıfı aynı kalır)
  final List<Habit> habits;
  final DateTime selectedDate;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;

  const HabitTrackerState({
    required this.habits,
    required this.selectedDate,
    required this.isLoadingInitial,
    required this.isLoadingMore,
    required this.hasMore,
    required this.offset,
  });

  HabitTrackerState copyWith({
    List<Habit>? habits,
    DateTime? selectedDate,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMore,
    int? offset,
  }) {
    return HabitTrackerState(
      habits: habits ?? this.habits,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
    );
  }
}

// Notifier: State'i yöneten ana sınıf
class HabitNotifier extends StateNotifier<HabitTrackerState> {
  final HabitRepository _repository;
  final int _limit = 5; // Lazy Loading için limit

  HabitNotifier(this._repository)
    : super(
        HabitTrackerState(
          habits: const [],
          selectedDate: DateUtils.dateOnly(DateTime.now()),
          isLoadingInitial: false,
          isLoadingMore: false,
          hasMore: true,
          offset: 0,
        ),
      ) {
    fetchInitialHabits(); // Sayfa açılışında ilk verileri çek
  }

  // ------------------------------------------------------------------------
  // 💰 LAZY LOADING / INFINITE SCROLL İşlemi
  // ------------------------------------------------------------------------

  Future<void> fetchInitialHabits() async {
    // ... (metot içeriği aynı)
    if (state.isLoadingInitial) return;
    state = state.copyWith(isLoadingInitial: true, offset: 0, hasMore: true);

    try {
      final newHabits = await _repository.getHabits(limit: _limit, offset: 0);

      state = state.copyWith(
        habits: newHabits,
        offset: newHabits.length,
        isLoadingInitial: false,
        hasMore: newHabits.length == _limit,
      );
    } catch (e) {
      debugPrint('Error fetching initial habits: $e');
      state = state.copyWith(isLoadingInitial: false);
    }
  }

  // 🚨 Hata Çözümü: Bu metot Notifier içinde bulunmalıdır.
  Future<void> fetchNextHabits() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);

    try {
      final newHabits = await _repository.getHabits(
        limit: _limit,
        offset: state.offset,
      );

      state = state.copyWith(
        habits: [...state.habits, ...newHabits],
        offset: state.offset + newHabits.length,
        isLoadingMore: false,
        hasMore: newHabits.length == _limit,
      );
    } catch (e) {
      debugPrint('Error fetching next habits: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  // ------------------------------------------------------------------------
  // ➕ CRUD ve Diğer İşlemler (Aynı kalır)
  // ------------------------------------------------------------------------

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: DateUtils.dateOnly(date));
  }

  Future<void> addHabit(Habit habit) async {
    await _repository.addHabit(habit);
    await fetchInitialHabits();
  }

  Future<void> deleteHabit(String id) async {
    await _repository.deleteHabit(id);
    await fetchInitialHabits();
  }

  Future<void> updateHabit(Habit habit) async {
    await _repository.updateHabit(habit);
    final index = state.habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      final newHabits = List<Habit>.from(state.habits);
      newHabits[index] = habit;
      state = state.copyWith(habits: newHabits);
    }
  }

  // Alışkanlığı artırma/tamamlama (Progress güncelleyen ana metot)
  void incrementHabit(Habit habit, DateTime date) {
    // 🚨 KESİN ÇÖZÜM: Tarihin saatini sıfırlayıp SADECE tarih kısmını alıyoruz
    // Bu, milisaniyelerden kaynaklanabilecek hataları önler.
    final targetDate = DateUtils.dateOnly(date);
    final dateKey = targetDate.toIso8601String();

    if (targetDate.isAfter(DateUtils.dateOnly(DateTime.now()))) {
      return;
    }

    final currentProgress = habit.getProgressForDate(targetDate);
    // 🚨 Progress Map'ini KOPYALA
    final newProgress = Map<String, int>.from(habit.progress);

    if (habit.type == HabitType.quit) {
      // Eğer başarılıysa (currentProgress == 0), tıklandığında başarısız kaydet (1)
      // Eğer başarısızsa (currentProgress == 1), tıklandığında geri al (0)
      newProgress[dateKey] = (currentProgress == 0) ? 1 : 0;
    } else {
      // GAIN MANTIĞI: Hedefe ulaşılana kadar artır
      if (currentProgress < habit.targetCount) {
        newProgress[dateKey] = currentProgress + 1;
      } else {
        // Tamamlanmışsa, sıfırla
        newProgress[dateKey] = 0;
      }
    }

    final updatedHabit = habit.copyWith(progress: newProgress);
    updateHabit(updatedHabit); // UI güncellemesi için updateHabit çağrılır
  }

  // Özet verisi metodu
  Future<Map<String, dynamic>> getSummaryData() async {
    // ... (metot içeriği aynı kalır)
    final habits = await _repository.getAllHabits();
    if (habits.isEmpty) return {'totalHabits': 0, 'completionRate': 0.0};

    int totalCompletionDays = 0;
    int totalPossibleDays = 0;

    for (int i = 0; i < 7; i++) {
      final date = DateUtils.dateOnly(
        DateTime.now().subtract(Duration(days: i)),
      );
      for (final habit in habits) {
        if (habit.isCompletedForDate(date)) {
          totalCompletionDays++;
        }
        totalPossibleDays++;
      }
    }

    double completionRate = totalPossibleDays > 0
        ? (totalCompletionDays / totalPossibleDays) * 100
        : 0.0;

    return {'totalHabits': habits.length, 'completionRate': completionRate};
  }
}

// Riverpod Provider Tanımı
final habitListProvider =
    StateNotifierProvider<HabitNotifier, HabitTrackerState>((ref) {
      return HabitNotifier(HabitRepositoryImpl());
    });

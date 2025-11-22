// lib/features/habit_tracker/presentation/state/habit_notifier.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_assistant/features/habit_tracker/domain/entities/habit.dart';
import '../../data/habit_repository.dart';
import '../../data/habit_repository_imlp.dart';

// 🔔 Bildirim Servisi Import Edildi (Yolunu kendi proje yapına göre kontrol et)
import '../../../../core/services/notification_service.dart';

// State yapısı (Değişiklik yok)
@immutable
class HabitTrackerState {
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

  // 🔔 Bildirim Servisi Örneği Oluşturuldu
  final NotificationService _notificationService = NotificationService();

  final int _limit = 10; // Lazy Loading için limit

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
    // Bildirim servisini başlat (Eğer main.dart'ta başlatmadıysan burada garanti olsun)
    _notificationService.initialize();
    fetchInitialHabits(); // Sayfa açılışında ilk verileri çek
  }

  // ------------------------------------------------------------------------
  // 💰 LAZY LOADING / INFINITE SCROLL İşlemi
  // ------------------------------------------------------------------------

  Future<void> fetchInitialHabits() async {
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
  // ➕ CRUD ve BİLDİRİM İşlemleri
  // ------------------------------------------------------------------------

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: DateUtils.dateOnly(date));
  }

  Future<void> addHabit(Habit habit) async {
    await _repository.addHabit(habit);

    // 🔔 BİLDİRİM EKLEME
    // Eğer kullanıcı bildirim istiyorsa ve saat seçiliyse planla
    if (habit.enableNotification && habit.notificationTime != null) {
      await _notificationService.scheduleDailyHabitNotification(
        id: habit.id.hashCode, // String ID'yi int'e çeviriyoruz
        title: "Hatırlatıcı: ${habit.name}",
        body: "Alışkanlığını tamamlama vakti geldi! 🔥",
        time: habit.notificationTime!,
      );
    }

    await fetchInitialHabits();
  }

  Future<void> deleteHabit(String id) async {
    // 🔔 BİLDİRİMİ SİL
    // Alışkanlık silindiğinde bildirimi de iptal etmeliyiz
    await _notificationService.cancelNotification(id.hashCode);

    await _repository.deleteHabit(id);
    await fetchInitialHabits();
  }

  Future<void> updateHabit(Habit habit) async {
    await _repository.updateHabit(habit);

    // 🔔 BİLDİRİM GÜNCELLEME
    // 1. Önceki olası bildirimi temizle (saat değişmiş veya kapatılmış olabilir)
    await _notificationService.cancelNotification(habit.id.hashCode);

    // 2. Eğer bildirim hala aktifse ve saat varsa yeniden kur
    if (habit.enableNotification && habit.notificationTime != null) {
      await _notificationService.scheduleDailyHabitNotification(
        id: habit.id.hashCode,
        title: "Hatırlatıcı: ${habit.name}",
        body: "Alışkanlığını tamamlama vakti geldi! 🔥",
        time: habit.notificationTime!,
      );
    }

    // State güncellemesi (Repo'dan çekmek yerine yerel listeyi güncellemek daha hızlıdır)
    final index = state.habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      final newHabits = List<Habit>.from(state.habits);
      newHabits[index] = habit;
      state = state.copyWith(habits: newHabits);
    }
  }

  // Alışkanlığı artırma/tamamlama (Progress güncelleyen ana metot)
  void incrementHabit(Habit habit, DateTime date) {
    final targetDate = DateUtils.dateOnly(date);
    final dateKey = targetDate.toIso8601String();

    if (targetDate.isAfter(DateUtils.dateOnly(DateTime.now()))) {
      return;
    }

    final currentProgress = habit.getProgressForDate(targetDate);
    final newProgress = Map<String, int>.from(habit.progress);

    if (habit.type == HabitType.quit) {
      newProgress[dateKey] = (currentProgress == 0) ? 1 : 0;
    } else {
      if (currentProgress < habit.targetCount) {
        newProgress[dateKey] = currentProgress + 1;
      } else {
        newProgress[dateKey] = 0;
      }
    }

    final updatedHabit = habit.copyWith(progress: newProgress);

    // Burada updateHabit çağırıyoruz, dolayısıyla bildirim mantığı orada zaten çalışacak.
    // Ancak sadece "progress" değiştiği için bildirim saatini tekrar kurmaya gerek yok aslında.
    // Performans için _repository.updateHabit(habit) direkt çağrılabilir ama
    // Şimdilik tutarlılık için updateHabit metodunu kullanıyoruz.
    updateHabit(updatedHabit);
  }

  // Özet verisi metodu
  Future<Map<String, dynamic>> getSummaryData() async {
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

// Provider Tanımları (Aynı kalır)
final habitRepositoryProvider = FutureProvider<HabitRepository>((ref) async {
  return await HabitRepositoryImpl.getInstance();
});

final habitListProvider =
    StateNotifierProvider<HabitNotifier, HabitTrackerState>((ref) {
      final repoAsync = ref.watch(habitRepositoryProvider);
      return repoAsync.when(
        data: (repo) => HabitNotifier(repo),
        loading: () => HabitNotifier(_DummyRepository()),
        error: (_, __) => HabitNotifier(_DummyRepository()),
      );
    });

// Geçici dummy repository
class _DummyRepository implements HabitRepository {
  @override
  Future<void> addHabit(Habit habit) async {}

  @override
  Future<void> deleteHabit(String id) async {}

  @override
  Future<List<Habit>> getAllHabits() async => [];

  @override
  Future<List<Habit>> getHabits({
    required int limit,
    required int offset,
  }) async => [];

  @override
  Future<void> updateHabit(Habit habit) async {}
}

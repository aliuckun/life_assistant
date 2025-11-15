// lib/features/fitness_tracker/presentation/state/fitness_notifier.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/fitness_entities.dart';
import '../../data/repositories/fitness_repository_impl.dart';
import '../../domain/repositories/fitness_repository.dart';

@immutable
class FitnessTrackerState {
  final List<FoodEntry> foodEntries;
  final DateTime selectedDate;
  final int totalCalories;
  final bool isLoading;
  final bool hasMore;
  final int offset;

  const FitnessTrackerState({
    required this.foodEntries,
    required this.selectedDate,
    required this.totalCalories,
    required this.isLoading,
    required this.hasMore,
    required this.offset,
  });

  FitnessTrackerState copyWith({
    List<FoodEntry>? foodEntries,
    DateTime? selectedDate,
    int? totalCalories,
    bool? isLoading,
    bool? hasMore,
    int? offset,
  }) {
    return FitnessTrackerState(
      foodEntries: foodEntries ?? this.foodEntries,
      selectedDate: selectedDate ?? this.selectedDate,
      totalCalories: totalCalories ?? this.totalCalories,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
    );
  }
}

class FitnessNotifier extends StateNotifier<FitnessTrackerState> {
  final FitnessRepository _repository;
  final int _limit = 5;

  FitnessNotifier(this._repository)
    : super(
        FitnessTrackerState(
          foodEntries: const [],
          selectedDate: DateUtils.dateOnly(DateTime.now()),
          totalCalories: 0,
          isLoading: false,
          hasMore: true,
          offset: 0,
        ),
      ) {
    // İlk verileri ve kaloriyi çek
    _fetchDataForSelectedDate(state.selectedDate);
  }

  // --- Veri Çekme İşlemleri ---

  Future<void> setSelectedDate(DateTime date) async {
    final newDate = DateUtils.dateOnly(date);
    // Tarihi güncelle
    state = state.copyWith(selectedDate: newDate);
    // Yeni tarihe ait verileri çek
    await _fetchDataForSelectedDate(newDate);
  }

  // Ana veri çekme ve Lazy Loading
  Future<void> _fetchDataForSelectedDate(DateTime date) async {
    state = state.copyWith(isLoading: true, offset: 0, hasMore: true);

    try {
      final entries = await _repository.getFoodEntries(
        date: date,
        limit: _limit,
        offset: 0,
      );
      final totalCals = await _repository.getTotalCaloriesForDate(date);

      state = state.copyWith(
        foodEntries: entries,
        totalCalories: totalCals,
        offset: entries.length,
        isLoading: false,
        hasMore: entries.length == _limit,
      );
    } catch (e) {
      debugPrint('Error fetching fitness data: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchNextEntries() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final newEntries = await _repository.getFoodEntries(
        date: state.selectedDate,
        limit: _limit,
        offset: state.offset,
      );

      state = state.copyWith(
        foodEntries: [...state.foodEntries, ...newEntries],
        offset: state.offset + newEntries.length,
        isLoading: false,
        hasMore: newEntries.length == _limit,
      );
    } catch (e) {
      debugPrint('Error fetching next entries: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  // --- CRUD İşlemleri ---

  Future<void> addFoodEntry(FoodEntry entry) async {
    await _repository.addFoodEntry(entry);
    await _fetchDataForSelectedDate(state.selectedDate); // Listeyi yenile
  }

  Future<void> updateFoodEntry(FoodEntry entry) async {
    await _repository.updateFoodEntry(entry);
    await _fetchDataForSelectedDate(state.selectedDate); // Listeyi yenile
  }

  Future<void> deleteFoodEntry(String id) async {
    await _repository.deleteFoodEntry(id);
    await _fetchDataForSelectedDate(state.selectedDate); // Listeyi yenile
  }

  // --- Kilo Kayıt İşlemleri ---

  Future<void> addWeightEntry(double weightKg) async {
    final entry = WeightEntry(id: '', date: DateTime.now(), weightKg: weightKg);
    await _repository.addWeightEntry(entry);
    // Kilo grafiğini etkilemek için summary provider'ı invalidate etmek gerekir.
  }

  // --- Egzersiz İşlemleri (Sadece kaydetme) ---

  Future<void> addWorkoutEntry(WorkoutEntry entry) async {
    await _repository.addWorkoutEntry(entry);
    debugPrint('Workout recorded: ${entry.exercise}');
  }
}

// 🔥 Repository Provider
final fitnessRepositoryProvider = FutureProvider<FitnessRepository>((
  ref,
) async {
  return await FitnessRepositoryImpl.getInstance();
});

// 🔥 Notifier Provider - Repository hazır olana kadar bekle
final fitnessNotifierProvider =
    StateNotifierProvider<FitnessNotifier, FitnessTrackerState>((ref) {
      final repoAsync = ref.watch(fitnessRepositoryProvider);
      return repoAsync.when(
        data: (repo) => FitnessNotifier(repo),
        loading: () => FitnessNotifier(_DummyFitnessRepository()),
        error: (_, __) => FitnessNotifier(_DummyFitnessRepository()),
      );
    });

// 🔥 Dummy Repository (Loading durumu için)
class _DummyFitnessRepository implements FitnessRepository {
  @override
  Future<void> addFoodEntry(FoodEntry entry) async {}

  @override
  Future<void> addWeightEntry(WeightEntry entry) async {}

  @override
  Future<void> addWorkoutEntry(WorkoutEntry entry) async {}

  @override
  Future<void> deleteFoodEntry(String id) async {}

  @override
  Future<List<FoodEntry>> getAllFoodEntries() async => [];

  @override
  Future<List<FoodEntry>> getFoodEntries({
    required DateTime date,
    required int limit,
    required int offset,
  }) async => [];

  @override
  Future<int> getTotalCaloriesForDate(DateTime date) async => 0;

  @override
  Future<void> updateFoodEntry(FoodEntry entry) async {}

  @override
  Future<List<WeightEntry>> getAllWeightEntries() async => [];

  @override
  Future<List<WorkoutEntry>> getWorkoutEntries(DateTime date) async => [];
}

// Kiloyu ve yemek özetini çeken ayrı bir Future Provider (Özet Sayfası için)
final weightSummaryProvider = FutureProvider.autoDispose<List<WeightEntry>>((
  ref,
) async {
  final repo = await FitnessRepositoryImpl.getInstance();
  return repo.getAllWeightEntries();
});

final calorieSummaryProvider = FutureProvider.autoDispose<List<FoodEntry>>((
  ref,
) async {
  final repo = await FitnessRepositoryImpl.getInstance();
  return repo.getAllFoodEntries();
});

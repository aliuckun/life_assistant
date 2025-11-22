// lib/features/fitness_tracker/domain/repositories/fitness_repository.dart
import '../entities/fitness_entities.dart';

abstract class FitnessRepository {
  // --- YEMEK/KALORİ İŞLEMLERİ (Lazy Loading) ---
  Future<List<FoodEntry>> getFoodEntries({
    required DateTime date,
    required int limit,
    required int offset,
  });

  Future<List<FoodEntry>> getFoodEntriesByDateRange(
    DateTime start,
    DateTime end,
  );

  Future<List<FoodEntry>> getAllFoodEntries(); // Özet için tüm veriyi çek
  Future<int> getTotalCaloriesForDate(DateTime date);
  Future<void> addFoodEntry(FoodEntry entry);
  Future<void> updateFoodEntry(FoodEntry entry);
  Future<void> deleteFoodEntry(String id);

  // --- KİLO İŞLEMLERİ ---
  Future<List<WeightEntry>> getAllWeightEntries();
  Future<void> addWeightEntry(WeightEntry entry);

  // --- EGZERSİZ İŞLEMLERİ ---
  Future<void> addWorkoutEntry(WorkoutEntry entry);
  Future<List<WorkoutEntry>> getWorkoutEntries(DateTime date);

  Future<void> saveTargetCalories(int target);
  Future<int> getTargetCalories();
}

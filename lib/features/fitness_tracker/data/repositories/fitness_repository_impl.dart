// lib/features/fitness_tracker/data/repositories/fitness_repository_impl.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/fitness_entities.dart';
import '../../domain/repositories/fitness_repository.dart';

class FitnessRepositoryImpl implements FitnessRepository {
  // 🔥 HIVE BOX İSİMLERİ
  static const String _foodBoxName = 'food_entries';
  static const String _weightBoxName = 'weight_entries';
  static const String _workoutBoxName = 'workout_entries';

  // 🔥 HIVE BOX'LARI
  Box<FoodEntry>? _foodBox;
  Box<WeightEntry>? _weightBox;
  Box<WorkoutEntry>? _workoutBox;

  // 🔥 SINGLETON PATTERN
  static FitnessRepositoryImpl? _instance;
  static Future<FitnessRepositoryImpl> getInstance() async {
    if (_instance == null) {
      _instance = FitnessRepositoryImpl._internal();
      await _instance!._initBoxes();
    }
    return _instance!;
  }

  // Private constructor
  FitnessRepositoryImpl._internal();

  Future<void> _initBoxes() async {
    _foodBox = await Hive.openBox<FoodEntry>(_foodBoxName);
    _weightBox = await Hive.openBox<WeightEntry>(_weightBoxName);
    _workoutBox = await Hive.openBox<WorkoutEntry>(_workoutBoxName);
    debugPrint('✅ Fitness boxes opened successfully');
  }

  // ------------------------- YEMEK/KALORİ İŞLEMLERİ -------------------------

  @override
  Future<List<FoodEntry>> getFoodEntries({
    required DateTime date,
    required int limit,
    required int offset,
  }) async {
    if (_foodBox == null || !_foodBox!.isOpen) {
      _foodBox = await Hive.openBox<FoodEntry>(_foodBoxName);
    }

    final targetDate = DateUtils.dateOnly(date);

    // 1. Verilen güne göre filtrele
    final filteredList = _foodBox!.values
        .where((e) => DateUtils.dateOnly(e.date) == targetDate)
        .toList();

    // 2. Lazy Loading (Pagination) uygula
    int start = offset;
    int end = (offset + limit);
    if (start >= filteredList.length) {
      return [];
    }
    if (end > filteredList.length) {
      end = filteredList.length;
    }

    await Future.delayed(const Duration(milliseconds: 500));
    return filteredList.sublist(start, end);
  }

  @override
  Future<List<FoodEntry>> getAllFoodEntries() async {
    if (_foodBox == null || !_foodBox!.isOpen) {
      _foodBox = await Hive.openBox<FoodEntry>(_foodBoxName);
    }
    await Future.delayed(const Duration(milliseconds: 100));
    return _foodBox!.values.toList();
  }

  @override
  Future<int> getTotalCaloriesForDate(DateTime date) async {
    if (_foodBox == null || !_foodBox!.isOpen) {
      _foodBox = await Hive.openBox<FoodEntry>(_foodBoxName);
    }

    final targetDate = DateUtils.dateOnly(date);

    final total = _foodBox!.values
        .where((e) => DateUtils.dateOnly(e.date) == targetDate)
        .fold(0, (sum, e) => sum + e.calories);

    await Future.delayed(const Duration(milliseconds: 100));
    return total;
  }

  @override
  Future<void> addFoodEntry(FoodEntry entry) async {
    if (_foodBox == null || !_foodBox!.isOpen) {
      _foodBox = await Hive.openBox<FoodEntry>(_foodBoxName);
    }

    final newId = 'F${DateTime.now().millisecondsSinceEpoch}';
    final newEntry = entry.copyWith(id: newId);

    // 🔥 HIVE'a kaydet - ID'yi key olarak kullan
    await _foodBox!.put(newId, newEntry);
  }

  @override
  Future<void> updateFoodEntry(FoodEntry entry) async {
    if (_foodBox == null || !_foodBox!.isOpen) {
      _foodBox = await Hive.openBox<FoodEntry>(_foodBoxName);
    }

    // 🔥 Mevcut kaydı güncelle
    await _foodBox!.put(entry.id, entry);
  }

  @override
  Future<void> deleteFoodEntry(String id) async {
    if (_foodBox == null || !_foodBox!.isOpen) {
      _foodBox = await Hive.openBox<FoodEntry>(_foodBoxName);
    }

    // 🔥 ID ile kaydı sil
    await _foodBox!.delete(id);
  }

  // ------------------------- KİLO İŞLEMLERİ -------------------------

  @override
  Future<List<WeightEntry>> getAllWeightEntries() async {
    if (_weightBox == null || !_weightBox!.isOpen) {
      _weightBox = await Hive.openBox<WeightEntry>(_weightBoxName);
    }

    // Tarihe göre sıralı döndür
    final list = _weightBox!.values.toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  @override
  Future<void> addWeightEntry(WeightEntry entry) async {
    if (_weightBox == null || !_weightBox!.isOpen) {
      _weightBox = await Hive.openBox<WeightEntry>(_weightBoxName);
    }

    final newId = 'W${DateTime.now().millisecondsSinceEpoch}';
    final newEntry = WeightEntry(
      id: newId,
      date: DateUtils.dateOnly(entry.date),
      weightKg: entry.weightKg,
    );

    // Aynı haftadan (gününden) giriş varsa güncelle
    final existingEntry = _weightBox!.values.firstWhere(
      (e) => DateUtils.dateOnly(e.date) == DateUtils.dateOnly(entry.date),
      orElse: () => WeightEntry(id: '', date: DateTime(1900), weightKg: 0),
    );

    if (existingEntry.id.isNotEmpty) {
      // 🔥 Mevcut kaydı güncelle
      await _weightBox!.put(existingEntry.id, newEntry);
    } else {
      // 🔥 Yeni kayıt ekle
      await _weightBox!.put(newId, newEntry);
    }
  }

  // ------------------------- EGZERSİZ İŞLEMLERİ -------------------------

  @override
  Future<void> addWorkoutEntry(WorkoutEntry entry) async {
    if (_workoutBox == null || !_workoutBox!.isOpen) {
      _workoutBox = await Hive.openBox<WorkoutEntry>(_workoutBoxName);
    }

    final newId = 'WO${DateTime.now().millisecondsSinceEpoch}';
    final newEntry = WorkoutEntry(
      id: newId,
      date: DateUtils.dateOnly(entry.date),
      region: entry.region,
      exercise: entry.exercise,
      sets: entry.sets,
      reps: entry.reps,
      weight: entry.weight,
    );

    // 🔥 HIVE'a kaydet
    await _workoutBox!.put(newId, newEntry);
  }

  @override
  Future<List<WorkoutEntry>> getWorkoutEntries(DateTime date) async {
    if (_workoutBox == null || !_workoutBox!.isOpen) {
      _workoutBox = await Hive.openBox<WorkoutEntry>(_workoutBoxName);
    }

    final targetDate = DateUtils.dateOnly(date);
    return _workoutBox!.values
        .where((e) => DateUtils.dateOnly(e.date) == targetDate)
        .toList();
  }
}

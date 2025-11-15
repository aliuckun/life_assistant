// lib/features/fitness_tracker/domain/entities/fitness_entities.dart
import 'package:hive/hive.dart';

part 'fitness_entities.g.dart'; // 🔥 Code generation için

// 🔥 HIVE TYPE IDs - Her entity için benzersiz ID
@HiveType(typeId: 0)
enum MealType {
  @HiveField(0)
  sabah,
  @HiveField(1)
  ogle,
  @HiveField(2)
  aksam,
  @HiveField(3)
  ekstra,
}

// 1. Yemek Girişi (Günlük Kalori)
@HiveType(typeId: 1)
class FoodEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final MealType mealType;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final int calories;

  FoodEntry({
    required this.id,
    required this.date,
    required this.mealType,
    required this.description,
    required this.calories,
  });

  FoodEntry copyWith({
    String? id,
    DateTime? date,
    MealType? mealType,
    String? description,
    int? calories,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      description: description ?? this.description,
      calories: calories ?? this.calories,
    );
  }
}

// 2. Spor/Egzersiz Girişi (Workout)
@HiveType(typeId: 2)
class WorkoutEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String region;

  @HiveField(3)
  final String exercise;

  @HiveField(4)
  final int sets;

  @HiveField(5)
  final int reps;

  @HiveField(6)
  final double weight;

  WorkoutEntry({
    required this.id,
    required this.date,
    required this.region,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.weight,
  });
}

// 3. Haftalık Kilo Girişi (Weight)
@HiveType(typeId: 3)
class WeightEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double weightKg;

  WeightEntry({required this.id, required this.date, required this.weightKg});
}

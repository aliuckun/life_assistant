// lib/features/habit_tracker/data/habit_repository.dart
import '../domain/entities/habit.dart';

abstract class HabitRepository {
  // Lazy Loading için sayfalama (limit ve offset)
  Future<List<Habit>> getHabits({required int limit, required int offset});

  // Özet ve analiz için tüm verileri çeker
  Future<List<Habit>> getAllHabits();

  Future<void> addHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> deleteHabit(String id);
}

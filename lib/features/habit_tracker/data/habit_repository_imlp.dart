// lib/features/habit_tracker/data/habit_repository_impl.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../domain/entities/habit.dart';
import './habit_repository.dart';

class HabitRepositoryImpl implements HabitRepository {
  // 🔥 HIVE BOX İSMİ
  static const String _habitBoxName = 'habits';

  // 🔥 HIVE BOX
  Box<Habit>? _habitBox;

  // 🔥 SINGLETON PATTERN
  static HabitRepositoryImpl? _instance;
  static Future<HabitRepositoryImpl> getInstance() async {
    if (_instance == null) {
      _instance = HabitRepositoryImpl._internal();
      await _instance!._initBox();
    }
    return _instance!;
  }

  // Private constructor
  HabitRepositoryImpl._internal();

  Future<void> _initBox() async {
    if (_habitBox == null || !_habitBox!.isOpen) {
      _habitBox = await Hive.openBox<Habit>(_habitBoxName);
      debugPrint('✅ Habit box opened successfully');
    }
  }

  // ------------------------------------------------------------------------
  // 💰 LAZY LOADING / INFINITE SCROLL İşlemi
  // ------------------------------------------------------------------------
  @override
  Future<List<Habit>> getHabits({
    required int limit,
    required int offset,
  }) async {
    await _ensureBoxOpen();

    // Tüm habit'leri liste olarak al
    final allHabits = _habitBox!.values.toList();

    // Belirtilen offset ve limitle veriyi parçala
    int start = offset;
    int end = (offset + limit);
    if (start >= allHabits.length) {
      return []; // Daha fazla veri yok
    }
    if (end > allHabits.length) {
      end = allHabits.length;
    }

    // Gecikmeyi simüle et (Lazy Loading'i görmek için)
    await Future.delayed(const Duration(milliseconds: 700));

    return allHabits.sublist(start, end);
  }

  // ------------------------------------------------------------------------
  // ➕ CRUD ve getAllHabits
  // ------------------------------------------------------------------------

  @override
  Future<List<Habit>> getAllHabits() async {
    await _ensureBoxOpen();
    await Future.delayed(const Duration(milliseconds: 100));
    return _habitBox!.values.toList();
  }

  @override
  Future<void> addHabit(Habit habit) async {
    await _ensureBoxOpen();

    // Yeni bir ID oluştur
    final newId = 'H${DateTime.now().millisecondsSinceEpoch}';
    final newHabit = habit.copyWith(id: newId);

    // 🔥 HIVE'a kaydet - ID'yi key olarak kullan
    await _habitBox!.put(newId, newHabit);
    debugPrint('Habit added: $newId');
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    await _ensureBoxOpen();

    // 🔥 Mevcut kaydı güncelle
    await _habitBox!.put(habit.id, habit);
    debugPrint('Habit updated: ${habit.id}');
  }

  @override
  Future<void> deleteHabit(String id) async {
    await _ensureBoxOpen();

    // 🔥 ID ile kaydı sil
    await _habitBox!.delete(id);
    debugPrint('Habit deleted: $id');
  }

  // 🔥 HELPER METHOD - Box'ın açık olduğundan emin ol
  Future<void> _ensureBoxOpen() async {
    if (_habitBox == null || !_habitBox!.isOpen) {
      _habitBox = await Hive.openBox<Habit>(_habitBoxName);
    }
  }
}

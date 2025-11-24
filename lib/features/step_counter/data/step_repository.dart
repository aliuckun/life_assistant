// -----------------------------------------------------------------------------
// DOSYA: lib/features/step_counter/data/step_repository.dart
// KATMAN: Data
// AÇIKLAMA: Code Generation yapısına uygun, nesne tabanlı repository.
// -----------------------------------------------------------------------------

import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/step_model.dart';

class StepRepository {
  // Artık kutumuzun içinde 'DailySteps' nesneleri olduğunu biliyoruz
  Box<DailySteps>? _dailyBox;
  Box? _settingsBox;

  Stream<StepCount>? _stepStream;

  static final StepRepository _instance = StepRepository._internal();
  factory StepRepository() => _instance;
  StepRepository._internal();

  Future<void> init() async {
    // Adapter kayıtlı olduğu için artık tip güvenli (type-safe) kutu açabiliriz
    if (!Hive.isBoxOpen('daily_steps_objects')) {
      _dailyBox = await Hive.openBox<DailySteps>('daily_steps_objects');
    } else {
      _dailyBox = Hive.box<DailySteps>('daily_steps_objects');
    }

    if (!Hive.isBoxOpen('step_settings')) {
      _settingsBox = await Hive.openBox('step_settings');
    } else {
      _settingsBox = Hive.box('step_settings');
    }
  }

  Future<bool> requestPermission() async {
    PermissionStatus status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  Stream<StepCount> getSensorStream() {
    _stepStream ??= Pedometer.stepCountStream;
    return _stepStream!;
  }

  // --- HIVE İŞLEMLERİ (NESNE TABANLI) ---

  int getStepsForDate(DateTime date) {
    final key = _getDateKey(date);
    // Kutudan direkt nesneyi çekiyoruz
    final DailySteps? data = _dailyBox?.get(key);
    return data?.steps ?? 0;
  }

  Future<void> updateStepsForDate(DateTime date, int steps) async {
    final key = _getDateKey(date);
    // Yeni bir nesne oluşturup kaydediyoruz
    final newStepData = DailySteps(date: date, steps: steps);
    await _dailyBox?.put(key, newStepData);
  }

  Future<void> saveLastSensorReading(int rawValue) async {
    await _settingsBox?.put('last_sensor_reading', rawValue);
  }

  int getLastSensorReading() {
    return _settingsBox?.get('last_sensor_reading', defaultValue: -1) ?? -1;
  }

  List<DailySteps> getMonthlyHistory() {
    List<DailySteps> history = [];
    final now = DateTime.now();

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final steps = getStepsForDate(date);
      history.add(DailySteps(date: date, steps: steps));
    }
    return history;
  }

  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }
}
